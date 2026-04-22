# 路径映射策略详解（对比专用）

本文档为 blade-compare 的补充参考，详细说明不同工程类型之间的路径映射规则。在对比过程中，正确的路径映射是判断两端文件对应关系的基础。

## 目录

1. [工程结构对照](#工程结构对照)
2. [Boot ↔ Cloud 映射规则](#boot--cloud-映射规则)
3. [Cloud ↔ Links 映射规则](#cloud--links-映射规则)
4. [Boot ↔ Links 映射规则](#boot--links-映射规则)
5. [Java 文件映射算法](#java-文件映射算法)
6. [资源文件映射](#资源文件映射)
7. [特殊文件处理](#特殊文件处理)
8. [常见陷阱](#常见陷阱)

---

## 工程结构对照

### Boot 单体工程

```
BladeX-Boot/
├── src/main/java/org/springblade/
│   ├── modules/                    # 业务模块（核心区别：有 modules 层级）
│   │   ├── auth/
│   │   ├── desk/
│   │   │   ├── controller/
│   │   │   ├── mapper/
│   │   │   ├── pojo/               # entity/dto/vo
│   │   │   ├── service/
│   │   │   └── wrapper/
│   │   ├── develop/
│   │   ├── resource/
│   │   └── system/
│   ├── common/
│   └── flow/
├── src/main/resources/
│   ├── application.yml
│   └── ...
└── pom.xml
```

### Cloud 微服务工程

```
BladeX/
├── blade-auth/                     # 独立认证服务
├── blade-gateway/                  # API 网关
├── blade-common/
├── blade-service/                  # 业务服务实现
│   ├── blade-desk/
│   │   └── src/main/java/org/springblade/desk/
│   └── blade-system/
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
└── blade-ops-api/
```

### Links IoT 工程

```
BladeX-Links/
├── blade-core/
│   ├── blade-links-base/
│   ├── blade-links-core/
│   ├── blade-broker-core/
│   ├── blade-broker-local/
│   ├── blade-broker-cluster/
│   ├── blade-data-core/
│   ├── blade-mq-api/
│   ├── blade-mq-kafka/
│   ├── blade-tsdb-api/
│   ├── blade-tsdb-tdengine/
│   ├── blade-tsdb-influxdb/
│   └── blade-tsdb-iotdb/
├── blade-service/
│   ├── blade-server/
│   ├── blade-broker/
│   ├── blade-data/
│   └── blade-emqx/
└── blade-demo/
```

---

## Boot ↔ Cloud 映射规则

### 包路径映射

| Boot 路径 | Cloud 路径 |
|---|---|
| `org.springblade.modules.system.*` | `org.springblade.system.*` |
| `org.springblade.modules.desk.*` | `org.springblade.desk.*` |
| `org.springblade.modules.auth.*` | `org.springblade.auth.*` |
| `org.springblade.modules.develop.*` | `org.springblade.develop.*` |
| `org.springblade.modules.resource.*` | `org.springblade.resource.*` |
| `org.springblade.common.*` | `org.springblade.common.*` |

**核心规则**：Boot 比 Cloud 多一个 `modules` 包层级。对比时，这种差异属于系统级差异。

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

**关键点**：Cloud 中 Entity/DTO/VO 在 `-api` 模块，Service/Controller/Mapper 在 service 模块。Boot 中全部在 `modules/xxx/` 下。这是结构差异，不是业务差异。

### 资源文件映射

| Boot | Cloud |
|---|---|
| `src/main/resources/mapper/system/*.xml` | `blade-service/blade-system/src/main/resources/mapper/*.xml` |
| `src/main/resources/application.yml` | 各服务独立配置 / Nacos 配置中心 |

### Cloud 独有文件（Boot 无对应）

- Feign Client 接口（`@FeignClient` 注解）
- Fallback 降级实现
- 网关路由配置
- Nacos 配置文件
- 各服务独立启动类

对比时直接标记为系统级差异，不视为业务缺失。

---

## Cloud ↔ Links 映射规则

| 维度 | Cloud | Links |
|---|---|---|
| 服务层 | `blade-service/blade-xxx/` | `blade-service/blade-server/`（主服务集中） |
| 核心层 | `blade-common/` | `blade-core/blade-links-base/` |
| API 层 | `blade-service-api/blade-xxx-api/` | 通常内嵌在 service 模块中 |

包路径一般无 `modules` 差异，但顶级包可能不同：
- Cloud: `org.springblade.system.*`
- Links: `org.springblade.iot.*`

IoT 特有模块（broker/tsdb/data/mq）在标准 Cloud 中不存在，对比时标记为系统级差异。

---

## Boot ↔ Links 映射规则

综合上述两种差异：
- 有 `modules` 层级差异
- 有模块拆分差异
- Links 的 IoT 特有模块在 Boot 中无对应

---

## Java 文件映射算法

对比时，建立两端文件的对应关系：

```
输入: 工程 A 的文件路径、工程 B、两端工程类型
输出: 工程 B 中的对应文件路径（或"无法映射"）

1. 从工程 A 文件中提取 package 声明 → sourcePackage
2. 提取类名 → className

3. 在工程 B 中搜索同名文件:
   find <B> -name "{className}.java" -not -path "*/target/*"

4. 若找到唯一匹配 → 使用该路径
5. 若找到多个:
   a. 计算包路径相似度（考虑 modules 层级差异后）
   b. 选择最相似的；若仍无法区分，标记为"多候选"
6. 若未找到 → 标记为"仅存在于工程 A"
```

### 判断逻辑等价

两个 Java 文件是否逻辑等价：

1. 将两个文件的 `package` 声明统一（去掉 modules 差异）
2. 将两个文件的 `import` 语句统一（去掉 modules 差异）
3. 比较剩余代码内容
4. 若仅有空行、尾部空白差异 → 逻辑等价
5. 否则 → 有业务差异，进入详细分析

---

## 资源文件映射

### Mapper XML

按文件名匹配。`DeviceMapper.xml` 在不同工程结构下文件名不变。

### 配置文件

配置文件因架构而异，属于系统级差异：
- Boot 的 `application.yml` 是集中配置
- Cloud 各服务有独立配置 + Nacos 配置中心

对比时标记为系统级差异，不做内容级对比。

### SQL 脚本

按文件名匹配，SQL 与架构无关，差异通常属于业务差异。

---

## 特殊文件处理

| 文件 | 对比处理 |
|---|---|
| `pom.xml` | 标记为系统级差异（结构本质不同） |
| `Application.java` | 标记为系统级差异（启动类因架构而异） |
| `Dockerfile` | 标记为系统级差异 |
| `docker-compose.yml` | 标记为系统级差异 |
| `.gitignore` | 跳过，不纳入对比 |
| `.editorconfig` | 跳过 |
| `target/` | 跳过（编译产物） |
| `.idea/`、`.vscode/` | 跳过（IDE 配置） |

---

## 常见陷阱

### 1. 同名类在不同模块

可能存在多个同名类（如不同模块各有 `BaseService.java`）。必须通过包名定位，不能仅靠文件名。

### 2. 包路径中的业务模块名差异

同一功能在不同工程中可能使用不同模块名：
- 源: `org.springblade.iot.device`
- 目标: `org.springblade.modules.device`

通过搜索目标工程是否有对应包来判断，而非机械替换。

### 3. API 模块拆分

Cloud 工程将 Entity/DTO/VO 放在 `-api` 模块。对比时不能因为"文件在不同位置"就判定为有差异——这是结构差异，需看内容是否等价。

### 4. 内部类引用

一个类的包路径变了，引用它的其他文件的 import 也会变。对比时需识别这种级联的包路径差异属于系统级差异。

### 5. 同一功能不同实现方式

Cloud 通过 Feign 远程调用，Boot 通过直接注入调用。功能等价但代码不同，应识别为系统级差异。判断依据：调用的目标方法是否功能等价。
