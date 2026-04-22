# Excel 工具包 + UReport2 报表 + 开发工具包

## Excel 工具包 (基于 EasyExcel)

### 依赖
基于阿里巴巴 EasyExcel: https://www.yuque.com/easyexcel/doc/easyexcel

### Excel Bean 定义
```java
@Data
@ColumnWidth(25)
@HeadRowHeight(20)
@ContentRowHeight(18)
public class NoticeExcel {
    @ColumnWidth(15)
    @ExcelProperty("标题")
    private String title;

    @ExcelIgnore
    @ExcelProperty("类型")
    private Integer category;

    @ExcelProperty("类型名称")
    private String categoryName;

    @ExcelProperty("发布日期")
    private Date releaseTime;

    @ExcelProperty("内容")
    private String content;
}
```

### 导出
```java
@GetMapping("export")
public void export(HttpServletResponse response) {
    List<NoticeExcel> list = ...; // 查询数据
    ExcelUtil.export(response, "文件名", "Sheet名", list, NoticeExcel.class);
}
```

### 读取
```java
@PostMapping("read")
public R<List<NoticeExcel>> read(MultipartFile file) {
    List<NoticeExcel> list = ExcelUtil.read(file, NoticeExcel.class);
    // 可指定 sheet: ExcelUtil.read(file, sheetNo, NoticeExcel.class)
    return R.data(list);
}
```

### 大数据量导入 (推荐)
```java
// 实现 ExcelImporter 接口
@RequiredArgsConstructor
public class NoticeImporter implements ExcelImporter<NoticeExcel> {
    private final INoticeService service;

    @Override
    public void save(List<NoticeExcel> data) {
        data.forEach(excel -> {
            Notice notice = BeanUtil.copy(excel, Notice.class);
            service.save(notice);
        });
    }
}

// Controller 调用
@PostMapping("import")
public R<Boolean> importExcel(MultipartFile file) {
    ExcelUtil.save(file, new NoticeImporter(noticeService), NoticeExcel.class);
    return R.success("操作成功");
}
```
**优势**: 默认每 3000 行批量处理，防止 OOM。

## UReport2 报表

### 概述
基于 Spring 的高性能报表引擎，支持 Web 可视化设计器 (Chrome/Firefox/Edge，不支持 IE)。

### 对接配置

**Cloud 版**:
1. 配置 blade-report 模块数据源
2. 启动 ReportApplication
3. 访问: http://localhost:8108/ureport/designer

**Boot 版**:
1. 在 application.yml 启用报表配置
2. 启动 Application
3. 访问: http://localhost/ureport/designer

### 学习资料
- 手册: https://www.w3cschool.cn/ureport/
- 视频教程: https://pan.baidu.com/s/1lkFYQhro7muxPYG6YJexQQ?pwd=ac7Y

## 开发工具包 (34个核心工具类)

### 加密解密

**AesUtil** - AES 加解密:
- `genAesKey()` 生成密钥
- `encryptToBase64(text, key)` / `decryptFormBase64ToString(text, key)`

**DesUtil** - DES 加解密:
- `genDesKey()` 生成密钥
- `encryptToBase64()` / `decryptFormBase64()`

**RsaUtil** - RSA 加解密:
- `genKeyPair()` 生成密钥对
- `encrypt(data, publicKey)` / `decrypt(data, privateKey)`

**DigestUtil** - 通用摘要:
- MD5: `md5Hex(data)`
- SHA: `sha1Hex()`, `sha256Hex()`, `sha512Hex()`
- HMAC: `hmacMd5Hex()`, `hmacSha256Hex()` 等
- `slowEquals()` 常量时间比较 (防时序攻击)

**Base64Util**: `encode()` / `decode()`, URL-safe 变体
**HexUtil**: `encodeToString()` / `decodeToString()`

### JSON / XML

**JsonUtil** (Jackson):
- `toJson(obj)` / `parse(json, Class)` / `parseArray(json, Class)`
- `readTree(json)` → JsonNode
- `readList()` / `readMap()`
- `convertValue(source, targetType)`

**XmlUtil**:
- `of(xml)` 创建实例
- XPath: `getString(expr)`, `getNode(expr)`, `getNodeList(expr)`
- `toMap()` 简单 XML 转 Map

### Web 工具

