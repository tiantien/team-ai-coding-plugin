# BladeX 审计检查清单

本文档包含六大审计维度的详细检查项。审计执行时按维度读取对应章节，逐项检查。

每个检查项格式：
- **ID**：唯一标识，用于报告中引用
- **检查内容**：具体检查什么
- **判定标准**：如何判断通过/不通过
- **典型违规**：常见的违规代码模式
- **严重级别**：该项不通过时的默认严重级别（可根据实际上下文调整）

---

## 目录

1. [安全审计 (SEC)](#1-安全审计-sec)
2. [逻辑健壮性 (ROB)](#2-逻辑健壮性-rob)
3. [架构合规 (ARC)](#3-架构合规-arc)
4. [框架规范 (CON)](#4-框架规范-con)
5. [性能隐患 (PRF)](#5-性能隐患-prf)
6. [代码质量 (QLT)](#6-代码质量-qlt)

---

## 1. 安全审计 (SEC)

### SEC-01: SQL 注入防护 🔴
**检查内容**：MyBatis XML 和注解中是否使用了 `${}` 拼接用户输入
**判定标准**：
- 所有用户可控参数必须使用 `#{}` 占位符
- `${}` 仅允许用于表名、列名等非用户输入场景，且必须有白名单校验
**典型违规**：
```xml
<!-- 违规：用户输入直接拼接 -->
<select id="findUser">
  SELECT * FROM user WHERE name = '${name}'
</select>
```
```java
// 违规：字符串拼接 SQL
@Select("SELECT * FROM user WHERE name = '" + name + "'")
```

### SEC-02: XSS 防护 🔴
**检查内容**：用户提交的内容在存储或输出时是否经过转义/过滤
**判定标准**：
- 存入数据库前应进行 XSS 过滤
- 富文本内容使用白名单过滤（如 jsoup）
- BladeX 项目应确认 XSS 过滤器是否启用
**典型违规**：
```java
// 违规：直接存储用户输入的 HTML 内容
entity.setContent(request.getParameter("content"));
```

### SEC-03: 接口鉴权 🔴
**检查内容**：Controller 方法是否配置了适当的权限控制
**判定标准**：
- 非公开接口必须有 `@PreAuth` 注解或在安全配置中声明
- 管理类接口必须有角色限制
- 数据修改接口（POST/PUT/DELETE）不得为匿名访问
**典型违规**：
```java
// 违规：删除接口无鉴权
@PostMapping("/remove")
public R remove(@RequestParam String ids) {
    return R.status(service.removeByIds(Func.toLongList(ids)));
}
```

### SEC-04: 敏感数据保护 🔴
**检查内容**：密码、密钥、Token 等敏感信息是否安全处理
**判定标准**：
- 密码必须加密存储（BCrypt 等），不得明文
- API Key、Secret 等不得硬编码在源码中
- 日志输出不得包含密码、Token 等敏感字段
- VO/DTO 返回给前端时不得包含密码字段
**典型违规**：
```java
// 违规：日志输出密码
log.info("用户登录：{}, 密码：{}", username, password);
// 违规：硬编码密钥
private static final String SECRET = "my-secret-key-123";
```

### SEC-05: 输入参数校验 🟠
**检查内容**：外部输入是否有完整的参数校验
**判定标准**：
- Controller 方法参数应使用 `@Valid` 或 `@Validated`
- DTO 字段应有 `@NotNull`、`@NotBlank`、`@Size` 等约束注解
- 关键业务参数（如 ID、金额）应有额外的业务校验
**典型违规**：
```java
// 违规：无任何参数校验
@PostMapping("/save")
public R save(@RequestBody UserDTO dto) {
    return R.status(service.save(dto));
}
```

### SEC-06: 文件上传安全 🔴
**检查内容**：文件上传是否有安全限制
**判定标准**：
- 必须校验文件类型（白名单机制，不仅仅检查扩展名）
- 必须限制文件大小
- 存储路径不得由用户输入控制（防止路径穿越）
- 上传后的文件名应重新生成

### SEC-07: 越权访问防护 🔴
**检查内容**：是否存在水平越权或垂直越权风险
**判定标准**：
- 数据查询/修改必须校验数据归属（租户隔离、用户隔离）
- 不能仅凭前端传入的 ID 直接操作数据，须后端校验权限
- 批量操作接口须逐条校验权限
**典型违规**：
```java
// 违规：直接用前端传入的 ID 删除，未校验数据归属
@PostMapping("/remove")
public R remove(@RequestParam Long id) {
    return R.status(service.removeById(id));
}
```

### SEC-08: SSRF 防护 🟠
**检查内容**：服务端发起的 HTTP 请求是否有目标地址限制
**判定标准**：
- 用户可控的 URL 参数不得直接用于服务端请求
- 若必须请求外部地址，需有白名单或黑名单（内网地址段）限制

### SEC-09: 序列化安全 🟠
**检查内容**：JSON/XML 反序列化是否安全
**判定标准**：
- Jackson 应关闭 `enableDefaultTyping`
- 不使用不安全的反序列化库或配置
- 自定义反序列化器应有类型白名单

### SEC-10: 租户数据隔离 🔴
**检查内容**：多租户场景下数据是否严格隔离
**判定标准**：
- 查询条件必须包含 tenant_id（除非是超管操作）
- 不得通过手动拼接 tenant_id，应使用框架的租户插件
- 跨租户数据访问必须有明确的权限校验

---

## 2. 逻辑健壮性 (ROB)

### ROB-01: 空指针防护 🟠
**检查内容**：是否存在空指针异常风险
**判定标准**：
- 数据库查询结果在使用前必须判空
- 链式调用中间环节可能为 null 时应有保护
- Map.get()、List.get() 等操作应考虑空/越界情况
- Optional 的使用应合理（不滥用也不缺失）
**典型违规**：
```java
// 违规：查询结果直接链式调用
User user = userService.getById(id);
String deptName = user.getDept().getName(); // user 或 dept 可能为 null
```

### ROB-02: 事务管理 🟠
**检查内容**：数据写操作的事务是否正确配置
**判定标准**：
- 涉及多表写入的方法必须有 `@Transactional(rollbackFor = Exception.class)`
- 事务方法不得在同一个类中自调用（代理失效）
- 只读操作不应开启写事务
- 事务范围不宜过大（不要把远程调用放在事务内）
**典型违规**：
```java
// 违规：多表写操作无事务
public void createOrder(OrderDTO dto) {
    orderMapper.insert(dto.getOrder());
    orderItemMapper.insertBatch(dto.getItems());
    // 若第二步失败，第一步不会回滚
}
// 违规：事务方法自调用
public void methodA() {
    this.methodB(); // 事务不生效
}
@Transactional
public void methodB() { ... }
```

### ROB-03: 并发安全 🟠
**检查内容**：多线程/高并发场景下是否有竞态条件
**判定标准**：
- 共享可变状态必须有同步保护
- "先查后改"模式须考虑并发（使用乐观锁或数据库原子操作）
- SimpleDateFormat 等非线程安全类不得用作共享实例
- Spring Bean 中不得有可变的实例变量（除非有意设计且有同步保护）
**典型违规**：
```java
// 违规：先查后改无并发保护
public void deductStock(Long productId, int count) {
    Product product = productMapper.selectById(productId);
    product.setStock(product.getStock() - count); // 并发下可能超卖
    productMapper.updateById(product);
}
```

### ROB-04: 边界条件处理 🟡
**检查内容**：是否正确处理各种边界情况
**判定标准**：
- 分页参数应有上限限制（防止一次查询数万条）
- 集合操作前应判断空集合
- 数值运算应考虑溢出、除零
- 字符串操作应考虑空串和超长输入

### ROB-05: 异常处理策略 🟠
**检查内容**：异常是否被正确捕获和处理
**判定标准**：
- 不得吞掉异常（空 catch 块）
- 不得捕获过宽（catch (Exception e) 然后什么都不做）
- 业务异常应使用自定义异常类（如 ServiceException），而非泛用 RuntimeException
- 异常信息应包含足够上下文（出错的参数、操作、原因）
**典型违规**：
```java
// 违规：吞掉异常
try {
    service.process(data);
} catch (Exception e) {
    // 什么都不做
}
// 违规：异常信息丢失
try { ... } catch (Exception e) {
    throw new RuntimeException("操作失败");  // 丢失原始异常信息
}
```

### ROB-06: 数据一致性 🟠
**检查内容**：跨表/跨服务操作是否保证数据一致性
**判定标准**：
- 主子表操作须在同一事务内
- 跨服务操作应有补偿机制或最终一致性方案
- 删除操作应处理关联数据（级联删除或前置检查）
- 状态机变更应有合法性校验

### ROB-07: 幂等性设计 🟡
**检查内容**：关键写接口是否具备幂等能力
**判定标准**：
- 支付、扣款等关键接口必须幂等
- 消息消费处理必须幂等
- 重复提交表单不应产生重复数据

---

## 3. 架构合规 (ARC)

### ARC-01: 分层纪律 🟠
**检查内容**：Controller → Service → Mapper 的分层调用是否严格遵守
**判定标准**：
- Controller 不得直接调用 Mapper
- Controller 不得包含业务逻辑（仅做参数接收、校验、调用 Service、返回结果）
- Service 不得直接操作 HttpServletRequest/Response
- Mapper 层不得包含业务逻辑

### ARC-02: 模块耦合 🟠
**检查内容**：业务模块之间的依赖是否合理
**判定标准**：
- Cloud 架构下，跨模块调用必须通过 Feign Client（不得直接引入其他模块的 Service）
- API 模块（blade-xxx-api）不得依赖 Service 实现模块
- 公共模块（blade-common）不得依赖业务模块
**典型违规**：
```java
// 违规（Cloud架构下）：直接注入其他模块的 Service
@Autowired
private IUserService userService;  // 应通过 IUserClient (Feign) 调用
```

### ARC-03: 依赖方向 🟠
**检查内容**：模块间的依赖方向是否正确
**判定标准**：
- 上层可以依赖下层，下层不得依赖上层
- 层级顺序：Controller > Service > Mapper > Entity
- API 模块是被依赖方，不得反向依赖 Service 模块
- 工具类/公共模块位于最底层

### ARC-04: 职责单一 🟡
**检查内容**：类和方法是否承担了过多职责
**判定标准**：
- 单个类不宜超过 500 行（超过应考虑拆分）
- 单个方法不宜超过 80 行
- 一个 Service 不应承担多个不相关的业务领域
- God Class（什么都干的工具类）应拆分为领域明确的小类

### ARC-05: API 设计质量 🟡
**检查内容**：REST API 的设计是否规范
**判定标准**：
- URL 路径应使用名词复数形式，体现资源语义
- HTTP Method 应语义正确（GET 查询、POST 创建、PUT 更新、DELETE 删除）
- 不应有过长的 URL 路径（超过 3 层嵌套）
- 接口版本应有管理策略

### ARC-06: 包结构规范 🟡
**检查内容**：Java 包的组织结构是否合理
**判定标准**：
- 遵循 BladeX 的标准分包：controller / service / mapper / pojo (entity/dto/vo) / config / wrapper
- 不应有游离的类（不属于任何合理分包的类）
- 测试代码应与主代码包结构对称

---

## 4. 框架规范 (CON)

### CON-01: 实体层次规范 🟡
**检查内容**：Entity / DTO / VO 的使用是否规范
**判定标准**：
- Entity 仅用于数据库映射，不直接返回给前端
- DTO 用于接收前端输入（创建/更新请求）
- VO 用于返回前端展示数据
- 不同场景使用不同对象，避免一个 Entity 贯穿所有层
**典型违规**：
```java
// 违规：直接返回 Entity 给前端（可能暴露敏感字段）
@GetMapping("/detail")
public R<User> detail(Long id) {
    return R.data(userService.getById(id));
}
```

### CON-02: 服务接口规范 🟡
**检查内容**：Service 层是否遵循接口-实现分离
**判定标准**：
- Service 必须定义 `IXxxService` 接口
- 实现类命名为 `XxxServiceImpl`
- 接口应继承 `IService<T>`（MyBatis-Plus）
- 实现类应继承 `ServiceImpl<XxxMapper, Xxx>`

### CON-03: 统一返回格式 🟡
**检查内容**：Controller 是否统一使用 `R<T>` 返回
**判定标准**：
- 所有 Controller 方法的返回类型应为 `R<T>`
- 成功返回使用 `R.data()` 或 `R.status()`
- 失败返回使用 `R.fail()`
- 不应直接返回原始类型或自定义返回结构

### CON-04: MyBatis-Plus 使用规范 🟡
**检查内容**：MyBatis-Plus 的使用是否符合最佳实践
**判定标准**：
- 优先使用 LambdaQueryWrapper 而非字符串字段名
- 复杂查询应写在 Mapper XML 中而非在 Service 中拼装
- 分页应使用框架提供的 Query 对象
- 批量操作应使用 saveBatch / updateBatchById
**典型违规**：
```java
// 违规：使用字符串字段名（硬编码，重构不安全）
QueryWrapper<User> wrapper = new QueryWrapper<>();
wrapper.eq("user_name", name);
// 正确写法
LambdaQueryWrapper<User> wrapper = Wrappers.<User>lambdaQuery()
    .eq(User::getUserName, name);
```

### CON-05: 租户处理规范 🟠
**检查内容**：多租户场景的处理是否正确
**判定标准**：
- 业务表必须有 tenant_id 字段
- 非租户维度的表（如系统配置表）应在租户插件中排除
- 超管操作应正确使用租户忽略机制
- 不得手动拼接 tenant_id 到 SQL 中

### CON-06: 数据库字段规范 🟡
**检查内容**：表设计是否包含 BladeX 要求的基础字段
**判定标准**：
- 必要字段：id (BIGINT)、create_user、create_dept、create_time、update_user、update_time、is_deleted、status
- 租户表还须有 tenant_id
- 主键应使用雪花算法生成（BIGINT），非自增
- 字段命名使用下划线分隔

### CON-07: Wrapper 转换规范 🟡
**检查内容**：Entity 与 VO 之间的转换是否使用 Wrapper 机制
**判定标准**：
- BladeX 推荐使用 BaseEntityWrapper 进行对象转换
- 不应在 Controller 中手动 new VO 并逐字段赋值
- Wrapper 中可嵌入字典翻译、关联查询等逻辑

### CON-08: Swagger/Knife4j 注解 🟢
**检查内容**：API 是否有完整的文档注解
**判定标准**：
- Controller 类应有 `@Tag` 注解
- 方法应有 `@Operation` 注解
- 参数应有 `@Parameter` 或 DTO 字段的 `@Schema` 注解
- 返回类型应有 `@Schema` 注解描述

---

## 5. 性能隐患 (PRF)

### PRF-01: N+1 查询 🟠
**检查内容**：是否存在循环内执行数据库查询的模式
**判定标准**：
- 循环体内不得有数据库查询（Mapper 调用、Service 查询）
- 应改为批量查询后再在内存中关联
**典型违规**：
```java
// 违规：经典 N+1
List<Order> orders = orderService.list();
for (Order order : orders) {
    User user = userService.getById(order.getUserId()); // 每次循环查一次
    order.setUserName(user.getName());
}
// 正确：批量查询
List<Long> userIds = orders.stream().map(Order::getUserId).collect(Collectors.toList());
Map<Long, User> userMap = userService.listByIds(userIds).stream()
    .collect(Collectors.toMap(User::getId, Function.identity()));
```

### PRF-02: 全表扫描风险 🟠
**检查内容**：SQL 查询是否可能导致全表扫描
**判定标准**：
- WHERE 条件应命中索引
- LIKE 查询不应以 `%` 开头（如 `LIKE '%keyword'`）
- 不应在 WHERE 中对索引字段进行函数运算
- 大表查询必须有分页或 LIMIT 限制

### PRF-03: 大对象和内存风险 🟡
**检查内容**：是否存在内存使用不当的情况
**判定标准**：
- 不应将全表数据加载到内存（`list()` 无条件查询大表）
- 循环中不应频繁创建大对象
- 大集合操作应考虑分批处理
- 字符串拼接应使用 StringBuilder 而非 `+` 连接（循环内）

### PRF-04: 连接和资源泄漏 🟠
**检查内容**：外部资源（DB连接、HTTP连接、文件流）是否正确释放
**判定标准**：
- IO 流必须使用 try-with-resources 或在 finally 中关闭
- HTTP Client 的 Response 必须关闭
- 手动获取的数据库连接必须归还
**典型违规**：
```java
// 违规：流未关闭
InputStream is = new FileInputStream(file);
// ... 使用 is，但未在 finally 中关闭
```

### PRF-05: 缺少批量操作 🟡
**检查内容**：大量数据操作是否使用了批处理
**判定标准**：
- 多条数据插入应使用 `saveBatch()` 而非循环 `save()`
- 多条数据更新应使用 `updateBatchById()` 而非循环 `updateById()`
- 批量大小应合理（通常 500-1000 条一批）

### PRF-06: 缓存使用 🟡
**检查内容**：热点数据是否有缓存策略
**判定标准**：
- 高频读取、低频变更的数据（如字典、配置）应使用缓存
- 缓存应有过期策略
- 数据变更时应清除或更新对应缓存
- 不应缓存大对象或私有数据

### PRF-07: 索引策略 🟡
**检查内容**：数据库索引设计是否合理
**判定标准**：
- 频繁查询的字段应建立索引
- 联合索引应遵循最左前缀原则
- 不应在低基数字段（如 is_deleted）上单独建索引
- 索引数量不宜过多（单表不超过 5-6 个）

---

## 6. 代码质量 (QLT)

### QLT-01: 命名规范 🟡
**检查内容**：命名是否清晰且符合约定
**判定标准**：
- 类名：大驼峰，名词，语义明确（不使用 Manager/Handler 等模糊后缀除非确有含义）
- 方法名：小驼峰，动词开头，表达行为
- 变量名：小驼峰，名词，语义明确，不使用单字母（循环变量除外）
- 常量名：全大写下划线分隔
- Boolean 变量/方法：使用 is/has/can/should 前缀

### QLT-02: 方法复杂度 🟡
**检查内容**：方法是否过长或逻辑过于复杂
**判定标准**：
- 方法行数不宜超过 80 行
- 圈复杂度不宜超过 10（嵌套 if/for/switch 过多）
- 参数数量不宜超过 5 个（超过应封装为对象）
- 嵌套层数不宜超过 3 层

### QLT-03: 代码重复 🟡
**检查内容**：是否存在明显的重复代码
**判定标准**：
- 同一模块内不应有超过 10 行的高度相似代码块
- 跨模块的重复逻辑应提取到公共模块
- 复制粘贴后只改了少量参数的代码应重构为参数化方法

### QLT-04: 魔法值 🟡
**检查内容**：代码中是否有未解释的硬编码值
**判定标准**：
- 数字、字符串常量应提取为命名常量或枚举
- 状态值（0/1/2）应使用枚举或常量类
- 特殊含义的值应有注释或使用自解释的常量名
**典型违规**：
```java
// 违规：魔法数字
if (user.getStatus() == 2) { ... }
// 正确
if (user.getStatus().equals(UserStatus.LOCKED)) { ... }
```

### QLT-05: 注释质量 🟢
**检查内容**：注释是否有助于理解代码
**判定标准**：
- 复杂业务逻辑应有注释说明"为什么"这样做
- 不应有大段被注释掉的代码（应删除，Git 有历史）
- 注释不应与代码矛盾（过时的注释比没有注释更糟）
- TODO/FIXME 应有明确的上下文信息

### QLT-06: 日志规范 🟡
**检查内容**：日志输出是否规范
**判定标准**：
- 使用 SLF4J 的占位符 `{}` 而非字符串拼接
- 日志级别使用恰当（ERROR 用于真正的错误，不滥用）
- 关键业务操作应有日志记录（入参、出参、异常）
- 不应在循环中输出大量日志
**典型违规**：
```java
// 违规：字符串拼接
log.info("处理用户：" + user.getName() + "，ID：" + user.getId());
// 正确：占位符
log.info("处理用户：{}，ID：{}", user.getName(), user.getId());
```

### QLT-07: 过时 API 使用 🟡
**检查内容**：是否使用了已弃用的 API 或过时的编码方式
**判定标准**：
- 不使用 `@Deprecated` 标记的方法
- 使用 Java 17+ 推荐的新 API（如 `List.of()` 代替 `Arrays.asList()`）
- 使用 Stream API 而非手动循环进行集合变换
- 使用 try-with-resources 而非手动关闭资源
