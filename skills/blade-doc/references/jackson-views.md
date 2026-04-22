# JacksonViews 视图过滤系统

基于 Jackson Serialization Views 的响应字段动态裁剪方案，通过 `@BladeView` 注解实现按角色/场景精确控制 JSON 输出字段。

**核心思路**：一个 VO + 一个注解 = 替代 N 个场景化 VO。

## 核心特性

- **一个注解通解**：`@BladeView` 同时用于字段标注和接口控制
- **四级视图层级**：Summary → Detail → Admin → Administrator，继承即包含
- **动态角色解析**：接口可根据当前登录用户角色自动选择视图级别
- **框架内置常驻**：随框架自动加载，未标注 `@BladeView` 的接口零开销
- **完全兼容**：与 `@JsonIgnore`、`@JsonSerialize`、`@JsonFormat`、`@Sensitive` 等注解无冲突
- **自由扩展**：通过 `BladeViewCustomizer` 可注册自定义视图层级

## 快速开始

### 1. 配置角色映射

```yaml
blade:
  jackson:
    view:
      default-view: summary       # 动态模式降级视图
      role-mapping:              # 角色名 → 视图名映射
        administrator: administrator
        admin: admin
        user: detail
        guest: summary
```

### 2. VO 字段标注

```java
@Data
@EqualsAndHashCode(callSuper = true)
public class UserVO extends User {

    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;              // 无标注，始终输出

    @JsonIgnore
    private String password;      // @JsonIgnore 优先级最高，始终不输出

    @BladeView(Views.Summary.class)
    private String roleName;      // 列表就需要

    @BladeView(Views.Detail.class)
    private String tenantName;    // 详情才需要

    @BladeView(Views.Admin.class)
    private String userExt;       // 管理员才能看
}
```

### 3. Controller 接口标注

```java
// 固定使用摘要视图
@GetMapping("/user-list")
@BladeView(Views.Summary.class)
public R<List<UserVO>> userList() { ... }

// 动态视图，根据当前用户角色自动解析
@GetMapping("/info")
@BladeView
public R<UserVO> info(BladeUser user) { ... }

// 写操作不需要 @BladeView — 不过滤，全量输出
@PostMapping("/submit")
public R submit(@Valid @RequestBody User user) { ... }
```

## 视图层级体系

### 四级视图继承

```
Views.Administrator (超级管理员)
  │ extends
Views.Admin (普通管理员)
  │ extends
Views.Detail (普通用户)
  │ extends
Views.Summary (访客 / 列表)
```

高级视图自动包含所有低级视图的字段。

### 判定规则

- **字段上的 `@BladeView`** = 该字段的「最低可见门槛」
- **Controller 上的 `@BladeView`** = 当前接口「激活的视图级别」
- **激活视图 >= 字段门槛 → 输出，否则裁剪**

### 可见性矩阵

| 字段注解 | Summary | Detail | Admin | Administrator | 无视图 |
|---------|---------|--------|-------|---------------|--------|
| 无 `@BladeView` | 输出 | 输出 | 输出 | 输出 | 输出 |
| `@BladeView(Views.Summary.class)` | 输出 | 输出 | 输出 | 输出 | 输出 |
| `@BladeView(Views.Detail.class)` | - | 输出 | 输出 | 输出 | 输出 |
| `@BladeView(Views.Admin.class)` | - | - | 输出 | 输出 | 输出 |
| `@BladeView(Views.Administrator.class)` | - | - | - | 输出 | 输出 |
| `@JsonIgnore` | - | - | - | - | - |

### 三种使用模式

| 模式 | Controller 写法 | 行为 |
|------|----------------|------|
| **静态视图** | `@BladeView(Views.Summary.class)` | 固定使用指定视图，不看角色 |
| **动态视图** | `@BladeView` | 根据当前用户角色自动解析视图 |
| **不过滤** | 不写 `@BladeView` | 全量输出，完全向后兼容 |

## @BladeView 注解参数

| 参数 | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| value | Class<?> | Auto.class | 视图类型。指定具体 Views 类 = 静态模式；默认 Auto.class = 动态模式 |

使用位置：字段（标记可见层级）、方法（控制视图策略）、类（类级别默认视图，方法级可覆盖）

## 角色解析与降级

```
@BladeView(Views.Summary.class)    → 静态：直接用 Summary（不看角色）
@BladeView                         → 动态：解析角色 ↓

AuthUtil.getUserRole()
    ├─ ""（未登录）         → default-view: summary
    ├─ "user"              → role-mapping → detail
    ├─ "admin"             → role-mapping → admin
    ├─ "administrator"     → role-mapping → administrator
    └─ "admin,user"（多角色）→ 取最高权限 → admin
```

