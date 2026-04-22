# BladeX 开发指南

## 技术基础

### Java 8-17 核心特性
- **Lambda**: `parameters -> expression`，简化匿名类写法
- **Stream API**: 声明式集合处理 (filter/map/flatMap/distinct/sorted/limit/skip → collect/reduce/forEach)
- **Optional**: 消灭空指针 (ofNullable/map/flatMap/orElse/orElseThrow)
- **函数式接口**: Function<T,R>, Predicate<T>, Consumer<T>, Supplier<T>, BinaryOperator<T>
- **新日期 API**: LocalDate, LocalTime, LocalDateTime, ZonedDateTime, DateTimeFormatter (线程安全)
- **Java 17**: Sealed Classes, Pattern Matching, ZGC 垃圾回收器

### ZGC 推荐生产配置
```bash
java -XX:+UseZGC -XX:+PrintCommandLineFlags \
  -Xms2g -Xmx2g \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.util=ALL-UNNAMED \
  -jar your-application.jar
```

### Lombok 常用注解
- `@Data`: 生成 getter/setter/toString/equals/hashCode/无参构造
- `@Slf4j`: 直接使用 log 变量
- `@Builder`: 构建者模式
- `@AllArgsConstructor`: 全参构造 (推荐用于 Controller 注入)
- `@NoArgsConstructor`: 无参构造
- `@SneakyThrows`: 免声明抛出异常

### OpenAPI 3 (Swagger 3) 注解
| Swagger 2 | Swagger 3 | 用途 |
|---|---|---|
| @Api | @Tag | 类级别标记 |
| @ApiOperation | @Operation | 方法级别 |
| @ApiParam | @Parameter | 参数文档 |
| @ApiModel | @Schema | 类文档 |
| @ApiModelProperty | @Schema | 字段文档 |
| @ApiIgnore | @Hidden / @Parameter(hidden=true) | 隐藏 |
| @ApiResponse | @ApiResponse | 响应码 |

**包路径**: `io.swagger.v3.oas.annotations.*`

### MyBatis-Plus 核心
- 非侵入式增强 (只加不改)
- 通用 CRUD: 继承 BaseMapper<T> / IService<T>
- Lambda 条件构造器
- 分页插件 (物理分页，透明化)
- 多数据库支持: MySQL, Oracle, PostgreSQL, DB2, SQLite 等
- 逻辑删除: `@TableLogic` 注解

### 动态多数据源 (dynamic-datasource)
- `@DS("dsName")` 注解切换数据源
- 命名约定: 下划线前缀定义分组 (slave_1, slave_2 → slave 组)
- 默认数据源: "master" (可配置)
- 优先级: 方法注解 > 类注解

## 第一个微服务

### 模块结构
每个业务域创建两个模块:
- `blade-demo` (在 blade-service 下): 业务实现
- `blade-demo-api` (在 blade-service-api 下): Entity/VO/DTO/Feign 接口

### 核心依赖
```xml
<!-- 核心启动依赖 (提供所有通用配置) -->
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-core-boot</artifactId>
</dependency>
<!-- Swagger 文档 -->
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-starter-swagger</artifactId>
</dependency>
```
blade-core-xxx 和 blade-starter-xxx 包无需指定版本 (BOM 管理)。

### 项目配置
1. 从参考模块 (如 blade-desk) 复制资源文件
2. `application-dev.yml` 中设置 `server.port` (如 9101)
3. 创建包结构: `org.springblade.demo`
4. 创建启动类: `BladeApplication.run("blade-demo", DemoApplication.class, args)`
5. 启动后自动注册到 Nacos

## 第一个 API

### Controller 基础
```java
@RestController
@RequestMapping("api")
@AllArgsConstructor  // Lombok 构造器注入
public class DemoController {

    @GetMapping("info")
    @PreAuth("hasRole('administrator')")
    public R<String> info(String name) {
        return R.data("Hello, My Name Is: " + name);
    }
}
```

### 鉴权放行配置
```yaml
# Boot 版本: application.yml / Cloud 版本: Nacos
blade:
  secure:
    skip-url:
      - /api/**
```
注意: Cloud 版 `blade-desk` 前缀是网关转发 key，不是 Controller 路径。

### 获取当前用户
```java
BladeUser user = AuthUtil.getUser();
// 或通过参数注入
public R<String> info(BladeUser user) { ... }
```

## 第一个缓存 (Redis)

```java
// 缓存读取
@Cacheable(cacheNames = "demo-info", key = "#name")
public R<String> info(String name) { ... }

// 缓存清除
@CacheEvict(cacheNames = "demo-info", key = "#name")
public R<String> removeInfo(String name) { ... }
```

