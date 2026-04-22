---
name: blade-compare
description: BladeX 跨工程智能对比工具。对比两个 BladeX 工程之间的代码差异，自动识别并分离「系统级架构差异」与「业务逻辑差异」。支持 Boot 单体 / Cloud 微服务 / Links IoT 等异构工程间的智能对比，自动处理目录结构、包路径、模块拆分等架构层面的差异映射。提供两种对比模式：目录全量对比和 commit 记录对比。当用户需要对比两个工程的代码差异、查看两个版本之间有什么不同、分析 Boot 和 Cloud 的差异、检查两个工程是否同步、或使用 /blade-compare 时触发。即使用户只是说"对比下这两个工程"、"看看两边代码有什么区别"、"Boot 和 Cloud 差了哪些东西"、"这两个工程同步了吗"、"帮我比一下"等模糊表述也应触发。
---

# Blade Compare — 跨工程智能代码对比

对比两个 BladeX 工程之间的代码差异，核心能力是将差异分为两大类：

- **系统级差异**（架构结构导致的固有差异，可忽略）：包路径 `modules` 层级、模块目录结构、Cloud 特有组件（Feign/Gateway/Nacos）等
- **业务逻辑差异**（重点关注）：实际的功能代码区别，包括新增功能、修改逻辑、缺失代码等

这种分离让用户快速聚焦到真正需要关注的代码差异上，过滤掉因架构选型不同而产生的噪音。

## 铁律

- **只读不写**：禁止修改任何工程的文件、禁止执行 `git commit`、`git push` 或任何写操作
- **不做假设**：对无法确定映射关系的文件，明确标记为"无法映射"而非猜测
- **完整呈现**：系统级差异虽标记为可忽略，但必须列出供用户知晓，不得隐藏
- **按模块组织**：对比结果按业务模块分组展示，而非平铺文件列表

## 使用方式

### 目录对比（默认模式）

```
/blade-compare <path-A> <path-B> [options]
```

对比两个工程目录下的所有代码文件，找出业务逻辑层面的差异。

| 参数 | 说明 | 示例 |
|---|---|---|
| path-A | 工程 A 路径（必填） | `/path/to/BladeX` |
| path-B | 工程 B 路径（必填） | `/path/to/BladeX-Boot` |
| --module | 只对比指定业务模块（可选，多个用逗号分隔） | `--module system,desk` |
| --focus | 只显示业务逻辑差异，隐藏系统级差异摘要（可选） | `--focus` |
| --detail | 显示文件内容级 diff（默认只显示文件级差异清单） | `--detail` |

**调用示例：**
```bash
# 对比两个工程的全部代码
/blade-compare /path/to/BladeX /path/to/BladeX-Boot

# 只对比 system 和 desk 模块
/blade-compare /path/to/BladeX /path/to/BladeX-Boot --module system,desk

# 显示详细的代码级 diff
/blade-compare /path/to/BladeX /path/to/BladeX-Boot --detail

# 只关注业务差异，不展示系统级差异
/blade-compare /path/to/BladeX /path/to/BladeX-Boot --focus
```

> 若当前工作目录就是其中一个工程，可以省略对应路径：
> `/blade-compare /path/to/another-project`（当前目录作为工程 A）

### Commit 对比模式

```
/blade-compare --commits <path-A> <path-B> [commit-range-A] [commit-range-B]
```

对比两个工程的 commit 记录，找出哪些变更已同步、哪些缺失、哪些有分歧。

| 参数 | 说明 | 示例 |
|---|---|---|
| --commits | 开启 commit 对比模式（必填） | |
| path-A | 工程 A 路径（必填） | `/path/to/BladeX` |
| path-B | 工程 B 路径（必填） | `/path/to/BladeX-Boot` |
| commit-range-A | 工程 A 的 commit 范围（可选） | `HEAD~10..HEAD` |
| commit-range-B | 工程 B 的 commit 范围（可选） | `HEAD~10..HEAD` |
| --since | 按日期筛选 commit（可选） | `--since 2024-01-01` |

