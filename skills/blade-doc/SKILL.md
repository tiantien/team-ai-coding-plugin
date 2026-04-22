---
name: blade-doc
description: "BladeX 全栈微服务框架知识库。涵盖 SpringBoot3 + SpringCloud 2025 + MyBatis 全体系：OAuth2认证、SaaS多租户、Secure安全框架（注解参考/配置参考）、JacksonViews视图过滤（@BladeView）、MyBatis-Plus增强插件（拦截器/SQL注入/查询构造器）、动态数据/接口权限、Flowable工作流、Seata分布式事务、API报文加密、代码生成、ELK日志追踪、Prometheus监控、Docker/K8S部署等。当用户提问涉及 BladeX、SpringBlade、bladex-tool、Saber、Saber3 前端、blade-gateway、blade-auth、Nacos配置、多租户、数据权限、接口权限、工作流、分布式事务、API加密解密、代码生成器、BladeX部署、BladeX升级、BladeX工具类、BladeX开发规范、@BladeView、视图过滤、Jackson Views、@PreAuth、@PermitAll、Secure注解、Secure配置、MyBatis-Plus拦截器、BladeMapper、BladeSqlInjector、SqlKeyword、Condition查询等任何 BladeX 相关话题时，必须使用此 skill。即使用户只是在 BladeX 项目中遇到错误、需要配置帮助、或询问某个 BladeX 功能如何使用，也应触发此 skill。"
---

# BladeX 全栈微服务框架知识库

BladeX 是基于 SpringBoot 3.5 + SpringCloud 2025 + MyBatis 的企业级 SaaS 微服务框架，生产稳定运行近 5 年。前端提供 Saber (Vue2) 和 Saber3 (Vue3) 两套方案。

## 知识索引

根据用户问题，读取对应的 reference 文件获取详细信息。每个 reference 文件都是自包含的完整知识模块。

### 产品概览与快速开始
| 用户问题方向 | 参考文件 | 包含内容 |
|---|---|---|
| 产品简介、系统架构、核心功能、授权说明 | `references/overview.md` | 架构设计、33项核心功能、授权版本对比、插件规范 |
| 环境搭建、项目导入、数据库建库、运行测试 | `references/quickstart.md` | JDK17/Nacos/Sentinel/Redis 安装、Maven token 配置、Cloud/Boot 版本导入运行、API 测试流程 |

### 开发指南
| 用户问题方向 | 参考文件 | 包含内容 |
|---|---|---|
| 技术基础 (Java/Lombok/MyBatis/Swagger) | `references/development.md` | Java 8-17 特性、Stream/Lambda/Optional、Lombok、SpringMVC、OpenAPI3(Swagger3)、MyBatis-Plus、动态多数据源、开发规范 |
| 第一个微服务/API/缓存/CRUD/远程调用/代码生成 | `references/development.md` | 模块结构、Controller 编写、Redis 缓存、分页查询、Feign 远程调用、Hystrix 熔断、代码生成配置(单表/主子表/树表) |
| 开发进阶 (聚合文档/鉴权/跨域/日志/安全) | `references/advanced.md` | Knife4j 聚合文档、鉴权配置、CORS 处理、单元测试、日志系统、XSS/SQL 防注入、请求黑白名单、请求方法限制、自定义启动器、统一服务配置、乐观锁、BladeX-Biz 工程 |

