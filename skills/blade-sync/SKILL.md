---
name: blade-sync
description: BladeX 跨工程 Git 提交智能同步工具。将源工程的 Git 提交记录逐条同步至目标镜像工程，自动处理 Boot/Cloud 等异构项目间的目录结构与包路径差异。支持 --adapt 异构同步模式，可将官方上游工程的提交智能适配到本地二开工程，自动分析功能意图、检测本地定制冲突并给出合并建议。当用户需要同步提交记录、跨工程迁移代码变更、在镜像工程间同步改动、把官方改动适配到二开工程、或使用 /blade-sync 时触发。即使用户只是说"把这几个 commit 同步过去"、"帮我把改动搬到 Boot 工程"、"把官方的更新合到我们工程"、"看看上游更新对我们有什么影响"等模糊表述也应触发。支持多 commit 按序同步，每次同步后自动 commit 并进行二次评审。只允许 commit，禁止 push 等远程操作。
---

# Blade Sync — 跨工程 Git 提交智能同步

将源工程的 Git 提交按时间顺序逐条同步至目标镜像工程，自动处理异构项目（Boot 单体 / Cloud 微服务 / Links IoT 等）之间的目录结构与包路径差异。

支持两种同步模式：
- **镜像同步**（默认）：源工程与目标工程功能一致，仅结构不同，逐文件映射同步
- **异构同步**（`--adapt`）：本地为二开工程，与官方上游代码有功能差异，需理解上游功能意图后智能适配到本地

## 铁律

- **只做 commit**：禁止执行 `git push`、`git pull`、`git rebase`、`git merge`、`git reset --hard` 或任何远程/破坏性 git 操作
- **逐 commit 同步**：每个源 commit 对应目标工程的一个独立 commit，不得合并
- **commit 信息规则**：镜像模式下 commit message 与源 commit 完全一致（原文复制）；adapt 模式下使用 `[upstream:<short-hash>] <原始message>` 格式标注来源
- **人工评审**：每个 commit 同步后，必须展示变更摘要等待用户确认，批准后才执行 commit
- **零署名**：不得在 commit 信息中添加任何工具或 AI 署名

## 使用方式

### 镜像同步（默认）

```
/blade-sync <target-path> [commit-range]
```

源工程默认为当前工作目录（即执行命令时所在的项目）。

| 参数 | 说明 | 示例 |
|---|---|---|
| target-path | 目标镜像工程路径（必填） | `/path/to/BladeX-Boot` |
| commit-range | 待同步的 commit 范围（可选） | `HEAD~3..HEAD`、`abc1234`、`dev..main` |

省略 commit-range 时默认同步最近一次 commit（`HEAD~1..HEAD`）。

**调用示例：**
```bash
/blade-sync /path/to/target                    # 同步最近 1 个 commit 到目标工程
/blade-sync /path/to/target HEAD~3..HEAD       # 同步最近 3 个 commit
/blade-sync /path/to/target abc1234            # 同步指定 commit
/blade-sync /path/to/target master..dev        # 同步分支差异
```

> 若需要显式指定源工程路径（不使用当前目录），可以写：
> `/blade-sync --source /path/to/source /path/to/target [commit-range]`

### 异构同步（--adapt）

```
/blade-sync --adapt <upstream-path> [commit-range] [--dry-run]
```

当前工作目录为本地二开工程（变更的接收方），upstream-path 为官方上游工程（变更的来源方）。

| 参数 | 说明 | 示例 |
|---|---|---|
| --adapt | 开启异构同步模式（必填） | |
| upstream-path | 官方上游工程路径（必填） | `/path/to/BladeX-Official` |
| commit-range | 上游待同步的 commit 范围（可选） | `HEAD~3..HEAD`、`abc1234` |
| --dry-run | 仅分析不应用，输出影响报告后结束 | |

