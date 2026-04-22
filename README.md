# Team AI Coding Plugin

> 团队专属 AI 编程规范插件 - BladeX 全栈开发 + Karpathy 心法 + Superpowers 工程化流程

## 功能概述

本插件整合三大核心能力：

| 能力 | 说明 |
|------|------|
| **BladeX Skills** | 全栈开发工具链：代码生成、知识库、审计、对比、同步 |
| **Karpathy Skills** | AI 编程底层心法：目标驱动、最小改动、先问后做、极简实现 |
| **Superpowers** | 工程化流程护栏：头脑风暴、计划编写、TDD 执行 |

---

## Skills 列表

### BladeX 全栈开发

| Skill | 用途 | 说明 |
|-------|------|------|
| `blade-design` | 全栈代码生成器 | 根据模块名、实体名、字段列表生成后端代码、前端页面、数据库建表语句 |
| `blade-doc` | 框架知识库 | BladeX 框架全体系知识：OAuth2、SaaS 多租户、Secure 安全框架、MyBatis-Plus 等 |
| `blade-commit` | Git 提交工具 | 基于 Gitmoji 规范生成提交信息，支持简单模式和详细模式 |
| `blade-storm` | 头脑风暴 | 渐进式提问将模糊想法精炼为可落地方案 |
| `blade-spec` | 规范驱动开发 | 复杂需求拆解为「需求分析 → 技术设计 → 任务拆解」三阶段 |
| `blade-plan` | 轻量规划执行 | 中等需求快速拆解为「分析规划 → 逐任务执行 → 完成总结」 |
| `blade-audit` | 代码审计 | 六维度审计：代码质量、架构合规、框架规范、安全漏洞、逻辑健壮性、性能隐患 |
| `blade-compare` | 跨工程对比 | 对比两个 BladeX 工程差异，自动分离系统级与业务级差异 |
| `blade-sync` | 跨工程同步 | 将源工程 Git 提交同步至目标工程，自动处理异构项目差异 |

### Avue 前端组件

| Skill | 用途 | 说明 |
|-------|------|------|
| `avue-design` | Avue 组件生成 | CRUD 表格、表单、树组件、数据展示等全部 Avue 组件代码生成 |

### Karpathy 底层心法

| Skill | 规则 | 触发方式 |
|-------|------|----------|
| `goal-driven` | 只给成功标准，不指定实现步骤 | 自动/手动 |
| `minimal-changes` | 只修改目标相关代码 | 自动 |
| `ask-first` | 模糊需求必须确认 | 自动/手动 |
| `keep-simple` | 优先最简单可维护方案 | 自动/手动 |

### Superpowers 工程化流程

| Skill | 用途 | 触发方式 |
|-------|------|----------|
| `brainstorm` | 需求澄清与设计探索 | 手动 `/brainstorm` |
| `write-plan` | 编写实现计划 | 手动 `/write-plan` |
| `execute-plan` | 执行实现计划 | 手动 `/execute-plan` |
| `tdd` | 测试驱动开发 | 自动 |

---

## 团队自定义命令

| 命令 | 功能 | 用法 |
|------|------|------|
| `/code-review` | 多维度代码审查 | `/code-review [文件路径]` |
| `/deploy` | 标准化部署流程 | `/deploy [环境]` |
| `/sprint-start` | 迭代启动初始化 | `/sprint-start [迭代名称]` |

---

## 强制门禁（Hooks）

| Hook | 功能 |
|------|------|
| `pre-tool-use.sh` | 工具调用前校验：禁止修改非目标文件、禁止高危命令 |
| `pre-commit.sh` | 提交前门禁：必须通过测试、代码审查、安全扫描 |
| `security-check.sh` | 安全扫描：SQL 注入、XSS、敏感信息检测 |

---

## 安装方法

### 方式一：从 GitHub 安装（推荐）

```bash
/plugin install github:tiantien/team-ai-coding-plugin
```

### 方式二：从 GitLab 安装（内部网络）

```bash
# 需要先添加 GitLab 为自定义 marketplace
# 目前 Claude Code 仅支持 GitHub 作为 marketplace source
```

---

## 使用方法

### 标准开发流程

```bash
# 1. 需求澄清
/blade-storm 需求：实现用户登录功能

# 2. 代码生成
/blade-design 模块：user，实体：User，字段：username, password, email

# 3. 知识查询
/blade-doc 查询 OAuth2 认证流程

# 4. 代码审计
/blade-audit 审计 src/main/java 目录

# 5. 提交代码
/blade-commit
```

### 跨工程同步流程

```bash
# 1. 对比工程差异
/blade-compare 源工程路径 目标工程路径

# 2. 同步提交记录
/blade-sync 源工程路径 目标工程路径 --adapt
```

---

## 目录结构

```
team-ai-coding-plugin/
├── .claude-plugin/
│   └── plugin.json              # 插件元信息
├── skills/
│   ├── blade-design/            # 全栈代码生成
│   ├── blade-doc/               # 框架知识库
│   ├── blade-commit/            # Git 提交
│   ├── blade-storm/             # 头脑风暴
│   ├── blade-spec/              # 规范驱动开发
│   ├── blade-plan/              # 轻量规划
│   ├── blade-audit/             # 代码审计
│   ├── blade-compare/           # 跨工程对比
│   ├── blade-sync/              # 跨工程同步
│   ├── avue-design/             # Avue 组件生成
│   ├── karpathy-team/           # Karpathy 心法
│   └── superpowers-team/        # Superpowers 流程
├── hooks/
│   ├── pre-tool-use.sh          # 工具调用前校验
│   ├── pre-commit.sh            # 提交前门禁
│   └── security-check.sh        # 安全扫描
├── commands/
│   ├── code-review.md           # 代码审查命令
│   ├── deploy.md                # 部署命令
│   └── sprint-start.md          # 迭代启动命令
├── templates/
│   ├── frontend/                # 前端模板
│   ├── backend/                 # 后端模板
│   └── mobile/                  # 移动端模板
├── CLAUDE.md                    # 团队统一规范
└── README.md                    # 本文档
```

---

## 更新方法

```bash
/plugin update team-ai-coding-plugin
```

---

## 版本历史

### v1.0.0 (2026-04-22)

- 集成 BladeX 全栈开发 Skills（9 个）
- 集成 Avue 组件生成 Skill
- 集成 Karpathy Skills 4 条核心原则
- 集成 Superpowers 标准 7 步工作流
- 添加强制门禁（PreToolUse、PreCommit、SecurityCheck）
- 添加团队自定义命令（code-review、deploy、sprint-start）

---

## 常见问题

### Q: 如何临时禁用某个门禁？

A: 不建议禁用门禁。如确需临时绕过，可在命令前添加 `--no-verify` 参数（需管理员权限）。

### Q: 如何添加团队自定义技能？

A: 在 `skills/` 目录下创建新的技能文件，并在 `plugin.json` 中注册。

### Q: 如何修改代码规范？

A: 编辑 `CLAUDE.md` 文件，所有团队成员更新插件后自动生效。

---

**维护团队**：Team AI
**版本**：v1.0.0
**更新日期**：2026-04-22
**GitHub**：https://github.com/tiantien/team-ai-coding-plugin
**GitLab**：http://192.168.30.204:9980/zhengyp/team-ai-coding-plugin.git