### 核心功能特性
| 用户问题方向 | 参考文件 | 包含内容 |
|---|---|---|
| OAuth2 认证、SaaS 多租户、Secure 安全框架 | `references/auth-system.md` | OAuth2三种模式(密码/刷新/授权码)、SM2国密加密、Token 管理、多租户体系(字段/数据源隔离)、租户产品包、Secure 安全框架(@PreAuth)、自定义授权、SSO 单点登录 |
| Secure 注解参考、配置参考 | `references/secure-reference.md` | @PermitAll/@PreAuth/@IsAdmin/@IsAdministrator 完整注解文档、注解优先级规则、blade.token.*/blade.secure.* 全量配置参数、权限/基础/签名/客户端四种认证配置、完整配置示例 |
| JacksonViews 视图过滤、@BladeView | `references/jackson-views.md` | @BladeView 注解用法、四级视图层级(Summary/Detail/Admin/Administrator)、静态/动态/不过滤三种模式、角色映射配置、BaseEntity内置视图标注、自定义视图扩展(BladeViewCustomizer)、兼容性矩阵 |
| MyBatis-Plus 增强插件 | `references/mybatis-plus.md` | 拦截器体系(租户/审计/分页/定制器)、SQL 日志、自定义 SQL 注入(insertIgnore/replace/insertBatchSomeColumn)、BladeMapper/BladeService、基类体系(BaseEntity/BizEntity/BaseService)、Condition 查询构造器、SqlKeyword 查询后缀、分页工具(Query/BladePage/PageUtil)、BaseEntityWrapper |
| 动态数据权限、动态接口权限 | `references/permissions.md` | 三层权限体系、@DataAuth 注解、纯注解/Web全自动/半自动 三种配置模式、自定义 SQL 占位符、接口权限 @RequiresPermissions、Web 动态配置、类级全局匹配 |
| Flowable 工作流 | `references/workflow.md` | 流程模型创建/部署/发起/审批/详情、表单路由系统、前后端代码示例、排除工作流模块方法 |
| ELK 日志追踪、Seata 分布式事务 | `references/middleware.md` | ELK 一键部署、微服务日志对接、分布式链路追踪、Seata AT/TCC/SAGA 模式详解、Docker 启动、微服务对接、分布式事务测试 |
| API 报文加密 | `references/crypto.md` | AES/DES/RSA 加解密、@ApiCrypto 注解体系、前后端对接实战(查询/增改/删除加密改造)、自动化配置 |
| Excel工具包、UReport2报表、开发工具包 | `references/toolkit.md` | EasyExcel 导入导出、大数据量导入、UReport2 报表集成、34个核心工具类(加解密/JSON/Web/反射/Bean/日期/文件/图片等) API 清单 |
| 任务调度、分库分表、OSS、SMS 等扩展功能 | `references/features.md` | XXL-JOB/PowerJob 任务调度、Sharding 分库分表、MinIO 对象存储、SMS 短信、Dubbo RPC、动态网关、灰度发布、LiteFlow/LiteRule 规则引擎、Sensitive 脱敏、DataRecord 数据审计、RedisDebounce 接口防抖、RateLimit 接口限流、DbDynamic 动态数据源、MyBatis 字段加解密、i18n 国际化、ApiKey 超级令牌、SkyWalking、消息队列、分布式锁 等 26 项功能 |

### 部署与运维
| 用户问题方向 | 参考文件 | 包含内容 |
|---|---|---|
| 生产部署 (Windows/Linux/Docker) | `references/deployment.md` | Windows 部署(AlwaysUp)、Jar 部署脚本、宝塔面板部署(含前后端+HTTPS)、Docker 完整部署(安装/Harbor 私有仓库/docker-compose 编排/Nginx 反向代理) |
| Prometheus 监控体系 | `references/monitoring.md` | Prometheus 部署、NodeExporter/MysqldExporter 插件、Cadvisor Docker 监控、Grafana 可视化、Alertmanager 告警(邮件/钉钉/企业微信)、BladeX 微服务对接(Consul API 服务发现) |

### 底层架构
| 用户问题方向 | 参考文件 | 包含内容 |
|---|---|---|
| BladeX-Tool 模块架构、Starter 配置、底层原理 | `references/bladex-tool.md` | 11 核心模块 + 34 Starter 全配置速查、模块依赖链、认证授权模块 (OAuth2/Secure/JWT/Key/Social) 完整配置属性、各 Starter 配置前缀与默认值 |

### 升级与FAQ
| 用户问题方向 | 参考文件 | 包含内容 |
|---|---|---|
| 版本升级 (2.0→4.9) | `references/upgrade.md` | 各版本关键变更、破坏性改动、数据库迁移、SpringBoot3 升级、JDK17 迁移、Swagger2→3 迁移、Jakarta EE 迁移、SM2 国密算法、4.9.0 JacksonViews/认证日志 |
| FAQ 常见问题 | `references/faq.md` | 54 个常见问题解答、Git 版本控制、学习资料推荐 |

## 快速参考

### 技术栈
- **后端**: Java 17, SpringBoot 3.5, SpringCloud 2025, MyBatis-Plus
- **前端**: Vue2 (Saber/Element) + Vue3 (Saber3/Element-Plus)
- **注册/配置中心**: Nacos 2.3.0+
- **网关**: Spring Cloud Gateway
- **认证**: 自研 OAuth2 (基于 JWT + SM2 国密)
- **流控**: Sentinel
- **数据库**: MySQL 5.7+ / PostgreSQL / Oracle / SQLServer / DaMeng / YashanDB
- **缓存**: Redis 6.0+
- **工作流**: Flowable 7.0.1
- **分布式事务**: Seata
- **日志**: ELK (Elasticsearch + Logstash + Kibana)
- **监控**: Prometheus + Grafana + Alertmanager
- **部署**: Docker / Docker-Compose / K8S

