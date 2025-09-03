#!/usr/bin/env bash

# 跨平台工作目录初始化脚本
# 支持 Linux、macOS 和 Windows (WSL)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查操作系统类型
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS_NAME="Linux";;
        Darwin*)    OS_NAME="macOS";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) 
                    OS_NAME="Windows";;
        *)          OS_NAME="UNKNOWN";;
    esac
    echo "$OS_NAME"
}

# 检查是否在 Git 仓库中
check_git_repo() {
    if [ ! -d ".git" ]; then
        log_error "当前目录不是 Git 仓库"
        log "请在 Git 仓库根目录中运行此脚本"
        exit 1
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 设置 Git 钩子
setup_git_hooks() {
    local HOOK_FILE=".git/hooks/commit-msg"
    
    # 检查 commit-msg 钩子是否已存在
    if [ -f "$HOOK_FILE" ]; then
        log_warning "commit-msg 钩子已存在"
        log "文件路径: $HOOK_FILE"
        log "初始化失败，请手动备份并删除该文件后再试"
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

# 定义允许的提交类型列表（支持表情符号前缀）
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

# 定义表情符号映射
EMOJI_MAP=(
    "✨ feat"
    "🐛 fix"
    "📝 docs"
    "💄 style"
    "♻️ refactor"
    "⚡ perf"
    "✅ test"
    "🔧 chore"
    "🚀 ci"
    "🚨 warnings"
    "🔒️ security"
    "🚚 move"
    "🏗️ architecture"
    "➕ add-dep"
    "➖ remove-dep"
    "🌱 seed"
    "🧑‍💻 dx"
    "🏷️ types"
    "👔 business"
    "🚸 ux"
    "🩹 minor-fix"
    "🥅 errors"
    "🔥 remove"
    "🎨 structure"
    "🚑️ hotfix"
    "🎉 init"
    "🔖 release"
    "🚧 wip"
    "💚 ci-fix"
    "📌 pin-deps"
    "👷 ci-build"
    "📈 analytics"
    "✏️ typos"
    "⏪️ revert"
    "📄 license"
    "💥 breaking"
    "🍱 assets"
    "♿️ accessibility"
    "💡 comments"
    "🗃️ db"
    "🔊 logs"
    "🔇 remove-logs"
    "🙈 gitignore"
    "📸 snapshots"
    "⚗️ experiment"
    "🚩 flags"
    "💫 animations"
    "⚰️ dead-code"
    "🦺 validation"
    "✈️ offline"
)

# 将类型数组转换为一个用于正则表达式的字符串，格式为 (type1|type2|...)
TYPES_REGEX=$(printf "|%s" "${VALID_TYPES[@]}")
TYPES_REGEX=${TYPES_REGEX:1} # 移除开头的 "|"

# 定义完整的提交信息格式正则表达式
# 格式: <type>: <subject> 或 <emoji> <type>: <subject>
# - 必须以一个有效的类型开头（可选表情符号前缀）
# - 类型后面必须跟一个冒号和一个空格
# - 冒号和空格后必须有描述内容
COMMIT_PATTERN="^((✨|🐛|📝|💄|♻️|⚡|✅|🔧|🚀|🚨|🔒️|🚚|🏗️|➕|➖|🌱|🧑‍💻|🏷️|👔|🚸|🩹|🥅|🔥|🎨|🚑️|🎉|🔖|🚧|💚|📌|👷|📈|✏️|⏪️|📄|💥|🍱|♿️|💡|🗃️|🔊|🔇|🙈|📸|⚗️|🚩|💫|⚰️|🦺|✈️) )?($TYPES_REGEX): .+$"

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
    echo "  <类型>: <主题> 或 <表情符号> <类型>: <主题>"
    echo ""
    echo "例如："
    echo "  feat: 新增用户登录功能"
    echo "  ✨ feat: 新增用户登录功能"
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
    echo "请修改您的提交信息。"
    echo "--------------------------------------------------------------------------------"
    
    # 退出并返回错误码 1，这将阻止本次提交
    exit 1
fi

# 如果验证通过，正常退出
exit 0
EOF
    
    # 给钩子文件添加可执行权限 (仅在非Windows系统上)
    if [[ "$(detect_os)" != "Windows" ]]; then
        chmod +x "$HOOK_FILE"
    fi
    
    log_success "已创建 commit-msg 钩子文件: $HOOK_FILE"
}

# Linux 系统初始化
init_linux() {
    log "检测到 Linux 系统"
    
    # 检测发行版和包管理器
    if command_exists apt; then
        log "检测到基于 Debian 的系统 (apt)"
        # 可以在这里添加 apt 相关的初始化逻辑
    elif command_exists yum; then
        log "检测到基于 Red Hat 的系统 (yum)"
        # 可以在这里添加 yum 相关的初始化逻辑
    elif command_exists dnf; then
        log "检测到基于 Fedora 的系统 (dnf)"
        # 可以在这里添加 dnf 相关的初始化逻辑
    elif command_exists pacman; then
        log "检测到基于 Arch 的系统 (pacman)"
        # 可以在这里添加 pacman 相关的初始化逻辑
    else
        log_warning "未识别的包管理器"
    fi
}

# macOS 系统初始化
init_macos() {
    log "检测到 macOS 系统"
    
    # 检查是否安装了 Homebrew
    if command_exists brew; then
        log "检测到 Homebrew"
        # 可以在这里添加 Homebrew 相关的初始化逻辑
    else
        log_warning "未检测到 Homebrew，建议安装以方便包管理"
    fi
}

# Windows 系统初始化 (WSL)
init_windows() {
    log "检测到 Windows 系统 (WSL)"
    # WSL 环境下的初始化逻辑可以在这里添加
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "此脚本将初始化工作目录并设置 Git commit-msg 钩子。"
}

# 主函数
main() {
    # 解析命令行参数
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        "")
            # 没有参数，继续执行初始化
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
    
    # 检查是否在 Git 仓库中
    check_git_repo
    
    # 检测操作系统
    OS=$(detect_os)
    
    # 根据操作系统执行相应的初始化逻辑
    case "$OS" in
        "Linux")
            init_linux
            ;;
        "macOS")
            init_macos
            ;;
        "Windows")
            init_windows
            ;;
        *)
            log_warning "未知操作系统: $OS"
            ;;
    esac
    
    # 设置 Git 钩子
    setup_git_hooks
    
    log_success "工作目录初始化成功！"
    log "该钩子将确保所有提交信息遵循团队规范"
}

# 执行主函数
main "$@"