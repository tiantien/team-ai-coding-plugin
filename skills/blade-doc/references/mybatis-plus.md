# MyBatis-Plus 增强插件

基于 MyBatis-Plus 的深度增强模块，提供分页、多租户、SQL 日志、自定义 SQL 注入、查询构造器等企业级能力。

## 依赖与配置

```xml
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-starter-mybatis</artifactId>
</dependency>
```

```yaml
blade:
  mybatis-plus:
    tenant-mode: true        # 开启租户模式，默认 true
    record-mode: true        # 开启数据变更审计，默认 true
    sql-log: true            # 开启 SQL 日志，默认 true
    sql-log-exclude: []      # SQL 日志忽略关键字列表
    page-limit: 500          # 单页最大条数，默认 500
    batch-update-limit: 1000 # 批量更新最大条数，默认 1000
    overflow: false          # 溢出总页数后是否处理，默认 false
    optimize-join: false     # 是否优化 join 查询，默认 false
```

## 拦截器体系

框架自动装配 `MybatisPlusInterceptor`，按以下顺序加载：

```
MybatisPlusInterceptor
  ├── 1. TenantLineInnerInterceptor     （租户拦截，tenant-mode=true 时加载）
  ├── 2. DataChangeRecorderInnerInterceptor （数据审计，record-mode=true 时加载）
  ├── 3. PaginationInnerInterceptor      （分页拦截，始终加载）
  └── 4. MybatisPlusInterceptorCustomizer（用户自定义，按 @Order 排序）
```

### 多租户拦截器

默认开启，自动在 SQL 中注入 `tenant_id` 条件。默认实现 `ignoreTable` 返回 `true`（忽略所有表），业务工程中通过 `@ConditionalOnMissingBean` 覆盖：

```java
@Bean
public TenantLineInnerInterceptor tenantLineInnerInterceptor() {
    return new TenantLineInnerInterceptor(new TenantLineHandler() {
        @Override
        public Expression getTenantId() {
            return new StringValue(AuthUtil.getTenantId());
        }
        @Override
        public boolean ignoreTable(String tableName) {
            return !tenantTables.contains(tableName);
        }
    });
}
```

关闭：`blade.mybatis-plus.tenant-mode: false`

### 数据变更审计拦截器

自动记录 INSERT / UPDATE / DELETE 操作，配合 `blade-starter-data-record` 实现完整数据审计。

关闭：`blade.mybatis-plus.record-mode: false`

### 智能分页拦截器

`BladePaginationInterceptor` 增强能力：
- **自动方言检测**：根据 JDBC URL 自动识别数据库类型（含崖山 YashanDB → Oracle 方言、SQLServer 自定义方言）
- **查询拦截器**：支持注入 `QueryInterceptor` 数组，在分页查询前执行自定义逻辑

```java
@Bean
public QueryInterceptor myQueryInterceptor() {
    return new QueryInterceptor() {
        @Override
        public void intercept(Executor executor, MappedStatement ms, Object parameter,
                              RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {
            // 自定义查询拦截逻辑
        }
        @Override
        public int getOrder() { return 0; }
    };
}
```

### 拦截器定制器

通过 `MybatisPlusInterceptorCustomizer` 扩展拦截器链，无需替换整个 Bean：

```java
@Bean
public MybatisPlusInterceptorCustomizer myCustomizer() {
    return interceptor -> {
        interceptor.addInnerInterceptor(new OptimisticLockerInnerInterceptor());
    };
}

// 多个定制器通过 @Order 控制顺序
@Bean
@Order(1)
public MybatisPlusInterceptorCustomizer blockAttackCustomizer() {
    return interceptor -> interceptor.addInnerInterceptor(new BlockAttackInnerInterceptor());
}
```

## SQL 日志

基于 Druid `FilterEventAdapter`，Statement 关闭时输出格式化后的可执行 SQL：

```
==============  Sql Start  ==============
Execute SQL : SELECT id, name, status FROM sys_user WHERE tenant_id = '000000' AND is_deleted = 0
Execute Time: 5.2 ms
==============  Sql  End   ==============
```

排除特定 SQL（内置排除 Flowable 的 `ACT_RU_JOB`、`ACT_RU_TIMER_JOB`）：

```yaml
blade:
  mybatis-plus:
    sql-log-exclude:
      - QRTZ_TRIGGER
      - ACT_HI_PROCINST
```

## 自定义 SQL 注入

`BladeSqlInjector` 在 MyBatis-Plus 默认方法基础上注入三种写入策略：

| 方法 | SQL | 说明 |
|-----|-----|------|
| `insertIgnore` | `INSERT IGNORE INTO ...` | 记录已存在则忽略 |
| `replace` | `REPLACE INTO ...` | 记录已存在则替换 |
| `insertBatchSomeColumn` | `INSERT INTO ... VALUES (...), (...)` | 批量插入 |

### BladeMapper

继承 `BladeMapper` 使用扩展方法：

```java
public interface UserMapper extends BladeMapper<User> {
    // 自动继承 insertIgnore、replace、insertBatchSomeColumn
}
```

### BladeService

`BladeService` / `BladeServiceImpl` 封装批量操作：

```java
@Service
public class UserServiceImpl extends BladeServiceImpl<UserMapper, User> implements UserService {
    // 自动继承：
    // saveIgnore(entity)          — 单条忽略插入
    // saveReplace(entity)         — 单条替换插入
    // saveIgnoreBatch(entityList) — 批量忽略插入
    // saveReplaceBatch(entityList)— 批量替换插入
}
```

