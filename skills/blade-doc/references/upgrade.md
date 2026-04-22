# 版本升级指南

## 升级通用步骤
1. 执行数据库升级脚本
2. Git 远程分支合并获取最新代码
3. 清除 Redis (`flushdb`)
4. 对照版本说明检查破坏性变更

## 关键版本变更一览

### 2.2.2 - 租户插件重设计
- 租户过滤从配置改为自动检测 (继承 TenantEntity 即自动启用)
- 排除表: `blade.tenant.exclude-tables`
- 字典 dictKey 从 int 改为 string

### 2.3.0 - Knife4j 升级
- swagger-bootstrap-ui → knife4j
- 导入路径: `com.github.xiaoymin.knife4j.annotations.ApiOperationSupport`
- Saber Avue 2.2.x → 2.3.x，searchChange 需 done 回调

### 2.5.0 - 密码双重加密 + 缓存租户隔离
- 前端 MD5 加密 → 后端二次加密
- CacheUtil 自动按租户隔离 (cacheName 前加 tenant_id)
- `@CacheEvict` → `CacheUtil.clear(cacheName)`
- `enable` → `enabled` (配置命名统一)
- Docker 构建: `docker-maven-plugin` → `dockerfile-maven-plugin`

### 2.6.0 - Token Redis 存储 + API 加密
- Token 可存 Redis (有状态认证)
- 新增 API 报文加密功能
- Long 主键不再需要 @JsonSerialize 注解

### 2.7.0 - SpringBoot 2.2.11 升级
- Knife4j 大版本升级
- 删除 Zipkin 服务 (使用官方)

### 2.7.2 - Prometheus 监控 + Sentinel
- Hystrix → Sentinel (默认)
- Swagger 独立为 blade-swagger 服务 (端口 18000)

### 2.8.0 - Nacos 2.0 + 新端口
- gRPC 端口: 9848 (+1000), 9849 (+1001)
- URL 匹配: 需 `/test/**` (不能仅 `/test`)

### 2.8.1 - 登录锁定 + 多角色选择
- 登录错误锁定功能
- 多角色多部门登录选择对话框

### 2.9.0 - MyBatis-Plus 3.5.1 + DaMeng
- `selectCount()` 返回 Long (不再是 Integer)
- 达梦数据库支持
- Flowable 工作流升级 (新流程设计 UI)

### 3.0.0 - SpringCloud 2021 大版本升级
- 删除 Hystrix → Sentinel, Ribbon → LoadBalancer
- `@SpringCloudApplication` → `@BladeCloudApplication`
- JUnit4 → JUnit5
- 新增 `loadbalancer.client.name` 配置
- blade-starter-ribbon → blade-starter-loadbalancer
- MySQL 驱动默认，其他需手动添加

### 3.1.0 - Token 必配 + Vue3 + 中央仓库
- **token sign-key 必须配置** (32位以上)
- Saber3 Vue3 支持 (Vite, Node.js 16+, `yarn run dev`)
- blade-user 合并入 blade-system: /blade-user/xxx → /blade-system/user/xxx

### 3.1.1 - 中央仓库迁移
- 迁移到 https://center.javablade.com
- Token 认证拉取依赖
- Docker 构建工具改回 fabric: `mvn clean package docker:build docker:push`
- 客户端单点登录: `single-level: all / client`

### 3.2.0 - Token 加密 + Nacos 认证
- 新增 `blade.token.crypto-key` Token 加密
- `CryptoKeyGenerator` 生成密钥
- Nacos 2.3.0 认证注册

### 4.0.0 - SpringBoot 3 + JDK 17 + OpenAPI 3 (里程碑)

**JDK 17 迁移**:
- 配置 IDEA SDK/编译级别为 17
- JVM 参数: `--add-opens java.base/java.lang=ALL-UNNAMED`

**Jakarta EE 迁移** (javax → jakarta):
```
javax.validation → jakarta.validation
javax.servlet → jakarta.servlet
javax.annotation → jakarta.annotation
javax.transaction → jakarta.transaction
javax.persistence → jakarta.persistence
```

**Redis 配置变更**:
```yaml
# 旧
spring.redis.host: xxx
# 新
spring.data.redis.host: xxx
```