**调用示例：**
```bash
/blade-sync --adapt /path/to/upstream                     # 适配上游最近 1 个 commit
/blade-sync --adapt /path/to/upstream HEAD~5..HEAD        # 适配上游最近 5 个 commit
/blade-sync --adapt /path/to/upstream abc1234 --dry-run   # 仅分析，不实际修改
```

---

## 执行流程

### 阶段一：环境预检

1. **验证路径**：确认源工程（当前工作目录，或 `--source` 指定的路径）和目标工程路径都存在且是 Git 仓库
2. **工作区检查**：确认目标工程工作区干净（`git status` 无未提交变更），若有变更则警告并中止
3. **解析 commit 范围**：
   - 范围格式（`A..B`）：`git -C <source> log --oneline --reverse A..B`
   - 单个 commit：`git -C <source> log -1 --oneline <hash>`
   - 省略时：`git -C <source> log -1 --oneline HEAD`
4. **展示待同步列表**，向用户确认后开始：
   ```
   待同步 3 个 commit（按时间正序）:
     1. abc1234 — :sparkles: 新增设备影子系统
     2. def5678 — :bug: 修复MQTT认证问题
     3. ghi9012 — :recycle: 重构物模型发布逻辑
   确认开始同步？
   ```

### 阶段二：项目结构分析

同步开始前，先识别源和目标工程的结构类型，这决定了路径映射策略。

**工程类型识别方法：**

| 类型 | 判断依据 |
|---|---|
| **Boot 单体** | 根目录有 `src/main/java/`，无 `blade-service/` 等子模块 |
| **Cloud 微服务** | 有 `blade-service/`、`blade-service-api/`、`blade-ops/` 等多模块目录 |
| **Links IoT** | 有 `blade-core/`、`blade-service/`，含 IoT 特有模块（broker/data/tsdb） |
| **其他** | 按实际结构分析，不做假设 |

```bash
# 识别工程类型的关键命令
ls <path>/blade-service 2>/dev/null       # 多模块？
ls <path>/blade-core 2>/dev/null          # Links？
ls <path>/src/main/java 2>/dev/null       # Boot 单体？
find <path> -maxdepth 3 -name "pom.xml" | head -20
```

识别完成后，记录映射方向（如 `Cloud → Boot`），后续所有路径映射基于此方向。

### 阶段三：逐 Commit 同步（核心循环）

对每个待同步的 commit，依次执行以下步骤：

#### 3.1 深度分析源 Commit

```bash
# commit 元信息（hash、完整 message）
git -C <source> log -1 --format="%H%n%B" <hash>

# 变更文件清单（含状态 A/M/D/R）
git -C <source> diff-tree --no-commit-id -r --name-status <hash>

# 变更统计
git -C <source> show --stat <hash>
```

逐文件读取 diff 内容，理解每个文件的变更语义：
```bash
git -C <source> show <hash> -- <file-path>
```

将文件按变更类型分组：
- **A（新增）** → 需在目标工程创建
- **M（修改）** → 需在目标工程找到并修改
- **D（删除）** → 需在目标工程找到并删除
- **R（重命名）** → 需在目标工程找到并重命名

#### 3.2 智能路径映射

这是同步的核心。对每个变更文件，找到它在目标工程中的对应路径。

**Java 文件（按优先级尝试）：**

1. **包名定位**（最可靠）：从源文件读取 `package` 声明，在目标工程搜索包含相同包路径的目录
   ```bash
   grep "^package " <source-file>
   find <target> -type d -path "*/<package-as-path>" -not -path "*/target/*"
   ```

2. **类名搜索**（包路径也有差异时）：在目标工程搜索同名 `.java` 文件
   ```bash
   find <target> -name "DeviceService.java" -not -path "*/target/*"
   ```

3. **模块推断**（目标中找不到现有文件时）：分析源文件所在模块的功能，在目标工程中找功能等价的模块，按包名创建目录结构

**资源文件：**
- MyBatis XML Mapper → 按 Mapper 接口类名匹配同名 `.xml`
- `application*.yml` → 按文件名匹配
- SQL 脚本 → 按文件名匹配
- 其他 → 按 `src/main/resources/` 下的相对路径匹配

