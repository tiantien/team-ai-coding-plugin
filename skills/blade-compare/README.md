# Blade Compare

跨工程智能代码对比工具，对比两个 BladeX 工程之间的代码差异，自动识别并分离「系统级架构差异」与「业务逻辑差异」。

## 核心能力

在 BladeX 生态中，同一套业务功能通常会有 Boot 单体版和 Cloud 微服务版两套工程。这两套工程之间存在大量因架构选型不同而导致的结构性差异（包路径、模块目录、特有组件等），如果用普通 diff 工具对比会产生大量噪音，难以发现真正的业务逻辑差异。

Blade Compare 理解 BladeX 的工程架构，能够：
- **自动识别系统级差异**：包路径 `modules` 层级、Cloud 特有的 Feign/Gateway/Nacos 组件、Boot 特有的集中配置等
- **聚焦业务逻辑差异**：过滤掉架构噪音后，精确展示功能代码的实际差异
- **按影响级别分类**：将差异标记为重要(缺失功能)/注意(实现差异)/轻微(风格差异)
- **按模块组织报告**：让对比结果结构清晰，便于逐模块检查

## 快速开始

### 目录对比（默认模式）

```bash
# 对比两个工程的全部代码
/blade-compare /path/to/BladeX /path/to/BladeX-Boot

# 当前目录作为工程 A，只对比 system 模块
/blade-compare /path/to/BladeX-Boot --module system

# 显示代码级详细 diff
/blade-compare /path/to/BladeX /path/to/BladeX-Boot --detail

# 只显示业务差异，隐藏系统级差异摘要
/blade-compare /path/to/BladeX /path/to/BladeX-Boot --focus
```

### Commit 对比模式

```bash
# 对比两个工程最近 10 个 commit 的同步状态
/blade-compare --commits /path/to/BladeX /path/to/BladeX-Boot HEAD~10..HEAD HEAD~10..HEAD

# 对比指定日期之后的 commit
/blade-compare --commits /path/to/BladeX /path/to/BladeX-Boot --since 2024-03-01

# 对比分支差异
/blade-compare --commits /path/to/BladeX /path/to/BladeX-Boot master..dev master..dev
```

## 支持的工程类型

| 类型 | 特征 |
|---|---|
| Boot 单体 | 单模块，代码在 `src/main/java/` 下 |
| Cloud 微服务 | 多模块，含 `blade-service/`、`blade-service-api/` 等 |
| Links IoT | 多模块，含 `blade-core/`、`blade-service/`，IoT 特有模块 |

支持以上任意组合的双向对比（Boot↔Cloud、Cloud↔Links、Boot↔Links），也支持同类型工程之间的对比。

## 工作流程

### 目录对比模式

```
环境预检 → 结构识别 → 文件清单构建与映射:
  ┌─────────────────────────────────────────┐
  │  扫描文件 → 建立映射 → 分类文件         │
  │       → 差异分析（系统级 vs 业务级）     │
  │       → 影响评估 → 生成对比报告          │
  └─────────────────────────────────────────┘
```

### Commit 对比模式

```
环境预检 → 获取 commit 列表:
  ┌──────────────────────────────────────────┐
  │  commit 匹配（精确/upstream标记/语义）    │
  │       → 逐 commit 差异分析               │
  │       → 生成同步状态报告                  │
  └──────────────────────────────────────────┘
```

## 对比报告结构

### 目录对比报告包含：

1. **总体统计** — 文件映射数、等价率、差异数
2. **系统级差异摘要** — 架构导致的差异（可忽略），分类列出
3. **业务逻辑差异（重点）** — 按模块分组，按影响级别排序
4. **无法映射的文件** — 需人工判断的文件
5. **对比总结** — 同步率、建议操作

### Commit 对比报告包含：

1. **匹配统计** — 完全同步/部分同步/独有 commit 的数量
2. **完全同步的 commit** — 两端一致的变更记录
3. **部分同步的 commit** — 已匹配但变更有差异的记录
4. **独有 commit** — 只在一端存在的变更（区分业务相关 vs 架构特有）
5. **同步状态总结** — 同步率、待同步列表

## 差异影响级别

| 级别 | 含义 | 典型场景 |
|---|---|---|
| 🔴 重要 | 功能缺失或逻辑不一致 | 整个功能类缺失、核心业务逻辑不同 |
| 🟡 注意 | 实现有差异但功能基本等价 | 参数差异、异常处理差异 |
| 🟢 轻微 | 非功能性差异 | 代码风格、注释差异 |

## 系统级差异识别（Boot ↔ Cloud）

以下差异会被自动识别为系统级差异：

- **包路径 modules 层级**：Boot 有 `modules` 层，Cloud 无
- **模块目录结构**：单体 vs 多模块拆分
- **Feign Client / Fallback**：Cloud 特有的远程调用
- **Gateway**：Cloud 特有的 API 网关
- **Nacos / Sentinel / Seata**：Cloud 特有的微服务组件
- **启动类**：单启动类 vs 多启动类
- **pom.xml 结构**：单 POM vs 多模块 POM
- **部署文件**：Dockerfile、docker-compose.yml

## 与 blade-sync 的配合

blade-compare 和 blade-sync 是互补的工具：

1. 先用 **blade-compare** 发现两个工程之间的差异
2. 确认哪些差异需要同步
3. 用 **blade-sync** 将缺失的功能同步到目标工程

```bash
# Step 1: 发现差异
/blade-compare /path/to/BladeX /path/to/BladeX-Boot

# Step 2: 确认后，同步缺失功能
/blade-sync /path/to/BladeX-Boot abc1234
```

## 安全保障

- **只读操作**：不修改任何工程文件，不执行任何 git 写操作
- **不做假设**：无法确定映射关系的文件明确标记，不猜测
- **完整展示**：系统级差异虽可忽略但仍列出，不隐藏信息

## 文件结构

```
blade-compare/
├── LICENSE                          # 许可协议
├── README.md                        # 本文件
├── SKILL.md                         # Skill 指令定义
└── references/
    ├── path-mapping.md              # Boot↔Cloud↔Links 路径映射详解
    └── diff-classification.md       # 差异分类判断规则
```
