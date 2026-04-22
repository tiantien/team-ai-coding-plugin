# BladeX 开发进阶

## 聚合文档 (Knife4j)

- **Cloud 版**: 网关聚合所有微服务 Swagger 文档，各服务只需 `blade-starter-swagger` 依赖
- **Boot 版**: 内置 swagger-ui
- **文档地址**: http://localhost/doc.html (Knife4j) 或 http://localhost/swagger-ui.html
- **Cloud 注意**: swagger-ui 和 knife4j-ui 互斥，只能启用一个
- **prod 环境**: Swagger 默认禁用，确保安全

**多包扫描**: BladeX 支持多包扫描配置
**API 排序**: `@ApiOperationSupport(order = 1)`
**隐藏 API**: `@Hidden` 注解
**注意**: Knife4j 刷新页面后增强配置丢失，需手动关闭标签重新打开

## 鉴权配置

### Cloud 版
- 鉴权放在网关层，基于 Nacos 动态鉴权
- Secure 模块默认关闭
```yaml
blade:
  secure:
    skip-url:
      - /test/**
      - /demo/**
```
**注意**: `blade-desk` 前缀是网关转发 key，不是 Controller 路径

### Boot 版
- 配置方式相同，需手动开启 Secure 模块
- Boot 版在 Controller 层添加前缀以匹配 Cloud 接口地址

### 获取当前用户
```java
// 方式1: 工具类
BladeUser user = AuthUtil.getUser();

// 方式2: 参数注入
public R info(BladeUser user) { ... }
```

## 跨域处理 (CORS)

**方案一**: Spring Cloud Gateway WebFilter (配置 CorsUtils 响应头)
**方案二**: SpringBoot WebMvcConfigurer.addCorsMappings()
**方案三 (推荐)**: Nginx 反向代理 (性能最优，减少网关负担)

## 单元测试

BladeX 自定义启动导致 SpringBoot 默认测试方式失效，使用:
```java
@ExtendWith(BladeSpringExtension.class)
@BladeBootTest(appName = "blade-runner", profile = "test", enableLoader = true)
public class BladeTest {
    // Cloud 版需在 Nacos 创建 test 环境配置
}
```
依赖: `blade-core-test`

## 日志系统

### 架构
使用 Spring Event 异步日志，替代传统 log4j 方案:
- **错误日志**: `BladeRestExceptionTranslator` 全局异常捕获 → `ErrorLogPublisher` → 异步写入数据库
- **API 日志**: `@ApiLog` 注解 → AOP 拦截 → `ApiLogPublisher` → 异步写入数据库

### 使用
```java
// API 日志注解
@ApiLog("Blog详情")
@GetMapping("/detail")
public R<Blog> detail(@RequestParam Integer id) { ... }

// 自定义日志
@Autowired
private BladeLogger logger;
logger.info("detail_test", JsonUtil.toJson(detail));
```

**高可用建议**: 日志表部署在独立数据库，多个 blade-log 服务实例

## 安全防护

### XSS 防注入
```yaml
blade:
  xss:
    enabled: true
    mode: clear  # clear(清除) / escape(转义) / validate(验证抛异常)
    pretty-print: false
    skip-url:
      - /webjars/**
```
- `@XssIgnore`: 方法/类级别跳过 XSS 过滤
- `@JsonDeserialize(using = XssDeserializer.class)`: 指定 JSON 字段使用 XSS 反序列化
- 可实现自定义 `XssCleaner` Bean

### SQL 防注入
```java
// 使用 Condition 类自动过滤
Condition.getQueryWrapper(notice, Notice.class)  // 自动移除非 Entity 字段
SqlKeyword.filter(someString)  // 直接过滤 SQL 关键字
```

### 请求黑白名单
```yaml
blade:
  request:
    enabled: true
    black-list:
      - 192.168.1.100
    white-list:
      - 10.0.0.1
    block-url:
      - /**
    skip-url:
      - /public/**
```
- 本地/Docker/K8S IP 自动白名单
- `/actuator` 从 4.3.0 起强制拦截外部访问

### 请求方法限制
```yaml
blade:
  request:
    allow-methods: GET,POST,PUT,DELETE
    method-rules:
      - pattern: /readonly/**
        methods: GET
      - pattern: /upload/**
        methods: POST
```
支持 Ant 风格路径匹配，path-level 规则优先级高于全局配置

## 自定义启动器 (BladeApplication)

```java
BladeApplication.run("blade-demo", DemoApplication.class, args);
```
- 自动检测 dev/test/prod 环境
- 默认 dev 环境 (无需配置 spring.profiles.active)
- 运行时覆盖: `java -jar app.jar --spring.profiles.active=prod --server.port=2333`
- 一次打包，处处运行

## 统一服务配置 (LauncherService)

**用途**: 配置启动级参数和所有微服务通用参数
**优势**: 写在共享依赖中，一处修改全平台生效，无需每个服务重复配置 yml

配置覆盖方式:
- 命令行: `java -jar app.jar --spring.profiles.active=prod`
- Docker Compose: `command:` 部分传参

## 乐观锁

1. 添加 `MybatisPlusInterceptor` 配置 Bean + `OptimisticLockerInnerInterceptor()`
2. 实体表添加 `version` 字段 (INT 类型)
3. 前端表单包含 version 字段
4. 每次保存自动递增 version，并发编辑时后保存方失败

## BladeX-Biz 工程

- **用途**: 分离业务代码和核心框架，适合多团队开发
- **优势**: 框架升级不影响业务代码
- **架构**: 每个子系统独立 BladeX-Biz + 独立网关
- **迁移**: 业务代码迁移到 blade-service/blade-service-api，公共代码到 blade-common
- **仓库**: https://git.bladex.vip/blade/BladeX-Biz

## Boot 版对接 Cloud

将 SpringBoot 单体迁移到 SpringCloud 平台:
1. 移除单体配置，添加 Cloud 自动配置
2. 复制 Cloud 版 blade-common 配置
3. 更新 application-dev.yml 从 Nacos 获取配置
4. 重启验证 Nacos 注册
