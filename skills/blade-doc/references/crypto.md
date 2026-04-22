# API 报文加密

## 概述
API 报文加密为认证和 Token 验证之上提供额外安全层，保护关键数据传输。

## 依赖
```xml
<dependency>
    <groupId>org.springblade</groupId>
    <artifactId>blade-starter-api-crypto</artifactId>
</dependency>
```

## 支持的加密方式
- **AES**: `@ApiEncryptAes` / `@ApiDecryptAes` (推荐，性能更优)
- **DES**: `@ApiEncryptDes` / `@ApiDecryptDes`
- **RSA**: `@ApiEncryptRsa` / `@ApiDecryptRsa`

## 注解体系

### 解密注解
| 注解 | 适用位置 | 说明 |
|------|----------|------|
| `@ApiDecryptAes` | 方法参数 / 方法 / 类 | AES 解密 |
| `@ApiDecryptDes` | 方法参数 / 方法 / 类 | DES 解密 |
| `@ApiDecryptRsa` | 方法参数 / 方法 / 类 | RSA 解密 |
| `@ApiDecrypt(CryptoType.AES)` | 同上 | 通用解密 (指定类型) |

- 参数级: GET/POST URL 参数 (base64 JSON)
- 方法级: POST body
- 类级: 整个 Controller 的 POST body

### 加密注解
| 注解 | 适用位置 | 说明 |
|------|----------|------|
| `@ApiEncryptAes` | 方法 / 类 | AES 加密响应 |
| `@ApiEncryptDes` | 方法 / 类 | DES 加密响应 |
| `@ApiEncryptRsa` | 方法 / 类 | RSA 加密响应 |
| `@ApiEncrypt(CryptoType.AES)` | 同上 | 通用加密 |

### 组合注解
| 注解 | 说明 |
|------|------|
| `@ApiCrypto` | 同时加密响应 + 解密请求 (仅 body 传参) |
| `@ApiCryptoAes` | AES 组合 |
| `@ApiCryptoDes` | DES 组合 |

## 配置

### 后端 (YAML)
```yaml
blade:
  api:
    crypto:
      enabled: true
      aes-key: "O2BEeIv399qHQNhD6aGW8R8DEj4bqHXm"
      des-key: "jMVCBsFGDQr1USHo"
  jackson:
    support-text-plain: true  # 必须开启
```

### 前端 (JavaScript)
```javascript
export default class crypto {
  static aesKey = 'O2BEeIv399qHQNhD6aGW8R8DEj4bqHXm';
  static desKey = 'jMVCBsFGDQr1USHo';
}
```

**注意**: 前后端密钥必须一致。示例密钥仅测试用，生产务必更换。

## 使用示例

### 基本解密 (参数传递)
```java
@PostMapping("/crypto")
public R<Notice> crypto(@ApiDecryptAes Notice notice) {
    return R.data(notice);
}
```
请求: 加密字符串作为 `data` 参数传入 (参数名可配置，默认 "data")

### 加解密组合 (Body 传递)
```java
@ApiCryptoAes
@PostMapping("/crypto")
public R<Notice> crypto(@RequestBody Notice notice) {
    return R.data(notice);
}
```

### 类级别注解
```java
@ApiCrypto
@RestController
@RequestMapping("notice")
public class NoticeController {

    @PostMapping("/submit")
    public R submit(@RequestBody Notice notice) {
        return R.status(noticeService.saveOrUpdate(notice));
    }

    // 可在方法级覆盖为参数传递
    @PostMapping("/search")
    public R<Notice> search(@ApiDecryptAes Notice notice) {
        return R.data(notice);
    }
}
```

## 实战改造

### 查询加密改造

**前端**:
```javascript
// 改造前
export const getList = (current, size, params) => {
  return request({ url: '/api/blade-desk/notice/list', method: 'get', params: { ...params, current, size } })
}
// 改造后
export const getList = (current, size, params) => {
  const param = { ...params, current, size }
  const data = crypto.encryptAES(JSON.stringify(param), crypto.aesKey);
  return request({ url: '/api/blade-desk/notice/list', method: 'get', params: { data } })
}
```

**后端**:
```java
// 改造前
@GetMapping("/list")
public R<IPage<NoticeVO>> list(@RequestParam Map<String, Object> notice, Query query) { ... }

// 改造后
@ApiCrypto
@GetMapping("/list")
public R<IPage<NoticeVO>> list(@ApiDecryptAes Notice notice, @ApiDecryptAes Query query) {
    Map<String, Object> params = JsonUtil.readMap(JsonUtil.toJson(notice), String.class, Object.class);
    IPage<Notice> pages = noticeService.page(Condition.getPage(query), Condition.getQueryWrapper(params, Notice.class));
    return R.data(NoticeWrapper.build().pageVO(pages));
}
```

### 增改加密改造

**前端**:
```javascript
export const add = (row) => {
  return request({
    url: '/api/blade-desk/notice/submit', method: 'post',
    text: true,  // 重要
    data: crypto.encryptAES(JSON.stringify(row), crypto.aesKey)
  })
}
```

**后端**:
```java
@ApiCrypto
@PostMapping("/submit")
public R submit(@RequestBody Notice notice) {
    return R.status(noticeService.saveOrUpdate(notice));
}
```

### 删除加密改造

**前端**:
```javascript
export const remove = (ids) => {
  const data = crypto.encryptAES(ids, crypto.aesKey);
  return request({ url: '/api/blade-desk/notice/remove', method: 'post', params: { data } })
}
```

**后端**:
```java
@ApiCrypto
@PostMapping("/remove")
public R remove(@ApiDecryptAes String ids) {  // 移除 @RequestParam
    return R.status(noticeService.deleteLogic(Func.toLongList(ids)));
}
```

## 自动化配置 (3.3.1+)

前端无需额外修改，只需启用 `cryptoData: true`:
```javascript
export const getList = (current, size, params) => {
  return request({
    url: '/blade-desk/notice/list', method: 'get',
    params: { ...params, current, size },
    cryptoData: true,  // 自动加解密
  });
};
```

## 最佳实践
- 参数传递: 适合 1-2 个参数
- Body 传递: 适合表单和大数据量
- **推荐 AES**: 性能更优，提升接口承载能力