**WebUtil**:
- `getRequest()`, `getIP()`, `getHeader(name)`, `getParameter(name)`
- `getRequestBody()` 获取请求体
- Cookie: `getCookieVal()`, `setCookie()`, `removeCookie()`
- `renderJson(response, obj)` 渲染 JSON 响应
- `isBody()` 检测 ResponseBody 注解
- Session: `getSessionAttribute()`, `setSessionAttribute()`
- CORS: `isValidOrigin()`, `isSameOrigin()`

### Bean / 对象工具

**BeanUtil**:
- `newInstance(Class)` 创建实例
- `getProperty(bean, "test.user.name")` 支持嵌套属性
- `copy(source, TargetClass)` / `copyNonNull()` / `copyWithConvert()`
- `toMap(bean)` / `toBean(map, Class)`
- `generator()` 动态添加字段

**ObjectUtil**:
- `isEmpty()` / `isNotEmpty()` / `isArray()`
- `nullSafeEquals()` / `nullSafeHashCode()`

**ConvertUtil**: `convert(source, TargetClass)` 类型转换

### 字符串 / 数字

**StringUtil** (继承 Spring StringUtils):
- `isBlank()` / `isNotBlank()` / `isAnyBlank()` / `isNumeric()`
- `format("Hello {0}", name)` 格式化
- `simpleMatch("xxx*", text)` 模式匹配

**NumberUtil**:
- `toInt()`, `toLong()`, `toDouble()`, `toFloat()` (含默认值)
- `to62String(long)` 转 62 进制短字符串

**Func** (瑞士军刀):
- `requireNotNull()` 断言
- `isBlank()` / `isNotBlank()` / `isEmpty()`
- `firstCharToLower()` / `firstCharToUpper()`

### 日期时间

**DateUtil**: `now()`, `plusDays()`, `minusHours()` 等日期运算
**DateTimeUtil**:
- `formatDateTime()`, `formatDate()`, `formatTime()`, `format(pattern)`
- `parseDateTime()`, `parseDate()`, `parseTime()`
- `toInstant()`, `toDateTime()`, `toDate()`
- `between(start, end)` 计算时间差

### 文件 / IO

**FileUtil**:
- `list(dir, pattern)` 扫描目录
- `readToString(file)` / `readToByteArray(file)`
- `writeToFile(file, content, append)`
- `toFile(multipartFile)` MultipartFile 转 File
- `moveFile()`, `deleteQuietly()`, `copy()`

**IoUtil**:
- `readToString(inputStream)` / `readToByteArray()`
- `copy(in, out)` / `copyRange()`
- `closeQuietly(closeable)`

**PathUtil**: `getJarPath()` 获取 jar 运行目录

### 图片工具

**ImageUtil**:
- `readImage(path)` 读取图片
- `zoomScale(image, scale)` 按比例缩放
- `zoomFixed(image, width, height)` 固定尺寸
- `crop(image, x, y, w, h)` 裁剪
- `sliceWithNumber(image, rows, cols)` 切片
- `textStamp()` 文字水印
- `imageStamp()` 图片水印
- `gray()` 灰度化
- `convert()` 格式转换

### 反射 / 类操作

**ReflectUtil**:
- `getField(Class, name)`, `findMethod()`, `invokeMethod()`
- `getBeanGetters()`, `getBeanSetters()`
- `makeAccessible()` 强制可访问
- `getAnnotation(Class, field, annotationType)`

**ClassUtil**:
- `forName(className)` 类加载
- `isPresent(className)` 检查类是否存在
- `getAnnotation()` / `isAnnotated()`

**ResourceUtil**: `getResource(path)` 支持 classpath:/file:/http: 等协议

### 其他工具

**SpringUtil**:
- `getBean(Class)` / `getBean(beanId)`
- `getContext()` 获取 ApplicationContext
- `publishEvent(event)` 发布 Spring 事件

**PlaceholderUtil**: 占位符解析
- `getDefaultResolver()` 默认 `${...}` 解析
- `resolveByMap(content, valueMap)` Map 替换
- `resolveByRule(content, rule)` 自定义规则

**ProtostuffUtil**: 高性能序列化
- `serialize(obj)` / `deserialize(bytes, Class)`

**RegexUtil**: `match()`, `find()`, `findResult()`
**ThreadUtil**: `sleep(millis)`
**ThreadLocalUtil**: `put()`, `get()`, `clear()` 线程局部存储
**RuntimeUtil**: `getPid()`, `getCpuNum()`, `getUpTime()`
**UrlUtil**: URL 编解码, RFC 3986 URI 组件编码
**Charsets**: `charset(name)` 字符集转换
