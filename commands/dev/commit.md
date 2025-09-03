---
description: "创建格式良好的提交，使用传统的提交消息和表情符号"
allowed-tools:
  [
    "Bash(git add:*)",
    "Bash(git status:*)",
    "Bash(git commit:*)",
    "Bash(git diff:*)",
    "Bash(git log:*)",
  ]
---

# Claude命令: 提交

创建格式良好的提交，使用传统的提交消息和表情符号。

## 用法

```
/commit
/commit --no-verify
```

## 流程

1. 检查已暂存的文件，如果存在则仅提交已暂存的文件
2. 分析差异以查找多个逻辑更改
3. 如需要，建议拆分
4. 使用表情符号传统格式创建提交
5. Husky自动处理预提交钩子

## 提交格式

`<emoji> <type>: <description>`

**类型:**

- `feat`: 新功能
- `fix`: 修复问题
- `docs`: 文档
- `style`: 代码格式
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 添加或更新测试
- `build`: 构建系统或外部依赖项的更改
- `ci`: 持续集成相关的变动
- `chore`: 工具或其他不修改 src 或测试文件的更改
- `revert`: 回滚某次提交

**规则:**

- 使用祈使语气 ("add" 而不是 "added")
- 第一行 <72 个字符
- 原子提交 (单一目的)
- 拆分不相关的更改

## 表情符号映射

✨ feat | 🐛 fix | 📝 docs | 💄 style | ♻️ refactor | ⚡ perf | ✅ test | 🔧 chore | 🚀 ci | 🚨 warnings | 🔒️ security | 🚚 move | 🏗️ architecture | ➕ add-dep | ➖ remove-dep | 🌱 seed | 🧑‍💻 dx | 🏷️ types | 👔 business | 🚸 ux | 🩹 minor-fix | 🥅 errors | 🔥 remove | 🎨 structure | 🚑️ hotfix | 🎉 init | 🔖 release | 🚧 wip | 💚 ci-fix | 📌 pin-deps | 👷 ci-build | 📈 analytics | ✏️ typos | ⏪️ revert | 📄 license | 💥 breaking | 🍱 assets | ♿️ accessibility | 💡 comments | 🗃️ db | 🔊 logs | 🔇 remove-logs | 🙈 gitignore | 📸 snapshots | ⚗️ experiment | 🚩 flags | 💫 animations | ⚰️ dead-code | 🦺 validation | ✈️ offline

## 拆分标准

不同关注点 | 混合类型 | 文件模式 | 大型更改

## 选项

`--no-verify`: 跳过Husky钩子

## 注意事项

- Husky处理预提交检查
- 使用中文
- 如果存在已暂存的文件，则仅提交已暂存的文件
- 分析差异以获取拆分建议
- **切勿在提交中添加Claude签名**