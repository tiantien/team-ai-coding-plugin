# Blade Commit

通用 Git 提交工具，基于 Gitmoji 规范生成风格统一的提交信息。

## 快速开始

```bash
# 简单模式（默认）— 单行 gitmoji + 描述
/blade-commit

# 详细模式 — gitmoji + conventional commit + 变更列表
/blade-commit -d

# 自定义信息 — 自动补全 gitmoji 格式
/blade-commit -m "新增设备影子系统"
```

## 两种模式

### 简单模式（默认）

单行格式，适用于日常小改动：

```
:sparkles: 新增Qwen与MiniMax模型驱动实现
:bug: 修复流式推理输出时Token计数不准确的问题
:zap: 优化向量检索召回策略，提升RAG响应质量
```

### 详细模式（`-d`）

多行格式，适用于涉及多文件的较大提交：

```
:sparkles: feat(rag): 新增多模态知识库检索引擎

- 新增MultiModalRetriever实现文本与图像的混合向量检索
- 新增PDF/Markdown文档的自动分块与Embedding入库流程
- 新增检索结果重排序策略，支持Cohere Rerank与交叉编码器
```

## 常用 Gitmoji

| Gitmoji | 图标 | 场景 |
|---|---|---|
| `:sparkles:` | ✨ | 新增功能 |
| `:bug:` | 🐛 | 修复 Bug |
| `:zap:` | ⚡ | 性能优化 |
| `:recycle:` | ♻️ | 重构 |
| `:memo:` | 📝 | 文档变更 |
| `:wrench:` | 🔧 | 配置变更 |
| `:fire:` | 🔥 | 移除代码 |
| `:tada:` | 🎉 | 发布版本 |
| `:white_check_mark:` | ✅ | 测试 |
| `:lock:` | 🔒 | 安全修复 |

完整对照表见 SKILL.md。

## 安全保障

- **只做 commit**，禁止 push、pull 等任何远程操作
- **零署名**，不添加任何 AI/工具署名
- **逐文件暂存**，不使用 `git add .`，排除敏感文件
- **自动适配**，根据项目历史提交记录匹配语言和风格