## 基类体系

### 实体基类

#### BaseEntity

通用基础实体，包含审计字段和逻辑删除：id, createUser, createDept, createTime, updateUser, updateTime, status, isDeleted

```java
@Data
@TableName("biz_order")
public class Order extends BaseEntity {
    private String orderNo;
    private BigDecimal amount;
}
```

#### BizEntity

比 BaseEntity 多 `tenantId` 字段，适用于多租户业务场景。

### 服务基类

#### BaseService（继承自 IService）

| 方法 | 说明 |
|------|------|
| `queryOne(queryWrapper)` | 条件查询单条 |
| `queryDetail(entity)` | 实体条件查询详情 |
| `queryDetail(map)` | Map 条件查询详情 |
| `deleteLogic(ids)` | 批量逻辑删除 |
| `changeStatus(ids, status)` | 批量变更状态 |
| `isFieldDuplicate(field, value)` | 字段值重复检测 |
| `isFieldDuplicate(field, value, excludedId)` | 排除自身的重复检测 |

#### BladeService

继承自 BaseService，额外提供 `saveIgnore`、`saveReplace` 等扩展写入方法。

## 查询构造器

### Condition 工具

将前端 `Map<String, Object>` 参数自动转换为 `QueryWrapper`：

```java
@GetMapping("/list")
public R<IPage<User>> list(@RequestParam Map<String, Object> user, Query query) {
    IPage<User> pages = userService.page(
        Condition.getPage(query),
        Condition.getQueryWrapper(user, User.class)
    );
    return R.data(pages);
}
```

### SqlKeyword 查询后缀

前端通过参数名后缀控制查询方式：

| 后缀 | 操作 | 示例参数 | 生成 SQL |
|------|------|---------|---------|
| `_equal` | 等于 | `name_equal=张三` | `name = '张三'` |
| `_notequal` | 不等于 | `status_notequal=0` | `status != 0` |
| `_like` | 模糊（默认） | `name=张` | `name LIKE '%张%'` |
| `_likeleft` | 左模糊 | `name_likeleft=三` | `name LIKE '%三'` |
| `_likeright` | 右模糊 | `name_likeright=张` | `name LIKE '张%'` |
| `_notlike` | 不包含 | `name_notlike=测试` | `name NOT LIKE '%测试%'` |
| `_ge` / `_le` / `_gt` / `_lt` | 比较运算 | `age_ge=18` | `age >= 18` |
| `_datege` / `_datele` | 日期比较 | `createTime_datege=2026-01-01` | `create_time >= '2026-01-01'` |
| `_null` / `_notnull` | 空值判断 | `remark_null=` | `remark IS NULL` |
| `_ignore` | 忽略 | `token_ignore=xxx` | 不参与查询 |

内置 SQL 注入防护，自动过滤 `SELECT`、`DROP`、`UNION` 等危险关键词。

## 分页工具

### Query 查询对象

| 参数 | 类型 | 说明 |
|------|------|------|
| current | Integer | 当前页码 |
| size | Integer | 每页条数 |
| ascs | String | 正序字段（逗号分隔） |
| descs | String | 倒序字段（逗号分隔） |

### BladePage 分页模型

```java
@GetMapping("/page")
public R<BladePage<UserVO>> page(Query query) {
    IPage<User> pages = userService.page(Condition.getPage(query));
    return R.data(BladePage.of(UserWrapper.build().pageVO(pages)));
}
```

### PageUtil 转换工具

```java
// IPage 转换为指定 VO 类型
Page<UserVO> voPage = PageUtil.toPage(page, UserVO.class);

// 配合自定义函数转换
Page<UserVO> voPage = PageUtil.toPage(page, user -> {
    UserVO vo = BeanUtil.copy(user, UserVO.class);
    vo.setRoleName(roleService.getRoleName(user.getRoleId()));
    return vo;
});
```

### BaseEntityWrapper

```java
public class UserWrapper extends BaseEntityWrapper<User, UserVO> {
    public static UserWrapper build() { return new UserWrapper(); }

    @Override
    public UserVO entityVO(User entity) {
        UserVO vo = BeanUtil.copy(entity, UserVO.class);
        vo.setRoleName(roleService.getRoleName(entity.getRoleId()));
        return vo;
    }
}

// 使用
UserWrapper.build().entityVO(user);      // 单个转换
UserWrapper.build().listVO(userList);    // 列表转换
UserWrapper.build().pageVO(userPage);    // 分页转换
```

## 配置参数一览

| 参数 | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| blade.mybatis-plus.tenant-mode | Boolean | true | 租户拦截 |
| blade.mybatis-plus.record-mode | Boolean | true | 数据变更审计 |
| blade.mybatis-plus.sql-log | Boolean | true | SQL 日志 |
| blade.mybatis-plus.sql-log-exclude | List | [] | SQL 日志忽略关键字 |
| blade.mybatis-plus.page-limit | Long | 500 | 单页最大条数 |
| blade.mybatis-plus.batch-update-limit | Integer | 1000 | 批量更新最大条数 |
| blade.mybatis-plus.overflow | Boolean | false | 溢出总页数后是否处理 |
| blade.mybatis-plus.optimize-join | Boolean | false | 是否优化 JOIN 查询 |