**调用示例：**
```bash
# 对比两个工程最近 10 个 commit
/blade-compare --commits /path/to/BladeX /path/to/BladeX-Boot HEAD~10..HEAD HEAD~10..HEAD

# 对比指定日期之后的 commit
/blade-compare --commits /path/to/BladeX /path/to/BladeX-Boot --since 2024-03-01

# 对比指定分支范围
/blade-compare --commits /path/to/BladeX /path/to/BladeX-Boot master..dev master..dev
```

---

## 执行流程

### 阶段一：环境预检与结构识别

1. **验证路径**：确认两个工程路径都存在且是 Git 仓库
2. **识别工程类型**：判断每个工程属于 Boot / Cloud / Links / 其他

**工程类型识别方法：**

| 类型 | 判断依据 |
|---|---|
| **Boot 单体** | 根目录有 `src/main/java/`，无 `blade-service/` 等子模块 |
| **Cloud 微服务** | 有 `blade-service/`、`blade-service-api/`、`blade-ops/` 等多模块目录 |
| **Links IoT** | 有 `blade-core/`、`blade-service/`，含 IoT 特有模块（broker/data/tsdb） |
| **其他** | 按实际结构分析，不做假设 |

```bash
# 识别工程类型的关键命令
ls <path>/blade-service 2>/dev/null
ls <path>/blade-core 2>/dev/null
ls <path>/src/main/java 2>/dev/null
find <path> -maxdepth 3 -name "pom.xml" | head -20
```

3. **确定映射方向**：根据两端工程类型确定路径映射策略（如 `Cloud ↔ Boot`），展示给用户确认：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  工程对比 · 环境预检
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
工程 A: /path/to/BladeX — Cloud 微服务
工程 B: /path/to/BladeX-Boot — Boot 单体
映射方向: Cloud ↔ Boot

检测到异构工程对比，将自动处理以下架构差异:
  · 包路径 modules 层级映射
  · 多模块 ↔ 单模块 目录结构映射
  · Cloud 特有组件识别（Feign/Gateway/Nacos）

确认开始对比？
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

若两个工程类型相同（如都是 Cloud），则无需架构差异映射，直接做文件级对比。

### 阶段二：文件清单构建与映射

#### 2.1 扫描两端文件

```bash
# 扫描 Java 文件（排除编译产物和 IDE 文件）
find <path> -name "*.java" -not -path "*/target/*" -not -path "*/.idea/*" -not -path "*/.git/*"

# 扫描资源文件
find <path> -name "*.xml" -o -name "*.yml" -o -name "*.yaml" -o -name "*.properties" \
  | grep -v target | grep -v .idea | grep -v .git

# 扫描 SQL 文件
find <path> -name "*.sql" -not -path "*/target/*"
```

#### 2.2 建立文件映射关系

对每个文件，在对端工程中找到对应文件。映射优先级：

**Java 文件：**
1. **全限定类名匹配**：从文件读取 `package` 声明 + 类名，在对端按包名 + 类名搜索
2. **类名搜索**：若包路径因 `modules` 差异无法直接匹配，按类名搜索后验证包路径的逻辑一致性
3. **无法映射**：标记为"仅存在于工程 A/B"

**资源文件：**
- Mapper XML → 按文件名匹配
- 配置文件 → 按文件名匹配
- SQL 脚本 → 按文件名匹配

> 详细的路径映射策略参见 `references/path-mapping.md`

#### 2.3 文件分类

将所有文件分为以下类别：

| 分类 | 说明 | 处理方式 |
|---|---|---|
| **已映射 · 一致** | 两端都有且内容逻辑等价 | 计入统计，不展示详情 |
| **已映射 · 有差异** | 两端都有但内容不同 | 进入差异分析（阶段三） |
| **仅 A 存在** | 在工程 A 中有，B 中无对应 | 按类型标记（系统级/业务级） |
| **仅 B 存在** | 在工程 B 中有，A 中无对应 | 同上 |
| **无法映射** | 无法确定对应关系 | 单独列出供人工判断 |

