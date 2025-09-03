@echo off
:: Windows 批处理脚本作为 init-workspace 的入口点
:: 自动检测并选择适当的执行环境

:: 设置颜色输出支持
@echo off
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%" GEQ "10.0" (
    :: Windows 10 及以上版本支持 VT100 转义序列
    reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
)

:: 设置标题
title 工作目录初始化

:: 显示启动信息
echo [INFO] 正在初始化工作目录...
echo.

:: 检查是否在 Git 仓库中
if not exist ".git" (
    echo [ERROR] 当前目录不是 Git 仓库
    echo [INFO] 请在 Git 仓库根目录中运行此脚本
    echo.
    echo 按任意键退出...
    pause >nul
    exit /b 1
)

:: 检测可用的执行环境并按优先级执行
echo [INFO] 检测可用的执行环境...

:: 检查 PowerShell 是否可用
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] 检测到 PowerShell，正在启动 PowerShell 脚本...
    powershell -ExecutionPolicy Bypass -File "%~dp0init-workspace.ps1" %*
    goto :end
)

:: 如果没有找到合适的执行环境
echo [ERROR] 未找到合适的执行环境
echo [INFO] 请确保已安装 PowerShell 5.1 或更高版本
echo.
echo 按任意键退出...
pause >nul
exit /b 1

:end
echo.
echo [SUCCESS] 工作目录初始化完成！
echo.
echo 按任意键退出...
pause >nul