**应标记为人工处理的文件：**
- `pom.xml` — 构建依赖在异构工程间通常不同
- `Dockerfile`、`docker-compose.yml` — 部署配置
- 启动类 / 网关配置 — 架构层面的差异
- Feign Client 接口 — Cloud 特有，Boot 中通常是直接调用

**应跳过的文件：**
- `.gitignore`、`.editorconfig`
- `target/`、`.idea/`、`.vscode/`
- 与源工程特有架构强绑定的文件（如 Links 的 broker 模块文件同步到非 IoT 工程）

> 详细的 Boot↔Cloud 路径映射策略和特殊情况处理，参见 `references/path-mapping.md`。

#### 3.3 应用变更

**新增文件（A）：**
1. 确认目标目录存在，不存在则创建
2. 从源 commit 中读取文件完整内容：`git -C <source> show <hash>:<file-path>`
3. 若包路径需调整（如 `org.springblade.modules.system` → `org.springblade.system`），修改文件内的 `package` 声明和相关 `import` 语句
4. 写入目标路径

**修改文件（M）：**
1. 读取源 commit 中该文件的 diff：`git -C <source> show <hash> -- <file>`
2. 读取目标工程中对应文件的当前内容
3. **语义级变更迁移**：理解 diff 做了什么（增加方法、修改逻辑、删除代码），将等价变更应用到目标文件。不是机械 patch，而是理解意图后智能应用
4. 若目标文件上下文与源文件差异过大（如方法签名不同、所在位置不同），标记为"需人工确认"

**删除文件（D）：**
1. 在目标工程中找到对应文件
2. 确认存在后删除；找不到则记录警告，不中断流程

**重命名文件（R）：**
1. 在目标工程中找到原文件
2. 按新名称和映射规则执行重命名
3. 若文件内容也有变更，同步应用

#### 3.4 同步报告与评审

变更应用完毕后，向用户展示同步报告：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Commit 同步报告 [1/3]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
源 Commit: abc1234 — :sparkles: 新增设备影子系统
映射方向: Links (Cloud) → Boot

✅ 成功映射 & 应用 (5 个文件):
  A  blade-service/.../ShadowService.java
     → src/main/java/.../ShadowService.java
  A  blade-service/.../ShadowController.java
     → src/main/java/.../ShadowController.java
  M  blade-service/.../DeviceServiceImpl.java
     → src/main/java/.../DeviceServiceImpl.java
  A  blade-core/.../ShadowEntity.java
     → src/main/java/.../ShadowEntity.java
  A  .../mapper/ShadowMapper.xml
     → src/main/resources/.../ShadowMapper.xml

⚠️ 需人工确认 (1 个文件):
  M  pom.xml — 构建文件变更，已跳过自动同步
     (新增依赖: blade-tsdb-tdengine)

❌ 无法映射 (1 个文件):
  A  blade-core/blade-broker-core/.../MqttShadowHandler.java
     — 目标工程无对应 broker 模块

📝 包路径调整:
  org.springblade.iot.shadow → org.springblade.modules.iot.shadow
  (已自动调整 package 声明和 import 语句)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

等待用户确认。用户可能的反馈：
- **确认通过** → 继续 3.5
- **要求修改** → 根据反馈调整后重新展示报告
- **跳过此 commit** → 回滚目标工程变更，进入下一个 commit
- **中止同步** → 回滚目标工程变更，结束流程

#### 3.5 二次对比验证

用户初步确认后，执行二次验证：

```bash
# 目标工程当前 diff
git -C <target> diff
git -C <target> diff --stat
```

将目标工程的 diff 与源 commit 的 diff 进行语义对比，检查：
- 所有业务逻辑变更是否已正确同步
- 是否有意外的多余修改
- 包名 / import 调整是否正确完整
- 新增文件内容是否完整

向用户简要展示对比结论，确认无误。

#### 3.6 执行 Commit

用户最终确认后：

