# blade-doc

BladeX 企业级微服务框架的离线知识库 Skill，将 338 篇官方文档 + 50 个底层架构模块精炼为结构化的 AI 可索引知识体系。

## 概述

`blade-doc` 是一个专为 Claude Code 设计的 Skill，将 BladeX 从底层架构到生产部署的完整知识体系封装为自包含的参考资料集。覆盖两大知识维度：

1. **应用层** — 338 篇官方文档：从快速开始到生产部署的全链路使用指南
2. **架构层** — 50 个 BladeX-Tool 模块：每个 Starter 的配置属性、注解、关键类与依赖关系

当用户在 BladeX 项目中提出任何技术问题时，Claude 能即时定位并调取对应领域的详细知识，提供精准的配置指导、代码示例和问题排查方案。

**核心设计理念**: 零外部依赖。所有知识内嵌于 Skill 文件中，可迁移到任何 Claude Code 环境无需网络访问。

## 知识覆盖

基于 BladeX 官方文档 v4.8.0 + BladeX-Tool 源码分析，覆盖完整技术栈：

```
SpringBoot 3.5 · SpringCloud 2025 · MyBatis-Plus · Nacos · Sentinel
Flowable 7.0 · Seata · ELK · Prometheus · Docker / K8S
Vue2 (Saber) · Vue3 (Saber3) · Element-Plus · Lemon (TS)
```

### 知识领域

| 领域 | 参考文件 | 核心主题 |
|------|----------|----------|
| 产品架构 | `overview.md` | 系统架构、33 项核心功能、授权版本、插件规范 |
| 快速开始 | `quickstart.md` | 环境搭建、Nacos/Sentinel/Redis 安装、Maven Token、项目导入运行 |
| 开发基础 | `development.md` | Java 8-17、MyBatis-Plus、Swagger 3、微服务/CRUD/Feign/代码生成 (Beetl 模板体系) |
| 开发进阶 | `advanced.md` | 聚合文档、鉴权、跨域、日志系统、安全防护、启动器、乐观锁 |
| 认证体系 | `auth-system.md` | OAuth2 十种授权模式、SM2 国密、Token 管理、SaaS 多租户、Secure 框架、SSO |
| 权限控制 | `permissions.md` | 动态数据权限 (三种配置模式)、动态接口权限、@DataAuth/@RequiresPermissions |
| 工作流 | `workflow.md` | Flowable 流程建模/部署/发起/审批、表单路由、模块排除 |
| 中间件 | `middleware.md` | ELK 日志追踪、Seata AT/TCC/SAGA 分布式事务 |
| 报文加密 | `crypto.md` | AES/DES/RSA 全链路加密、@ApiCrypto 注解、前后端实战改造 |
| 工具包 | `toolkit.md` | EasyExcel 导入导出、UReport2 报表、34 个核心工具类 API |
| 扩展功能 | `features.md` | 26 项功能：任务调度/分库分表/OSS/SMS/灰度发布/规则引擎/脱敏/审计/防抖/限流/字段加密/i18n 等 |
| 生产部署 | `deployment.md` | Windows/Jar/宝塔/Docker 部署、Harbor 私仓、Nginx 反代、HTTPS |
| 监控告警 | `monitoring.md` | Prometheus 全套、Grafana、Alertmanager (邮件/钉钉/企微) |
| **底层架构** | **`bladex-tool.md`** | **11 核心模块 + 34 Starter 全配置速查、模块依赖链、认证授权子模块完整属性** |
| 版本升级 | `upgrade.md` | 2.0 → 4.8 全版本关键变更、SpringBoot 3 迁移、Jakarta EE 迁移 |
| 常见问题 | `faq.md` | 54 个高频 FAQ、Git 版本控制、学习资料 |

## 架构设计

```
blade-doc/
├── SKILL.md                ← 路由中枢
│   ├── 知识索引表            按问题领域指向 reference 文件
│   ├── 技术栈速查            核心组件版本一览
│   ├── 模块结构图            BladeX 项目目录结构
│   ├── 认证流程              最常用的 Token 获取与使用流程
│   ├── 常用注解速查          @PreAuth / @DataAuth / @ApiCrypto 等
│   └── 常用配置模板          blade.yaml 核心配置项
│
└── references/             ← 领域知识层 (16 个文件)
    ├── overview.md           产品概览
    ├── quickstart.md         快速开始
    ├── development.md        开发基础 + 代码生成模板体系
    ├── advanced.md           开发进阶
    ├── auth-system.md        认证与租户
    ├── permissions.md        权限控制
    ├── workflow.md           工作流
    ├── middleware.md         中间件
    ├── crypto.md             报文加密
    ├── toolkit.md            工具包
    ├── features.md           扩展功能 (26 项)
    ├── deployment.md         生产部署
    ├── monitoring.md         监控告警
    ├── bladex-tool.md        底层架构模块手册 (新增)
    ├── upgrade.md            版本升级
    └── faq.md                常见问题
```

