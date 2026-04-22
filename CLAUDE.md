# 团队 AI 编程规范

> 本规范融合 BladeX 全栈开发、Karpathy Skills 底层心法与 Superpowers 工程化流程，适用于团队所有 AI 辅助编程场景。

## 一、BladeX 全栈开发 Skills

### 代码生成

| Skill | 用途 | 调用方式 |
|-------|------|----------|
| `blade-design` | 全栈代码生成器（后端+前端+数据库） | `/blade-design` |
| `blade-doc` | 框架知识库查询 | `/blade-doc` |
| `blade-commit` | Gitmoji 规范提交 | `/blade-commit` |

### 流程管理

| Skill | 用途 | 调用方式 |
|-------|------|----------|
| `blade-storm` | 头脑风暴与设计探索 | `/blade-storm` |
| `blade-spec` | 规范驱动开发（复杂需求） | `/blade-spec` |
| `blade-plan` | 轻量规划执行（中等需求） | `/blade-plan` |

### 工程对比与同步

| Skill | 用途 | 调用方式 |
|-------|------|----------|
| `blade-audit` | 代码审计（6 大维度） | `/blade-audit` |
| `blade-compare` | 跨工程智能对比 | `/blade-compare` |
| `blade-sync` | 跨工程提交同步 | `/blade-sync` |

### 前端组件

| Skill | 用途 | 调用方式 |
|-------|------|----------|
| `avue-design` | Avue 组件代码生成 | `/avue-design` |

---

## 二、底层行为准则（Karpathy Skills）

### 1. 目标驱动执行（Goal-Driven）

**规则**：只给成功标准，不指定具体实现步骤，让 AI 自主选择最优方案。

**示例**：
```
✅ 正确：目标：实现用户登录接口，成功标准：支持JWT鉴权、错误率<0.1%、响应时间<200ms
❌ 错误：用 Redis 存储会话，密码用 bcrypt 加密，返回 JSON 格式
```

### 2. 最小改动原则（Minimal Changes）

**规则**：只修改与目标相关的代码，不碰无关文件，不做非必要的重构。

**检查清单**：
- [ ] 这个文件是否与当前目标直接相关？
- [ ] 这个改动是否是实现目标所必需的？
- [ ] 这个改动是否会影响其他功能？

### 3. 不确定先询问（Ask-First）

**规则**：需求模糊、边界不清晰、存在歧义时，必须先向用户确认，不擅自脑补需求。

**必须确认的场景**：
- 功能边界
- 技术选型
- 兼容性要求
- 性能要求
- 安全要求

### 4. 极简实现原则（Keep It Simple）

**规则**：优先选择最简单、可维护的实现方案，不做过度工程化、不炫技、不引入非必要依赖。

**反模式警示**：
- ❌ 过度抽象
- ❌ 过度分层
- ❌ 引入不必要依赖
- ❌ 过度配置化

---

## 三、工程化流程（Superpowers）

### 标准 7 步工作流

| 步骤 | 操作 | 命令 |
|------|------|------|
| 1 | 需求澄清 | `/blade-storm` 或 `/brainstorm` |
| 2 | 方案设计 | 基于需求输出设计 |
| 3 | 计划拆解 | `/blade-spec` 或 `/write-plan` |
| 4 | TDD 开发 | `/execute-plan` |
| 5 | 调试修复 | 自动触发 `systematic-debugging` |
| 6 | 代码审查 | `/blade-audit` 或 `/code-review` |
| 7 | 合并交付 | `/blade-commit` 完成提交 |

### TDD 开发规范

严格遵循 RED-GREEN-REFACTOR 循环：

1. **RED**：先写失败测试用例
2. **GREEN**：写实现代码使测试通过
3. **REFACTOR**：优化代码结构

**禁止**：先写实现后写测试

---

## 四、代码规范

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 变量 | camelCase | `userName` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 函数 | camelCase | `getUserInfo()` |
| 类 | PascalCase | `UserService` |
| 接口 | PascalCase + I 前缀 | `IUserService` |
| 文件 | kebab-case | `user-service.ts` |

### 函数规范

- 单个函数不超过 50 行
- 单个函数参数不超过 4 个
- 嵌套层级不超过 3 层
- 单一职责原则

---

## 五、安全规范

### 禁止行为

- ❌ 硬编码敏感信息（密码、密钥、Token）
- ❌ 使用字符串拼接 SQL
- ❌ 直接使用用户输入渲染 HTML
- ❌ 提交包含敏感信息的文件

### 必须行为

- ✅ 使用环境变量存储敏感配置
- ✅ 使用参数化查询
- ✅ 对用户输入进行验证和转义
- ✅ 定期更新依赖版本

---

## 六、Git 规范

### 分支命名

| 类型 | 命名 | 示例 |
|------|------|------|
| 功能 | feature/* | feature/user-login |
| 修复 | fix/* | fix/login-timeout |
| 重构 | refactor/* | refactor/auth-module |
| 发布 | release/* | release/v1.0.0 |

### 提交信息格式

使用 Gitmoji 规范，通过 `/blade-commit` 自动生成：

```
<gitmoji> <类型>(<范围>): <描述>

示例：
✨ feat(user): add login feature
🐛 fix(api): resolve timeout issue
📝 docs(readme): update installation guide
```

---

## 七、强制门禁

### PreToolUse 钩子

- 禁止修改非目标文件
- 禁止执行高危命令（rm -rf、git push --force 等）

### PreCommit 钩子

- 必须通过代码审查
- 必须通过测试用例
- 必须通过安全扫描
- 禁止直接提交到 main/master 分支

### SecurityCheck 钩子

- SQL 注入检测
- XSS 漏洞检测
- 敏感信息泄露检测

---

## 八、团队自定义命令

| 命令 | 功能 | 用法 |
|------|------|------|
| `/code-review` | 多维度代码审查 | `/code-review [文件路径]` |
| `/deploy` | 标准化部署流程 | `/deploy [环境]` |
| `/sprint-start` | 迭代启动初始化 | `/sprint-start [迭代名称]` |

---

**版本**：v1.0.0
**更新日期**：2026-04-22
**维护团队**：Team AI
