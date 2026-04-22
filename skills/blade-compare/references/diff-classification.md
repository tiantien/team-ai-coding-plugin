# 差异分类判断规则

本文档为 blade-compare 的补充参考，详细说明如何将对比发现的差异分类为「系统级差异」或「业务逻辑差异」。在对比过程中遇到模糊边界情况时参阅。

## 目录

1. [分类原则](#分类原则)
2. [系统级差异完整清单](#系统级差异完整清单)
3. [业务逻辑差异判断](#业务逻辑差异判断)
4. [灰色地带处理](#灰色地带处理)
5. [影响级别评估](#影响级别评估)

---

## 分类原则

**系统级差异**：因架构选型（Boot/Cloud/Links）不同而天然存在的差异。这些差异是可预期的，不意味着任何一端有代码缺失或功能缺陷。

**业务逻辑差异**：与架构无关的功能代码差异。一端有而另一端没有的功能、同一功能的不同实现逻辑，这些才是用户真正需要关注的。

**判断原则**：如果将两个工程的架构统一（假设都是 Boot 或都是 Cloud），这个差异是否还存在？
- 统一后差异消失 → 系统级差异
- 统一后差异仍在 → 业务逻辑差异

---

## 系统级差异完整清单

### 一、包路径差异

| 差异表现 | 示例 |
|---|---|
| `modules` 层级 | `o.s.modules.system.UserService` vs `o.s.system.UserService` |
| package 声明 | `package org.springblade.modules.system;` vs `package org.springblade.system;` |
| import 语句 | import 中的 modules 差异 |

**判断方式**：将两端 package/import 中的 `.modules.` 统一后，内容是否一致。

### 二、目录结构差异

| Boot | Cloud | 说明 |
|---|---|---|
| `src/main/java/...` | `blade-service/blade-xxx/src/main/java/...` | 模块目录层级 |
| entity 在 `modules/xxx/pojo/entity/` | entity 在 `blade-service-api/blade-xxx-api/.../entity/` | API 模块拆分 |
| 单一 resources 目录 | 各模块独立 resources | 资源文件位置 |

### 三、Cloud 特有组件

| 组件 | 识别方式 | 说明 |
|---|---|---|
| Feign Client | `@FeignClient` 注解 | 远程服务调用接口 |
| Feign Fallback | 实现 Feign 接口，通常含 `Fallback` 后缀 | 降级实现 |
| Gateway 模块 | `blade-gateway/` 目录 | API 网关 |
| Nacos 配置 | `bootstrap.yml` 中的 nacos 配置 | 注册/配置中心 |
| 服务发现 | `@EnableDiscoveryClient`、`@EnableFeignClients` | 微服务注册 |
| Seata 事务 | `@GlobalTransactional`、Seata 配置类 | 分布式事务 |
| Sentinel | Sentinel 相关配置和注解 | 流量控制 |
| 多启动类 | 各模块独立 `*Application.java` | 微服务独立部署 |
| Swagger 分组 | 各服务独立 Swagger 配置 | API 文档 |

### 四、Boot 特有组件

| 组件 | 识别方式 | 说明 |
|---|---|---|
| 集中启动类 | 单一 `BladeApplication.java` | 单体启动 |
| 集中配置 | 单一 `application.yml` | 配置集中管理 |
| 直接注入调用 | `@Autowired` 直接注入其他模块 Service | 模块间直接调用 |

### 五、Links IoT 特有组件

| 组件 | 说明 |
|---|---|
| Broker 模块 | MQTT 消息代理（broker-core/local/cluster） |
| TSDB 模块 | 时序数据库适配（tdengine/influxdb/iotdb） |
| Data 模块 | IoT 数据处理 |
| MQ 模块 | 消息队列（kafka 等） |
| EMQX 集成 | EMQX 对接模块 |

### 六、构建与部署文件

| 文件 | 原因 |
|---|---|
| `pom.xml` | 单 POM vs 多模块 POM，结构本质不同 |
| `Dockerfile` | 部署方式因架构而异 |
| `docker-compose.yml` | 编排方式不同 |
| `.github/`、`.gitlab-ci.yml` | CI/CD 因架构而异 |

---

## 业务逻辑差异判断

### 明确的业务差异

- 某个 Service 方法在 A 中有，B 中没有（且不是 Feign/直调方式差异）
- 同一个方法的实现逻辑不同（如 A 有数据权限过滤，B 没有）
- Entity/DTO/VO 的字段不同
- Mapper XML 的 SQL 逻辑不同
- Controller 暴露的接口不同（接口数量或参数差异）

### 业务差异的细分

| 类型 | 说明 | 示例 |
|---|---|---|
| **功能缺失** | 一端有完整功能，另一端没有 | A 有 DataScopeFilter，B 完全没有 |
| **逻辑不一致** | 双方都有同一功能但实现不同 | 同一查询方法的过滤条件不同 |
| **接口差异** | API 层面的差异 | A 有批量操作接口，B 只有单条操作 |
| **字段差异** | 数据模型差异 | Entity 字段不同 |
| **配置差异** | 业务相关配置不同 | 业务参数、阈值等配置值不同 |

---

## 灰色地带处理

有些差异处于系统级和业务级之间，需要进一步分析：

### 1. 调用方式不同但功能等价

```java
// Cloud: 通过 Feign 调用
@Autowired
private IUserClient userClient;
User user = userClient.userInfoById(userId).getData();

// Boot: 直接注入调用
@Autowired
private IUserService userService;
User user = userService.getById(userId);
```

**判断**：若两种调用获取的数据一致、后续处理逻辑一致 → 系统级差异。
若 Feign 调用做了额外的数据转换或错误处理 → 可能包含业务差异。

### 2. 事务注解差异

```java
// Cloud
@GlobalTransactional  // Seata 分布式事务
public void transfer() { ... }

// Boot
@Transactional  // 本地事务
public void transfer() { ... }
```

**判断**：事务的业务逻辑是否一致。注解本身的差异是系统级的（分布式 vs 本地），但如果事务包裹的代码逻辑不同则是业务差异。

### 3. 缓存实现差异

```java
// Cloud: Redis 分布式缓存
redisTemplate.opsForValue().set(key, value);

// Boot: 本地缓存
ConcurrentHashMap.put(key, value);
```

**判断**：缓存键值和失效策略是否一致。存储介质差异是系统级的，但缓存策略差异可能是业务级的。

### 4. 配置加载方式差异

Cloud 从 Nacos 加载配置，Boot 从本地 yml 加载。加载方式差异是系统级的，但配置值的差异需分析是否涉及业务逻辑。

### 处理原则

对灰色地带差异，在报告中同时标注：
- 标记为系统级差异
- 但在备注中说明可能存在的业务影响
- 让用户自行判断是否需要关注

---

## 影响级别评估

对每个业务逻辑差异，评估影响程度：

### 🔴 重要（必须关注）

- 整个类/方法缺失（一端有完整功能，另一端没有）
- 核心业务逻辑不同（如权限判断、数据过滤、金额计算）
- 数据模型差异（Entity 缺少关键字段）
- 安全相关差异（如认证、授权逻辑不同）

### 🟡 注意（建议关注）

- 方法参数不同（如少了一个过滤条件参数）
- 异常处理不同（如 A 有专门的异常捕获，B 没有）
- 日志记录不同（如关键操作的审计日志缺失）
- 数据校验不同（如 A 有额外的参数校验）
- 缓存策略不同（可能导致数据一致性差异）

### 🟢 轻微（可选关注）

- 代码风格差异（变量命名、代码格式）
- 非关键注释差异
- 日志级别差异
- 非功能性注解差异（如 `@ApiOperation` 描述文本不同）
- 工具方法的实现细节差异（如用 Stream 还是 for 循环）
