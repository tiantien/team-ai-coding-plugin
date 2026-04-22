# Secure 安全框架 — 注解参考 & 配置参考

## 安全注解体系

BladeX Secure 提供两层安全防线：

| 层级 | 组件 | 职责 | 相关注解 |
|------|------|------|----------|
| 第一层：身份认证 | `TokenInterceptor` | 校验 Token 是否有效 | `@PermitAll` |
| 第二层：权限认证 | `AuthAspect` 等 AOP 切面 | 校验角色/权限 | `@PermitAll`、`@PreAuth`、`@IsAdmin`、`@IsAdministrator` |

请求先经过身份认证，再经过权限认证，两层均通过后才能到达业务方法。

### 注解一览

| 注解 | 来源 | 身份认证 | 权限认证 | 适用场景 |
|------|------|:---:|:---:|------|
| `@PermitAll` | Jakarta 标准 | 跳过 | 跳过 | 完全公开的接口（验证码、公告、健康检查等） |
| `@PreAuth` | BladeX | - | SpEL 表达式 | 细粒度权限控制（权限编号、角色、菜单、SpEL） |
| `@IsAdmin` | BladeX | - | 管理员角色 | 管理端接口 |
| `@IsAdministrator` | BladeX | - | 超级管理员 | 系统级接口 |

> 身份认证列标记 `-` 表示该注解不影响 Token 校验，Token 校验照常执行。

### @PermitAll

来自 `jakarta.annotation.security.PermitAll`，同时跳过身份认证和权限认证，接口完全公开。

```java
// 方法级别 — 单个接口放行
@PermitAll
@GetMapping("/captcha")
public R<CaptchaVO> captcha() {
    return R.data(captchaService.generate());
}

// 类级别 — 整个 Controller 放行
@PermitAll
@RestController
@RequestMapping("/open")
public class OpenController { ... }
```

**覆盖类级权限注解**：`@PermitAll` 可以覆盖所有权限认证注解，包括 `@PreAuth`、`@IsAdmin`、`@IsAdministrator`：

```java
@PreAuth(permission = "system:manage")
@RestController
public class SystemController {

    @PermitAll
    @GetMapping("/version")
    public R<String> version() {
        // @PermitAll 覆盖类级 @PreAuth，无需任何认证
    }

    @GetMapping("/config")
    public R<Config> config() {
        // 未标注 @PermitAll，继承类级 @PreAuth 权限校验
    }
}
```

### @PreAuth

通用权限校验注解，支持多种权限模式：

```java
// 接口权限
@PreAuth(permission = "user:add")

// 角色权限（支持逗号分隔多角色）
@PreAuth(role = "admin,user")

// 菜单权限
@PreAuth(menu = "user")

// 组合属性（必须同时满足）
@PreAuth(role = "admin", permission = "user:add")

// SpEL 表达式
@PreAuth("hasPermission('user:add') and hasRole('admin')")
```

### @IsAdmin / @IsAdministrator

```java
@IsAdmin           // 等价于 @PreAuth("hasAnyRole('administrator', 'admin')")
@IsAdministrator   // 等价于 @PreAuth("hasRole('administrator')")
```

### 注解优先级规则

**方法级优先于类级**：方法和类上同时存在注解时，方法级注解优先。

**@PermitAll 覆盖范围**：在各 AOP 切面的入口处检查，一旦匹配到则直接放行：

| 类级注解 | 方法级注解 | 身份认证 | 权限认证 |
|----------|-----------|:---:|:---:|
| 无 | `@PermitAll` | 跳过 | 跳过 |
| `@PreAuth(...)` | `@PermitAll` | 跳过 | 跳过 |
| `@IsAdmin` | `@PermitAll` | 跳过 | 跳过 |
| `@IsAdministrator` | `@PermitAll` | 跳过 | 跳过 |

### 注解 vs 配置式放行

| 方式 | 作用时机 | 配置位置 |
|------|----------|----------|
| `blade.secure.skip-url` | 路径匹配阶段，命中后不进入 `TokenInterceptor` | YAML 配置文件 |
| `@PermitAll` | 进入 `TokenInterceptor` 后，通过注解检查放行 | Controller 代码 |

两种方式任一生效即可放行。配置方式适合统一管理公共路径，注解方式适合在代码中就近声明。

---

## 配置参考

### 令牌配置 (blade.token.*)

