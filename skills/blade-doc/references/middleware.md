# ELK 分布式日志追踪 + Seata 分布式事务

## ELK 分布式日志追踪

### ELK 组件
- **Elasticsearch**: 分布式搜索分析引擎，近实时存储/搜索/分析
- **Logstash**: 数据采集引擎，过滤/分析/标准化数据
- **Kibana**: 数据分析可视化平台
- **Filebeat**: 轻量日志采集器

### 一键部署
**依赖**: Docker + Docker-Compose

**常见问题**:
| 问题 | 解决 |
|------|------|
| `$'\r': command not found` | 修改编码，赋执行权限 |
| `vm.max_map_count too low` | 编辑 `/etc/sysctl.conf` 添加 `vm.max_map_count=262144`，执行 `sysctl -p` |

**部署步骤**:
1. 复制 BladeX `script` 目录下 ELK 脚本到服务器
2. 赋权: `chmod +x deploy.sh undeploy.sh`
3. 执行: `./deploy.sh`
4. 验证:
   - ES 集群: http://server_ip:9100
   - Kibana: http://server_ip:5601

### 微服务对接 ELK

**代码配置** (blade-common / LauncherServiceImpl):
- 取消 ELK 配置注释
- 设置 ELK 地址为 server_ip:9000 (无 http 前缀)

**动态配置** (无需重新编译):
```bash
# 命令行
java -jar app.jar --blade.log.elk.destination=192.168.0.30:9000

# docker-compose
command:
  - --blade.log.elk.destination=192.168.0.30:9000
```

### 分布式链路追踪
1. Kibana 查看日志
2. 搜索关键词定位日志
3. 找到 `traceId`
4. 用 traceId 搜索即可看到完整调用链日志

## Seata 分布式事务

### 概述
Seata 提供 AT、TCC、SAGA、XA 四种事务模式。

### AT 模式 (自动事务 - 推荐)

**前提**: 关系型数据库 + JDBC + 本地 ACID 事务支持

**两阶段提交机制**:
- **阶段1**: 业务数据 + 回滚日志在同一本地事务提交，释放本地锁和连接
- **阶段2 提交**: 异步完成，快速
- **阶段2 回滚**: 用阶段1回滚日志反向补偿

**写隔离**: 阶段1提交前必须获取全局锁，防止脏写
**读隔离**: 默认全局读未提交，需 Read Committed 使用 SELECT FOR UPDATE

**UNDO_LOG 表**:
```sql
CREATE TABLE `undo_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `branch_id` bigint(20) NOT NULL,
  `xid` varchar(100) NOT NULL,
  `context` varchar(128) NOT NULL,
  `rollback_info` longblob NOT NULL,
  `log_status` int(11) NOT NULL,
  `log_created` datetime NOT NULL,
  `log_modified` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_undo_log` (`xid`,`branch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

### TCC 模式 (手动分支事务)
- 自定义 Phase 1 准备、Phase 2 提交、Phase 2 回滚行为
- 不依赖底层数据库事务支持

### SAGA 模式 (长事务方案)
- 参与者各自提交本地事务
- 失败时补偿已成功的参与者
- 适用: 长业务流程、多步骤、包含第三方/遗留系统
- 优势: 高性能 (无锁)、高吞吐 (异步)
- 劣势: 无隔离保证

### 编译包启动

**File 模式** (最简):
```bash
./seata-server.sh -h 127.0.0.1 -p 8091 -m file -n 1
```

**DB 模式**:
1. 编辑 `registry.conf`: config/registry 设为 file
2. 编辑 `file.conf`: mode 设为 db，配置数据库连接
3. 创建 `seata` 数据库并执行脚本
4. 启动: `./seata-server.sh -h 127.0.0.1 -p 8091 -m db -n 1`

### Docker 启动

```bash
# 简单启动
docker run --name seata-server -d -p 8091:8091 seataio/seata-server:1.4.1

# 挂载配置启动 (推荐)
docker run --name seata-server -d -p 8091:8091 \
  -e SEATA_CONFIG_NAME=file:/root/seata-config/registry \
  -v /your/config/path:/root/seata-config \
  seataio/seata-server:1.4.1
```

### 微服务对接

1. 添加依赖:
```xml
<dependency>
    <groupId>io.seata</groupId>
    <artifactId>seata-spring-boot-starter</artifactId>
</dependency>
```

2. 开启 Seata 基础配置 (LauncherServiceImpl)
3. 使用注解:
```java
@GlobalTransactional  // Seata 全局事务
@Transactional        // Spring 本地事务
public void createOrder(Order order) { ... }
```

4. 创建业务数据库并建表
5. 启动服务验证分布式事务

### 测试验证
1. 正常场景: 数据持久化成功
2. 异常场景: 大数值触发失败，自动回滚
3. 检查控制台日志和数据库验证回滚成功

**生产建议**:
- File 模式足够使用，集群可用 file+db 模式
- Nacos 模式当前复杂且有问题，不推荐生产使用
- 跟随 BladeX 主分支版本保持兼容