## 第一个 CRUD

### 实体类 (放在 blade-demo-api)
```java
@Data
@TableName("blade_blog")
public class Blog implements Serializable {
    @TableId(value = "id", type = IdType.ASSIGN_ID) // 雪花算法
    private Long id;
    private String blogTitle;
    private String blogContent;
    private Date blogDate;
    @TableLogic // 逻辑删除
    private Integer isDeleted;
}
```

### Mapper + Service
```java
public interface BlogMapper extends BaseMapper<Blog> {}
public interface BlogService extends IService<Blog> {}

@Service
public class BlogServiceImpl extends ServiceImpl<BlogMapper, Blog> implements BlogService {}
```

### CRUD 接口
```java
@RestController
@RequestMapping("api/blog")
@AllArgsConstructor
public class BlogController {
    private BlogService service;

    @PostMapping("/save")
    public R save(@RequestBody Blog blog) { return R.status(service.save(blog)); }

    @PostMapping("/update")
    public R update(@RequestBody Blog blog) { return R.status(service.updateById(blog)); }

    @PostMapping("/remove")
    public R remove(@RequestParam String ids) {
        return R.status(service.removeByIds(Func.toLongList(ids)));
    }

    @GetMapping("/detail")
    public R<Blog> detail(Integer id) { return R.data(service.getById(id)); }

    // 列表查询 (支持模糊搜索)
    @GetMapping("/list")
    public R<List<Blog>> list(@RequestParam Map<String, Object> blog) {
        List<Blog> list = service.list(
            Condition.getQueryWrapper(blog, Blog.class)
                .lambda().orderByDesc(Blog::getBlogDate));
        return R.data(list);
    }

    // 分页查询
    @GetMapping("/page")
    public R<IPage<Blog>> page(@RequestParam Map<String, Object> blog, Query query) {
        IPage<Blog> pages = service.page(
            Condition.getPage(query),
            Condition.getQueryWrapper(blog, Blog.class));
        return R.data(pages);
    }
}
```

**分页参数**: `?current=1&size=10&blogContent=关键词`

## Feign 远程调用

### 1. 定义 Feign 接口 (在 blade-demo-api)
```java
@FeignClient(value = "blade-demo", fallback = BlogClientFallback.class)
public interface BlogClient {
    String API_PREFIX = "/api/blog";

    @GetMapping(API_PREFIX + "/detail")
    R<Blog> detail(@RequestParam("id") Integer id);
}
```

### 2. 实现 (在 blade-demo)
```java
@RestController
@AllArgsConstructor
public class BlogClientImpl implements BlogClient {
    private BlogService service;

    @Override
    @GetMapping(API_PREFIX + "/detail")
    public R<Blog> detail(Integer id) { return R.data(service.getById(id)); }
}
```

### 3. Hystrix 熔断降级
```java
public class BlogClientFallback implements BlogClient {
    @Override
    public R<Blog> detail(Integer id) {
        Blog blog = new Blog();
        blog.setBlogTitle("Hystrix FallBack");
        return R.data(blog);
    }
}
```

## 代码生成

基于 **Beetl 模板引擎** (`.btl`) + MyBatis-Plus Generator，使用 `blade-starter-develop` 模块。

### 配置项
- **数据模型**: 数据表结构
- **服务名**: Controller 前缀和前端包名
- **表前缀**: 生成实体时忽略的前缀 (如 `tb_` → Blog 而非 TbBlog)
- **主键名**: 主键字段名
- **包名**: 后端包路径
- **基础业务**: 继承 BaseEntity (含审计字段)
- **包装器**: 生成 VO 和 Wrapper 类
- **远程调用**: 生成 Feign 代码

### 支持类型
1. **单表 (crud)**: 标准 CRUD
2. **主子表 (sub)**: 父子关联表
3. **树表 (tree)**: 带 parent_id 的层级结构

### 模板体系 (79 个模板文件)

