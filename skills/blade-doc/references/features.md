# 扩展功能特性

## 分布式任务调度

### XXL-JOB
- 轻量级分布式任务调度平台
- 官网: https://www.xuxueli.com/xxl-job/

**Docker 部署**:
```bash
docker run --name xxl-job-admin -d -p 8080:8080 \
  --add-host="host.docker.internal:host-gateway" \
  xuxueli/xxl-job-admin:2.4.0
```
访问: http://localhost:8080/xxl-job-admin , 账号: admin / 123456

**集成**: BladeX-Biz 中的 blade-xxljob 项目，启动后在执行器管理中注册。

### PowerJob (原 OhMyScheduler)
- 新一代分布式任务调度与计算框架
- Web UI 可视化管理
- 定时策略: CRON、固定频率、固定延迟、API
- 执行模式: 单机、广播、Map、MapReduce
- 工作流: 在线 DAG 配置，任务间数据传递
- 执行器: Spring Bean、Java 类、Shell、Python、HTTP、SQL

## Sharding 分库分表

### 依赖
```xml
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-starter-sharding</artifactId>
</dependency>
```

### 配置
```yaml
blade:
  sharding:
    enabled: true
```

支持与多租户数据库隔离结合使用。

## OSS 对象存储

### 概述
集成 MinIO 分布式文件服务，支持多租户 OSS 系统。

### 配置 (blade_oss 表)
| 字段 | 说明 |
|------|------|
| oss_code | 存储类型 (minio/qiniu/alioss/tencentcos) |
| endpoint | 端点地址 |
| access_key | 访问密钥 |
| secret_key | 安全密钥 |
| bucket_name | 存储桶 |
| transform_domain | 内部上传返回外网地址 (3.3.0+) |

### 存储类型
- **MinIO**: 自建对象存储
- **七牛云**: qiniu
- **阿里 OSS**: alioss
- **腾讯 COS**: tencentcos
- **本地文件**: local 模式 (4.2.0+)

### 使用
每个租户可配置独立的 OSS，实现文件存储隔离。

## SMS 短信服务

### 支持平台
- 阿里云短信
- 腾讯云短信
- 七牛云短信

### 配置 (blade_sms 表)
| 字段 | 说明 |
|------|------|
| sms_code | 短信类型 (alicloud/tencentcloud/qiniu) |
| template_id | 模板 ID |
| access_key | 访问密钥 |
| secret_key | 安全密钥 |
| sign_name | 签名名称 |

### 短信登录 (4.1.0+)
集成多租户 SMS 模块实现短信验证码登录。

## Dubbo RPC 远程调用

完美集成最新 Dubbo，支持远程 RPC 调用。除 Feign (HTTP) 外的另一种微服务通信方式。

## 动态网关

### 特性
- 基于 Nacos 的动态网关
- 在线配置，实时生效
- 支持动态路由、鉴权、限流

### 网关鉴权
```yaml
# Nacos 配置动态鉴权规则
blade:
  secure:
    skip-url:
      - /blade-auth/**
      - /blade-resource/**
```

## 限流 (Sentinel)

### 概述
Sentinel 从流量控制、熔断降级、系统负载保护多维度保障系统稳定性。

### 配置
```yaml
spring:
  cloud:
    sentinel:
      transport:
        dashboard: localhost:8858
```

## 消息队列

### 支持
- **Kafka**: 高吞吐分布式消息系统
- **RabbitMQ**: AMQP 消息代理
- **SpringCloud Stream**: 统一消息抽象

## 分布式锁

基于 Redisson 封装的高性能分布式锁插件。

## SkyWalking APM

### 概述
分布式应用性能监控工具，支持微服务、Cloud Native 和容器化架构。

### 集成方式
- Agent 方式无侵入接入
- 链路追踪、性能监控、告警

## 多租户数据库隔离

### 模式
- **字段隔离**: 共享数据库，`tenant_id` 字段区分 (默认)
- **数据源隔离**: 每个租户独立数据库
  - 配置 `blade_tenant_datasource` 表
  - 使用 `blade-starter-sharding`

## Loadbalancer 组件与灰度发布

### 团队协作负载配置
支持多开发者同时调试同一服务:
- IP 段优先级 Feign 调用
- 灵活的负载均衡策略

### 灰度服务发布与调用
实现金丝雀部署 (灰度发布)，在正式版和灰度版之间平滑过渡。