**判断"逻辑等价"**：两端文件在忽略以下差异后内容一致则视为等价：
- `package` 声明中的 `modules` 层级差异
- `import` 语句中的 `modules` 层级差异
- 空行、尾部空格差异
- 文件头注释中的模块信息差异

### 阶段三：差异分析与分类

这是 blade-compare 的核心——将差异分为系统级和业务级。

#### 3.1 系统级差异识别

以下差异属于系统级（架构导致的固有差异），对比时应识别并标记为可忽略：

**包路径差异：**
- Boot 的 `org.springblade.modules.xxx` 对应 Cloud 的 `org.springblade.xxx`
- 文件内的 `package` 声明和 `import` 语句中的此类差异

**模块结构差异：**
- Cloud 将 Entity/DTO/VO 放在 `-api` 模块，Service/Controller/Mapper 放在 service 模块；Boot 全部集中在 `modules/xxx/` 下
- Cloud 有独立网关模块（`blade-gateway/`），Boot 无
- Cloud 有独立认证服务（`blade-auth/`），Boot 中认证逻辑集成在主工程中

**Cloud 特有组件（Boot 无对应）：**
- Feign Client 接口及其 Fallback 实现
- 网关路由配置（Gateway routes）
- Nacos 配置文件
- 服务注册/发现配置
- 分布式事务配置（Seata）

**Boot 特有组件（Cloud 无对应）：**
- 集中式启动类（单一 `Application.java`）
- 集中式配置文件（单一 `application.yml` 而非分散配置）

**构建文件差异：**
- `pom.xml` 结构差异（单 POM vs 多模块父子 POM）
- 部署文件（Dockerfile、docker-compose.yml）

**配置文件差异：**
- `application.yml` / `bootstrap.yml` 的结构和内容因架构而异

#### 3.2 业务逻辑差异提取

排除系统级差异后，剩余的差异即为业务逻辑差异。对每个有差异的文件：

```bash
# 读取两端文件内容
cat <path-A>/<file-A>
cat <path-B>/<file-B>
```

进行语义级对比，重点关注：
- **方法级差异**：哪些方法是新增的、被修改的、或被删除的
- **逻辑差异**：同一方法内的实现逻辑差异
- **注解差异**：业务相关的注解（非架构注解）差异
- **字段差异**：Entity/DTO/VO 的字段差异

对比时要过滤掉因架构差异导致的"伪差异"：
- 不同的依赖注入方式（直接调用 vs Feign 调用）实现同一功能时，注意识别这是架构差异而非业务差异
- 但如果一端有某个业务逻辑而另一端完全没有，这就是真正的业务差异

#### 3.3 差异影响评估

对每个业务逻辑差异，评估其影响程度：

| 级别 | 含义 | 判断标准 |
|---|---|---|
| 🔴 **重要** | 功能缺失或逻辑不一致 | 整个方法/类缺失；核心业务逻辑不同 |
| 🟡 **注意** | 实现有差异但功能基本等价 | 参数不同、异常处理不同、日志不同 |
| 🟢 **轻微** | 非功能性差异 | 代码风格、变量命名、注释差异 |

### 阶段四：生成对比报告

#### 目录对比模式的报告

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  工程对比报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
工程 A: /path/to/BladeX (Cloud 微服务)
工程 B: /path/to/BladeX-Boot (Boot 单体)
映射方向: Cloud ↔ Boot
对比时间: 2024-03-15