```bash
# 暂存变更文件（逐个添加，不用 git add .）
git -C <target> add <file1> <file2> ...

# 删除的文件
git -C <target> rm <deleted-file>

# 使用源 commit 的完整 message
git -C <target> commit -m "$(cat <<'EOF'
<源 commit 的完整 message，原文复制>
EOF
)"
```

#### 3.7 Commit 后确认

```bash
git -C <target> log -1 --oneline
git -C <target> status
```

确认工作区干净、commit 成功后，输出进度信息并进入下一个 commit。

### 阶段四：同步完成总结

所有 commit 处理完毕后，展示最终总结：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  同步完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
方向: BladeX-Links → BladeX-Boot
总计: 3 个 commit

  ✅ abc1234 — :sparkles: 新增设备影子系统
  ✅ def5678 — :bug: 修复MQTT认证问题
  ⚠️ ghi9012 — :recycle: 重构物模型发布逻辑
     (2 个文件需人工确认，已在报告中标注)

后续建议:
  1. 在目标工程执行编译验证: mvn clean compile -DskipTests
  2. 检查标记为"需人工确认"的文件
  3. 确认无误后再执行 push
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 异构同步模式（--adapt）

当本地工程已经过二次开发，与官方上游代码存在功能差异时，使用 `--adapt` 模式。该模式不做机械的文件复制，而是理解上游 commit 的功能意图，结合本地代码现状，智能生成适配方案。

### adapt 与镜像模式的核心差异

| | 镜像同步（默认） | 异构同步（--adapt） |
|---|---|---|
| 前提假设 | 两个工程功能一致，仅结构不同 | 本地已二开，功能有差异 |
| 同步逻辑 | 文件级 diff 映射 + 包名调整 | 功能意图分析 → 本地扫描 → 智能适配 |
| commit message | 1:1 复制源 commit | `[upstream:<hash>] <原始message>` |
| 人工介入程度 | 中（路径映射大部分自动） | 高（冲突文件需逐个决策） |

### adapt 执行流程

阶段一（环境预检）和阶段二（项目结构分析）与镜像模式相同，但注意方向：
- **上游工程**（`upstream-path`）= 读取 commit 的来源
- **本地工程**（当前工作目录）= 应用变更的目标，需工作区干净

以下为阶段三的 adapt 专属步骤，替代镜像模式的 3.1 ~ 3.6。

#### A.1 功能意图深度分析

在镜像模式 3.1 的基础上，进一步分析 commit 的业务语义：

```bash
# 读取完整 diff
git -C <upstream> show <hash>

# 读取变更文件完整内容（理解上下文）
git -C <upstream> show <hash>:<file-path>

# 读取变更前的文件版本（对比理解变更意图）
git -C <upstream> show <hash>^:<file-path>
```

分析重点：
- 这个 commit 新增了什么业务能力？修复了什么 bug？
- 变更的核心逻辑是什么？涉及哪些业务领域？
- 各文件之间的关联关系（如 Entity + Service + Mapper + XML 构成一组完整功能）

输出「功能意图摘要」供用户审阅：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  功能意图分析 [commit 1/3]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
源 Commit: abc1234 — ✨ 新增数据权限过滤
功能概述: 在查询接口中增加基于部门的数据权限过滤，
         影响 system 模块的用户列表和角色列表查询

变更清单:
  A  DataScopeFilter.java       — 新增数据权限过滤器
  M  UserServiceImpl.java       — 查询方法中注入过滤器
  M  RoleServiceImpl.java       — 同上
  M  UserMapper.xml              — SQL 增加权限条件
  M  RoleMapper.xml              — 同上
  M  pom.xml                     — 新增依赖

业务意图:
  1. 新建 DataScopeFilter 类，基于当前用户部门 ID 过滤数据
  2. 在 UserService 和 RoleService 的列表查询中调用该过滤器
  3. Mapper XML 增加动态 SQL 条件
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### A.2 本地代码扫描

