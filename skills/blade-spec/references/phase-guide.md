# Blade Spec — 阶段执行指南

本文件包含阶段转换规则、质量检查清单和异常处理方案。执行各阶段时参阅。

---

## 阶段转换规则

### 前置条件

| 转换 | 前置条件（交互模式） | 前置条件（自动模式） |
|---|---|---|
| → 需求 | spec.json 已创建 | spec.json 已创建（auto_mode: true） |
| 需求 → 设计 | requirements.md 已生成且用户已批准 | requirements.md 已生成 |
| 设计 → 任务 | design.md 已生成且用户已批准 | design.md 已生成 |
| 任务 → 执行 | tasks.json 已生成且用户已批准 | tasks.json 已生成 |
| 执行 → 完成 | 所有任务状态为 completed 或 skipped | 所有任务状态为 completed 或 skipped |

### 审批流程

**交互模式（默认）：**

1. 文档写入对应文件
2. 向用户展示摘要（关键数据点，不全文复述）
3. 等待用户明确表态：
   - "通过"/"可以"/"没问题"/"OK" → 更新 spec.json，进入下一阶段
   - 具体修改意见 → 修改文档后重新展示摘要
   - "重来"/"重新生成" → 清空当前阶段文档，重新生成

**自动模式（--auto）：**

1. 文档写入对应文件
2. 输出一行简要进度（路径 + 关键指标）
3. 直接更新 spec.json（phases.{phase}.status = `approved`，approved_at 写入当前时间），进入下一阶段
4. 不等待用户输入，不暂停

### spec.json 一致性

spec.json 是恢复执行的唯一依据。每次状态变更**必须立即**更新 spec.json，确保：

- 中断后可从任意断点恢复
- 状态与实际文件内容一致
- updated_at 反映最新操作时间

---

## 各阶段质量检查

### 需求阶段

- [ ] 每个用户故事有 ≥2 条验收标准
- [ ] 至少 1 条验收标准覆盖边界/异常场景
- [ ] 正常流程和异常流程都有覆盖
- [ ] 范围外事项已列出（避免后续范围蔓延）
- [ ] 需求编号连续无跳号（R-001, R-002...）
- [ ] 验收标准使用 GIVEN/WHEN/THEN 格式且可验证
- [ ] 术语无歧义

### 设计阶段

- [ ] 包结构与目标工程一致（Boot: `modules/{module}/`，Cloud: `{module}/` 或 `modules/aigc/{module}/business/`）
- [ ] Entity 继承 `TenantEntity`，使用 `@Data @TableName @EqualsAndHashCode(callSuper = true)`
- [ ] VO 继承 Entity，添加展示层补充字段（如字典翻译、关联名称）
- [ ] Controller 继承 `BladeController`，标注 `@TenantDS`（多租户）和 `@PreAuth`（权限）
- [ ] Service 接口继承 `BaseService<T>`，实现类继承 `BaseServiceImpl<Mapper, T>`
- [ ] Wrapper 继承 `BaseEntityWrapper<Entity, VO>`，`entityVO()` 中通过 `DictCache`/`SysCache` 补充关联数据
- [ ] Controller 使用 `R<T>` 响应包装，通过 `Wrapper.build().entityVO()` 转换
- [ ] 表名使用项目约定前缀（如 `blade_`、`blade_ai_`），包含审计字段和租户隔离
- [ ] Boot 路由需加服务名前缀（`AppConstant` 常量或字符串），Cloud 只写功能路径（网关通过 Nacos 补全服务名）
- [ ] Cloud 工程需考虑 Entity/VO 是否拆分到 `blade-service-api` 对应模块
- [ ] 数据流图完整（从入口到存储全链路，包含 Wrapper 转换环节）
- [ ] 影响分析覆盖现有代码改动（具体到文件）
- [ ] 每个类/组件关联到需求编号
- [ ] Mermaid 图语法正确可渲染

### 任务阶段

- [ ] 每个任务粒度适中（一个类/组件或一组紧密相关改动）
- [ ] 依赖关系无循环
- [ ] 每个任务关联 ≥1 个需求编号
- [ ] 任务描述具体（包含模块、路径、文件名）
- [ ] 排序符合分层依赖（DDL → Entity → Mapper → VO/Wrapper → Service → Controller）
- [ ] 总任务数合理（典型值 5-20 个）
- [ ] 依赖链无断裂（被引用的任务 ID 都存在）