**配置** (必须在 `application-dev.yml`，不能在 Nacos):
```yaml
blade:
  loadbalancer:
    enabled: true
    version: 3.0.0           # 灰度版本号
    prior-ip-pattern:
      - 192.168.0.*
      - 127.0.0.1
```

**工作方式**:
- 无 version 配置 = 正式服务
- 有 version 配置 = 灰度服务
- Nacos metadata 展示各实例版本号
- 前端两套部署: 正式 + 灰度 (灰度前端 axios 请求头添加 `version`)
- 灰度用户通过规则识别 (地区、用户等级、消费等级等)

## 高性能 Http 工具

基于 `okhttp3` + `jsoup` 的轻量 HTTP 客户端，封装在 `blade-starter-http`。

**SSL 证书配置**:
```java
// 加载证书 → 创建 SSLContext → 配置 OkHttpClient
HttpRequest.setHttpClient(builder.build());

// 单次请求配置
HttpRequest.get("https://example.com")
    .useConsoleLog(LogLevel.BODY)
    .sslSocketFactory(sc.getSocketFactory(), trustManager)
    .disableSslValidation()
    .execute()
    .asString();
```

## LiteFlow 组件式规则引擎

解耦复杂业务逻辑的组件化流程引擎，支持热加载规则配置。官网: https://liteflow.cc/

**适用场景**: 多逻辑有序执行、条件判断、频繁变化的逻辑。**不适用**于角色审批 (用 Flowable)。

**依赖**: `blade-starter-liteflow`

**组件实现**:
```java
@LiteflowComponent(id = "a")
public class ComponentA extends NodeComponent {
    @Override
    public void process() { /* 业务逻辑 */ }
}

// 条件分支组件
@LiteflowComponent(id = "b")
public class ComponentB extends NodeSwitchComponent {
    @Override
    public String processSwitch() { return "c"; }
}
```

**规则配置 (xxx.el.xml)**:
```xml
<chain name="chain1">THEN(a, b, c, d);</chain>       <!-- 串行 -->
<chain name="chain2">WHEN(a, b, c);</chain>            <!-- 并行 -->
<chain name="chain3">SWITCH(a).to(b, c, d);</chain>    <!-- 条件分支 -->
<chain name="chain4">IF(x, a, b);</chain>              <!-- IF/ELSE -->
<chain name="chain5">IF(x1, a).ELIF(x2, b).ELSE(c);</chain>
```

## LiteRule 超轻量级规则引擎 (4.6.0+)

BladeX 自研轻量规则引擎，替代 LiteFlow。已有 LiteFlow 实现建议继续保留。

**依赖**: `blade-starter-literule`

**核心概念**: Rule (最小执行单元) → RuleChain (执行顺序) → RuleContext (数据载体) → RuleConfig (执行行为)

**规则实现**:
```java
@LiteRuleComponent("orderValidateRule")
public class OrderValidateRule extends RuleComponent {
    @Override
    protected void process() throws Exception {
        OrderContext ctx = getContextBean(OrderContext.class);
        if (StringUtils.isEmpty(ctx.getOrderId())) { ctx.addError("订单ID不能为空"); }
    }
}

// 分支规则
@LiteRuleComponent("paymentRouteRule")
public class PaymentRouteRule extends RuleSwitchComponent {
    @Override
    protected List<String> process() throws Exception {
        OrderContext ctx = getContextBean(OrderContext.class);
        if ("ALIPAY".equals(ctx.getPaymentType())) return Collections.singletonList("alipayRule");
        return Collections.emptyList();
    }
}
```

**规则链构建**:
```java
@EngineComponent("orderChain")
public class OrderRuleBuilder implements RuleBuilder {
    @Override
    public RuleChain build() {
        RuleChain paymentRule = LiteRule.SWITCH("paymentRouteRule").TO("alipayRule", "wechatPayRule").build();
        return LiteRule.THEN("orderValidateRule", "orderAmountRule").THEN(paymentRule).build();
    }
}
```

**执行**:
```java
@Autowired private RuleEngineExecutor ruleEngine;
LiteRuleResponse<OrderContext> response = ruleEngine.execute("orderChain", context, config);
// 支持异步: ruleEngine.executeAsync("orderChain", context, threadPool)
```

**配置**:
```yaml
literule:
  cache:
    enabled: true
  preload:
    enabled: true
  execution:
    timeout: 30000
    enable-parallel: true
    max-parallel-threads: 10
```

## Sensitive 脱敏工具

