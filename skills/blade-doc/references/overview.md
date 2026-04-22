# BladeX 产品概览

## 产品简介
BladeX 是基于 SpringBoot 3 + SpringCloud 2025 + MyBatis 的企业级微服务框架，生产稳定运行近 5 年。从 Boot 1 演进到 Boot 3，部署架构从 FatJar → Docker → K8S + Jenkins。

**核心技术栈**: Java 17, SpringBoot 3.5, SpringCloud 2025, MyBatis-Plus

**前端框架**:
- Saber: Vue2 + Element UI
- Saber3: Vue3 + Element-Plus (基于 Vite)

**后端版本**:
- BladeX: SpringCloud 微服务版
- BladeX-Boot: SpringBoot 单体版
- 两个版本 API 完全兼容

**关键组件**:
- BladeX-Tool: 后端核心封装框架，推送至 Maven 私有仓库
- 注册/配置中心: Nacos
- 流控保护: Sentinel (流量控制、熔断降级、系统负载保护)
- 网关: 自定义 Nacos 动态网关
- 对象存储: MinIO 多租户 OSS
- 认证: 自研 OAuth2 (JWT + SM2 国密)

## 系统架构

架构层次:
1. **核心框架**: SpringBoot3, SpringCloud 2025, MyBatis
2. **认证层**: OAuth2 统一 Token 签发与鉴权
3. **网关层**: Gateway 统一转发，生产环境 Traefik 代理
4. **服务注册**: 微服务统一注册到 Nacos
5. **远程通信**: Feign 远程调用 + Ribbon 负载均衡 + Hystrix/Sentinel 熔断
6. **限流**: Sentinel 流量限制
7. **分布式事务**: Seata 集成
8. **日志监控**: 集成日志采集与监控服务
9. **部署**: 支持 FatJar、Docker、K8s、阿里云等多种部署方式

## 33 项核心功能

| # | 功能 | 说明 |
|---|------|------|
| 1 | 前后端分离 | Sword(React) + Saber(Vue) 两套前端 |
| 2 | 分布式/单体后端 | SpringCloud 分布式 + SpringBoot 单体 |
| 3 | API 完全兼容 | 四种架构组合 API 完全兼容 |
| 4 | 代码生成 | 自定义模板前后端代码生成 |
| 5 | 组件化/插件化 | 深度自定义 starter 即插即用 |
| 6 | Nacos | 统一服务注册和配置管理 |
| 7 | Sentinel | 多维度流控、熔断、系统负载保护 |
| 8 | Dubbo | 远程 RPC 调用支持 |
| 9 | 多租户 | 完整 SaaS 多租户架构 |
| 10 | OAuth2 | 多终端接入和授权 |
| 11 | 工作流 | 深度定制 Flowable 分布式工作流 |
| 12 | 独立流程设计器 | 全自主独立流程设计器 |
| 13 | 动态网关 | Nacos 动态网关鉴权 |
| 14 | 动态聚合文档 | Swagger SpringCloud 聚合文档 |
| 15 | 分布式文件服务 | MinIO 集成 |
| 16 | 多租户对象存储 | 每个租户配置私有 OSS |
| 17 | 权限管理 | 角色权限精确到按钮级别 |
| 18 | 动态数据权限 | 注解+可视化配置，无需重启 |
| 19 | 动态接口权限 | 注解+可视化配置，无需重启 |
| 20 | 多租户顶部菜单 | 每个租户独立顶部菜单 |
| 21 | 主流数据库兼容 | MySQL、PostgreSQL、Oracle、SqlServer、DaMeng、YashanDB |
| 22 | 全能代码生成器 | 自定义模型、模板、业务建模、在线配置 |
| 23 | Seata 分布式事务 | 无代码侵入式分布式事务 |
| 24 | Turbine 集群监控 | 实时查看 Hystrix 状态 |
| 25 | Zipkin 链路追踪 | 快速定位每个请求的调用链 |
| 26 | ELK 分布式日志 | 7.x ELK 分布式日志追踪 |
| 27 | 钉钉监控报警 | 微服务上下线钉钉告警 |
| 28 | 分布式任务调度 | XXL-JOB / PowerJob 集成 |
| 29 | 消息队列 | Kafka、RabbitMQ、SpringCloud Stream |
| 30 | 分布式锁 | 基于 Redisson 的分布式锁插件 |
| 31 | API 报文加密 | AES/DES/RSA 全链路加密 |
| 32 | SkyWalking | APM 应用性能监控 |
| 33 | 持续更新 | 持续迭代开发中 |

## 授权版本对比

| 项目 | 专业版 | 企业版 |
|------|--------|--------|
| Archer: 全能代码生成系统 | - | ✔ |
| Sword: React 前端 | - | ✔ |
| BladeX: Cloud 后端 | - | ✔ |
| BladeX-Biz: 团队协作业务架构 | - | ✔ |
| Saber: Vue 前端 | ✔ | ✔ |
| BladeX-Boot: Boot 后端 | ✔ | ✔ |
| BladeX-Tool: 核心封装 | ✔ | ✔ |

**授权范围**:
- 专业版: 仅限个人学习和个人接单，不可用于公司/团队
- 企业版: 可用于企业名义下的任何项目
- 如需交付源码给客户，客户须另外购买企业版授权

## 插件规范

**命名规则**:
- BladeX 业务项目: `blade-xx` 前缀，包名 `org.springblade.plugin.xx`
- BladeX 内部功能: 放置在 `blade-plugin` 目录
- BladeX-Tool 项目: `blade-plugin-xx` 格式
- 核心封装: 包名 `org.springblade.core.plugin.xx`
- 前端 Saber 页面: `/src/views/plugin` 目录
- 前端 API: `/src/api/plugin` 目录
- 数据库表: `blade_xx` 格式

**插件要求**:
- 必须易于插拔，不与 BladeX 耦合
- Starter 类封装使用 `blade.plugin.xx.enabled=true` 启用
- 常量/工具类放在 `blade-xx` 和 `blade-xx-api` 包内，不放 `blade-common`
