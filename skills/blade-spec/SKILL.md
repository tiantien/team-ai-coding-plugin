---
name: blade-spec
description: >
  BladeX 规范驱动开发工作流 Spec-Driven Development (SDD) 。将复杂需求自动拆解为「需求分析 → 技术设计 → 任务拆解」
  三阶段规范文档，然后逐任务驱动自动开发，全程状态可追踪。适用场景：从零开发完整功能模块、复杂系统设计、大型重构规划。
  当用户说"帮我规划一下"、"先设计再开发"、"这个功能比较复杂"、"我要做一个新功能"、"帮我拆解一下需求"、
  "spec"、"SDD"、"规范驱动"等时触发。也可直接使用 /blade-spec 调用。不适用于简单修改、单个 bug 修复或快速问答。
---

# Blade Spec — 规范驱动开发工作流

先谋定，后行动。将一句话需求转化为结构化的工程规范，再逐任务驱动自动开发。

## 核心理念

直接"边聊边写"容易导致上下文丢失和逻辑冲突。Blade Spec 将规划与执行分离：

- **规划阶段**（人机协作）：AI 生成结构化文档，人类审查把关方向
- **执行阶段**（AI 驱动）：以规范文档为锚点，逐任务自动开发

规范文档是整个开发过程的「单一事实来源」，防止 AI 在长对话中偏离需求。

## 铁律

- **先规划后执行**：交互模式下，未经用户审批的阶段不得跳到下一阶段；自动模式下，阶段间自动推进但文档仍然完整生成
- **文档即契约**：生成的文档是开发准则，不得自行偏离
- **可追溯性**：每个任务关联具体需求编号，每行代码有据可循
- **遵循项目规范**：所有生成代码必须严格遵循项目 CLAUDE.md 中的编码规范（如有）
- **状态即文件**：spec.json 和 tasks.json 是进度的唯一事实来源，每次状态变更必须立即写入文件

## 状态管理

spec.json 和 tasks.json 是 Spec 恢复执行的唯一依据。 `/blade-spec continue` 完全依赖这两个文件来判断断点位置，如果文件内容与实际进度不一致，恢复将出错。因此，状态更新是每个阶段的强制动作，不是可选的收尾步骤。

**核心规则：先更新文件，再报告进度。**

⚠️ **严禁用 Claude Code 内置的 TaskCreate / TaskUpdate 替代 tasks.json 文件更新。** 它们是完全独立的两套系统——TaskCreate/TaskUpdate 只存在于当前对话的内存中，下次对话就消失了；而 tasks.json 是磁盘上的持久文件，`/blade-spec continue` 恢复执行时只认它。如果只调用了 TaskUpdate 而没有 Write tasks.json，等于没有记录任何进度。

⚠️ **禁止批量更新。** 不要等所有任务完成后一次性写入 tasks.json 终态。每完成一个任务，必须立即用 Write 工具重写 tasks.json（详见阶段四的「状态同步协议」）。tasks.json 的 `completed` 字段应该随着执行逐步递增（0 → 1 → 2 → 3 → ...），而不是从 0 直接跳到终值。

⚠️ **Write 时保留完整结构。** 每次重写 tasks.json 时，必须保留所有任务的全部字段（包括 description、requirement_ids、depends_on 等初始字段）。只更新变更的字段（status、started_at、completed_at、result、files_created、files_modified）和顶层计数。不得在重写时丢弃任何字段。

### spec.json 更新时机

在以下事件发生时，立即用 Write 工具重写 spec.json：

| 事件 | 更新字段 |
|---|---|
| 阶段文档生成完成 | `phase` → 当前阶段名，`phases.{phase}.status` → `in_progress`，`updated_at` |
| 用户审批通过 / 自动模式推进 | `phases.{phase}.status` → `approved`，`phase` → 下一阶段名，`updated_at` |
| 开始执行某个任务 | `current_task` → 任务 ID，`updated_at` |
| 某个任务完成 | `current_task` → null，`updated_at` |
| 全部完成 | `phase` → `completed`，`current_task` → null，`phases.execution.completed_at`，`updated_at` |

### tasks.json 更新时机