### 渐进式加载

Skill 采用两级加载策略，在知识深度和上下文开销间取得平衡：

1. **SKILL.md** 始终加载至上下文 — 提供知识索引和高频参考，使 Claude 能即时判断问题领域
2. **references/** 按需加载 — Claude 根据索引表读取对应文件，获取该领域的完整技术细节

一次对话中，Claude 仅加载用户当前问题所涉及的知识模块，而非全量内容。

## 触发场景

以下场景会自动触发此 Skill：

- 提问涉及 BladeX / SpringBlade / bladex-tool / Saber / Saber3
- 配置 blade-gateway / blade-auth / Nacos / Sentinel
- 使用多租户、数据权限、接口权限、工作流
- 处理分布式事务 (Seata)、API 加解密
- 代码生成器使用、BladeX 工具类调用
- 查询 Starter 模块配置属性 (如 `blade.redis.*`, `blade.tenant.*`)
- 了解底层模块依赖关系和自动配置机制
- 生产部署 (Docker/K8S/宝塔) 和监控配置
- 版本升级迁移和错误排查

## 数据来源

### 应用层文档 (BladeX-Doc v4.8.0)

| 原始章节 | 文档数量 | 对应 Reference |
|----------|----------|----------------|
| 第 0 章 · 序 | 10 篇 | `overview.md` |
| 第 1 章 · 快速开始 | 32 篇 | `quickstart.md` |
| 第 2 章 · 技术基础 | 13 篇 | `development.md` |
| 第 3 章 · 开发初探 | 44 篇 | `development.md` |
| 第 4 章 · 开发进阶 | 12 篇 | `advanced.md` |
| 第 5 章 · 功能特性 | 196 篇 | `auth-system` · `permissions` · `workflow` · `middleware` · `crypto` · `toolkit` · `features` |
| 第 6 章 · 生产部署 | 86 篇 | `deployment.md` · `monitoring.md` |
| 第 7 章 · 系统升级 | 43 篇 | `upgrade.md` |
| 第 8-10 章 | 4 篇 | `faq.md` |

### 架构层源码 (BladeX-Tool)

| 模块分类 | 数量 | 对应 Reference |
|----------|------|----------------|
| 核心模块 (blade-core-*) | 11 | `bladex-tool.md` |
| 认证子模块 (blade-core-auth/*) | 6 | `bladex-tool.md` |
| 功能 Starter (blade-starter-*) | 34 | `bladex-tool.md` |
| 代码生成模板 (.btl) | 79 | `development.md` |

所有技术细节、配置示例、代码片段均忠实于原始文档和源码，未添加任何臆造内容。

## 安装

将 `blade-doc/` 目录复制到 Claude Code 的 skills 路径下：

```bash
# macOS / Linux
cp -r blade-doc/ ~/.claude/skills/blade-doc/

# 验证
ls ~/.claude/skills/blade-doc/
# SKILL.md  README.md  references/
```

无需额外配置，Claude Code 启动后自动识别。

## 版本

- **Skill 版本**: 1.1.0
- **知识基线**: BladeX + BladeX-Tool 源码
- **技术栈**: SpringBoot 3.5 / SpringCloud 2025 / JDK 17

### 更新日志

**v1.1.0**
- 新增 `bladex-tool.md`：50 个底层架构模块的完整配置属性手册
- 补全 `features.md`：新增灰度发布、LiteFlow/LiteRule、脱敏、数据审计、防抖、限流、动态数据源、字段加密、i18n、超级令牌等 12 项功能详细文档
- 更新 `development.md`：代码生成部分重写为最新 Beetl 模板体系 (79 个模板文件、5 套 UI 框架、Controller/Entity/Wrapper 最新代码风格)

**v1.0.0**
- 初始版本，338 篇文档精炼为 14 个领域知识文件

## 许可

本 Skill 为 BladeX 官方文档与源码的结构化提炼，仅供已获得 BladeX 商业授权的用户使用。知识产权归上海布雷德科技有限公司所有。
