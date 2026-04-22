# OAuth2 认证 + SaaS 多租户 + Secure 安全框架

## OAuth2 认证系统

### 三种授权模式

#### 1. 密码模式 (Password) - 内部可信应用
```
POST http://localhost/blade-auth/oauth/token
Headers:
  Tenant-Id: 000000
  Authorization: Basic {base64(clientId:clientSecret)}
Form:
  grant_type: password
  scope: all
  username: admin
  password: {SM2加密后的密码}
```
**重要**: 框架使用 **SM2 国密算法**加密密码，前端必须先 SM2 加密再传输。使用 `Sm2KeyGenerator` 获取加密密文。

#### 2. 刷新令牌模式 (Refresh Token)
```
POST http://localhost/blade-auth/oauth/token
Form:
  grant_type: refresh_token
  scope: all
  refresh_token: {刷新令牌}
```

#### 3. 授权码模式 (Authorization Code) - 第三方应用
最复杂安全的模式:
1. 请求授权码 → 用户同意 → 回调获取 code
2. 用 code 换取 access_token
3. 用 access_token 访问资源

### Token 管理

**Token 存储方式**:
- 默认: 无状态 JWT
- Redis 有状态: 配置 `blade.token.state: true` 存入 Redis

**Token 字段说明**:
- `access_token`: 访问令牌
- `token_type`: 令牌类型 (bearer)
- `refresh_token`: 刷新令牌 (有效期更长)
- `expires_in`: 过期秒数 (可在 blade_client 表配置)

**客户端配置** (blade_client 表):
| 字段 | 说明 |
|------|------|
| client_id | 客户端 ID (如 saber) |
| client_secret | 客户端密钥 |
| access_token_validity | Token 过期秒数 |
| refresh_token_validity | 刷新 Token 过期秒数 |
| authorized_grant_types | 授权类型 |

### SM2 国密配置 (4.1.0+)
```yaml
blade:
  oauth2:
    public-key: SM2公钥
    private-key: SM2私钥
```
使用 `Sm2KeyGenerator` 生成密钥对。

### Token 加密 (3.2.0+)
```yaml
blade:
  token:
    sign-key: 你的签名密钥(32位以上必须配置)
    crypto-key: 你的加密密钥
```
使用 `CryptoKeyGenerator` 生成密钥。

### 客户端单点登录控制 (3.1.1+)
```yaml
blade:
  token:
    single-level: all     # 全平台单用户
    # single-level: client # 仅客户端内单用户
```

### 短信登录 (4.1.0+)
集成多租户 SMS 模块，通过短信验证码获取 Token。

## SaaS 多租户体系

### 租户隔离模式

#### 模式一: 字段隔离 (默认)
- 所有租户共享数据库，通过 `tenant_id` 字段区分
- 框架自动在 SQL 中添加 `WHERE tenant_id = 'xxx'`
- Entity 继承 `TenantEntity` 即自动启用租户过滤
- 排除表: `blade.tenant.exclude-tables` 配置

#### 模式二: 数据源隔离
- 每个租户独立数据库
- 配置 `blade_tenant_datasource` 表
- 使用 `blade-starter-sharding` 依赖
```yaml
blade:
  sharding:
    enabled: true
```

### 租户增强配置
```yaml
blade:
  tenant:
    enhance: true  # 开启增强模式
    exclude-tables:
      - blade_log_api
      - blade_log_error
      - blade_log_usual
```

### 租户产品包 (2.8.1+)
- 在系统中配置租户可用的功能模块
- 不同租户看到不同的菜单和功能
- 通过 "产品包配置" 管理

### TenantUtil 工具 (4.2.0+)
非 HTTP 请求场景 (任务调度、RPC) 指定租户:
```java
Notice detail = TenantUtil.use("000000", () ->
    noticeService.getOne(Condition.getQueryWrapper(notice))
);
```

### 多租户顶部菜单
- 每个租户独立顶部菜单配置
- 在菜单管理中为不同租户配置不同菜单

## Secure 安全框架

### 基于 JWT 的轻量级安全框架

**核心注解 @PreAuth**:
```java
@PreAuth("permitAll()")           // 允许所有已认证请求
@PreAuth("denyAll()")             // 拒绝所有
@PreAuth("hasRole('admin')")      // 需要角色
@PreAuth("hasAllRole('admin','user')")  // 需要所有角色
@PreAuth("hasMenu('notice:add')") // 需要菜单权限 (4.3.0+)
```

**简化注解 (4.6.0+)**:
```java
@IsAdmin        // 管理员判断
@IsAdministrator // administrator 角色判断
```

**自定义授权扩展**:
- 继承 AuthFun 类
- 添加自定义权限判断方法
- 在 @PreAuth 中使用 Spring EL 表达式调用

### 严格模式 (4.0.0+ 默认开启)
```yaml
blade:
  secure:
    strict-token: true    # 验证完整 Token (含用户/部门/角色/权限信息)
    strict-header: true   # 需要 Blade-Requested-With 请求头
```
关闭: 设为 false (不推荐)

### SSO 单点登录
- 支持第三方系统 OAuth2 授权码模式接入
- 跨域系统集成 (4.4.0+ 优化)
- SSO 登出逻辑优化

### 动态签名认证 (2.7.1+)
```yaml
blade:
  secure:
    sign:
      - method: ALL
        pattern: /blade-desk/dashboard/sign
        crypto: "sha1"
```

### 超级令牌认证 (4.8.0+)
- 用于服务间可信调用
- 签名认证防重放攻击
- 请求方法全局规则配置
