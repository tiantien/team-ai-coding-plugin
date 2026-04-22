# FAQ 常见问题 + 版本控制 + 学习资料

## 高频问题速查

### 启动与配置

**Q: AuthApplication 启动报错 sign-key 未配置**
A: 必须在 blade.yaml (Nacos) 或 application.yml (Boot) 配置 `blade.token.sign-key`，32位以上。参考章节 1.3.2。

**Q: Nacos 配置失败，项目无法启动**
A: 检查 Nacos 配置 Data ID 后缀必须是 `yaml` (不是 yml)。确认所有必需配置已填写。详见: https://sns.bladex.vip/q-41.html

**Q: Windows 服务器 Nacos 配置乱码导致启动失败**
A: 删除中文注释或进行 Unicode 转码。

**Q: JDK 17 反射报错 "module java.base does not opens..."**
A: 添加 JVM 参数:
```bash
--add-opens java.base/java.lang=ALL-UNNAMED
--add-opens java.base/java.lang.reflect=ALL-UNNAMED
--add-opens java.base/java.io=ALL-UNNAMED
--add-opens java.base/java.util=ALL-UNNAMED
```

**Q: Nacos 地址不是默认 localhost:8848**
A: 在配置中修改 Nacos 地址 (地址不能包含 http://)

**Q: Nacos 3.x 控制台访问不了**
A: Nacos 3.x 控制台端口从 8848 改为 8080。

### 认证与鉴权

**Q: 调用接口返回 "缺失令牌,鉴权失败"**
A: 需先调用 Token 接口获取令牌，然后在请求头添加 `Blade-Auth: bearer {access_token}`

**Q: 密码加密方式是什么?**
A: 4.1.0+ 使用 SM2 国密算法。密码需前端 SM2 加密后传输，使用 `Sm2KeyGenerator` 生成密钥对。旧版使用 MD5 前端加密 + 后端二次加密。

**Q: 严格模式下接口被拦截**
A: 4.0.0+ 默认开启严格模式，需额外添加请求头: `Blade-Requested-With: BladeHttpRequest`

**Q: Token 过期时间怎么配置?**
A: 修改 `blade_client` 表的 `access_token_validity` (秒) 和 `refresh_token_validity` 字段。

**Q: 如何实现单点登录控制?**
A: 配置 `blade.token.single-level`:
- `all`: 全平台单用户
- `client`: 仅客户端内单用户

### 数据库

**Q: 如何切换 Oracle/PostgreSQL/SqlServer/DaMeng?**
A: 默认只含 MySQL 驱动，需在 pom.xml 手动添加对应驱动依赖，修改数据库连接配置。

**Q: 主键为什么用 BigInt 而非自增?**
A: 使用雪花算法 (Snowflake) 生成分布式唯一 ID，实体用 `@TableId(type = IdType.ASSIGN_ID)`。

**Q: 逻辑删除怎么用?**
A: 表添加 `is_deleted` 字段，实体添加 `@TableLogic` 注解。MyBatis-Plus 自动处理 (查询加 WHERE is_deleted=0，删除改 UPDATE is_deleted=1)。

### 前端

**Q: Knife4j 增强配置刷新后丢失**
A: 已知问题，需手动关闭标签页重新打开文档页面。

**Q: Saber3 启动命令是什么?**
A: `yarn run dev` (不再用 `run serve`)

**Q: Node.js 18 报 error:0308010C**
A: 设置环境变量: `NODE_OPTIONS="--openssl-legacy-provider"`

**Q: 前端 .npmrc Token 怎么配置?**
A: 复用后端 Maven Token，注意不要移除 `//` 前缀。

### 多租户

**Q: 超级管理员为什么不受数据权限限制?**
A: 设计如此。超级管理员完全绕过数据权限，仅普通用户生效。

**Q: 如何排除某些表的租户过滤?**
A: 配置 `blade.tenant.exclude-tables` 列表。

**Q: 非 HTTP 场景 (定时任务) 如何指定租户?**
A: 使用 `TenantUtil.use("tenantId", () -> { ... })`

### 工作流

**Q: 工作流需要单独建库吗?**
A: Cloud 版需要 (`bladex_flow`)，Boot 版共用同一数据库。

**Q: 如何排除工作流模块?**
A: Cloud: 删除工作流项目 + 移除 blade-flow-api 依赖。Boot: 删除 flow 包 + 移除 blade-starter-flowable 依赖。

### 部署

**Q: Docker push 报 503 错误**
A: 通常由 VPN 导致，关闭后重试。

**Q: Docker 服务间通信用 localhost 不通**
A: Docker 容器间不能用 localhost，需用服务器 IP 或 Docker 子网 IP。

**Q: 生产环境 Redis 和 MySQL 安全**
A: 必须设密码，禁止暴露外网端口，否则会被挖矿攻击。

### 升级

**Q: 升级后出现各种异常**
A: 确认: 1) 执行了数据库升级脚本 2) 清除了 Redis (flushdb) 3) 检查版本说明中的破坏性变更

**Q: 4.0.0 升级最大变化?**
A: JDK 8→17, javax→jakarta, Swagger2→OpenAPI3, spring.redis→spring.data.redis, 自研 OAuth2

## 版本控制

### Git 远程分支合并 (同步官方更新)
```bash
git remote add upstream https://git.bladex.vip/blade/BladeX-Tool.git
git checkout -b dev
git pull upstream dev
git push origin dev
```
**前提**: 未修改包名/结构，业务代码在 bladex-biz 中。

### Git 仓库地址更换
```bash
git remote set-url origin [新仓库地址.git]
```

## 学习资料

1. **跟上 Java 8**: https://github.com/biezhi/learn-java8
2. **Java 学习+面试指南**: https://github.com/Snailclimb/JavaGuide
3. **互联网 Java 工程师进阶知识**: https://github.com/doocs/advanced-java

## 社区与支持

- **技术社区**: https://sns.bladex.vip/
- **官网**: https://bladex.vip
- **代码仓库**: https://git.bladex.vip
- **Q&A 时间**: 工作日 9:00-17:00，周末节假日休息
- **提问流程**: 先自查 → 搜索社区 → 发帖 → 发链接到商业群
