# Flowable 工作流

## 概述
Flowable 是轻量级 Java 业务流程引擎，支持 BPMN 2.0 标准。BladeX 深度定制 Flowable 支持 SpringCloud 分布式场景。

**文档**: https://tkjohn.github.io/flowable-userguide/ (中文) / https://www.flowable.org/docs/userguide/index.html (英文)

**重要**: 工作流复杂度高，使用前务必阅读官方文档。

## 系统启动

### 架构
工作流设计为独立微服务，拥有独立数据库 (与业务库隔离)。

### 启动步骤
1. 创建数据库 `bladex_flow` (BladeX-Boot 不需要单独建库)
2. Nacos 创建配置 `blade-flow-dev.yaml`
3. 执行工作流数据库脚本
4. 启动 `blade-flow` 服务

### 流程设计器
- **Sword 前端**: 需单独下载启动 Flowable-Design，访问 http://localhost:9999/index.html
- **Saber 前端**: NutFlow 设计器已内嵌集成，无需单独启动
- 首次访问前端前: 清除 Redis (`flushdb`)

## 流程模型创建

1. 启动 flowable-design 服务
2. 在 web 中配置设计器地址
3. 点击 "创建模型"
4. 导入流程文件 (项目中的流程配置文件)

## 流程部署

### 方式一: 从模型部署
1. 点击新建模型的部署按钮
2. 选择流程类型 (如 "请假流程")
3. 流程出现在流程管理中
4. 可控制激活/挂起状态

### 方式二: 上传文件部署
1. 进入流程部署页面
2. 选择流程类型并上传文件
3. "通用流程": 所有租户可用
4. "定制流程": 指定租户独享

## 流程发起

### 表单路由系统
```
process/
├── [流程路由Key]/
    ├── form.vue    # 流程发起表单
    ├── handle.vue  # 流程审批表单
    └── detail.vue  # 流程详情页
```

每个流程有字典数据分类，分类关联三个路由项: 表单路由、审批路由、详情路由。

### 发起流程后端代码
```java
// 1. 获取业务表名
String businessTable = FlowUtil.getBusinessTable(ProcessConstant.LEAVE_KEY);

// 2. 保存业务数据
leave.setApplyTime(LocalDateTime.now());
save(leave);

// 3. 创建流程变量
Kv variables = Kv.create()
    .set(ProcessConstant.TASK_VARIABLE_CREATE_USER, SecureUtil.getUserName())
    .set("taskUser", TaskUtil.getTaskUser(leave.getTaskUser()))
    .set("days", Duration.between(leave.getStartTime(), leave.getEndTime()).toDays());

// 4. 启动流程 (Cloud 用 Feign，Boot 用 Service)
BladeFlow flow = flowClient.startProcessInstanceById(
    leave.getProcessDefinitionId(),
    FlowUtil.getBusinessKey(businessTable, String.valueOf(leave.getId())),
    variables
);

// 5. 回写流程 ID
if (Func.isNotEmpty(flow)) {
    leave.setProcessInstanceId(flow.getProcessInstanceId());
    updateById(leave);
}
```

## 流程审批

### 审批逻辑
- "同意": 添加 `flag: 'ok'` 参数
- "驳回": 不传 flag 参数
- 后端根据 flag 判断流程走向

### 完成任务后端
```java
// 使用 Flowable taskService 完成任务
// 获取 taskId, processId, opinion
// 组装 map 调用 taskService 完成任务
// 自动推进工作流
```

### 审批意见
记录审批意见和详情的评论模块。

## 排除工作流模块

### BladeX (Cloud)
- 删除工作流相关项目
- 移除 blade-desk 项目中的 `blade-flow-api` 依赖

### BladeX-Boot
1. 删除 `flow` 包
2. 移除 `blade-starter-flowable` 依赖
3. 刷新 Maven 并 `mvn clean`

### Saber 前端
- 删除 `flow` 和 `work` 模块

### 菜单
- 在菜单管理中删除工作流相关菜单项