### 执行阶段

- [ ] 代码遵循项目编码规范（CLAUDE.md 或现有代码风格）
- [ ] 先阅读同模块现有代码并模仿其风格
- [ ] 使用 MyBatis-Plus（LambdaQueryWrapper），不用 JDBC 直接查询
- [ ] 使用 Lombok 注解（@Data、@Slf4j、@RequiredArgsConstructor），不手写 getter/setter
- [ ] 日志用占位符格式，变量名有明确语义（禁止 `Exception e`、`LlmConfig l` 等简写）
- [ ] 使用项目已有的框架和工具（不引入未经批准的新依赖）
- [ ] 每个逻辑阶段完成后执行构建验证（`mvn clean compile -DskipTests`）
- [ ] 不引入循环依赖（引入新模块依赖前先检查）
- [ ] 不附带任务范围外的"优化"或"重构"

---

## 异常处理

### 用户中途修改需求

1. 评估影响范围
2. **小修改**（补充字段、调整描述）→ 直接修改当前阶段文档 + 同步更新 requirements.md
3. **大修改**（新增核心功能、改变架构方向）→ 建议回退到需求阶段重新审阅
4. 受影响的后续文档需标记为待更新

### 执行中发现设计缺陷

1. 暂停当前任务
2. 向用户报告问题和建议修改方案
3. 用户确认后修改 design.md
4. 调整 tasks.json 中受影响的后续任务（新增/删除/修改）
5. 继续执行

### 构建失败

1. 分析错误信息，定位问题代码
2. 修复代码
3. 重新构建直到通过
4. 在任务 result 中注明修复内容

### 任务无法完成

1. 分析原因（依赖缺失？技术限制？需求不清？）
2. 依赖缺失 → 检查是否遗漏前置任务，必要时补充
3. 技术限制 → 标记为 `skipped`，在 result 中记录原因
4. 需求不清 → 暂停，向用户确认后再继续
5. 告知用户，由用户决定后续处理

### 循环依赖

在引入新模块依赖时检查循环依赖：

1. 报告完整依赖链路
2. 提出替代方案（提取公共模块、接口隔离、事件驱动等）
3. 用户确认后调整设计

---

## 连续执行模式

以下情况启用连续执行模式：
- 用户说"全部执行"/"自动跑完"/"不用一个个确认"
- spec.json 中 `auto_mode: true`（自动模式进入执行阶段时自动启用）

1. 跳过任务间的确认步骤
2. 每完成一个任务输出一行进度：
   ```
   ✅ T-001 [1/8] 创建 DDL 脚本
   ✅ T-002 [2/8] 创建 LlmConversation 实体类
   ✅ T-003 [3/8] 创建 Mapper 接口
   ...
   ```
3. 构建检查点保留（每组逻辑相关任务完成后构建验证）
4. 遇到以下情况**必须停下来**报告：
   - 构建失败且无法自动修复
   - 任务无法完成
   - 发现设计缺陷需要修改
5. 全部完成后给出完整总结

---

## 恢复执行

通过 `/blade-spec continue` 恢复时：

1. 读取 spec.json 确定当前阶段和状态
2. 根据阶段加载对应文件：
   - `requirements` → 检查 requirements.md 是否存在，存在则展示等待审批，不存在则重新生成
   - `design` → 加载 requirements.md，检查 design.md 状态
   - `tasks` → 加载 requirements.md + design.md，检查 tasks.json 状态
   - `executing` → 加载全部文档，从 tasks.json 中第一个 pending 任务继续
3. 向用户确认当前进度后继续

---

## Spec 命名规范

文件夹名称（英文短名）的生成规则：

1. 从需求描述中提取核心概念
2. 翻译为英文，使用 kebab-case
3. 控制在 2-4 个单词以内
4. 避免过于宽泛的名称（如 `new-feature`、`update`）

**示例：**

| 需求描述 | 文件夹名 |
|---|---|
| 多模型对话管理功能 | `chat-management` |
| RAG 检索增强生成管道 | `rag-pipeline` |
| Prompt 模板管理系统 | `prompt-template` |
| 模型调用日志与统计 | `model-usage-stats` |
| 用户权限与 API Key 管理 | `auth-api-key` |