### 使用
```java
SensitiveUtil.process("13812345678");                        // → 138****5678
SensitiveUtil.process("test@example.com", SensitiveType.EMAIL); // → t***@example.com
SensitiveUtil.process("330102199001011234", SensitiveType.ID_CARD); // → 330102********1234
```

### Jackson 注解
```java
public class UserDTO {
    @Sensitive(type = SensitiveType.MOBILE)
    private String mobile;
    @Sensitive(type = SensitiveType.EMAIL)
    private String email;
    @Sensitive(regex = "(?<=区域：).*", replacement = "***")
    private String region;
}
```

### 注意
- **仅 JSON 序列化生效** (Controller 返回、Feign 返回)，反序列化不受影响
- Feign 返回不需脱敏时，新建无 @Sensitive 注解的类
- 前端提交时对比脱敏字段: 未改不提交，已改则提交新值
- User 类默认脱敏手机号和邮箱，相关前端需更新防止 *** 存入数据库

## DataRecord 数据审计工具

MyBatis-Plus 数据变更审计组件，自动记录 INSERT/UPDATE/DELETE 操作。

**依赖**: `blade-starter-data-record`

```yaml
blade:
  data-record:
    enabled: true
    ignore-tables: [sys_log, sys_dict]
    ignore-fields: [create_time, update_time, status, version]
```

**实体注解**:
```java
@DataRecord(module = "用户管理", operation = "用户数据变更",
  recordDetail = true, recordOldData = true, ignoreFields = {"password"},
  level = DataRecordLevel.INFO, async = false, condition = "")
@TableName("sys_user")
public class User { ... }

// 字段级
@FieldRecord(description = "用户名")
private String username;
@FieldRecord(description = "用户状态", condition = "#newValue == 0", level = DataRecordLevel.ERROR)
private Integer status;
```

**条件表达式变量**: 实体级 `#oldData` / `#newData` (Map)；字段级 `#oldValue` / `#newValue`

**自定义处理器**: 实现 `DataRecordHandler` 接口将审计日志写入数据库。

## RedisDebounce 接口防抖工具

基于 Redis 的分布式接口防抖方案。**依赖**: `blade-starter-redis`

```java
@RedisDebounce(key = "sms:send", param = "#phone", interval = 60)
public void sendSms(String phone) { /* 同一手机号 60 秒内仅发一次 */ }

@RedisDebounce(key = "order:submit", param = "#userId", interval = 30,
  includeRemainingTime = true, message = "操作过于频繁")
public void submitOrder(Long userId, OrderDto order) { ... }
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| key | String | - | 防抖键 (必须唯一) |
| param | String | "" | SpEL 表达式 |
| interval | long | 60 | 防抖间隔 |
| timeUnit | TimeUnit | SECONDS | 时间单位 |
| includeRemainingTime | boolean | false | 异常包含剩余时间 |
| message | String | "操作过于频繁，请稍后再试" | 提示消息 |

**编程式**: `debounceClient.tryDebounce(key, 60, TimeUnit.SECONDS)` / `getRemainingTime()`

```yaml
blade:
  redis:
    debounce:
      enabled: true
      key-prefix: "blade:debounce:"
      default-interval: 60
```

## RateLimit 接口限流工具

基于 Redis 滑动窗口算法的分布式限流。**依赖**: `blade-starter-redis`

```java
@RateLimiter(value = "api:getUser", max = 100, ttl = 1, timeUnit = TimeUnit.MINUTES)
@GetMapping("/user")
public User getUser() { /* 每分钟最多 100 次 */ }

// 用户级限流
@RateLimiter(value = "sms:send", param = "#userId", max = 5, ttl = 1, timeUnit = TimeUnit.HOURS)
public void sendSms(Long userId, String phone) { ... }

// IP 级限流
@RateLimiter(value = "login:attempt", param = "#request.remoteAddr", max = 3, ttl = 15, timeUnit = TimeUnit.MINUTES)
public LoginResult login(String username, String password, HttpServletRequest request) { ... }
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| value | String | - | 限流键 (必须) |
| param | String | "" | SpEL 表达式 |
| max | long | 100 | 时间窗口内最大请求数 |
| ttl | long | 1 | 时间窗口大小 |
| timeUnit | TimeUnit | MINUTES | 时间单位 |

**编程式**: `rateLimiterClient.isAllowed(key, max, ttl, unit)` 或回调式 `rateLimiterClient.allow(key, max, ttl, unit, () -> { ... })`

**Redis Key 结构**: `limiter:{app-name}:{value}:{param}`