| 事件 | Write 次数 | 更新字段 |
|---|---|---|
| 阶段三生成任务清单 | 1 次 | 用 Write 工具写入完整 tasks.json（字段格式见 `references/templates.md`，必须包含 version、spec_name、所有任务的 description/requirement_ids/depends_on 等完整字段） |
| STEP-A: 开始执行某个任务 | 每个任务 1 次 | `tasks[i].status` → `"in_progress"`，`tasks[i].started_at` → ISO 8601，顶层 `current_task` → 任务 ID |
| STEP-C: 某个任务完成 | 每个任务 1 次 | `tasks[i].status` → `"completed"`，`tasks[i].completed_at`，`tasks[i].result`，`tasks[i].files_created/files_modified`，顶层 `completed` +1，顶层 `current_task` → null |

一个有 N 个任务的 Spec，执行阶段 tasks.json 至少被 Write `2N + 1` 次（阶段三初始化 1 次 + 每个任务 STEP-A 和 STEP-C 各 1 次）。

## 使用方式

```
/blade-spec <需求描述>           # 启动新 Spec（交互模式，每阶段需审批）
/blade-spec --auto <需求描述>    # 启动新 Spec（自动模式，全流程一次性完成）
/blade-spec continue [name]     # 继续未完成的 Spec
/blade-spec next [name]         # 执行下一个任务
/blade-spec status              # 查看所有 Spec 状态
```

**示例：**

```
/blade-spec 多模型对话管理功能，支持多轮会话、模型切换和历史记录
/blade-spec --auto 多模型对话管理功能，支持多轮会话、模型切换和历史记录
/blade-spec continue chat-management
/blade-spec next
```

---

## 自动模式（Auto Mode）

当使用 `--auto` 参数时，整个工作流从需求分析到代码生成全自动完成，不在阶段间暂停等待用户审批：

- **跳过所有审批门控**：需求 → 设计 → 任务拆解 → 执行，一路贯通
- **阶段间自动推进**：每个阶段完成后立即进入下一阶段，无需用户确认
- **保留进度输出**：每个阶段完成时输出简要摘要（路径 + 关键数据），方便事后审阅
- **保留构建检查点**：编译验证不跳过，构建失败仍会尝试自动修复
- **保留错误中断**：构建失败且无法自动修复、任务无法完成时仍会停下来报告
- **任务连续执行**：执行阶段自动启用连续执行模式，不逐任务确认

自动模式的状态会记录在 spec.json 的 `auto_mode: true` 字段中。通过 `continue` 恢复时会读取此字段，继续以自动模式运行。

自动模式适合需求已经想清楚、希望快速出完整骨架代码的场景。如果需求还比较模糊、需要逐步探讨，建议使用默认的交互模式。

---

## 路由逻辑

收到用户输入后，按以下规则判断操作：

1. **带子命令**：`continue`、`next`、`status` → 执行对应操作
2. **带 `--auto` 参数**：提取 `--auto` 后剩余文本作为需求描述 → 启动新 Spec（自动模式）
3. **带需求描述**：不匹配任何子命令和参数的文本 → 启动新 Spec（交互模式）
4. **无参数**：`/blade-spec` → 扫描已有 Spec，有进行中的则询问是否继续，否则提示输入需求
5. **阶段审批**：如当前有进行中的 Spec（非自动模式）且用户回复"可以"/"通过"/"没问题"等，视为当前阶段审批通过

---

## 文件结构

所有 Spec 存放在 `{project}/.claude/blade-spec/` 下：

```
.claude/blade-spec/
├── chat-management/               # 英文短名（kebab-case）
│   ├── spec.json                  # 元数据与状态
│   ├── requirements.md            # 阶段一：需求文档
│   ├── design.md                  # 阶段二：技术设计
│   ├── tasks.json                 # 阶段三：任务清单
│   └── result.md                  # 完成总结
```

各文件的完整模板参见 `references/templates.md`。

---

## 工作流

**交互模式（默认）：**
```
用户需求 → [需求分析] → 审批 → [技术设计] → 审批 → [任务拆解] → 审批 → [逐任务执行] → 完成总结
```

**自动模式（--auto）：**
```
用户需求 → [需求分析] → [技术设计] → [任务拆解] → [连续执行全部任务] → 完成总结
```

### 阶段零：初始化

