# BladeX 快速开始

## 环境要求

| 组件 | 版本 |
|------|------|
| JDK | 17 |
| Maven | 3.8+ |
| MySQL | 5.7+ |
| Redis | 6.0+ |
| Nacos | 2.3.0+ |
| Sentinel | 1.8.0+ |
| Node.js | 16.x |
| NPM | 6.x |

**必装 IDE 插件**: Lombok Plugin, MybatisX Plugin
**推荐 IDE**: 后端 IntelliJ IDEA，前端 WebStorm 或 VSCode

## Docker 快速搭建基础环境

```bash
# PostgreSQL 16.2
docker run --name postgres -d -p 5432:5432 \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=你的密码 \
  -v /docker/data/postgres/data:/var/lib/postgresql/data postgres:16.2

# MySQL 5.7 (大小写不敏感)
docker run --name mysql -d -p 3306:3306 \
  -v /docker/data/mysql/data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=你的密码 --privileged=true \
  mysql:5.7.44 --lower_case_table_names=1

# MySQL 8.3.0
docker run --name mysql8 -d -p 3306:3306 \
  -v /docker/data/mysql8/data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=你的密码 --privileged=true \
  mysql:8.3.0 --lower_case_table_names=1

# Redis 7.2.4
docker run --name redis -d -p 6379:6379 redis:7.2.4
```

## Nacos 安装

```bash
# Docker 安装 (无认证)
docker run --name nacos-standalone -d -p 8080:8080 -p 8848:8848 -p 9848:9848 \
  -e NACOS_AUTH_ENABLE=false -e MODE=standalone nacos/nacos-server:v3.1.0

# Docker 安装 (开启认证)
docker run --name nacos-standalone -d -p 8080:8080 -p 8848:8848 -p 9848:9848 \
  -e NACOS_AUTH_ENABLE=true -e MODE=standalone \
  -e NACOS_AUTH_TOKEN=BladeKey012345678901234567890123456789012345678901234567890123456789 \
  -e NACOS_AUTH_IDENTITY_KEY=nacos -e NACOS_AUTH_IDENTITY_VALUE=nacos \
  -e NACOS_AUTH_CACHE_ENABLE=true nacos/nacos-server:v3.1.0
```

**访问**: http://localhost:8080/ (Nacos 3.x 控制台端口从 8848 改为 8080)
**账号**: nacos / nacos

**Nacos 端口说明**:
| 端口 | 偏移量 | 说明 |
|------|--------|------|
| 8848 | - | 主端口 |
| 9848 | +1000 | 客户端 gRPC |
| 9849 | +1001 | 服务间 gRPC |

**重要**: 不要使用文档默认的 NACOS_AUTH_TOKEN，需创建唯一 token 防止攻击。

## Sentinel 安装

```bash
docker pull bladex/sentinel-dashboard
docker run --name sentinel -d -p 8858:8858 bladex/sentinel-dashboard
```
**访问**: http://localhost:8858 , 账号: sentinel / sentinel

## 配置资源令牌 (Maven Token)

1. 登录中央仓库: https://center.javablade.com/
2. 设置 → 创建令牌 (勾选所有令牌范围)
3. **令牌仅显示一次，务必保存**
4. 成功拉取依赖后立即删除令牌

**Maven settings.xml 配置**:
```xml
<servers>
  <server>
    <id>bladex</id>
    <configuration>
      <httpHeaders>
        <property>
          <name>Authorization</name>
          <value>token c6e5fc556xxxxxxxxxxx7482e9ba05bf1f</value>
        </property>
      </httpHeaders>
    </configuration>
  </server>
</servers>

<mirrors>
    <mirror>
        <id>aliyun-repos</id>
        <name>Aliyun Public Repository</name>
        <url>https://maven.aliyun.com/repository/public</url>
        <mirrorOf>*,!bladex</mirrorOf>
    </mirror>
</mirrors>
```