**后端模板** (`templates/api/` 12 个 + `templates/api-fast/` 10 个):
| 模板 | 生成文件 | 说明 |
|------|----------|------|
| `controller.java.btl` | XxxController.java | REST 控制器 (OpenAPI 3 注解) |
| `entity.java.btl` | Xxx.java | 实体类 (@TableName + @TableId) |
| `entityVO.java.btl` | XxxVO.java | 视图对象 |
| `entityDTO.java.btl` | XxxDTO.java | 传输对象 |
| `entityExcel.java.btl` | XxxExcel.java | Excel 导出对象 |
| `wrapper.java.btl` | XxxWrapper.java | 包装器 (Entity→VO 转换) |
| `service.java.btl` | IXxxService.java | 服务接口 |
| `serviceImpl.java.btl` | XxxServiceImpl.java | 服务实现 |
| `mapper.java.btl` | XxxMapper.java | Mapper 接口 |
| `mapper.xml.btl` | XxxMapper.xml | MyBatis XML |
| `feign.java.btl` | IXxxClient.java | Feign 客户端接口 |
| `feignclient.java.btl` | XxxClient.java | Feign 客户端实现 |

**前端模板** (5 套 UI 框架 × 3 种表类型):
| 框架 | 技术栈 | 文件 |
|------|--------|------|
| Saber3 | Vue3 + avue-crud | crud.vue, api.js, option.js |
| Saber | Vue2 + avue-crud | crud.vue, api.js, option.js |
| Element-Plus | Vue3 + 原生 Element | crud.vue, api.js, option.js |
| Element | Vue2 + 原生 Element | crud.vue, api.js, option.js |
| Lemon | Vue3 + Composition API + TS | index.vue, Modal.vue, data.ts |

**SQL 模板**: `menu.sql.btl` — 生成菜单 INSERT 语句

### 生成的代码风格 (最新模板)

**Controller 模式** — 使用 OpenAPI 3 注解 + `@IsAdmin` 权限:
```java
@RestController
@AllArgsConstructor
@RequestMapping("/xxx")
@Tag(name = "Xxx", description = "Xxx接口")
public class XxxController extends BladeController {

    private final IXxxService xxxService;

    @GetMapping("/detail")
    @ApiOperationSupport(order = 1)
    @Operation(summary = "详情", description = "传入xxx")
    public R<XxxVO> detail(Xxx xxx) {
        Xxx detail = xxxService.getOne(Condition.getQueryWrapper(xxx));
        return R.data(XxxWrapper.build().entityVO(detail));
    }

    @GetMapping("/page")
    @ApiOperationSupport(order = 3)
    @Operation(summary = "分页", description = "传入xxx")
    public R<IPage<XxxVO>> page(XxxVO xxx, Query query) {
        IPage<Xxx> pages = xxxService.page(Condition.getPage(query), Condition.getQueryWrapper(xxx));
        return R.data(XxxWrapper.build().pageVO(pages));
    }

    @PostMapping("/save")
    @ApiOperationSupport(order = 4)
    @Operation(summary = "新增", description = "传入xxx")
    public R save(@Valid @RequestBody Xxx xxx) {
        return R.status(xxxService.save(xxx));
    }

    @PostMapping("/update")
    @ApiOperationSupport(order = 5)
    @Operation(summary = "修改", description = "传入xxx")
    public R update(@Valid @RequestBody Xxx xxx) {
        return R.status(xxxService.updateById(xxx));
    }

    @PostMapping("/remove")
    @ApiOperationSupport(order = 7)
    @Operation(summary = "逻辑删除", description = "传入ids")
    public R remove(@Parameter(description = "主键集合", required = true) @RequestParam String ids) {
        return R.status(xxxService.deleteLogic(Func.toLongList(ids)));
    }
}
```

**Entity 模式** — 使用 `@Schema` + `@TableName`:
```java
@Data
@TableName("xxx_table")
@EqualsAndHashCode(callSuper = true)
@Schema(description = "Xxx对象")
public class Xxx extends BaseEntity {
    @Schema(description = "字段说明")
    private String fieldName;
}
```

**Wrapper 模式** — Entity→VO 转换:
```java
public class XxxWrapper extends BaseEntityWrapper<Xxx, XxxVO> {
    public static XxxWrapper build() { return new XxxWrapper(); }

    @Override
    public XxxVO entityVO(Xxx entity) {
        XxxVO vo = BeanUtil.copyProperties(entity, XxxVO.class);
        return vo;
    }
}
```

### 快速生成
- **在线快速生成**: 选择数据源和物理表，自动填充默认值
- **离线快速生成**: Boot 版右键运行 `CodeGenerator` / `BladeFastCodeGenerator` 类
- **可视化表单设计器**: v4.3.0+ 集成拖拽式表单绑定 (免费)
- **模板引擎**: Beetl (`BladeTemplateEngine`)，模板位于 `blade-starter-develop/src/main/resources/templates/`

### 开发规范
- 遵循阿里巴巴 Java 开发手册
- IDEA 安装 P3C 插件: https://github.com/alibaba/p3c