1. 分析用户需求，提炼核心功能点
2. 生成英文短名（kebab-case）。交互模式下向用户确认；**自动模式下直接采用，不等待确认**
3. 创建 `.claude/blade-spec/{name}/` 目录和 `spec.json`（自动模式下 `auto_mode: true`）
4. 自动进入阶段一

### 阶段一：需求分析（Requirements）

**目标**：明确"做什么"和"为什么做"。

**执行步骤：**

1. **读取项目上下文**：
   - CLAUDE.md 了解架构和规范（如有）
   - 扫描相关模块现有代码，理解业务模型和技术栈
   - 检查是否有类似功能已实现

2. **生成 requirements.md**（模板见 `references/templates.md`）：
   - **需求原文**：将用户的原始需求进行文案润色后放在文档最上方。润色仅限措辞优化（使表达更清晰、更专业），严禁添加用户未提及的功能或需求
   - 需求概述
   - 用户故事（R-001、R-002...），每个包含：角色、功能、价值
   - 验收标准（GIVEN/WHEN/THEN），覆盖正常和边界场景
   - 范围外事项
   - 约束与假设

3. **展示摘要**：
   - **交互模式**：展示摘要并等待审批：
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       📋 需求文档已生成
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     路径: .claude/blade-spec/{name}/requirements.md
     用户故事: X 个 | 验收标准: Y 条

     请审阅后回复：
       ✅ 通过 → 进入技术设计阶段
       ✏️ 修改意见 → 我来调整
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     ```
   - **自动模式**：输出一行进度后直接进入下一阶段：
     ```
     📋 需求文档已生成 → .claude/blade-spec/{name}/requirements.md (R-001~R-00X, AC x Y 条)
     ```

4. **推进**：交互模式等待用户确认；自动模式直接更新 spec.json，进入阶段二

### 阶段二：技术设计（Design）

**目标**：明确"怎么做"，连接需求与代码。

**执行步骤：**

1. **深入分析**：
   - 阅读已批准的 requirements.md
   - 分析现有相关模块代码和数据结构
   - 确定新功能的模块归属

2. **生成 design.md**（模板见 `references/templates.md`）：
   - 架构概述：新功能如何融入现有系统
   - 模块设计：包/目录结构、类/组件职责
   - 数据模型：数据库表结构或数据存储设计（如涉及）
   - API 设计：接口端点定义
   - 数据流图：Mermaid 序列图/流程图
   - 技术决策：关键实现策略
   - 影响分析：对现有代码的改动范围

3. **展示摘要**：
   - **交互模式**：展示摘要并等待审批
   - **自动模式**：输出一行进度后直接进入下一阶段：
     ```
     📐 技术设计已生成 → .claude/blade-spec/{name}/design.md (X 个类, Y 张表, Z 个接口)
     ```

4. **推进**：交互模式等待用户确认；自动模式直接更新 spec.json，进入阶段三

### 阶段三：任务拆解（Tasks）

**目标**：将设计拆解为可独立执行的最小任务单元。

**执行步骤：**

1. **读取 requirements.md 和 design.md**

2. **用 Write 工具将 tasks.json 写入文件**（格式见 `references/templates.md`）：
   - 每个任务包含：ID、标题、描述、关联需求、依赖、涉及文件
   - 粒度：一个任务 = 一个类/组件或一组紧密相关的改动
   - 排序：按依赖关系拓扑排序，基础设施优先，业务逻辑其次
   - 典型顺序：数据模型 → 数据访问层 → 服务层 → 接口层 → 配置
   - tasks.json 必须是一个实际文件，不要仅在内存中规划

3. **更新 spec.json**：`phase` → `tasks`，`phases.tasks.status` → `in_progress`

4. **展示任务列表**：
   - **交互模式**：展示完整任务列表并等待审批：
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       📝 任务清单已生成
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     共 X 个任务:
       T-001  创建 DDL 脚本                       R-001,R-002
       T-002  创建 LlmConversation 实体类         R-001,R-002
       T-003  创建 Mapper 接口                    R-001
       T-004  创建 VO 和 Wrapper                  R-002
       T-005  创建 Service 接口和实现             R-001,R-002,R-003
       T-006  创建 Controller                     R-001,R-002,R-004
       ...

     请审阅后回复：
       ✅ 通过 → 开始逐任务执行
       ✏️ 修改意见 → 我来调整
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     ```
   - **自动模式**：输出一行进度后直接进入执行阶段：
     ```
     📝 任务清单已生成 → .claude/blade-spec/{name}/tasks.json (共 X 个任务)
     ```

