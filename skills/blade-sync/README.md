# Blade Sync

跨工程 Git 提交智能同步工具，将源工程的提交记录逐条同步至目标镜像工程，自动处理异构项目间的目录结构与包路径差异。支持 `--adapt` 异构同步模式，可将官方上游提交智能适配到本地二开工程。

## 快速开始

### 镜像同步（默认）

在源工程目录下执行：

```bash
# 同步最近 1 个 commit 到目标工程
/blade-sync /path/to/target

# 同步最近 3 个 commit
/blade-sync /path/to/target HEAD~3..HEAD

# 同步指定 commit
/blade-sync /path/to/target abc1234

# 同步分支差异
/blade-sync /path/to/target master..dev

# 显式指定源工程（不使用当前目录）
/blade-sync --source /path/to/source /path/to/target
```

### 异构同步（--adapt）

在本地二开工程目录下执行，从官方上游工程拉取变更并智能适配：

```bash
# 适配上游最近 1 个 commit
/blade-sync --adapt /path/to/upstream

# 适配上游最近 5 个 commit
/blade-sync --adapt /path/to/upstream HEAD~5..HEAD

# 仅分析影响，不实际修改（干跑模式）
/blade-sync --adapt /path/to/upstream abc1234 --dry-run
```

## 支持的工程类型

| 类型 | 特征 |
|---|---|
| Boot 单体 | 单模块，代码在 `src/main/java/` 下 |
| Cloud 微服务 | 多模块，含 `blade-service/`、`blade-service-api/` 等 |
| Links IoT | 多模块，含 `blade-core/`、`blade-service/`，IoT 特有模块 |

支持以上任意方向的互相同步，自动处理包路径（如 `modules` 层级差异）和模块归属映射。

## 工作流程

### 镜像模式

```
环境预检 → 结构分析 → 逐 Commit 循环:
  ┌─────────────────────────────────────┐
  │  分析 Commit → 路径映射 → 应用变更  │
  │       → 同步报告 → 用户评审         │
  │       → 二次对比 → 执行 Commit      │
  └─────────────────────────────────────┘
                  ↓
            同步完成总结
```

### adapt 模式

```
环境预检 → 结构分析 → 逐 Commit 循环:
  ┌──────────────────────────────────────────┐
  │  功能意图分析 → 本地代码扫描 → 冲突分析  │
  │       → 交互式适配（用户逐文件决策）      │
  │       → 同步报告 → 二次对比 → Commit      │
  └──────────────────────────────────────────┘
                  ↓
            同步完成总结
```

每个 commit 同步后都会展示详细报告，经用户确认后才执行 commit，然后处理下一个。

## 安全保障

- **只做 commit**，禁止 push、pull、rebase、merge 等远程/破坏性操作
- **逐 commit 1:1 对应**，不合并多个 commit
- **commit 信息**：镜像模式原文复制；adapt 模式使用 `[upstream:<hash>]` 前缀标注来源
- **目标工作区不干净时自动中止**，避免变更混淆
- **人工评审关卡**，每个 commit 需用户确认后才提交

## 智能特性

- **语义级同步**：理解变更意图而非机械 patch，适配目标工程上下文
- **包名自动调整**：处理 Boot/Cloud 间的 `modules` 层级差异，自动修改 `package` 和 `import`
- **文件分类处理**：自动识别可同步文件、需人工确认文件和应跳过文件
- **无法映射时不猜测**：明确标记为"需人工确认"，展示上下文供用户决策
- **异构适配**（adapt 模式）：分析上游功能意图，扫描本地定制状态，自动检测冲突并提供 4 种处理方式（采纳上游/保留本地/智能合并/手动编辑）
- **干跑分析**（`--dry-run`）：仅输出影响报告，不修改文件，适合评估上游更新的冲突程度

## 文件结构

```
blade-sync/
├── README.md                       # 本文件
├── SKILL.md                        # Skill 指令定义
└── references/
    └── path-mapping.md             # Boot↔Cloud↔Links 路径映射详解
```
