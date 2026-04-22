# 生产部署

## Windows 部署

**不推荐但某些项目需要**

### 工具
AlwaysUp: https://www.coretechnologies.com/products/AlwaysUp/ (管理 Windows 服务，自动重启，邮件通知)

### 步骤
1. 安装 Java、MySQL、Redis、Nacos
2. `mvn clean package` 获取 jar 包
3. 编写启动脚本 (参考 `/script/service.cmd`)
4. 添加到 AlwaysUp，按顺序启动

## Linux Jar 部署

**适合学习，不推荐生产** (难以扩容和持续集成)

### 服务管理脚本
```bash
#!/bin/bash
APP_NAME=app.jar

is_exist(){
    pid=`ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}'`
    if [ -z "${pid}" ]; then return 1; else return 0; fi
}

start(){
    is_exist
    if [ $? -eq "0" ]; then
        echo "${APP_NAME} is already running. pid=${pid}"
    else
        nohup java -jar $APP_NAME > /dev/null 2>&1 &
    fi
}

stop(){
    is_exist
    if [ $? -eq "0" ]; then kill -9 $pid
    else echo "${APP_NAME} is not running"; fi
}

restart(){ stop; start; }

status(){
    is_exist
    if [ $? -eq "0" ]; then echo "${APP_NAME} is running. Pid is ${pid}"
    else echo "${APP_NAME} is NOT running."; fi
}

case "$1" in
    "start") start ;; "stop") stop ;; "status") status ;; "restart") restart ;;
    *) echo "Usage: sh service.sh [start|stop|restart|status]"; exit 1 ;;
esac
```

## 宝塔面板部署

### 安装
```bash
yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh
```
**要求**: 纯净 CentOS 系统

### 环境配置
1. 软件商店安装 Tomcat8 (提供 Java 环境)
2. 安装 Redis (务必修改默认端口和密码!)
3. 创建 MySQL 数据库导入脚本

**安全警告**: Redis 和 MySQL 必须设密码，禁止暴露外网，否则服务器很快被挖矿。

### 后端部署 (BladeX-Boot)
1. 修改 `application-test.yml` (Redis/MySQL 配置)
2. `mvn clean package -Dmaven.test.skip=true`
3. 上传 jar 到网站根目录 `api` 文件夹
4. 修改启动脚本: `--server.port=88 --spring.profiles.active=test`
5. `chmod 744 service.sh && ./service.sh start`

### 前端部署 (Saber)
1. `yarn run build` 打包
2. 上传 dist 到网站根目录
3. 配置伪静态 (Nginx):
```nginx
location ^~ /api {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    rewrite ^/api/(.*)$ /$1 break;
    proxy_pass http://127.0.0.1:88;
}
```

### HTTPS 配置
- 使用 Let's Encrypt 免费证书
- 宝塔面板 SSL → Let's Encrypt → 选择域名 → 申请

## Docker 部署

### Docker 安装 (CentOS 7)
```bash
# 安装依赖
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# 添加阿里云源
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 安装
sudo yum makecache fast && sudo yum install docker-ce
# 启动
sudo systemctl start docker
```

### Docker-Compose 安装
```bash
sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.23.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 镜像加速器
注册阿里云 → 容器镜像服务 → 镜像加速器 → 按说明配置

### Harbor 私有仓库

```bash
mkdir /data/ && cd /data/
wget https://storage.googleapis.com/harbor-releases/release-1.9.0/harbor-offline-installer-v1.9.4.tgz
tar xvzf harbor-offline-installer-v1.9.4.tgz && cd harbor
vi harbor.yml  # 修改 hostname 为服务器 IP
./install.sh
```
**访问**: http://server_ip , 账号: admin / Harbor12345

**HTTPS 问题**:
```json
// /etc/docker/daemon.json
{
  "registry-mirrors": ["https://xxx.mirror.aliyuncs.com"],
  "insecure-registries": ["192.168.186.129"]
}
```

### Docker 远程 API (端口 2375)
编辑 `/lib/systemd/system/docker.service`:
```
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock
```

### Dockerfile 示例
```dockerfile
FROM bladex/alpine-java:openjdk17_cn_slim
MAINTAINER bladejava@qq.com
RUN mkdir -p /blade/gateway
WORKDIR /blade/gateway
EXPOSE 80
ADD ./target/blade-gateway.jar ./app.jar
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
CMD ["--spring.profiles.active=test"]
```

### Maven Docker 构建
```bash
# 构建并推送
mvn clean package docker:build docker:push
# 仅本地构建 (不需要 Harbor)
mvn clean package docker:build
```

### Docker-Compose 部署

**目录**: `/script/docker/app/`

```bash
chmod 744 deploy.sh

# 1. 开放端口
./deploy.sh port

# 2. 挂载配置文件
./deploy.sh mount

# 3. 启动基础设施 (Nacos, Redis, Sentinel, Seata, Nginx)
./deploy.sh base

# 4. 启动业务模块
./deploy.sh modules

# 5. 启动监控 (可选)
./deploy.sh monitor

# 6. 启动 Prometheus (可选)
./deploy.sh prometheus

# 7. 启动告警 (可选)
./deploy.sh alertmanager
```

### Nginx 反向代理配置

**API 网关**:
```nginx
upstream blade_gateway {
    server blade-gateway1:80;
    server blade-gateway2:80;
}
server {
    listen 88;
    location / { proxy_pass http://blade_gateway; }
}
```

**前端**:
```nginx
server {
    listen 8000;
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }
    location /api {
        proxy_pass http://blade_gateway;
    }
}
```

### Docker 部署端口映射
| 服务 | 端口 |
|------|------|
| Nacos | 8848 |
| Redis | 3379 (映射 6379) |
| Gateway (Nginx) | 88 |
| Swagger | 18000 |
| Admin | 7002 |
| 前端 | 8000 |
| Prometheus | 9090 |
| Grafana | 3000 |
| Alertmanager | 9093 |

### 前端 Docker 部署
1. `yarn run build` (或用 build.sh 自动上传)
2. 上传 dist 内容到 `/docker/nginx/web/html`
3. 访问: http://server_ip:8000
