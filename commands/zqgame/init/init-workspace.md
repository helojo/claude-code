# 工作目录初始化脚本

此脚本用于初始化工作目录，自动设置 Git commit-msg 钩子以确保提交信息格式符合规范。

## 使用方法

```bash
# 执行初始化脚本
./init-workspace.sh
```

## 功能说明

1. 检查 `.git/hooks/commit-msg` 文件是否存在
2. 如果不存在，则创建该文件并设置适当的权限
3. 如果已存在，则提示用户初始化失败并说明原因
4. 确保钩子脚本具有可执行权限

## 脚本内容

创建 `init-workspace.sh` 文件：

```bash
#!/usr/bin/env bash

# 定义颜色以便输出更友好的提示信息
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo -e "${RED}错误: 当前目录不是 Git 仓库${NC}"
    echo "请在 Git 仓库根目录中运行此脚本"
    exit 1
fi

# 定义 commit-msg 钩子文件路径
HOOK_FILE=".git/hooks/commit-msg"

# 检查 commit-msg 钩子是否已存在
if [ -f "$HOOK_FILE" ]; then
    echo -e "${YELLOW}警告: commit-msg 钩子已存在${NC}"
    echo "文件路径: $HOOK_FILE"
    echo "初始化失败，请手动备份并删除该文件后再试"
    exit 1
fi

# 创建 .git/hooks 目录（如果不存在）
mkdir -p ".git/hooks"

# 创建 commit-msg 钩子文件
cat > "$HOOK_FILE" << 'EOF'
#!/usr/bin/env bash

# 获取提交信息文件的路径
COMMIT_MSG_FILE=$1

# 读取提交信息的第一行
FIRST_LINE=$(head -n 1 "$COMMIT_MSG_FILE")

# 定义允许的提交类型列表
VALID_TYPES=(
    "feat"      # 新功能
    "fix"       # 修复问题
    "docs"      # 文档更新
    "style"     # 代码格式
    "refactor"  # 代码重构
    "perf"      # 性能优化
    "test"      # 添加或更新测试
    "build"     # 构建系统或外部依赖项的更改
    "ci"        # 持续集成相关的变动
    "chore"     # 其他不修改 src 或测试文件的更改
    "revert"    # 回滚某次提交
)

# 将类型数组转换为一个用于正则表达式的字符串，格式为 (type1|type2|...)
TYPES_REGEX=$(printf "|%s" "${VALID_TYPES[@]}")
TYPES_REGEX=${TYPES_REGEX:1} # 移除开头的 "|"

# 定义完整的提交信息格式正则表达式
# 格式: <type>: <subject>
# - 必须以一个有效的类型开头
# - 类型后面必须跟一个冒号和一个空格
# - 冒号和空格后必须有描述内容
COMMIT_PATTERN="^($TYPES_REGEX): .+$"

# 忽略 Merge 和 Rebase 等自动生成的提交信息
if [[ "$FIRST_LINE" =~ ^Merge || "$FIRST_LINE" =~ ^Rebase || "$FIRST_LINE" =~ ^fixup! || "$FIRST_LINE" =~ ^squash! ]]; then
    echo "Commit message is a merge, rebase, or squash, skipping validation."
    exit 0
fi

# 使用正则表达式验证提交信息
if ! [[ "$FIRST_LINE" =~ $COMMIT_PATTERN ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "ERROR: 无效的提交信息格式。"
    echo "您的提交信息没有遵循团队的提交规范。"
    echo ""
    echo "正确的格式应该是："
    echo "  <类型>: <主题>"
    echo ""
    echo "例如："
    echo "  feat: 新增用户登录功能"
    echo ""
    echo "允许的 <类型> 包括:"
    echo "  feat     - 新功能"
    echo "  fix      - 修复问题"
    echo "  docs     - 文档更新"
    echo "  style    - 代码格式"
    echo "  refactor - 代码重构"
    echo "  perf     - 性能优化"
    echo "  test     - 添加或更新测试"
    echo "  build    - 构建系统或外部依赖项的更改"
    echo "  ci       - 持续集成相关的变动"
    echo "  chore    - 其他不修改 src 或测试文件的更改"
    echo "  revert   - 回滚某次提交"
    echo ""
    echo "您的提交信息第一行是："
    echo "  ${FIRST_LINE}"
    echo ""
    echo "--------------------------------------------------------------------------------"
    
    # 退出并返回错误码 1，这将阻止本次提交
    exit 1
fi

# 如果验证通过，正常退出
exit 0
EOF

# 给钩子文件添加可执行权限
chmod +x "$HOOK_FILE"

# 输出成功信息
echo -e "${GREEN}工作目录初始化成功！${NC}"
echo "已创建 commit-msg 钩子文件: $HOOK_FILE"
echo "该钩子将确保所有提交信息遵循团队规范"