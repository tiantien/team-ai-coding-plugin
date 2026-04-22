# 路径映射策略详解

本文档为 blade-sync 的补充参考，详细说明不同工程类型之间的路径映射规则和特殊情况处理。仅在遇到复杂映射场景时参阅。

## 目录

1. [工程结构对照](#工程结构对照)
2. [Boot ↔ Cloud 映射规则](#boot--cloud-映射规则)
3. [Cloud ↔ Links 映射规则](#cloud--links-映射规则)
4. [Boot ↔ Links 映射规则](#boot--links-映射规则)
5. [Java 文件映射详解](#java-文件映射详解)
6. [资源文件映射详解](#资源文件映射详解)
7. [特殊文件处理](#特殊文件处理)
8. [常见陷阱](#常见陷阱)

---

## 工程结构对照

### Boot 单体工程（以 BladeX-Boot 为参考）

```
BladeX-Boot/
├── src/main/java/org/springblade/
│   ├── modules/                    # 业务模块（核心区别：有 modules 层级）
│   │   ├── auth/                   # 认证模块
│   │   ├── desk/                   # 工作台模块
│   │   │   ├── controller/
│   │   │   ├── mapper/
│   │   │   ├── pojo/               # entity/dto/vo
│   │   │   ├── service/
│   │   │   └── wrapper/
│   │   ├── develop/                # 开发工具模块
│   │   ├── resource/               # 资源管理模块
│   │   └── system/                 # 系统管理模块
│   ├── common/                     # 公共工具
│   │   ├── cache/
│   │   ├── config/
│   │   ├── constant/
│   │   └── utils/
│   └── flow/                       # 工作流
├── src/main/resources/
│   ├── application.yml             # 集中配置
│   ├── application-dev.yml
│   └── ...
└── pom.xml                         # 单一 POM
```

### Cloud 微服务工程（以 BladeX 为参考）

```
BladeX/
├── blade-auth/                     # 独立认证服务
├── blade-gateway/                  # API 网关
├── blade-common/                   # 公共模块
├── blade-service/                  # 业务服务（实现）
│   ├── blade-desk/                 # 工作台服务
│   │   └── src/main/java/org/springblade/desk/
│   └── blade-system/               # 系统服务
│       └── src/main/java/org/springblade/system/
├── blade-service-api/              # 业务服务 API（接口 + DTO）
│   ├── blade-desk-api/
│   ├── blade-system-api/
│   └── blade-user-api/
├── blade-ops/                      # 运维服务
│   ├── blade-admin/
│   ├── blade-develop/
│   ├── blade-flow/
│   ├── blade-log/
│   └── blade-resource/
├── blade-ops-api/                  # 运维服务 API
└── doc/
```

### Links IoT 工程（以 BladeX-Links 为参考）

```
BladeX-Links/
├── blade-core/                     # 核心模块
│   ├── blade-links-base/           # 基础工具
│   ├── blade-links-core/           # IoT 核心
│   ├── blade-broker-core/          # MQTT Broker 核心
│   ├── blade-broker-local/         # 本地 Broker
│   ├── blade-broker-cluster/       # 集群 Broker
│   ├── blade-data-core/            # 数据处理核心
│   ├── blade-mq-api/               # 消息队列 API
│   ├── blade-mq-kafka/             # Kafka 集成
│   ├── blade-tsdb-api/             # 时序数据库 API
│   ├── blade-tsdb-tdengine/        # TDengine 适配
│   ├── blade-tsdb-influxdb/        # InfluxDB 适配
│   └── blade-tsdb-iotdb/           # IoTDB 适配
├── blade-service/                  # 业务服务
│   ├── blade-server/               # 主平台服务
│   ├── blade-broker/               # Broker 服务
│   ├── blade-data/                 # 数据处理服务
│   └── blade-emqx/                 # EMQX 集成服务
└── blade-demo/                     # 演示应用
```

---

## Boot ↔ Cloud 映射规则

这是最常见的同步方向，也是结构差异最大的场景。

### 包路径映射

| Boot 路径 | Cloud 路径 | 说明 |
|---|---|---|
| `org.springblade.modules.system.*` | `org.springblade.system.*` | 去掉/加上 `modules` 层级 |
| `org.springblade.modules.desk.*` | `org.springblade.desk.*` | 同上 |
| `org.springblade.modules.auth.*` | `org.springblade.auth.*` | 同上 |
| `org.springblade.modules.develop.*` | `org.springblade.develop.*` | 同上 |
| `org.springblade.modules.resource.*` | `org.springblade.resource.*` | 同上 |
| `org.springblade.common.*` | `org.springblade.common.*` | 通常一致，无需调整 |

**核心规则**：Boot 比 Cloud 多一个 `modules` 包层级。

### 模块 → 目录映射

| Boot 中的位置 | Cloud 中的位置 |
|---|---|
| `src/main/java/.../modules/system/controller/` | `blade-service/blade-system/src/main/java/.../system/controller/` |
| `src/main/java/.../modules/system/service/` | `blade-service/blade-system/src/main/java/.../system/service/` |
| `src/main/java/.../modules/system/mapper/` | `blade-service/blade-system/src/main/java/.../system/mapper/` |
| `src/main/java/.../modules/system/pojo/entity/` | `blade-service-api/blade-system-api/src/main/java/.../system/entity/` |
| `src/main/java/.../modules/system/pojo/dto/` | `blade-service-api/blade-system-api/src/main/java/.../system/dto/` |
| `src/main/java/.../modules/system/pojo/vo/` | `blade-service-api/blade-system-api/src/main/java/.../system/vo/` |
| `src/main/java/.../modules/system/wrapper/` | `blade-service/blade-system/src/main/java/.../system/wrapper/` |
| `src/main/java/.../common/` | `blade-common/src/main/java/.../common/` |

**关键点**：Cloud 中 Entity/DTO/VO 通常在 `-api` 模块，Service/Controller/Mapper 在 `-service` 模块。Boot 中则全部在同一个 `modules/xxx/` 下。

### 资源文件映射

| Boot | Cloud |
|---|---|
| `src/main/resources/mapper/system/*.xml` | `blade-service/blade-system/src/main/resources/mapper/*.xml` |
| `src/main/resources/application.yml` | 各服务独立配置 / Nacos 配置中心 |

### API 层差异

Cloud 独有的文件类型（Boot 中无对应）：
- **Feign Client** 接口（`blade-service-api` 中的 `@FeignClient` 接口）
- **降级实现**（Fallback 类）
- **网关路由配置**
- **Nacos 配置文件**

同步时应跳过这些文件，或标记为"Cloud 特有，Boot 中无需处理"。

---

## Cloud ↔ Links 映射规则

Cloud 和 Links 都是多模块结构，映射相对直接。

### 结构对应

| 维度 | Cloud | Links |
|---|---|---|
| 服务层 | `blade-service/blade-xxx/` | `blade-service/blade-server/` (主服务集中) |
| 核心层 | `blade-common/` | `blade-core/blade-links-base/` |
| API 层 | `blade-service-api/blade-xxx-api/` | 通常内嵌在 service 模块中 |

### 包路径

Cloud 和 Links 通常不存在 `modules` 层级差异，但顶级包可能不同：
- Cloud: `org.springblade.system.*`
- Links: `org.springblade.iot.*`

同步共有业务模块时包路径通常一致，IoT 特有模块则不存在映射关系。

---

## Boot ↔ Links 映射规则

结合上述两种映射的特点：
- 存在 `modules` 层级差异（Boot 有，Links 无）
- 存在模块拆分差异（Boot 单体 vs Links 多模块）
- Links 的 IoT 特有模块在 Boot 中通常没有对应

---

## Java 文件映射详解

### 映射算法

```
输入: 源文件路径、源工程类型、目标工程类型
输出: 目标文件路径

1. 提取源文件的 package 声明 → sourcePackage
2. 提取源文件的类名 → className

3. 在目标工程中搜索同名类:
   find <target> -name "{className}.java" -not -path "*/target/*"

4. 若找到且唯一 → 使用该路径
5. 若找到多个:
   a. 优先选择包路径最相似的
   b. 若仍无法区分，列出所有候选供用户选择

6. 若未找到（新文件）:
   a. 根据 sourcePackage 推断目标包路径
      - Boot→Cloud: 去掉 .modules. 层级
      - Cloud→Boot: 加上 .modules. 层级
   b. 根据文件类型判断目标模块:
      - Entity/DTO/VO → Cloud 的 -api 模块
      - Service/Controller/Mapper → Cloud 的 service 模块
   c. 在目标工程中找到对应模块的 src/main/java/ 目录
   d. 按调整后的包路径创建目录结构
   e. 将文件写入该路径
```

### import 语句调整

当包路径有 `modules` 层级差异时，不仅要调整文件自身的 `package` 声明，还要调整 `import` 语句：

```java
// Boot → Cloud
// 调整前
import org.springblade.modules.system.entity.UserEntity;
// 调整后
import org.springblade.system.entity.UserEntity;

// Cloud → Boot
// 调整前
import org.springblade.system.entity.UserEntity;
// 调整后
import org.springblade.modules.system.entity.UserEntity;
```

**注意**：只调整属于同一项目的 import，不要修改第三方依赖的 import。判断方法：只调整以 `org.springblade` 开头的 import。

---

## 资源文件映射详解

### MyBatis Mapper XML

Mapper XML 的位置通常遵循约定：
- Boot: `src/main/resources/mapper/{module}/{MapperName}.xml`
- Cloud: `blade-service/blade-{module}/src/main/resources/mapper/{MapperName}.xml`

映射策略：按 Mapper 类名匹配。如 `DeviceMapper.xml` 无论在哪个路径结构下，文件名不变。

### 配置文件

配置文件通常不应自动同步，因为：
- Boot 使用本地 `application-*.yml`
- Cloud 使用 Nacos 配置中心
- 配置的 key 和值可能因架构不同而不同

遇到配置文件变更时，展示 diff 内容并标记为人工处理。

### SQL 脚本

SQL 脚本通常可以直接复制，因为数据库结构与应用架构无关。
按文件名匹配，放到目标工程的 `doc/sql/` 或对应目录下。

---

## 特殊文件处理

### pom.xml

**永远不要自动同步 pom.xml**。原因：
- Boot 和 Cloud 的依赖管理完全不同（单一 POM vs 多模块继承）
- 依赖的 groupId/artifactId 可能因架构不同而不同
- 版本管理策略不同

应做的：展示 pom.xml 的 diff，指出新增/删除/修改了哪些依赖，供用户手动处理。

### 启动类

`Application.java` / `XxxApplication.java` 等启动类通常不同步。
Boot 有一个启动类，Cloud 每个服务各有一个。

### Docker / 部署文件

`Dockerfile`、`docker-compose.yml`、部署脚本等与工程结构强绑定，不同步。

### 测试文件

`src/test/` 下的文件可以同步，映射规则与 `src/main/` 相同。

---

## 常见陷阱

### 1. 同名类在不同模块

目标工程可能存在多个同名类（如不同模块各有一个 `BaseService.java`）。此时必须通过包名而非仅靠文件名来定位，或列出所有候选让用户选择。

### 2. 内部类引用

如果源 commit 修改了一个被其他文件 import 的类，而这个类的包路径在同步后发生了变化，那么引用它的其他文件也可能需要更新 import。但这种跨文件级联修改风险较高，建议标记为人工确认，不自动处理。

### 3. 包路径中的业务模块名

有时同一个业务功能在不同工程中使用不同的模块名：
- 源工程: `org.springblade.iot.device`
- 目标工程: `org.springblade.modules.device`（Boot 中没有 iot 中间包）

遇到此类情况时，通过搜索目标工程中是否已有对应的包来判断，而非机械替换。

### 4. 枚举/常量类的位置差异

枚举和常量类在 Boot 中可能在 `common/` 下，在 Cloud 中可能在对应的 `-api` 模块中。
用文件名搜索法确认位置。

### 5. Cloud 的 API 模块拆分

Cloud 工程将 Entity/DTO/VO 放在 `-api` 模块以供其他服务引用。同步时要注意：
- 从 Boot 同步到 Cloud 的 Entity 文件，应放到 `-api` 模块而非 service 模块
- 判断依据：Entity 类上有 `@TableName` 注解 → `-api` 模块中的 entity 包
- DTO/VO 也在 `-api` 模块
- Service/ServiceImpl/Controller/Mapper → service 实现模块