```yaml
blade:
  token:
    state: false          # Token 是否有状态（true = 存储于 Redis）
    single: false         # 是否开启单用户登录
    single-level: all     # 单用户模式级别：all（全平台唯一）/ client（客户端唯一）
    sign-key: xxx         # JWT 签名密钥，必须 32 位以上
    crypto-key: xxx       # Token 加密传输密钥
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `state` | Boolean | `false` | Token 是否有状态，`true` 存储于 Redis |
| `single` | Boolean | `false` | 是否开启单用户登录 |
| `single-level` | SingleLevel | `ALL` | `ALL` 全平台唯一，`CLIENT` 客户端唯一 |
| `sign-key` | String | - | JWT 签名密钥，**必须 32 位以上** |
| `crypto-key` | String | - | Token 加密传输密钥 |

### 安全核心配置 (blade.secure.*)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enabled` | Boolean | `false` | 是否开启鉴权 |
| `strict-token` | Boolean | `true` | 是否开启令牌严格模式 |
| `strict-header` | Boolean | `true` | 是否开启请求头严格模式 |
| `skip-url` | List\<String\> | `[]` | 放行路径列表 |

### 权限校验配置 (blade.secure.auth)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `auth-enabled` | Boolean | `true` | 是否开启权限校验 |
| `auth` | List\<AuthSecure\> | `[]` | 权限校验规则列表 |

AuthSecure 参数：`method`(HttpMethod)、`pattern`(路径)、`expression`(SpEL 权限表达式)

### 基础认证配置 (blade.secure.basic)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `basic-enabled` | Boolean | `true` | 是否开启基础认证 |
| `basic` | List\<BasicSecure\> | `[]` | 基础认证规则列表 |

BasicSecure 参数：`method`、`pattern`、`username`、`password`

### 签名认证配置 (blade.secure.sign)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sign-enabled` | Boolean | `true` | 是否开启签名认证 |
| `sign` | List\<SignSecure\> | `[]` | 签名认证规则列表 |

SignSecure 参数：`method`、`pattern`、`crypto`（加密方式：`sha1` 默认 / `md5`）

### 客户端认证配置 (blade.secure.client)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `client-enabled` | Boolean | `true` | 是否开启客户端认证 |
| `client` | List\<ClientSecure\> | `[]` | 客户端认证规则列表 |

ClientSecure 参数：`client-id`(客户端标识)、`path-patterns`(路径匹配列表)、`exclude-patterns`(豁免路径列表)

### 完整配置示例

```yaml
blade:
  token:
    state: true
    single: true
    single-level: all
    sign-key: bladex-is-a-java-development-platform

  secure:
    enabled: true
    strict-token: true
    strict-header: true
    skip-url:
      - /api/public/**
      - /api/open/**

    auth-enabled: true
    auth:
      - method: GET
        pattern: /api/admin/**
        expression: "hasRole('admin')"
      - method: POST
        pattern: /api/user/**
        expression: "hasPermission('user:edit')"

    basic-enabled: true
    basic:
      - method: ALL
        pattern: /api/internal/**
        username: admin
        password: admin123

    sign-enabled: true
    sign:
      - method: ALL
        pattern: /api/sign/**
        crypto: sha1

    client-enabled: true
    client:
      - client-id: sword
        path-patterns:
          - /api/web/**
        exclude-patterns:
          - /api/web/public/**
```

### 默认放行路径

框架默认放行以下路径，无需额外配置：

```
/actuator/health/**    /v3/api-docs/**      /swagger-ui/**
/oauth/**              /feign/client/**     /static/**
/assets/**             /error               /favicon.ico
```

### 环境变量覆盖

```bash
BLADE_TOKEN_STATE=true
BLADE_TOKEN_SINGLE=true
BLADE_TOKEN_SIGN_KEY=your-secret-key
BLADE_SECURE_ENABLED=true
BLADE_SECURE_STRICT_TOKEN=true
```

### 相关类

| 类名 | 说明 |
|------|------|
| `BladeSecureProperties` | 安全配置属性类 |
| `JwtProperties` | JWT 配置属性类 |
| `TokenInterceptor` | 身份认证拦截器（第一层） |
| `AuthAspect` | 权限认证切面（第二层） |
| `AuthFun` | SpEL 内置函数类 |
| `AuthSecure` / `BasicSecure` / `SignSecure` / `ClientSecure` | 各认证配置类 |
