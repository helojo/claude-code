# PowerShell 脚本用于 Windows 系统的工作目录初始化
# 支持 Windows 10/11 和 PowerShell 5.1 或更高版本

# 颜色定义
$RESET = [System.ConsoleColor]::White
$INFO = [System.ConsoleColor]::Blue
$SUCCESS = [System.ConsoleColor]::Green
$WARNING = [System.ConsoleColor]::Yellow
$ERROR = [System.ConsoleColor]::Red

# 日志函数
function Write-Log {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = $INFO
    )
    Write-Host "[INFO] " -ForegroundColor $INFO -NoNewline
    Write-Host $Message -ForegroundColor $Color
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "[SUCCESS] " -ForegroundColor $SUCCESS -NoNewline
    Write-Host $Message -ForegroundColor $RESET
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "[WARNING] " -ForegroundColor $WARNING -NoNewline
    Write-Host $Message -ForegroundColor $RESET
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor $ERROR -NoNewline
    Write-Host $Message -ForegroundColor $RESET
}

# 检查是否以管理员权限运行
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查是否在 Git 仓库中
function Test-GitRepo {
    if (-not (Test-Path ".git" -PathType Container)) {
        Write-LogError "当前目录不是 Git 仓库"
        Write-Log "请在 Git 仓库根目录中运行此脚本"
        exit 1
    }
}

# 检查命令是否存在
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# 设置 Git 钩子
function Setup-GitHooks {
    $HookFile = ".git\hooks\commit-msg"
    
    # 检查 commit-msg 钩子是否已存在
    if (Test-Path $HookFile -PathType Leaf) {
        Write-LogWarning "commit-msg 钩子已存在"
        Write-Log "文件路径: $HookFile"
        Write-Log "初始化失败，请手动备份并删除该文件后再试"
        exit 1
    }
    
    # 创建 .git\hooks 目录（如果不存在）
    $HookDir = ".git\hooks"
    if (-not (Test-Path $HookDir -PathType Container)) {
        New-Item -ItemType Directory -Path $HookDir | Out-Null
    }
    
    # 创建 commit-msg 钩子文件
    $HookContent = @'
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
'@
    
    # 将内容写入文件
    Set-Content -Path $HookFile -Value $HookContent -Encoding UTF8
    
    Write-LogSuccess "已创建 commit-msg 钩子文件: $HookFile"
}

# Windows 系统初始化
function Initialize-Windows {
    Write-Log "检测到 Windows 系统"
    
    # 检查包管理器
    if (Test-Command "choco") {
        Write-Log "检测到 Chocolatey 包管理器"
        # 可以在这里添加 Chocolatey 相关的初始化逻辑
    } else {
        Write-LogWarning "未检测到 Chocolatey 包管理器"
    }
    
    if (Test-Command "winget") {
        Write-Log "检测到 winget 包管理器"
        # 可以在这里添加 winget 相关的初始化逻辑
    } else {
        Write-LogWarning "未检测到 winget 包管理器"
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host "用法: .\init-workspace.ps1 [选项]"
    Write-Host ""
    Write-Host "选项:"
    Write-Host "  -h, --help     显示此帮助信息"
    Write-Host ""
    Write-Host "此脚本将初始化工作目录并设置 Git commit-msg 钩子。"
}

# 主函数
function Main {
    param(
        [string]$Argument
    )
    
    # 解析命令行参数
    switch ($Argument) {
        {($_ -eq "-h") -or ($_ -eq "--help")} {
            Show-Help
            exit 0
        }
        "" {
            # 没有参数，继续执行初始化
        }
        default {
            Write-LogError "未知参数: $Argument"
            Show-Help
            exit 1
        }
    }
    
    # 检查是否在 Git 仓库中
    Test-GitRepo
    
    # Windows 系统初始化
    Initialize-Windows
    
    # 设置 Git 钩子
    Setup-GitHooks
    
    Write-LogSuccess "工作目录初始化成功！"
    Write-Log "该钩子将确保所有提交信息遵循团队规范"
}

# 执行主函数
Main -Argument $args[0]