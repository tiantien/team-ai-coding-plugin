# BladeX-Tool 底层架构模块手册

BladeX-Tool 是 BladeX 框架的核心封装层，包含 11 个核心模块 + 34 个 Starter 模块，提供从启动到部署的全链路基础能力。

## 模块总览

```
BladeX-Tool/
├── blade-bom                    # 依赖版本管理 (BOM)
├── blade-core-auto              # 编译期注解处理器
├── blade-core-launch            # 应用启动核心
├── blade-core-tool              # 通用工具库
├── blade-core-context           # 请求上下文管理
├── blade-core-db                # 数据库基础配置
├── blade-core-boot              # Web 应用引导
├── blade-core-cloud             # 微服务云端集成
├── blade-core-test              # 测试框架
├── blade-core-log4j2            # Log4j2 日志
├── blade-core-auth/             # 认证授权 (复合模块)
│   ├── blade-core-oauth2        # OAuth2 授权服务
│   ├── blade-core-secure        # 安全拦截框架
│   ├── blade-starter-auth       # 认证基础
│   ├── blade-starter-jwt        # JWT 令牌
│   ├── blade-starter-key        # 超级密钥
│   └── blade-starter-social     # 社交登录
└── blade-starter-*/             # 34 个功能 Starter
```

## 核心模块详解

### blade-core-launch — 应用启动核心

框架入口，封装 SpringBoot 启动逻辑，提供环境检测和 SPI 组件发现。

**关键类**:
- `BladeApplication` — 主入口 (`BladeApplication.run("app-name", App.class, args)`)
- `LauncherService` — SPI 扩展接口，通过 ServiceLoader 自动加载
- `BladeProperties` — 全局配置属性

**配置**:
- 默认使用 **Undertow** 替代 Tomcat (HTTP/2)
- 自动检测 dev/test/prod 环境
- 默认 dev 环境，无需配置 `spring.profiles.active`

### blade-core-tool — 通用工具库

核心工具集，提供 40+ 工具类。