定位本地工程中与上游变更对应的文件，分析本地定制状态：

```bash
# 在本地工程中搜索对应文件
find <local> -name "UserServiceImpl.java" -not -path "*/target/*"

# 读取本地文件内容
cat <local-file>

# 若有 git 历史，查看本地对该文件的修改记录
git -C <local> log --oneline -5 -- <file-path>
```

对每个涉及的本地文件，判断定制状态：

| 状态 | 含义 |
|---|---|
| **未定制** | 本地文件与上游前一版本基本一致，可安全应用 diff |
| **轻度定制** | 有局部修改，但不涉及上游变更的区域 |
| **重度定制** | 本地对同一代码区域有大幅改动，需人工决策 |
| **不存在** | 本地无对应文件（可能被删除或从未引入） |

#### A.3 冲突分析与适配方案

根据「上游变更类型 × 本地定制状态」交叉分析，制定逐文件策略：

| 上游变更 | 本地状态 | 策略 |
|---|---|---|
| 新增文件（A） | 无对应文件 | **直接引入** — 走镜像模式的映射逻辑，调整包路径后写入 |
| 新增文件（A） | 已有同名文件 | **展示对比** — 本地可能已自行实现类似功能，需用户决策 |
| 修改文件（M） | 未定制 | **直接应用** — 映射后应用 diff |
| 修改文件（M） | 轻度定制（不冲突） | **智能合并** — 将上游变更应用到本地文件的非定制区域 |
| 修改文件（M） | 重度定制 | **人工决策** — 展示双方代码，由用户选择处理方式 |
| 修改文件（M） | 不存在 | **标记跳过** — 本地未引入此文件，展示上游意图供参考 |
| 删除文件（D） | 未定制 | **确认删除** — 展示后由用户确认 |
| 删除文件（D） | 有定制 | **默认保留** — 警告上游已删除，但本地有定制，建议保留 |
| 重命名（R） | 未定制 | **跟随重命名** |
| 重命名（R） | 有定制 | **人工决策** — 展示说明，由用户选择 |

若使用了 `--dry-run`，到此步骤为止：输出完整的分析报告后结束，不修改任何文件。参见下方「dry-run 报告格式」。

#### A.4 交互式适配

对需要人工决策的文件，逐个展示详情并提供操作选项：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  冲突文件 [2/3]: UserServiceImpl.java
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
上游意图: 在 selectUserList() 方法中注入 DataScopeFilter
本地定制: selectUserList() 已被改写为支持多租户过滤

上游变更 (diff):
  + DataScopeFilter filter = new DataScopeFilter();
  + query.apply(filter.getScopeCondition());

本地当前代码 (相关片段):
  public IPage<User> selectUserList(...) {
      // 本地定制：多租户过滤
      query.apply(TenantFilter.getCondition());
      return userMapper.selectPage(page, query);
  }

请选择操作:
  [1] 采纳上游变更（覆盖本地定制）
  [2] 保留本地代码（跳过此文件）
  [3] 智能合并（保留本地定制，同时加入上游变更）
  [4] 手动编辑（输入你想要的最终代码或修改指令）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**用户选择 [3] 智能合并时**：分析双方代码的意图，在保留本地定制的基础上融入上游变更，然后展示合并后的代码供确认。

**用户选择 [4] 手动编辑时**：接收用户的自由输入，可以是：
- 具体的代码片段 → 直接替换
- 修改指令（如"两个过滤器都保留，先租户过滤再数据权限过滤"）→ 按指令生成代码
- 生成后再次展示结果供确认，用户不满意可继续调整

#### A.5 同步报告（adapt 增强版）

所有文件处理完毕后，展示 adapt 模式专属的同步报告：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Adapt 同步报告 [1/3]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
源 Commit: abc1234 — ✨ 新增数据权限过滤
映射方向: BladeX (Cloud) → 本地二开工程 (Boot)
模式: --adapt (异构同步)