安全降级原则：身份不明时，只展示最少量数据。

## BaseEntity 内置视图标注

框架已为 `BaseEntity` 审计字段预设了合理的视图级别：

| 字段 | 视图级别 | 说明 |
|------|---------|------|
| `id` | 始终输出 | 主键 |
| `createTime` | Detail | 创建时间 |
| `status` | Detail | 业务状态 |
| `createUser` | Admin | 创建人 |
| `createDept` | Admin | 创建部门 |
| `updateUser` | Admin | 更新人 |
| `updateTime` | Admin | 更新时间 |
| `isDeleted` | Admin | 删除标记 |

业务 VO 继承 Entity 后，这些字段自动具备视图过滤能力，无需重复标注。

## 自定义扩展

### 自定义视图层级

```java
// Step 1：定义自定义视图接口
public interface SuperAdminView extends Views.Administrator {}

// Step 2：注册到解析器
@Bean
public BladeViewCustomizer myViewCustomizer() {
    return resolver -> {
        // 参数：视图名, 视图Class, 优先级（内置：summary=0, detail=1, admin=2, administrator=3）
        resolver.registerView("superadmin", SuperAdminView.class, 4);
    };
}

// Step 3：YAML 配置角色映射
// blade.jackson.view.role-mapping.superadmin: superadmin

// Step 4：在字段和接口上使用
@BladeView(SuperAdminView.class)
private String internalSecret;
```

### 自定义角色提供者

```java
@Bean
public Supplier<String> roleNameSupplier() {
    return () -> MySecurityContext.getCurrentRole();
}
```

### 自定义视图解析器

```java
@Bean
public BladeViewResolver bladeViewResolver(BladeJacksonProperties properties) {
    BladeViewResolver resolver = new BladeViewResolver(properties.getView());
    resolver.registerView("vip", VipView.class, 1);
    return resolver;
}
```

## 作用域与兼容性

**仅影响响应输出**：`@BladeView` 不参与反序列化（请求入参），写操作无需改造。

| 注解 | 兼容性 | 说明 |
|------|--------|------|
| `@JsonSerialize` | 完全兼容 | 控制"如何输出"，@BladeView 控制"是否输出" |
| `@JsonIgnore` | 优先级更高 | 无论什么视图都不输出 |
| `@JsonInclude` | 完全兼容 | 先视图过滤，再 Include 判断 |
| `@JsonFormat` | 完全兼容 | 字段输出时格式化 |
| `@Sensitive` | 完全兼容 | 脱敏在序列化时生效 |

**零开销设计**：Controller 方法无 `@BladeView` 时，`BladeViewResponseAdvice.supports()` 返回 false，不进入过滤逻辑，与未引入视图功能完全一致。

## 新模块接入流程

```
Step 1: VO 字段标注 @BladeView
Step 2: Controller 查询方法标注 @BladeView
Step 3: 完成（无需修改 Wrapper、Service、Mapper）
```

## 核心组件

| 类名 | 位置 | 用途 |
|-----|------|------|
| `Views` | blade-core-tool | 四级视图层级接口定义 |
| `@BladeView` | blade-core-tool | 统一注解（字段 + 方法 + 类） |
| `BladeViewAnnotationIntrospector` | blade-core-tool | 让 Jackson 识别 @BladeView |
| `BladeViewResolver` | blade-core-tool | 视图名/角色名 → 视图 Class 解析 |
| `BladeViewResponseAdvice` | blade-core-tool | Controller 层响应拦截与视图包装 |
| `BladeViewCustomizer` | blade-core-tool | 自定义视图扩展接口 |
| `BladeViewAutoConfiguration` | blade-core-tool | 自动装配 |
| `BladeViewRoleConfiguration` | blade-core-secure | 默认角色提供者 |

## 注意事项

1. **仅影响序列化输出**：不影响反序列化（请求入参），写接口无需改造
2. **@JsonIgnore 优先级最高**：在任何视图下都不输出
3. **未标注字段始终输出**：没有 `@BladeView` 的字段在所有视图下正常输出
4. **Feign 不受影响**：微服务间调用不经过 `BladeViewResponseAdvice`
5. **Wrapper 正常工作**：Wrapper 在序列化之前执行，所有字段正常填充后再由视图过滤
6. **动态模式降级**：角色获取不到时自动降级到 `default-view`
7. **多角色取最高**：多角色时自动选择权限最高的视图