**Jackson 配置** (`blade.jackson`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `nullToEmpty` | true | null 转空值 |
| `bigNumToString` | true | 大数字转字符串 (防精度丢失) |
| `supportTextPlain` | false | 支持 text/plain 媒体类型 |

**关键类**: `R` (统一响应), `JsonUtil`, `BeanUtil`, `StringUtil`, `DateTimeUtil`, `AesUtil`, `DesUtil`, `SM2Util`, `TreeNode`

### blade-core-context — 请求上下文

跨服务请求头传播与线程上下文管理。

**配置** (`blade.context.headers`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `requestId` | Blade-RequestId | 请求 ID 头名 |
| `accountId` | Blade-AccountId | 账户 ID 头名 |
| `tenantId` | Blade-TenantId | 租户 ID 头名 |
| `allowed` | [] | 允许跨服务传递的自定义头 |

**关键类**: `BladeContext`, `BladeCallableWrapper`, `BladeRunnableWrapper` (异步上下文传播)

### blade-core-db — 数据库基础

多数据库驱动支持 + Druid 连接池。

**内置驱动**: MySQL (默认), Oracle, PostgreSQL, SQL Server, DaMeng, YashanDB, KingbaseES

**Druid 默认配置** (`blade-db.yml`):
```yaml
spring.datasource.druid:
  initial-size: 5
  max-active: 20
  min-idle: 5
  max-wait: 60000
  validation-query: select 1
  stat-view-servlet:
    enabled: true
    login-username: blade
    login-password: 1qaz@WSX
```

### blade-core-boot — Web 应用引导

HTTP 请求处理、文件上传、请求过滤。

**文件上传** (`blade.file`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `remoteMode` | false | 远程上传模式 |
| `uploadDomain` | - | 外部访问域名 |
| `uploadPath` | /upload | 上传相对路径 |
| `compress` | false | 图片压缩 |
| `compressScale` | 2.00 | 压缩比例 |

**请求过滤** (`blade.request`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用自定义请求处理 |
| `skipUrl` | [] | URL 白名单 |
| `blockUrl` | [] | URL 黑名单 |
| `whiteList` | [] | IP 白名单 (支持通配符) |
| `blackList` | [] | IP 黑名单 |
| `allowMethods` | GET,POST,PUT,DELETE,PATCH,HEAD,OPTIONS | 允许的 HTTP 方法 |
| `methodRules` | [] | 路径级方法规则 |

**Undertow 默认配置**:
```yaml
server.undertow:
  io-threads: 16
  worker-threads: 400
  buffer-size: 1024
  direct-buffers: true
spring.servlet.multipart:
  max-file-size: 1024MB
  max-request-size: 1024MB
```

### blade-core-cloud — 微服务云端集成

Feign、Sentinel、负载均衡、HTTP 客户端。

**HTTP 客户端** (`blade.http`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `maxConnections` | 200 | 最大连接池 |
| `timeToLive` | 900 | 连接 TTL (秒) |
| `connectionTimeout` | 2000 | 连接超时 (ms) |
| `followRedirects` | true | 跟随重定向 |
| `disableSslValidation` | true | 关闭 SSL 验证 |
| `level` | NONE | HTTP 日志级别 |

**关键特性**: API 版本控制 (`@VersionMapping`)、Sentinel 熔断集成、OkHttp3 连接池、HTTP/2 (Undertow)、跨服务请求头传播

### blade-core-test — 测试框架
```java
@ExtendWith(BladeSpringExtension.class)
@BladeBootTest(appName = "blade-test", profile = "test", enableLoader = true)
public class MyTest { ... }
```

## 认证授权模块

### blade-core-oauth2 — OAuth2 授权服务

**配置** (`blade.oauth2`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用 OAuth2 |
| `codeTimeout` | 600 | 授权码过期秒数 |
| `publicKey` | - | SM2 公钥 |
| `privateKey` | - | SM2 私钥 |

**授权模式开关** (`blade.oauth2.granter`):
| 模式 | 默认 | 说明 |
|------|------|------|
| `authorizationCode` | true | 授权码模式 |
| `password` | true | 密码模式 |
| `refreshToken` | true | 刷新令牌 |
| `clientCredentials` | true | 客户端凭证 |
| `implicit` | true | 隐式模式 |
| `captcha` | true | 验证码模式 |
| `smsCode` | true | 短信验证码 |
| `wechatApplet` | true | 微信小程序 |
| `social` | true | 社交登录 |
| `register` | true | 注册模式 |

### blade-core-secure — 安全拦截框架

**配置** (`blade.secure`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | false | 启用安全规则 |
| `strictToken` | true | 严格 Token 验证 |
| `strictHeader` | true | 严格请求头验证 |
| `skipUrl` | [] | 跳过验证的路径 |
| `authEnabled` | true | 启用授权规则 |
| `auth[]` | [] | 自定义授权规则 (pattern/method/expression) |
| `basicEnabled` | true | 启用 Basic 认证 |
| `basic[]` | [] | Basic 认证规则 (username/password per pattern) |
| `signEnabled` | true | 启用签名验证 |
| `sign[]` | [] | 签名规则 (crypto per pattern) |
| `clientEnabled` | true | 启用客户端认证 |
| `client[]` | [] | 客户端规则 (clientId/pathPatterns) |

**拦截器**: `TokenInterceptor`, `BasicInterceptor`, `SignInterceptor`, `ClientInterceptor`, `AuthInterceptor`

**权限注解**: `@PreAuth`, `@IsAdmin`, `@IsAdministrator`

**防重放**: `NonceStore` 接口 (默认 `LocalNonceStore`，可替换为 Redis 实现)

### blade-starter-jwt — JWT 令牌

**配置** (`blade.token`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `state` | false | 启用 Redis 有状态 Token |
| `single` | false | 单用户单 Token |
| `singleLevel` | ALL | 约束范围 (ALL/CLIENT) |
| `signKey` | (必须, 32位+) | JWT 签名密钥 |
| `cryptoKey` | - | Token 载荷加密密钥 |

### blade-starter-key — 超级密钥

**配置** (`blade.key`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | false | 启用超级密钥 |
| `cryptoKey` | (启用时必须) | 主加密密钥 |

### blade-starter-social — 社交登录

**配置** (`social`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | false | 启用社交登录 |
| `domain` | - | 应用域名 (OAuth 回调) |
| `oauth[PROVIDER]` | - | 各平台 AuthConfig (clientId/secret) |
| `alias[name]` | - | 平台别名映射 |

支持: WECHAT, QQ, GITHUB, GOOGLE, FACEBOOK 等 (基于 JustAuth)

## Starter 模块配置速查

### blade-starter-redis
**配置** (`blade.redis`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `serializerType` | ProtoStuff | 序列化方式 (ProtoStuff/JSON/JDK) |

**分布式锁** (`blade.lock`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | false | 启用分布式锁 |
| `address` | - | Redis 地址 |
| `password` | - | 密码 |
| `database` | 0 | 数据库 |
| `poolSize` | 20 | 连接池大小 |
| `timeout` | 5000 | 超时 (ms) |

**注解**: `@RedisLock`, `@RateLimiter`, `@RedisDebounce`

### blade-starter-mybatis
**配置** (`blade.mybatis-plus`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `tenantMode` | true | 租户模式 |
| `recordMode` | true | 数据审计模式 |
| `sqlLog` | true | SQL 日志 |
| `sqlLogExclude` | - | SQL 日志排除关键词 |
| `pageLimit` | 500 | 最大分页数 |
| `batchUpdateLimit` | 1000 | 批量更新限制 |
| `overflow` | false | 页码溢出处理 |
| `optimizeJoin` | false | 优化 JOIN 查询 |

### blade-starter-mybatis-encrypt
**配置** (`blade.mybatis-plus.encrypt`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用字段加密 |
| `windowSize` | 3 | 模糊查询滑动窗口 |
| `algorithm` | AES | 算法 (SM4/AES/DES/BASE64/CUSTOM) |
| `secretKey` | (必须) | 加密密钥 (32 位) |

### blade-starter-tenant
**配置** (`blade.tenant`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enhance` | true | 增强模式 |
| `license` | false | 许可验证 |
| `dynamicDatasource` | false | 动态数据源 |
| `dynamicGlobal` | false | 全局动态数据源扫描 |
| `column` | tenant_id | 租户字段名 |
| `annotationExclude` | false | 注解排除 |
| `excludeTables` | [] | 排除表列表 |

**注解**: `@TenantIgnore`, `@TenantAsync`, `@TableExclude`, `@TenantDS`, `@NonDS`

### blade-starter-data-scope
**配置** (`blade.data-scope`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用数据权限 |
| `mapperKey` | page,Page,list,List | Mapper 方法关键词 |
| `mapperExclude` | FlowMapper | 排除的 Mapper 类 |

### blade-starter-log
**配置** (`blade.log.request`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用请求日志 |
| `errorLog` | true | 启用错误日志推送 |
| `traceLog` | true | 启用链路追踪日志 |
| `level` | BODY | 日志级别 |
| `skipUrl` | [] | 跳过日志的 URL |

**注解**: `@ApiLog`, `@LogTrace`

### blade-starter-xss
**配置** (`blade.xss`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用 XSS 防护 |
| `trimText` | true | 文本修剪 |
| `mode` | CLEAR | 模式 (CLEAR/ESCAPE/VALIDATE) |
| `prettyPrint` | false | CLEAR 模式保留换行 |
| `enableEscape` | false | CLEAR 模式内转义 |
| `blockUrl` | [/**] | 拦截路由 |
| `skipUrl` | [] | 跳过路由 |

### blade-starter-swagger
**配置** (`swagger`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用 Swagger |
| `basePackages` | - | 扫描包路径 |
| `title` | - | API 标题 |
| `description` | - | API 描述 |
| `version` | - | API 版本 |

### blade-starter-oss
**配置** (`oss`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | - | 启用 OSS |
| `tenantMode` | false | 租户模式 |
| `endpoint` | - | 端点地址 |
| `accessKey` / `secretKey` | - | 密钥 |
| `bucketName` | bladex | 存储桶 |
| `transformEndpoint` | - | 外网地址转换 |

**支持**: MinIO, 阿里 OSS, 腾讯 COS, 七牛, 华为 OBS, AWS S3, 本地文件

### blade-starter-sms
**配置** (`sms`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | - | 启用短信 |
| `templateId` | - | 短信模板 ID |
| `regionId` | cn-hangzhou | 区域 |
| `accessKey` / `secretKey` | - | 密钥 |
| `signName` | - | 签名 |

**支持**: 阿里云, 腾讯云, 七牛, 云片

### blade-starter-loadbalancer
**配置** (`blade.loadbalancer`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用负载均衡 |
| `version` | - | 灰度版本号 |
| `priorIpPattern` | [] | IP 优先匹配 |

### blade-starter-api-crypto
**配置** (`blade.api.crypto`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用 API 加密 |
| `paramName` | data | URL 加密参数名 |
| `aesKey` | - | AES 密钥 |
| `desKey` | - | DES 密钥 |
| `rsaPrivateKey` | - | RSA 私钥 |

### blade-starter-sharding
**配置** (`blade.sharding`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | false | 启用分库分表 |

### blade-starter-i18n
**配置** (`blade.i18n`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用国际化 |
| `defaultLocale` | zh_CN | 默认语言 |
| `supportLocales` | [] | 支持的语言列表 |
| `headerName` | Accept-Language | 语言头名 |
| `paramName` | lang | 请求参数名 |
| `messageSource.baseNames` | [] | 消息文件基名 |
| `messageSource.encoding` | UTF-8 | 编码 |
| `messageSource.cacheDuration` | 30m | 缓存时长 |

### blade-starter-literule
**配置** (`literule`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `execution.timeout` | 30000 | 执行超时 (ms) |
| `execution.maxParallelThreads` | 10 | 最大并行线程 |
| `execution.queueCapacity` | 1000 | 队列容量 |
| `cache.enabled` | true | 启用缓存 |
| `preload.enabled` | true | 启用预加载 |

### blade-starter-data-record
**配置** (`blade.data-record`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用数据审计 |
| `ignoreTables` | [] | 忽略的表 |
| `ignoreFields` | [] | 忽略的字段 |
| `recordDetailedChanges` | true | 记录详细变更 |
| `recordRawData` | true | 记录原始数据 |

### blade-starter-actuate
**配置** (`blade.http.cache`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | false | 启用 HTTP 缓存 |
| `cacheName` | bladeHttpCache | 缓存名 |
| `includePatterns` | [/**] | 缓存 URL |
| `excludePatterns` | [] | 排除 URL |

### blade-starter-report
**配置** (`report`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | true | 启用报表 |
| `auth` | true | 启用认证 |
| `debug` | false | 调试模式 |

### blade-starter-holidays
**配置** (`blade.holidays`):
| 属性 | 默认 | 说明 |
|------|------|------|
| `extData[].year` | - | 年份 |
| `extData[].dataPath` | - | 数据路径 |

### 其他 Starter (纯依赖引入)
- `blade-starter-flowable` — Flowable 工作流引擎
- `blade-starter-liteflow` — LiteFlow 规则引擎
- `blade-starter-excel` — FastExcel + Apache POI
- `blade-starter-http` — OkHttp3 + JSoup
- `blade-starter-mongo` — MongoDB
- `blade-starter-ehcache` — Ehcache 本地缓存
- `blade-starter-metrics` — Micrometer + Prometheus
- `blade-starter-prometheus` — Prometheus 服务发现
- `blade-starter-powerjob` — PowerJob 任务调度
- `blade-starter-transaction` — Seata 分布式事务
- `blade-starter-trace` — SkyWalking 链路追踪
- `blade-starter-develop` — Beetl 代码生成器

## 模块依赖链

```
blade-core-auto (编译期，无运行时依赖)
  ↓
blade-core-launch → blade-core-tool → blade-core-context
                                     → blade-core-db
                                     → blade-core-cloud
                                        ↓
                                   blade-core-boot (聚合: context + db + cloud + tool)

blade-core-auth:
  blade-core-oauth2 → blade-core-secure → blade-starter-auth → blade-starter-jwt (Redis)
                                                              → blade-starter-key
                    → blade-starter-social (JustAuth + Redis)
```
