# init-workspace
当用户在新项目中执行 `/init-workspace` 命令时，应检查当前目录是否存在 `init-workspace` 脚本文件。如果存在，则执行该脚本以初始化工作目录并设置 Git commit-msg 钩子；如果不存在，则提示用户脚本不存在。