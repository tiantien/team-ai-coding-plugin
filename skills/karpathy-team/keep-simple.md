---
name: keep-simple
description: 极简实现原则 - 优先选择最简单、可维护的实现方案，不做过度工程化、不炫技、不引入非必要依赖
type: skill
---

# Keep It Simple（极简实现原则）

## 核心规则

优先选择最简单、可维护的实现方案，不做过度工程化、不炫技、不引入非必要依赖。

## 触发场景

- AI 做架构设计、代码实现时自动校验
- 手动触发：`/simplify 优化当前代码，去除冗余逻辑，保持最简实现`

## 使用方法

### 自动触发

当 AI 进行架构设计或代码实现时，自动校验是否符合极简原则。

### 手动触发示例

```
/simplify 优化当前代码，去除冗余逻辑，保持最简实现
```

## 极简原则检查清单

### 设计层面

1. **是否过度抽象？** - 不要为未来可能的需求设计抽象层
2. **是否过度分层？** - 层级数量与项目复杂度匹配
3. **是否引入不必要依赖？** - 能用标准库就不用第三方库
4. **是否过度配置化？** - 不要为不存在的场景预留配置

### 代码层面

1. **函数是否过长？** - 单个函数不超过 50 行
2. **参数是否过多？** - 单个函数参数不超过 4 个
3. **嵌套是否过深？** - 嵌套层级不超过 3 层
4. **是否有重复代码？** - DRY 原则

## 反模式警示

### 过度工程化

```javascript
// 错误：为简单功能设计复杂架构
class UserServiceFactory {
  createUserService(config) {
    return new UserServiceBuilder()
      .withRepository(config.repository)
      .withCache(config.cache)
      .withLogger(config.logger)
      .build();
  }
}

// 正确：简单直接
class UserService {
  constructor(repository, cache, logger) {
    this.repository = repository;
    this.cache = cache;
    this.logger = logger;
  }
}
```

### 过度抽象

```javascript
// 错误：为不需要扩展的场景设计抽象
interface DataProcessor {
  process(data: any): any;
}

class UserDataProcessor implements DataProcessor { ... }
class OrderDataProcessor implements DataProcessor { ... }

// 正确：直接实现
function processUserData(data) { ... }
function processOrderData(data) { ... }
```

## 判断标准

| 场景 | 简单方案 | 复杂方案 | 选择 |
|------|----------|----------|------|
| 单一功能 | 直接实现 | 抽象工厂 | 简单方案 ✅ |
| 明确扩展需求 | 策略模式 | 简单 if-else | 复杂方案 ✅ |
| 不确定需求 | 简单实现 | 预留扩展点 | 简单方案 ✅ |

## YAGNI 原则

You Aren't Gonna Need It - 不要为未来可能的需求编写代码

- 只实现当前需要的功能
- 不要预留扩展点
- 不要过度参数化
- 让代码易于修改，而不是易于扩展