📊 总体统计:
  已映射文件: 156 个
    · 逻辑等价: 128 个 (82%)
    · 有差异:    28 个 (18%)
  仅 A 存在:  23 个
  仅 B 存在:   8 个
  无法映射:    5 个

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔧 系统级差异（架构导致，可忽略）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  包路径 modules 层级:
    全部 Java 文件的 package/import 中存在
    org.springblade.modules.xxx ↔ org.springblade.xxx

  Cloud 特有组件 (15 个文件):
    · Feign Client: IUserClient.java, ILogClient.java 等 (8)
    · Feign Fallback: UserClientFallback.java 等 (4)
    · Gateway: gateway 模块全部文件 (3)

  Boot 特有组件 (3 个文件):
    · BladeApplication.java (集中启动类)
    · application.yml (集中配置)
    · application-dev.yml

  构建/部署差异:
    · pom.xml 结构不同 (单 POM vs 多模块)
    · Dockerfile (Cloud 各服务独立, Boot 单一)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 业务逻辑差异（重点关注）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [system 模块] — 5 个差异

  🔴 UserServiceImpl.java
     A (Cloud): 包含 DataScope 数据权限过滤逻辑
     B (Boot):  无数据权限过滤
     差异方法: selectUserList(), selectUserPage()

  🔴 DataScopeFilter.java
     仅存在于工程 A (Cloud)
     功能: 基于部门的数据权限过滤器

  🟡 RoleServiceImpl.java
     A (Cloud): grant() 方法包含分布式缓存刷新
     B (Boot):  grant() 方法仅清理本地缓存

  🟡 MenuWrapper.java
     A (Cloud): 包含 hasChildren 字段
     B (Boot):  无 hasChildren 字段

  🟢 DictController.java
     A (Cloud): 方法参数使用 @Valid 注解
     B (Boot):  部分方法缺少 @Valid

  ──────────────────────────────

  [desk 模块] — 2 个差异

  🔴 NoticeServiceImpl.java
     A (Cloud): 新增了发布通知后的推送逻辑
     B (Boot):  仅保存通知，无推送

  🟢 NoticeController.java
     A (Cloud): 新增 batchPublish() 批量发布接口
     B (Boot):  无此接口

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ❓ 无法映射的文件
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  A: blade-service/blade-report/... (5 个文件)
     — 工程 B 中未找到 report 模块对应目录

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📈 对比总结
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  同步率: 82% (128/156 文件逻辑等价)
  重要差异: 3 个 (🔴)
  注意事项: 4 个 (🟡)
  轻微差异: 2 个 (🟢)

  建议:
    1. 优先处理 🔴 标记的重要差异
    2. DataScopeFilter 功能 Boot 工程尚未同步
    3. 通知推送功能 Boot 工程尚未同步
    4. 可使用 /blade-sync 将缺失功能同步到目标工程
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### --detail 模式的补充输出

使用 `--detail` 参数时，对每个有差异的文件额外展示代码级 diff：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  文件详细对比: UserServiceImpl.java
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A: blade-service/blade-system/.../UserServiceImpl.java
B: src/main/java/.../modules/system/service/impl/UserServiceImpl.java

方法级差异:

  [selectUserList] — 🔴 逻辑差异
  A (Cloud):
    public IPage<User> selectUserList(IPage<User> page, ...) {
  +     DataScopeFilter filter = new DataScopeFilter();
  +     query.apply(filter.getScopeCondition());
        return userMapper.selectPage(page, query);
    }

  B (Boot):
    public IPage<User> selectUserList(IPage<User> page, ...) {
        return userMapper.selectPage(page, query);
    }

  分析: 工程 A 新增了数据权限过滤，工程 B 缺少此逻辑

  ──────────────────────────────

  [其他方法]: 逻辑等价 ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Commit 对比模式

### 执行流程

commit 对比模式用于分析两个工程的变更历史，找出同步状态。

#### C.1 获取 commit 列表

```bash
# 获取工程 A 的 commit 列表
git -C <path-A> log --oneline --reverse [commit-range-A]
# 或按日期
git -C <path-A> log --oneline --reverse --since="<date>"

# 获取工程 B 的 commit 列表
git -C <path-B> log --oneline --reverse [commit-range-B]
```

#### C.2 Commit 匹配

按以下策略将两端的 commit 进行匹配：

