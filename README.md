# Team AI Coding Plugin

> 团队专属 AI 编程规范插件 - 融合 Karpathy Skills 底层心法与 Superpowers 工程化流程

## 功能概述

本插件融合两大核心插件的能力：

- **Karpathy Skills**：AI 编程的「底层心法」，解决 AI 编程四大顽疾
- **Superpowers**：AI 编程的「工程化流程护栏」，实现完整生命周期管控

## 核心功能

### 1. 底层行为约束（4 条黄金原则）

| 技能 | 规则 | 触发方式 |
|------|------|----------|
| goal-driven | 只给成功标准，不指定实现步骤 | 自动/手动 |
| minimal-changes | 只修改目标相关代码 | 自动 |
| ask-first | 模糊需求必须确认 | 自动/手动 |
| keep-simple | 优先最简单可维护方案 | 自动/手动 |

### 2. 工程化流程（7 步标准工作流）

1. **需求澄清**：`/brainstorm` - 苏格拉底式问答，明确需求
2. **方案设计**：输出架构设计方案
3. **计划拆解**：`/write-plan` - 拆解为最小任务单元
4. **TDD 开发**：`/execute-plan` - RED-GREEN-REFACTOR 循环
5. **调试修复**：自动触发标准化调试流程
6. **代码审查**：`/code-review` - 多维度审查
7. **合并交付**：完成分支合并与文档归档

### 3. 强制门禁（Hooks）

- **PreToolUse**：禁止修改非目标文件、禁止高危命令
- **PreCommit**：必须通过测试、代码审查、安全扫描
- **SecurityCheck**：SQL 注入、XSS、敏感信息检查

### 4. 团队自定义命令

| 命令 | 功能 | 用法 |
|------|------|------|
| `/code-review` | 多维度代码审查 | `/code-review [文件路径]` |
| `/deploy` | 标准化部署流程 | `/deploy [环境]` |
| `/sprint-start` | 迭代启动初始化 | `/sprint-start [迭代名称]` |

## 安装方法

### 方式一：从 Git 仓库安装

```bash
/plugin install 内部GitLab地址/team-ai-coding-plugin.git#v1.0.0
```

### 方式二：本地安装

将插件目录放置到 Claude Code 的插件目录：

```
~/.claude/plugins/team-ai-coding-plugin/
```

## 使用方法

### 基础使用

安装后，插件会自动加载所有技能和门禁。输入 `/help` 查看可用命令。

### 标准开发流程

```bash
# 1. 需求澄清
/brainstorm 需求：实现用户登录功能

# 2. 计划拆解
/write-plan 基于设计文档生成开发计划

# 3. 计划执行（自动 TDD）
/execute-plan 执行开发计划

# 4. 代码审查
/code-review

# 5. 部署
/deploy staging
```

### 快速修复流程

```bash
# 直接修复，受底层原则约束
修复登录接口的超时问题

# 或使用最小改动原则
/minimal-edit 仅修复登录接口的超时问题，不改动其他业务逻辑
```

## 目录结构

```
team-ai-coding-plugin/
├── .claude-plugin/
│   └── plugin.json              # 插件元信息
├── skills/
│   ├── karpathy-team/           # Karpathy 技能
│   │   ├── goal-driven.md
│   │   ├── minimal-changes.md
│   │   ├── ask-first.md
│   │   └── keep-simple.md
│   └── superpowers-team/        # Superpowers 工作流
│       ├── brainstorm.md
│       ├── write-plan.md
│       ├── execute-plan.md
│       └── tdd.md
├── hooks/
│   ├── pre-tool-use.sh          # 工具调用前校验
│   ├── pre-commit.sh            # 提交前门禁
│   └── security-check.sh        # 安全扫描
├── commands/
│   ├── code-review.md
│   ├── deploy.md
│   └── sprint-start.md
├── templates/
│   ├── frontend/
│   ├── backend/
│   └── mobile/
├── CLAUDE.md                    # 团队统一规范
└── README.md                    # 本文档
```

## 更新方法

```bash
/plugin update team-ai-coding-plugin
```

## 版本历史

### v1.0.0 (2026-04-21)

- 初始版本
- 集成 Karpathy Skills 4 条核心原则
- 集成 Superpowers 标准 7 步工作流
- 添加强制门禁（PreToolUse、PreCommit、SecurityCheck）
- 添加团队自定义命令（code-review、deploy、sprint-start）

## 常见问题

### Q: 如何临时禁用某个门禁？

A: 不建议禁用门禁。如确需临时绕过，可在命令前添加 `--no-verify` 参数（需管理员权限）。

### Q: 如何添加团队自定义技能？

A: 在 `skills/` 目录下创建新的技能文件，并在 `plugin.json` 中注册。

### Q: 如何修改代码规范？

A: 编辑 `CLAUDE.md` 文件，所有团队成员更新插件后自动生效。

## 技术支持

如有问题，请联系团队 AI 负责人。

---

**维护团队**：Team AI
**版本**：v1.0.0
**更新日期**：2026-04-21