5. **推进**：交互模式等待用户确认；自动模式直接更新 spec.json（`phase` → `executing`，`phases.tasks.status` → `approved`），进入阶段四（自动启用连续执行模式）

### 阶段四：逐任务执行（Execution）

#### 状态同步协议（每个任务必须执行）

每个任务的执行严格遵循 3 步状态同步。这不是建议，而是强制协议——跳过任何一步都会导致 `/blade-spec continue` 断点恢复失败。无论是交互模式还是自动模式、无论是串行还是并行、无论任务大小，每个任务都必须完整执行这 3 步。

**STEP-A: 标记开始** → 用 Write 工具重写 tasks.json：
- `tasks[i].status` → `"in_progress"`
- `tasks[i].started_at` → 当前 ISO 8601 时间
- 顶层 `current_task` → 该任务 ID

**STEP-B: 执行任务** → 编写代码（期间不写 tasks.json）

**STEP-C: 标记完成** → 用 Write 工具重写 tasks.json：
- `tasks[i].status` → `"completed"`
- `tasks[i].completed_at` → 当前 ISO 8601 时间
- `tasks[i].result` → 一句话描述完成了什么
- `tasks[i].files_created` → 实际新建的文件路径列表
- `tasks[i].files_modified` → 实际修改的文件路径列表
- 顶层 `completed` → 加 1（如之前是 3，现在是 4）
- 顶层 `current_task` → `null`
- **保留任务的所有原始字段**（description、requirement_ids、depends_on 等不得删除）

Write 时重写整个 tasks.json 文件。只更新当前任务的字段和顶层计数，其他任务保持原样。

这意味着一个有 8 个任务的 Spec，tasks.json 至少被 Write 16 次（每个任务 STEP-A 和 STEP-C 各 1 次）。如果你发现自己只 Write 了 1-2 次，说明协议被跳过了。

> 为什么这么重要？因为用户可能在任意时刻中断对话。如果 T-004 已经执行完但 tasks.json 还停在 `completed: 0`，下次 `/blade-spec continue` 会从 T-001 重新开始，导致重复工作甚至文件冲突。实时更新是断点续传的生命线。

#### 核心循环

对每个任务重复以下步骤：

1. **读取 tasks.json**，找到第一个 `pending` 任务
2. **STEP-A**：标记为 `in_progress`，Write tasks.json（同时更新 spec.json 的 `current_task`）
3. **加载上下文**：重新阅读 requirements.md 和 design.md 中关联的部分，阅读已完成任务的产出文件，阅读目标模块现有代码并模仿其风格
4. **STEP-B**：执行任务——编写代码，严格遵循项目编码规范。执行前先判断当前任务是否可借助其他 Blade 技能加速（见下方「技能协同」）
5. **STEP-C**：标记为 `completed`，Write tasks.json（必须保留所有原始字段，只更新状态相关字段）
6. **报告完成**（交互模式展示详细卡片，连续执行模式输出一行进度）
7. **继续下一个任务**，除非用户说"暂停"/"停一下"

交互模式的完成报告格式：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ T-002 完成 [2/8]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
创建 LlmConversation 实体类 (R-001, R-002)

+ .../llm/business/pojo/entity/LlmConversation.java
+ .../llm/business/pojo/entity/LlmMessage.java

下一个: T-003 创建 Mapper 接口
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 连续执行模式

当用户明确说"全部执行"/"自动跑完"/"不用一个个确认"时，或在自动模式下：

- 跳过每个任务之间的确认步骤
- **状态同步协议不变**——每个任务仍然执行 STEP-A → STEP-B → STEP-C，Write tasks.json 不可省略
- 每完成一个任务输出一行进度：`✅ T-002 [2/8] 创建 LlmConversation 实体类`
- 构建检查点仍然保留
- 遇到构建失败或任务无法完成时停下来报告
- 全部完成后给出完整总结

> 连续执行≠跳过状态同步。连续执行跳过的是「等待用户确认」，不是 Write tasks.json。

### 构建检查点

每完成一组逻辑相关的任务，执行项目对应的构建命令进行编译验证：

