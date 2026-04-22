# 动态数据权限 + 动态接口权限

## 三层权限体系
BladeX 提供三层权限: 功能权限 (菜单/按钮) → 接口权限 → 数据权限

## 动态数据权限

### 核心注解 @DataAuth

支持五种权限类型 (其中四种无需自定义 SQL):
- **所在机构可见**: 按 create_dept 过滤
- **所在机构及子集可见**: 含子部门数据
- **个人可见**: 仅创建者可见
- **自定义 SQL**: 灵活配置
- **全部可见**: 无限制

**重要**: 超级管理员不受数据权限影响，仅普通用户账号生效。

### 方式一: 纯注解配置

```java
// 场景1: 所在机构可见 (默认按 create_dept 过滤)
@DataAuth
public IPage<NoticeVO> selectNoticePage(IPage page, Notice notice) { ... }

// 场景2: 所在机构及子集可见
@DataAuth(type = DataAuthType.DEPT_AND_CHILD)
public IPage<NoticeVO> selectNoticePage(IPage page, Notice notice) { ... }

// 场景3: 个人可见
@DataAuth(type = DataAuthType.OWN, column = "create_user")
public IPage<NoticeVO> selectNoticePage(IPage page, Notice notice) { ... }

// 场景4: 自定义 SQL
@DataAuth(type = DataAuthType.CUSTOM,
  value = "create_dept = #{deptId} and create_user = #{userId}")
public IPage<NoticeVO> selectNoticePage(IPage page, Notice notice) { ... }
```

**自定义 SQL 占位符**:
- `${userId}` / `#{userId}` - 当前用户 ID
- `${deptId}` / `#{deptId}` - 当前部门 ID
- `${roleId}` / `#{roleId}` - 当前角色 ID
- `${tenantId}` / `#{tenantId}` - 当前租户 ID
- `${account}` / `#{account}` - 当前账号
- `${userName}` / `#{userName}` - 当前用户名

### 方式二: Web 全自动配置

1. 进入 "数据权限" 模块
2. 选择模块 → 点击数据权限按钮
3. 新建配置:
   - **可见字段**: `*` 全部或 `id, name` 指定
   - **权限类名**: Mapper 方法全路径
4. 在 "角色管理" > "权限配置" 中分配

**权限类名路径差异**:
- BladeX (Cloud): `org.springblade.modules.desk.mapper.NoticeMapper.selectNoticePage`
- BladeX-Boot: `org.springblade.modules.desk.mapper.NoticeMapper.selectNoticePage` (含 modules)
- MyBatis-Plus 自动方法: 用 `selectList` / `selectPage` 等

**无需重启，通过 Redis 缓存即时生效。**

### 方式三: 注解半自动配置

```java
@DataAuth(code = "notice")  // code 对应数据库中的权限编号
public IPage<NoticeVO> selectNoticePage(IPage page, Notice notice) { ... }
```
单条规则可在多个 Mapper 方法间共享。

### 重要注意事项

1. **超级管理员例外**: 完全绕过数据权限
2. **包路径差异**: Boot 有 modules 子目录，Cloud 无
3. **Redis 缓存**: 动态权限使用 Redis，生产需高可用
4. **方法扫描**: 默认只扫描含 "Page" 或 "List" 的方法
   ```yaml
   # 自定义扫描方法名
   blade.scope.method-pattern=Page|List|Custom
   ```
5. **多数据库场景**: 业务库非核心库时需引入 `blade-scope-api` 远程 API
   ```xml
   <dependency>
       <groupId>org.springblade</groupId>
       <artifactId>blade-scope-api</artifactId>
   </dependency>
   ```
6. **BladeX-Biz 使用**: 需先在 BladeX 根目录 `mvn clean install`

## 动态接口权限

补充数据权限，在接口/API 层保护系统。

### 方式一: 注解指定 (最高优先级)
```java
// 单角色
@RequiresPermissions("user")
public R<List<Notice>> list() { ... }

// 多角色 (OR 逻辑)
@RequiresPermissions({"admin", "user"})
public R<List<Notice>> list() { ... }
```
需重启生效，适合不可变敏感端点。

### 方式二: Web 动态配置
1. 进入 "接口权限" > "权限配置"
2. 新建配置:
   - **权限编号**: 冒号分隔 (如 "notice:delete")
   - **权限名称**: 人类可读名称
3. 在角色管理中分配权限
4. Controller 添加注解: `@RequiresPermissions("notice:delete")`
5. **无需重启，即时生效**

### 方式三: 类级全局匹配
```java
@RequiresPermissions("notice")
@RestController
@RequestMapping("notice")
public class NoticeController { ... }
```
- 类级别所有方法继承权限要求
- **路径匹配**: 包含匹配 (设 `/notice/list` 可匹配 `/notice/list/abc`)

### 权限扩展
- **AuthFun 类**: 处理 @PreAuth 方法扩展的主逻辑
- 可扩展 @PreAuth 方法创建企业专属权限系统