1. **精确匹配**：commit message 完全一致（最可靠）
2. **upstream 标记匹配**：B 的 commit 以 `[upstream:<hash>]` 格式引用了 A 的 commit hash（blade-sync adapt 模式产生的记录）
3. **语义匹配**：commit message 的核心含义一致（忽略 emoji 和格式差异），且变更的文件有交集
4. **无法匹配**：找不到对应关系

#### C.3 逐 Commit 差异分析

对已匹配的 commit 对，对比两端的变更内容：

```bash
# 查看工程 A 中某个 commit 的变更
git -C <path-A> diff-tree --no-commit-id -r --name-status <hash-A>
git -C <path-A> show <hash-A>

# 查看工程 B 中对应 commit 的变更
git -C <path-B> diff-tree --no-commit-id -r --name-status <hash-B>
git -C <path-B> show <hash-B>
```

比较两端是否修改了对应的文件、变更逻辑是否一致。

#### C.4 Commit 对比报告

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Commit 对比报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
工程 A: /path/to/BladeX (Cloud) — 12 个 commit
工程 B: /path/to/BladeX-Boot (Boot) — 10 个 commit
对比范围: 2024-03-01 至今

📊 匹配统计:
  ✅ 完全同步:  7 个 (commit 已匹配且变更一致)
  🟡 部分同步:  2 个 (commit 已匹配但变更有差异)
  🔴 A 独有:    3 个 (工程 B 中无对应 commit)
  🔵 B 独有:    1 个 (工程 A 中无对应 commit)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✅ 完全同步的 Commit:
  1. abc1234 ↔ xyz7890 — :bug: 修复用户列表分页问题
  2. def5678 ↔ uvw3456 — :sparkles: 新增字典缓存机制
  ... (省略 5 个)

  🟡 部分同步的 Commit:
  1. ghi9012 ↔ rst1234
     A: :zap: 优化角色权限查询并增加数据权限
     B: :zap: 优化角色权限查询
     差异: B 缺少数据权限相关变更 (DataScopeFilter.java 等 2 个文件)

  2. jkl3456 ↔ opq5678
     A: :sparkles: 新增通知推送功能
     B: :sparkles: 新增通知推送功能
     差异: B 缺少 WebSocket 推送实现 (功能不完整)

  🔴 仅工程 A 存在 (未同步到 B):
  1. mno7890 — :sparkles: 新增数据权限过滤器
     影响文件: DataScopeFilter.java, DataScopeAspect.java (2 个)
     建议: 需同步到 B

  2. pqr1234 — :recycle: 重构 OSS 配置逻辑
     影响文件: OssBuilder.java, OssEndpoint.java (3 个)
     建议: 需同步到 B

  3. stu5678 — :sparkles: 新增 Seata 分布式事务支持
     影响文件: SeataConfiguration.java 等 (4 个)
     建议: Cloud 特有功能，可忽略

  🔵 仅工程 B 存在 (B 独有变更):
  1. vwx9012 — :bug: 修复 Boot 启动类配置
     影响文件: BladeApplication.java
     说明: Boot 特有修改，不需要同步到 A

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📈 同步状态总结
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  同步率: 75% (9/12 A 的 commit 已同步或部分同步)
  待同步: 2 个业务相关 commit
  可忽略: 1 个 Cloud 特有 commit

  建议操作:
    1. 使用 /blade-sync 将 mno7890, pqr1234 同步到 B
    2. 检查部分同步的 2 个 commit，补齐缺失部分
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 系统级差异识别规则

这部分是 blade-compare 区别于普通 diff 工具的关键。普通 diff 会把所有文本差异平等对待，而 blade-compare 理解 BladeX 的架构特点，能区分"因为选了不同架构而天然不同"和"真的写了不同的业务逻辑"。

### Boot ↔ Cloud 的系统级差异清单

以下差异在 Boot 和 Cloud 之间是预期存在的，属于架构选型带来的固有差异：