📥 直接引入 (1 个文件):
  A  DataScopeFilter.java
     → src/main/java/.../modules/system/filter/DataScopeFilter.java
     (包路径已调整)

🔀 智能合并 (1 个文件):
  M  RoleServiceImpl.java — 本地无冲突区域，已自动合并

👤 用户决策 (1 个文件):
  M  UserServiceImpl.java — 用户选择: 智能合并
     (保留多租户过滤 + 加入数据权限过滤)

⏭️ 已跳过 (1 个文件):
  M  pom.xml — 构建文件，需手动处理
     (上游新增依赖: blade-scope)

📊 直接应用 (2 个文件):
  M  UserMapper.xml — 本地未定制，直接应用
  M  RoleMapper.xml — 本地未定制，直接应用
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

等待用户确认后，执行二次对比验证（同镜像模式 3.5），然后 commit。

#### A.6 Commit（adapt 格式）

adapt 模式使用带上游引用的 commit message：

```bash
git -C <local> commit -m "$(cat <<'EOF'
[upstream:abc1234] ✨ 新增数据权限过滤
EOF
)"
```

后续的 commit 后确认（3.7）和同步完成总结（阶段四）与镜像模式相同，但总结中应标注模式为 `--adapt`。

### --dry-run 干跑模式

与 `--adapt` 配合使用，仅执行 A.1 ~ A.3（功能意图分析 + 本地代码扫描 + 冲突分析），输出完整的影响报告但不修改任何文件、不进入交互式适配。

适用场景：
- 先评估上游一批 commit 的影响范围，再决定同步哪些
- 了解上游更新与本地定制的冲突程度
- 团队评审时生成分析报告

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Dry-Run 影响分析报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
上游工程: /path/to/BladeX
本地工程: /path/to/local (当前目录)
分析范围: 5 个 commit (abc1234..def5678)

按冲突级别汇总:
  🟢 可直接引入/应用: 12 个文件
  🟡 需智能合并:       4 个文件
  🔴 需人工决策:       3 个文件
  ⚪ 建议跳过:         2 个文件 (pom.xml, Dockerfile)

高风险文件:
  UserServiceImpl.java — 本地重度定制 vs 上游新增数据权限逻辑
  SecurityConfig.java  — 本地重写了鉴权链 vs 上游新增 OAuth2 配置
  application.yml      — 配置差异较大

建议: 先同步前 3 个 commit（冲突较少），
     后 2 个 commit 涉及安全模块，建议逐文件评审后再同步
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 异构工程同步要点

### 语义级同步而非机械复制

同步的本质不是复制粘贴文件，而是将"变更意图"从一个工程迁移到另一个工程。面对结构差异时，应理解变更做了什么，然后在目标工程中以等价方式实现相同效果。

例如，源 commit 在 Cloud 工程的 `blade-service/blade-system` 模块新增了一个 Service 类。同步到 Boot 工程时，不仅要把文件放到正确位置，还要确保包名、import 都适配 Boot 的结构，让代码在目标工程中能正常编译。

### 包名自动调整

Boot 和 Cloud 最常见的包路径差异是 `modules` 层级：

| Boot | Cloud |
|---|---|
| `org.springblade.modules.system` | `org.springblade.system` |
| `org.springblade.modules.desk` | `org.springblade.desk` |

同步时需自动调整：
1. 文件内的 `package` 声明
2. 文件内引用其他已调整类的 `import` 语句
3. 新增文件的存放目录路径

### 无法自动处理时的原则

1. **不猜测**：明确标记为"需人工确认"
2. **展示上下文**：展示源 diff 内容和目标文件当前状态
3. **给出建议**：说明你认为应该怎么处理，但不擅自行动
4. **等待决策**：用户确认后再执行

### 关于目标工程已有本地改动的情况

如果目标工程有未提交的变更，**必须中止**，因为：
- 同步变更会与本地改动混在一起，无法区分
- commit 信息会不准确
- 出问题时无法干净回滚

告知用户先处理目标工程的本地变更（commit 或 stash），然后重新执行同步。