```yaml
blade:
  redis:
    rate-limiter:
      enabled: true
```

## DbDynamic 动态数据源工具

通过可扩展接口支持自定义数据源创建逻辑。**依赖**: `blade-starter-db-dynamic`

**核心接口**:
```java
@Component
public class CustomDataSourceProcessor implements DynamicDataSourceProcessor {
    @Override
    public int getOrder() { return 50; }

    @Override
    public Map<String, DataSourceProperty> loadDataSourceProperties(
            Statement statement, DynamicDataSourceProperties props) throws SQLException {
        Map<String, DataSourceProperty> map = new HashMap<>();
        ResultSet rs = statement.executeQuery("SELECT name, driver_class, url, username, password FROM custom_datasource WHERE enabled = 1");
        while (rs.next()) {
            DataSourceProperty p = new DataSourceProperty();
            p.setUrl(rs.getString("url"));
            p.setUsername(rs.getString("username"));
            p.setPassword(rs.getString("password"));
            map.put(rs.getString("name"), p);
        }
        return map;
    }
}
```

**使用**:
```java
@DS("test-db1")
public List<Map<String, Object>> queryFromTestDb1() { ... }

// 编程式
List<Map<String, Object>> result = DataSourceUtil.use("test-db1", () ->
    jdbcTemplate.queryForList("SELECT * FROM test_table"));
```

**生命周期**: 启动时自动发现 Processor → 按 getOrder() 排序 → 执行加载 → 合并结果 → 测试连通性

## MyBatis 字段加解密工具

企业级透明数据库字段加密方案。**依赖**: `blade-starter-mybatis-encrypt`

```yaml
blade:
  mybatis-plus:
    encrypt:
      enabled: true
      window-size: 3                              # 模糊查询滑动窗口
      algorithm: SM4                               # SM4/AES/DES/BASE64/CUSTOM
      secret-key: blade1234567890blade1234567890XY # 32 位密钥
```

**实体注解**:
```java
@TableName(value = "sys_user", autoResultMap = true)  // 重要: autoResultMap = true
public class User {
    @FieldEncrypt
    private String phone;        // 自动加解密

    @SearchableFieldEncrypt      // 支持模糊查询的加密
    @TableField("name_enc")
    private String nameEnc;
}
```

**Mapper XML**:
```xml
<result column="phone" property="phone"
  typeHandler="org.springblade.core.mp.encrypt.handler.EncryptTypeHandler"/>
```

**特性**: 支持 SM4/AES/DES/Base64/自定义算法、滑动窗口模糊查询、查询条件自动加密、高性能缓存池

## i18n 国际化工具

内置国际化支持，根据请求语言自动切换响应语言。

**配置**:
```yaml
blade:
  locale:
    enabled: true
    default-locale: zh_CN
    param-name: lang         # URL 参数名
    header-name: Accept-Language
```

**使用**:
```java
// 获取国际化消息
String msg = MessageUtil.getMessage("user.not.found");
String msg = MessageUtil.getMessage("user.welcome", new Object[]{username});
```

**资源文件**: `messages.properties` / `messages_zh_CN.properties` / `messages_en_US.properties`

## ApiKey 超级令牌认证 (4.8.0+)

用于服务间可信调用的超级令牌机制。

**特性**:
- 超级令牌认证: 服务间可信调用无需常规 OAuth2 流程
- 签名认证防重放攻击: 请求签名 + 时间戳 + nonce 防止重放
- 请求方法全局规则配置: 按 path 粒度控制允许的 HTTP 方法

**配置**:
```yaml
blade:
  api-key:
    enabled: true
    keys:
      - name: internal-service
        value: your-api-key-value
        permissions:
          - /blade-system/**
          - /blade-desk/**
```

## Redis 序列化配置

### 支持格式 (2.7.1+)
- `json`: JSON 序列化
- `protostuff`: Protostuff 序列化 (高性能)
- `jdk`: JDK 默认序列化

## 动态聚合文档

### Swagger 聚合
- Cloud 版: 网关自动发现 Nacos 服务并聚合
- Boot 版: 内置聚合
- 访问: http://localhost/doc.html (Knife4j)

## 独立流程设计器

### NutFlow (Saber 内嵌)
- 已集成到 Saber 前端
- 免费 (原价 299 元编译版)
- 源码版 999 元 (含完整工作流插件源码)

### Flowable-Design (Sword 独立)
- 需单独启动服务
- 访问: http://localhost:9999/index.html
