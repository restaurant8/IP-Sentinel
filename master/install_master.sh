#!/bin/bash
# ==========================================================
# 脚本名称: install_master.sh (v4.3.0 终极模块化引导入口)
# 核心功能: 极简引导入口。包含 Ctrl+C 优雅中断，采用物理文件执行规避管道污染
# ==========================================================

# [中断防护] 捕获 Ctrl+C 并执行优雅清理
cleanup_and_exit() {
    echo -e "\n\n\033[33m⚠️ 检测到中断信号 (Ctrl+C)，安装操作已被手动中止。\033[0m"
    echo -e "🧹 正在清理临时沙盒文件..."
    rm -rf "$SECURE_TMP" 2>/dev/null
    exit 1
}
trap cleanup_and_exit INT QUIT TERM
trap 'rm -rf "$SECURE_TMP" 2>/dev/null' EXIT HUP

if [ "$EUID" -ne 0 ]; then
  echo -e "\033[31m❌ 权限被拒绝: 部署 IP-Sentinel 需要最高系统权限。\033[0m"
  echo -e "💡 请切换到 root 用户 (执行 su root 或 sudo -i) 后重新运行指令。"
  exit 1
fi

SECURE_TMP=$(mktemp -d /tmp/ips_master_install.XXXXXX)
REPO_RAW_URL="https://raw.githubusercontent.com/hotyue/IP-Sentinel/main"

echo -e "\n⏳ 正在拉取 IP-Sentinel Master v4.3.0 安装引擎..."

# 仅拉取编排大管家
curl -fsSL --connect-timeout 10 --retry 3 "${REPO_RAW_URL}/install/build_master.sh" -o "${SECURE_TMP}/build_master.sh"

if [ ! -s "${SECURE_TMP}/build_master.sh" ]; then
    echo -e "\033[31m❌ 致命错误：中枢安装引擎拉取失败！\033[0m"
    exit 1
fi

export SECURE_TMP
export REPO_RAW_URL

# 【核心解法】不再使用 exec 劫持或 source 嵌套
# 直接以子进程物理文件方式运行，这样终端交互 (TTY) 将自然纯净，毫无污染
chmod +x "${SECURE_TMP}/build_master.sh"
bash "${SECURE_TMP}/build_master.sh"

# 透传子进程的退出状态码
exit $?