**Swagger 2 → OpenAPI 3 完整迁移**:
| 旧注解 | 新注解 |
|--------|--------|
| @Api | @Tag |
| @ApiOperation | @Operation |
| @ApiParam | @Parameter |
| @ApiModel | @Schema |
| @ApiModelProperty | @Schema |
| @ApiIgnore | @Hidden / @Parameter(hidden=true) |
| @ApiResponse | @ApiResponse |

- 包路径: `io.swagger.annotations.*` → `io.swagger.v3.oas.annotations.*`
- Knife4j: `knife4j-openapi2-ui` → `knife4j-openapi3-ui`
- 删除 blade-swagger 服务，网关统一聚合

**MyBatis-Plus 升级**:
- `mybatis-plus-boot-starter` → `mybatis-plus-spring-boot3-starter`
- `dynamic-datasource-spring-boot-starter` → `dynamic-datasource-spring-boot3-starter`
- 添加 `mybatis-spring` 3.0.3

**Flowable 6.4.2 → 7.0.1**: 大版本跳跃，自动升级或手动迁移

**OAuth2**: 自研 JWT OAuth2 组件替代 Spring 官方

**Secure 严格模式** (默认开启):
- `strict-token: true` - 验证完整 Token
- `strict-header: true` - 需要 Blade-Requested-With 头

**ZGC 垃圾回收器**: 推荐生产配置

### 4.1.0 - SM2 国密 + 短信登录
- SM2 国密算法加密密码
- `Sm2KeyGenerator` 生成密钥对
- 短信验证码登录
- Node.js 18 错误: 需 `NODE_OPTIONS="--openssl-legacy-provider"`

### 4.2.0 - TenantUtil + 代码生成增强
- `TenantUtil.use("000000", () -> ...)` 非请求场景指定租户
- 代码快速生成 (无需模型设计)
- 本地文件上传 OSS

### 4.3.0 - XSS 重构 + 菜单权限
- XSS 模块完全重构 (注解模式 + 自定义解析器)
- `@PreAuth("hasMenu('xxx')")` 菜单权限绑定
- 在线角色/部门切换
- 可视化表单设计器 (免费)

### 4.4.0 - Saber3 性能优化
- Saber3 分层加载: 打包速度 +100%，系统加载速度 +200%
- 字段脱敏工具类
- 全局 `@PreAuth("hasMenu('xxx')")` 垂直权限控制
- SSO 跨域优化

### 4.6.0 - LiteRule + 注解简化
- `blade-starter-literule` 轻量规则引擎
- `@PreAuth` 简化 (无需 EL 表达式)
- 新增 `@IsAdmin`, `@IsAdministrator`
- 环境变量配置密钥

### 4.8.0 - 超级令牌 + 签名认证
- 超级令牌认证 (服务间可信调用)
- 签名认证防重放攻击
- 请求方法全局规则配置

### 4.9.0 - JacksonViews + AI Skills + 认证日志
- **JacksonViews 视图过滤系统**: `@BladeView` 注解实现按角色/场景动态裁剪 JSON 响应字段，替代 N 个场景化 VO (详见 jackson-views.md)
- **Secure 注解参考 & 配置参考**: 新增 `@PermitAll` / `@PreAuth` / `@IsAdmin` / `@IsAdministrator` 完整注解文档和全量配置参数文档 (详见 secure-reference.md)
- **MyBatis-Plus 增强插件文档**: 新增拦截器体系、SQL 日志、自定义 SQL 注入、查询构造器等详细文档 (详见 mybatis-plus.md)
- **BladeX 全栈开发 AI Skills 集合**: 为 Claude Code 提供框架专属开发辅助能力
- **用户登录锁定日志模块**: 记录用户登录锁定信息
- **用户登录认证日志模块**: 记录用户登录认证信息
- **超级令牌调用日志模块**: 记录超级令牌调用信息
- **数据权限 / 接口权限列表模式与树形模式切换**
- **顶部菜单首页配置功能**: 指定首页后，首页菜单按配置运行，不再全量展示
- 数据库有多处变动，需执行升级 SQL 脚本

## Git 远程分支合并

**前提**: 未修改包名和结构，业务代码在 bladex-biz 中

```bash
# 添加官方远程
git remote add upstream https://git.bladex.vip/blade/BladeX-Tool.git
# 创建 dev 分支
git checkout -b dev
# 拉取官方更新
git pull upstream dev
# 推送到自己仓库
git push origin dev
```

## Git 仓库地址更换
```bash
git remote set-url origin [新仓库地址.git]
```
