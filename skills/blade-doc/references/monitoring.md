# Prometheus 监控体系

## Prometheus 部署

### 概述
开源监控系统，多维数据模型 + PromQL 查询 + HTTP Pull 模式采集。

### 二进制部署
```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.24.1/prometheus-2.24.1.linux-amd64.tar.gz
tar xf prometheus-2.24.1.linux-amd64.tar.gz -C /data/
mv /data/prometheus-2.24.1.linux-amd64 /data/prometheus
```

**systemd 服务** (`/usr/lib/systemd/system/prometheus.service`):
```ini
[Unit]
Description=https://prometheus.io
[Service]
Restart=on-failure
ExecStart=/data/prometheus/prometheus --config.file=/data/prometheus/prometheus.yml --web.enable-lifecycle --storage.tsdb.path=/data/prometheus/data
[Install]
WantedBy=multi-user.target
```

### Docker 部署
```bash
docker run --name prometheus -d -p 9090:9090 \
  -v /data/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v /data/prometheus/rules:/etc/prometheus/rules \
  prom/prometheus --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle
```

**访问**: http://server_ip:9090

### 基础配置 (prometheus.yml)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['server_ip:9090']
```

**热更新**: `curl -XPOST server_ip:9090/-/reload`

## NodeExporter (Linux 监控)

### 部署
```bash
# 二进制
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz

# Docker
docker run --name node-exporter -d -p 9190:9100 prom/node-exporter
```

### 集成 Prometheus
```yaml
- job_name: linux
  static_configs:
    - targets: ['server_ip:9190']
      labels:
        instance: localhost
```

## MysqldExporter (MySQL 监控)

### MySQL 授权
```sql
CREATE USER 'exporter'@'server_ip' IDENTIFIED BY '1qaz@WSX';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'server_ip';
FLUSH PRIVILEGES;
```

### 部署
```bash
# Docker
docker run -d --name mysqld-exporter -p 9104:9104 \
  -e DATA_SOURCE_NAME="exporter:1qaz@WSX@(server_ip:3306)/" \
  prom/mysqld-exporter
```

### 集成 Prometheus
```yaml
- job_name: 'mysql'
  static_configs:
    - targets: ['server_ip:9104']
```

## Cadvisor (Docker 容器监控)

```bash
docker run --name=cadvisor \
  --volume=/:/rootfs:ro --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=18080:8080 --detach=true google/cadvisor
```

**UI**: http://server_ip:18080

## Grafana 可视化

### 部署
```bash
# Docker
docker run --name grafana --restart=always -d -p 3000:3000 \
  -e "GF_SECURITY_ADMIN_PASSWORD=1qaz@WSX" \
  -v "/data/grafana/:/var/lib/grafana" grafana/grafana
```

**访问**: http://server_ip:3000 , 默认 admin/admin

### 配置数据源
1. Home → Data Sources → Add → Prometheus
2. URL: http://server_ip:9090
3. **Docker 注意**: 不能用 localhost，需用服务器 IP 或 Docker 子网 IP

### 导入仪表盘
1. 访问 https://grafana.com/grafana/dashboards 搜索模板
2. Grafana → Import → 粘贴 ID/URL → 选择 Prometheus → Import

### BladeX 专用仪表盘
- `bladex-jvm.json` - JVM 监控
- `bladex-docker.json` - Docker 监控
- `bladex-linux.json` - Linux 监控
- `bladex-mysql.json` - MySQL 监控
- `bladex-nacos.json` - Nacos 监控

## Alertmanager 告警

### 部署
```bash
# Docker
docker run --name alertmanager -d -p 9093:9093 \
  -v /data/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
  prom/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
```

### 邮件告警
```yaml
global:
  smtp_smarthost: 'smtp.163.com:25'
  smtp_from: 'your@163.com'
  smtp_auth_username: 'your@163.com'
  smtp_auth_password: 'xxxxx'  # 授权码非密码
route:
  group_by: ["alertname"]
  receiver: "email"
receivers:
  - name: 'email'
    email_configs:
      - to: 'recipient@email.com'
        send_resolved: true
```

### 钉钉告警
```bash
# 安装 webhook 桥接
docker run --name webhook-dingtalk -d -p 8060:8060 \
  timonwong/prometheus-webhook-dingtalk \
  --ding.profile="webhook_robot=https://oapi.dingtalk.com/robot/send?access_token=xxxxx"
```

```yaml
receivers:
  - name: 'dingtalk'
    webhook_configs:
      - url: http://server_ip:8060/dingtalk/webhook_robot/send
        send_resolved: true
```

### 企业微信告警
```yaml
receivers:
  - name: "wechat"
    wechat_configs:
      - send_resolved: true
        agent_id: "1000002"
        api_secret: "your_secret"
        corp_id: "your_corp_id"
        to_user: "@all"
```

### 常用告警规则
```yaml
groups:
  - name: alert_rules
    rules:
      - alert: CpuUsageAlertWarning
        expr: sum(avg(irate(node_cpu_seconds_total{mode!='idle'}[5m])) without (cpu)) by (instance) > 0.60
        for: 2m
        labels: { level: warning }
        annotations:
          summary: "{{ $labels.instance }} CPU 使用率过高"

      - alert: MemUsageAlertWarning
        expr: avg by(instance) ((1 - (node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) / node_memory_MemTotal_bytes) * 100) > 70
        for: 2m
        labels: { level: warning }

      - alert: DiskUsageAlertWarning
        expr: (1 - node_filesystem_free_bytes{fstype!="rootfs"} / node_filesystem_size_bytes) * 100 > 80
        for: 2m
        labels: { level: warning }
```

## BladeX 微服务对接

### 启用指标
```xml
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-starter-metrics</artifactId>
</dependency>
```
验证: http://service_ip:port/actuator/prometheus

### Consul API 服务发现
**问题**: Prometheus 原生支持 Consul 但不支持 Nacos
**方案**: blade-admin 实现 Consul 兼容 API

```xml
<!-- blade-admin 添加 -->
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-starter-prometheus</artifactId>
</dependency>
```

### Prometheus 配置 (BladeX 服务发现)
```yaml
- job_name: "bladex"
  metrics_path: "/actuator/prometheus"
  scrape_interval: 5s
  consul_sd_configs:
    - server: 'blade-admin-ip:7002'
      services: []
  relabel_configs:
    - source_labels: [__meta_consul_service]
      regex: "blade*"
      action: drop
    - source_labels: [__meta_consul_service]
      target_label: application
    - source_labels: [__meta_consul_service_address]
      target_label: instance
    - source_labels: [__meta_consul_tags]
      target_label: job
```

### 验证
1. Prometheus targets 页面显示 BladeX 服务
2. Grafana 导入 bladex-jvm.json
3. 下拉菜单切换不同服务查看 JVM 指标