| 差异类型 | 说明 | 识别方式 |
|---|---|---|
| **modules 包层级** | Boot 多一层 `modules`，Cloud 无 | `package`/`import` 中的 `modules` 差异 |
| **模块目录结构** | Boot 单体目录 vs Cloud 多模块 | 文件路径结构差异 |
| **pom.xml 结构** | 单 POM vs 父子 POM | pom.xml 整体结构不同 |
| **Feign Client** | Cloud 独有的远程调用接口 | `@FeignClient` 注解标记的类 |
| **Feign Fallback** | Cloud 独有的降级实现 | 实现了 Feign 接口的 Fallback 类 |
| **Gateway 配置** | Cloud 独有的 API 网关 | `blade-gateway/` 模块全部内容 |
| **Nacos 配置** | Cloud 使用注册/配置中心 | `bootstrap.yml` 中的 Nacos 配置 |
| **启动类差异** | Boot 单一启动类 vs Cloud 多启动类 | `@SpringBootApplication` 标记的类 |
| **配置文件结构** | 集中配置 vs 分散配置 | `application.yml` 的组织方式 |
| **Seata 事务** | Cloud 特有的分布式事务 | Seata 相关配置和注解 |
| **服务发现注解** | Cloud 特有 | `@EnableDiscoveryClient` 等 |
| **Sentinel 限流** | Cloud 常用 | Sentinel 相关配置 |

### Cloud ↔ Links 的系统级差异

| 差异类型 | 说明 |
|---|---|
| **IoT 特有模块** | broker、tsdb、data 模块在标准 Cloud 中不存在 |
| **消息队列模块** | Links 的 MQ 模块是 IoT 特有的 |
| **顶级包名差异** | `org.springblade.iot.*` vs `org.springblade.*` |

### Boot ↔ Links 的系统级差异

综合以上两类差异。

### 识别逻辑

在对比过程中，对每个差异文件执行以下判断流程：

```
1. 文件是否在「系统级差异清单」中？
   ├─ 是 → 标记为系统级差异
   └─ 否 → 继续

2. 文件内容差异是否仅有 modules 包路径差异？
   ├─ 是 → 标记为系统级差异（逻辑等价）
   └─ 否 → 继续

3. 差异方法中，业务逻辑是否等价，仅调用方式不同？
   （如直接调用 vs Feign 调用，本质是同一功能）
   ├─ 是 → 标记为系统级差异
   └─ 否 → 标记为业务逻辑差异

4. 文件仅存在于一端？
   ├─ 属于 Cloud 特有组件 → 系统级差异
   ├─ 属于 Boot 特有组件 → 系统级差异
   └─ 其他 → 业务逻辑差异（一端缺失功能）
```

---

## 异构工程对比要点

### "等价"不等于"相同"

两个异构工程之间，同一个业务功能的代码实现可能表面上看差异很大，但本质上是等价的。blade-compare 需要穿透表面差异，判断业务语义是否一致。

例如，Cloud 工程中通过 Feign Client 调用用户服务获取用户信息，Boot 工程中直接注入 UserService 调用。这两种方式实现的业务功能是相同的，只是因为架构不同导致调用方式不同，应标记为系统级差异而非业务差异。

### 对比粒度

- **文件级**（默认）：列出有差异的文件及差异类型，不展示代码 diff
- **方法级**（`--detail`）：对有差异的 Java 文件，进一步分析到方法粒度
- **代码级**（`--detail`）：展示具体的代码 diff

默认使用文件级对比以保持报告简洁。用户可以通过 `--detail` 查看更细的差异，或在对比报告后针对感兴趣的文件要求进一步查看。

### 对比性能

当文件数量较多时，全量对比可能耗时较长。优化策略：

1. 先用 `git diff --stat` 快速获取差异概览
2. 对同名文件先做 hash 比较（排除完全一致的文件）
3. 对有差异的文件再做内容级分析
4. 若用户指定了 `--module`，只扫描对应模块的文件

```bash
# 快速 hash 比较
md5 -q <file-A>
md5 -q <file-B>
```

> 详细的 Boot↔Cloud↔Links 路径映射规则参见 `references/path-mapping.md`。
> 系统级差异与业务差异的分类判断规则参见 `references/diff-classification.md`。
