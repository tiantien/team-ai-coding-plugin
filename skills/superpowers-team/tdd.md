---
name: tdd
description: TDD 开发规范 - 强制 RED-GREEN-REFACTOR 的 TDD 开发节奏，无测试不写实现代码
type: skill
---

# TDD（测试驱动开发规范）

## 核心规则

强制 RED-GREEN-REFACTOR 的 TDD 开发节奏，无测试不写实现代码。

## 触发场景

- 编写实现代码时自动触发
- 手动触发：`/tdd 开始 TDD 开发`

## TDD 循环

### RED 阶段 - 先写失败测试

1. 理解需求
2. 编写测试用例
3. 运行测试，确认失败
4. 提交测试代码

```javascript
// 示例：测试先行
describe('CouponService', () => {
  it('should redeem valid coupon', async () => {
    const service = new CouponService();
    const result = await service.redeem('COUPON123');
    expect(result.success).toBe(true);
  });
});
// 此时运行测试会失败，因为 redeem 方法还不存在
```

### GREEN 阶段 - 写最小实现

1. 编写最小实现代码
2. 运行测试，确认通过
3. 不做额外优化

```javascript
// 示例：最小实现
class CouponService {
  async redeem(code) {
    return { success: true };
  }
}
// 刚好让测试通过，不做更多
```

### REFACTOR 阶段 - 优化代码

1. 检查代码质量
2. 消除重复
3. 优化结构
4. 确保测试仍然通过

```javascript
// 示例：重构优化
class CouponService {
  constructor(private repository: CouponRepository) {}

  async redeem(code: string): Promise<RedeemResult> {
    const coupon = await this.repository.findByCode(code);
    if (!coupon || coupon.isExpired()) {
      return { success: false, error: 'INVALID_COUPON' };
    }
    await this.repository.markAsUsed(coupon.id);
    return { success: true, discount: coupon.value };
  }
}
```

## 测试分类

### 单元测试

- 测试单个函数/方法
- 隔离外部依赖
- 快速执行

### 集成测试

- 测试模块间交互
- 使用真实依赖
- 验证数据流

### 端到端测试

- 测试完整流程
- 模拟用户操作
- 验证业务场景

## 测试覆盖要求

| 代码类型 | 最低覆盖率 |
|----------|------------|
| 核心业务逻辑 | 90% |
| API 接口 | 80% |
| 工具函数 | 70% |
| UI 组件 | 60% |

## 测试命名规范

```
[功能名称] should [预期行为] when [条件]
```

示例：
- `redeem should return success when coupon is valid`
- `redeem should fail when coupon is expired`
- `redeem should fail when coupon already used`

## 禁止行为

- ❌ 先写实现后写测试
- ❌ 为了通过测试而跳过测试
- ❌ 测试中包含逻辑判断
- ❌ 测试依赖执行顺序
- ❌ 使用真实外部服务（单元测试）

## 最佳实践

1. **小步前进**：每次只测试一个行为
2. **快速反馈**：测试应该在秒级完成
3. **独立运行**：测试之间互不依赖
4. **清晰表达**：测试名称即文档