- **Maven 项目**：`mvn clean compile -DskipTests`
- **Gradle 项目**：`gradle compileJava`
- **Node.js 项目**：`npm run build` 或 `tsc --noEmit`
- **Python 项目**：`python -m py_compile` 或对应的 lint 工具
- **其他项目**：根据项目构建配置自动识别

构建失败则立即修复，不跳过。

### 技能协同

执行任务时，识别任务类型并借助对应的 Blade 技能提升效率和一致性：

| 任务特征 | 推荐技能 | 触发时机 |
|---------|---------|---------|
| 后端固定模块开发（Entity → Mapper → Service → Controller 全套） | `/blade-design` | 任务涉及新建完整 CRUD 模块时，将模块名、实体名、字段列表传给 blade-design 生成骨架代码，再根据 design.md 补充业务逻辑 |
| 前端页面开发且使用 Avue 组件 | `/avue-design` | 任务涉及 avue-crud、avue-form 等组件的页面开发时，借助 avue-design 生成配置化的前端代码 |
**协同原则：**

- 技能生成的代码是起点而非终点，必须根据 design.md 中的设计细节进行调整
- 生成后仍需执行构建检查点验证
- 任务报告中注明使用了哪个技能辅助生成，便于追溯
- `/blade-commit` 绝不自动执行，仅当用户明确要求提交时才调用

### 阶段五：完成总结

所有任务完成后，依次执行以下 4 步（每步都是必须的文件操作，不可跳过）：

1. **写入 result.md**：用 Write 工具生成完成总结（模板见 `references/templates.md`）

2. **写入 tasks.json 终态**：确保所有任务的 status 为 `completed` 或 `skipped`，`completed` 计数与实际一致

3. **写入 spec.json 终态**：用 Write 工具重写 spec.json，确保包含以下字段：
   ```json
   {
     "phase": "completed",
     "current_task": null,
     "phases": {
       "requirements": { "status": "approved" },
       "design": { "status": "approved" },
       "tasks": { "status": "approved" },
       "execution": { "status": "completed", "completed_at": "ISO-8601时间戳" }
     }
   }
   ```

4. **展示最终报告**：
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     🎉 Spec 执行完毕: chat-management
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   任务: 8/8 完成
   新增: 10 个文件 | 修改: 2 个文件

   详细报告: .claude/blade-spec/chat-management/result.md

   后续建议:
     1. 执行构建验证
     2. 功能测试（交由用户执行）
     3. 确认无误后可使用 /blade-commit 提交代码
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

---

## 继续未完成的 Spec

`/blade-spec continue [name]`：

1. 扫描 `.claude/blade-spec/` 下所有 spec.json
2. 未指定名称时，列出未完成的 Spec 供选择
3. 读取 spec.json 的 phase 确定断点
4. 从断点处继续：
   - `requirements` → 继续完善需求文档或等待审批
   - `design` → 进入或继续技术设计
   - `tasks` → 进入或继续任务拆解
   - `executing` → 从第一个 pending 任务继续
   - `completed` → 告知已完成

---

## 查看状态

`/blade-spec status`：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Blade Spec 状态总览
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 chat-management     设计中       2/5 阶段
  🔨 rag-pipeline        执行中       8/12 任务
  ✅ prompt-template     已完成       2024-03-28
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 关键原则

### 上下文锚定

执行任一任务前，重新阅读 requirements.md 和 design.md 中的关联部分。这些文档是开发的指南针，防止在长对话中偏离方向。

### 遵守项目规范

先阅读同模块现有代码，模仿其风格。严格遵循项目 CLAUDE.md（如有）中定义的命名规范、编码风格和架构约定。BladeX 体系 Boot 和 Cloud 共享统一分层：Controller(`BladeController`) → Service(`BaseService`/`BaseServiceImpl`) → Mapper(`BaseMapper`) → Wrapper(`BaseEntityWrapper`) → Entity(`TenantEntity`)。差异仅在包路径和路由前缀。如无 CLAUDE.md，从现有代码中学习并保持一致。

### 最小变更原则

每个任务只做任务描述中的事，不附带额外的"优化"或"重构"。

### 构建验证

代码变更后主动执行构建验证，确保每次变更可编译/构建通过。

---

阶段转换规则和质量检查清单参见 `references/phase-guide.md`。