### 核心模块结构
```
BladeX/
├── blade-auth          # 授权服务
├── blade-common        # 公共工具包
├── blade-gateway       # Spring Cloud 网关
├── blade-ops/          # 运维中心
│   ├── blade-admin     # 服务管理 + Prometheus 对接
│   ├── blade-develop   # 代码生成
│   ├── blade-flow      # 工作流服务
│   ├── blade-flow-design # 流程设计器
│   ├── blade-log       # 日志服务
│   ├── blade-resource  # 资源服务
│   └── blade-xxljob    # 任务调度
├── blade-service/      # 业务模块
│   ├── blade-desk      # 工作台
│   ├── blade-system    # 系统管理 (含原 blade-user)
│   └── blade-demo      # 示例模块
└── blade-service-api/  # 业务 API 封装 (Entity/VO/DTO/Feign)
```

### 认证流程 (最常用)
1. 从 `blade_client` 表获取 `client_id:client_secret`
2. Base64 编码: `saber:saber_secret` → `c2FiZXI6c2FiZXJfc2VjcmV0`
3. 请求头 `Authorization: Basic c2FiZXI6c2FiZXJfc2VjcmV0`
4. 请求头 `Tenant-Id: 000000`
5. 密码使用 SM2 国密加密后传入
6. 调用 `/blade-auth/oauth/token` 获取 token
7. 后续请求头 `Blade-Auth: bearer {access_token}`
8. 严格模式需额外添加 `Blade-Requested-With: BladeHttpRequest`

### 数据库命名规范
- 表名: `blade_` 前缀，下划线分隔 (如 `blade_blog`)
- 字段: 下划线分隔 (如 `blog_title`)
- 主键: BigInt(20)，Snowflake 雪花算法生成 (非自增)
- 逻辑删除: `is_deleted` 字段 + `@TableLogic` 注解
- 审计字段: `create_user`, `create_time`, `update_user`, `update_time`, `create_dept`

### 统一响应格式 R<T>
```java
R.data(data)           // 返回数据
R.data(data, msg)      // 返回数据 + 消息
R.success(msg)         // 成功
R.failure(msg)         // 失败
R.status(boolean)      // 根据布尔值返回成功/失败
```

### 常用注解速查
```java
@PermitAll                        // 跳过身份认证+权限认证，接口完全公开 (jakarta.annotation.security)
@PreAuth("permitAll()")           // 允许所有已认证请求
@PreAuth("hasRole('admin')")      // 需要指定角色
@PreAuth(permission = "user:add") // 接口权限 (4.6.0+ 简化写法)
@PreAuth(menu = "notice")        // 菜单权限 (4.3.0+)
@IsAdmin                          // 管理员判断 (4.6.0+)
@IsAdministrator                  // 超级管理员判断 (4.6.0+)
@BladeView(Views.Summary.class)  // 静态视图过滤 (4.9.0+)
@BladeView                        // 动态视图过滤，按角色自动选择 (4.9.0+)
@DataAuth                         // 数据权限 (默认按 create_dept 过滤)
@DataAuth(type = DataAuthType.DEPT_AND_CHILD)  // 部门及子集可见
@DataAuth(type = DataAuthType.OWN, column = "create_user") // 仅个人可见
@RequiresPermissions("notice:delete")  // 接口权限
@ApiLog("操作描述")               // API 日志记录
@ApiCrypto / @ApiCryptoAes       // API 加解密
@XssIgnore                        // 跳过 XSS 过滤
@GlobalTransactional              // Seata 分布式事务
@DS("slave")                      // 切换数据源
@Cacheable / @CacheEvict          // Spring Cache
```

### 常用配置 (blade.yaml / application.yml)
```yaml
# Token 签名 (必须配置，32位以上)
blade:
  token:
    sign-key: 你的签名密钥  # 必须配置!
    crypto-key: 你的加密密钥

  # 安全框架 - 跳过鉴权的URL
  secure:
    skip-url:
      - /test/**
      - /demo/**
    # 严格模式 (4.0.0+ 默认开启)
    strict-token: true
    strict-header: true

  # 多租户
  tenant:
    enhance: true
    exclude-tables:
      - blade_log_api

  # XSS 防护
  xss:
    enabled: true
    mode: clear  # clear / escape / validate
    skip-url:
      - /webjars/**

  # 请求黑白名单
  request:
    enabled: true
    black-list: []
    white-list: []

  # OAuth2 SM2 密钥
  oauth2:
    public-key: SM2公钥
    private-key: SM2私钥
```

## 使用指南

当回答用户关于 BladeX 的问题时：

1. **先判断问题领域**：根据上方知识索引表，确定属于哪个模块
2. **读取对应 reference 文件**：获取该领域的完整技术细节
3. **提供精准回答**：基于 reference 中的具体配置、代码示例和步骤进行回答
4. **注意版本差异**：BladeX 经历了从 2.0 到 4.8 的多次重大升级，注意用户使用的版本
5. **Cloud vs Boot**：注意区分 SpringCloud 微服务版和 SpringBoot 单体版的配置差异

如果用户的问题跨越多个领域，可以同时读取多个 reference 文件来综合回答。