**构建命令**: `mvn clean package -U -Pdev -DskipTests`

**前端 Saber3 Token 配置**:
- 在 `.npmrc` 文件中配置同一 token
- 删除 `node_modules` 后执行 `yarn install`
- 启动: `yarn run dev`

## 导入 Nacos 配置 (Cloud 版本)

1. 新建配置，Data ID 后缀必须是 `yaml` (不是 yml)
2. **blade.yaml 必须配置**:
   - `blade.token.sign-key` (必须! 否则 AuthApplication 无法启动)
   - `blade.token.encryption-key` (Token 加密)
   - 使用 Generator 生成密钥值
3. 配置 `blade-dev.yaml` (数据库、Redis 地址)
4. 配置 `blade-flow-dev.yaml` (工作流数据库)

**Windows 服务器注意**: 删除 Nacos 配置中的中文注释或进行 Unicode 转码，否则乱码导致启动失败。

## Boot 版本配置

在 `application.yml` 中配置:
- `blade.token.sign-key` (必须)
- `blade.token.encryption-key`
- SM2 加密密钥 (通过 Generator 获取)

在 `application-dev.yml` 中配置:
- Redis 连接
- 数据库连接

## 数据库导入

1. 创建数据库 `bladex` 或 `bladex_boot`
2. SQL 脚本位于项目 `doc -> sql` 目录
3. 前端用 Saber: 使用含 "saber" 的 SQL 文件
4. **工作流数据库**: Cloud 版需单独建 `bladex_flow` 数据库; Boot 版导入同一数据库

**其他数据库驱动** (默认 MySQL):
```xml
<!-- Oracle -->
<dependency><groupId>com.oracle</groupId><artifactId>ojdbc7</artifactId></dependency>
<!-- PostgreSQL -->
<dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency>
<!-- SQL Server -->
<dependency><groupId>com.microsoft.sqlserver</groupId><artifactId>mssql-jdbc</artifactId></dependency>
<!-- DaMeng -->
<dependency><groupId>com.dameng</groupId><artifactId>DmJdbcDriver18</artifactId></dependency>
```

## 工程运行

### 启动顺序
1. 启动 Redis, MySQL, Nacos, Sentinel 基础服务
2. **Cloud 版**: 先启动所有项目 (除 blade-gateway)，最后启动 blade-gateway
3. **Boot 版**: 直接启动 Application

### Nacos 认证配置 (如已开启)
在 `LauncherServiceImpl` 类中添加 NACOS_USERNAME 和 NACOS_PASSWORD 配置

### JDK 17 模块系统错误处理
错误: `module java.base does not "opens java.lang" to unnamed module`

添加 JVM 参数:
```bash
java --add-opens java.base/java.lang=ALL-UNNAMED \
     --add-opens java.base/java.lang.reflect=ALL-UNNAMED \
     --add-opens java.base/java.io=ALL-UNNAMED \
     --add-opens java.base/java.util=ALL-UNNAMED \
     -jar your-application.jar
```

## API 测试

### Cloud 版
1. 打开 http://localhost/doc.html (Knife4j)
2. 启用所有增强配置
3. 配置全局参数:
   - `Authorization`: `Basic c2FiZXI6c2FiZXJfc2VjcmV0` (saber 客户端 Base64)
   - `Tenant-Id`: `000000`

### 获取 Token
1. 找到 Token 接口
2. 密码使用 **SM2 国密加密** (原始密码 admin 需先 SM2 加密)
3. 通过 Sm2KeyGenerator 获取加密密文
4. 调用成功返回 access_token

### 认证调用
1. 拼接 `token_type` + 空格 + `access_token`
2. 配置到 `Blade-Auth` 全局参数
3. 严格模式需额外添加: `Blade-Requested-With: BladeHttpRequest`

**注意**: Knife4j 刷新页面后增强配置丢失，需手动关闭标签重新打开。
