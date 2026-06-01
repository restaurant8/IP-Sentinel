#!/bin/bash

# ==========================================================
# 脚本名称: install_master.sh
# 核心功能: Master 环境探底预装、无感 OTA 置换、持久化 SQLite 建库
# ==========================================================

# ----------------------------------------------------------
# [权限鉴权] 阻断非预期非最高权限的部署操作
# ----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo -e "\033[31m❌ 权限被拒绝: 部署 IP-Sentinel 需要最高系统权限。\033[0m"
  echo -e "💡 请切换到 root 用户 (执行 su root 或 sudo -i) 后重新运行指令。"
  exit 1
fi

SECURE_TMP=$(mktemp -d /tmp/ips_master_install.XXXXXX)
trap 'rm -rf "$SECURE_TMP"' EXIT HUP INT QUIT TERM

# ----------------------------------------------------------
# [环境预检] 中枢架构探测与系统级诊断
# ----------------------------------------------------------
is_systemd() {
    command -v systemctl >/dev/null 2>&1 || return 1
    [ -d /run/systemd/system ] || return 1
    return 0
}

get_os_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    else
        uname -srm
    fi
}

get_virt_info() {
    if grep -qaE 'docker|containerd|podman' /proc/1/cgroup 2>/dev/null || [ -f /.dockerenv ]; then
        echo "Docker/OCI Container"
    elif grep -qa container=lxc /proc/1/environ 2>/dev/null || [ -d /proc/vz ]; then
        echo "LXC/OpenVZ"
    elif command -v systemd-detect-virt >/dev/null 2>&1; then
        systemd-detect-virt
    else
        echo "Unknown/Bare Metal"
    fi
}

echo -e "\n======================================"
echo -e "📊 \033[36mIP-Sentinel 中枢靶机环境侦测\033[0m"
echo -e "--------------------------------------"
echo -e "OS 架构   : $(get_os_info)"
echo -e "虚拟化    : $(get_virt_info)"
if is_systemd; then
    echo -e "Init 系统 : systemd ✅"
else
    echo -e "Init 系统 : 非 systemd ⚠️ (将自动降维至看门狗模式)"
fi
echo -e "======================================\n"
sleep 1

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/hotyue/IP-Sentinel/main}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
[ -z "$SCRIPT_DIR" ] && SCRIPT_DIR="$(pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd)"
[ -z "$REPO_ROOT" ] && REPO_ROOT="$SCRIPT_DIR"
ALLOW_REMOTE_FETCH="${ALLOW_REMOTE_FETCH:-false}"
ALLOW_FLOATING_REMOTE="${ALLOW_FLOATING_REMOTE:-false}"

remote_fetch_allowed() {
    if [[ "$REPO_RAW_URL" =~ /(main|master)$ ]] && [ "$ALLOW_FLOATING_REMOTE" != "true" ]; then
        echo -e "\033[31m[SECURITY] Refusing floating remote URL: ${REPO_RAW_URL}. Pin REPO_RAW_URL to an audited commit/tag, or set ALLOW_FLOATING_REMOTE=true explicitly.\033[0m" >&2
        return 1
    fi
    return 0
}

fetch_repo_file() {
    local rel_path="$1"
    local dest_path="$2"
    local local_path="${REPO_ROOT}/${rel_path}"

    if [ -f "$local_path" ]; then
        cp -f "$local_path" "$dest_path"
        return 0
    fi

    if [ "$ALLOW_REMOTE_FETCH" == "true" ] && remote_fetch_allowed; then
        curl -fsSL --connect-timeout 10 --retry 3 "${REPO_RAW_URL}/${rel_path}" -o "$dest_path"
        return $?
    fi

    echo -e "\033[31m[SECURITY] Refusing to fetch ${rel_path} from a floating remote branch. Run from a complete local checkout, or set ALLOW_REMOTE_FETCH=true after auditing the source.\033[0m" >&2
    return 1
}

read_repo_version() {
    local key="$1"
    local version_file="${REPO_ROOT}/version.txt"

    if [ -f "$version_file" ]; then
        grep "^${key}=" "$version_file" | cut -d'=' -f2 | tr -d '[:space:]'
        return 0
    fi

    if [ "$ALLOW_REMOTE_FETCH" == "true" ] && remote_fetch_allowed; then
        (curl -fsSL --connect-timeout 5 --retry 2 "${REPO_RAW_URL}/version.txt" || curl -4 -fsSL --connect-timeout 5 --retry 2 "${REPO_RAW_URL}/version.txt") 2>/dev/null | grep "^${key}=" | cut -d'=' -f2 | tr -d '[:space:]'
    fi
}

# [链路容灾] 双栈冗余防抖抓取，确立本地态势版本号
TARGET_VERSION=$(read_repo_version "MASTER_VERSION")
TARGET_VERSION=${TARGET_VERSION:-"4.2.0"}

MASTER_DIR="/opt/ip_sentinel_master"
DB_FILE="${MASTER_DIR}/sentinel.db"

echo "========================================================"
echo "      🧠 欢迎使用 IP-Sentinel Master (控制中枢) v${TARGET_VERSION}"
echo "========================================================"

# ==========================================================
# [安全版] 拦截并拒绝云端 OTA 重构流
# ==========================================================
if [ "$SILENT_MASTER_OTA" == "true" ]; then
    echo -e "\n⛔ [安全熔断] 安全版已禁用 SILENT_MASTER_OTA。请通过 SSH 手动运行安装脚本升级。"
    exit 1
else
    echo -e "\n请选择操作:"
    echo "  1) 🚀 部署 Master 控制中枢"
    echo "  2) 🗑️ 一键卸载 Master 中枢"
    read -p "请输入选择 [1-2] (默认1): " ACTION_CHOICE

    ACTION_CHOICE=${ACTION_CHOICE:-1}

    if [ "$ACTION_CHOICE" == "2" ]; then
        echo -e "\n⏳ 正在拉取卸载程序..."
        fetch_repo_file "master/uninstall_master.sh" "${SECURE_TMP}/uninstall_master.sh"
        chmod +x "${SECURE_TMP}/uninstall_master.sh"
        bash "${SECURE_TMP}/uninstall_master.sh"
        rm -f "/tmp/uninstall_master.sh"
        exit 0
    fi

    # [态势传承] 平滑接管探查并保护库文件
    UPGRADE_MODE="false"
    KEEP_DB="true"

    if [ "$ACTION_CHOICE" == "1" ] && [ -f "${MASTER_DIR}/master.conf" ]; then
        echo -e "\n\033[33m💡 司令部雷达提示：检测到本机已部署过 Master 中枢。\033[0m"
        read -p "👉 是否按原配置直接进行平滑升级？(y/n, 默认y): " UPGRADE_CHOICE
        if [[ -z "$UPGRADE_CHOICE" || "$UPGRADE_CHOICE" =~ ^[Yy]$ ]]; then
            UPGRADE_MODE="true"
            read -p "👉 是否保留历史节点数据库 (SQLite)？(y/n, 默认y): " DB_CHOICE
            if [[ "$DB_CHOICE" =~ ^[Nn]$ ]]; then
                KEEP_DB="false"
            fi
            
            source "${MASTER_DIR}/master.conf"
            
            if grep -q "^MASTER_VERSION=" "${MASTER_DIR}/master.conf"; then
                sed -i "s/^MASTER_VERSION=.*/MASTER_VERSION=\"$TARGET_VERSION\"/" "${MASTER_DIR}/master.conf"
            else
                echo "MASTER_VERSION=\"$TARGET_VERSION\"" >> "${MASTER_DIR}/master.conf"
            fi
            
            echo -e "\033[32m✅ 已激活 [平滑升级模式]，版本已锚定为 v${TARGET_VERSION}...\033[0m"
        else
            echo -e "\033[33m🔄 您选择了重新配置，旧的中枢数据将被彻底抹除。\033[0m"
        fi
    fi
fi

# ----------------------------------------------------------
# [环境清洗] 执行装配前系统清理动作
# ----------------------------------------------------------
echo -e "\n⏳ 正在验证本地环境与数据..."

if [ "$UPGRADE_MODE" == "true" ]; then
    if [ "$KEEP_DB" == "false" ]; then
        rm -f "$DB_FILE" 2>/dev/null
        echo -e "🗑️ 历史节点数据库已按指令清空。"
    else
        echo -e "📦 历史节点数据库 (SQLite) 已绝密保留。"
    fi
else
    rm -rf "$MASTER_DIR" 2>/dev/null
fi

# ==========================================================
# [依赖装甲] 多分支环境极简包管理器适配策略
# ==========================================================
echo -e "\n[1/4] 正在探测核心依赖 (curl, jq, sqlite3, crontab, pgrep, openssl)..."

REQUIRED_CMDS=("curl" "jq" "sqlite3" "crontab" "pgrep" "openssl")
MISSING_CMDS=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
    echo "⏳ 发现缺失依赖: ${MISSING_CMDS[*]}，正在尝试自动补齐..."
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1
        apt-get install -y --no-install-recommends curl jq sqlite3 cron procps openssl >/dev/null 2>&1
        systemctl enable cron >/dev/null 2>&1 && systemctl start cron >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1 || command -v microdnf >/dev/null 2>&1; then
        PKG_MGR="yum"
        OPT_ARGS=""
        if command -v dnf >/dev/null 2>&1; then
            PKG_MGR="dnf"
            OPT_ARGS="--setopt=install_weak_deps=False"
        elif command -v microdnf >/dev/null 2>&1; then
            PKG_MGR="microdnf"
        fi
        
        echo -e "\033[90m   (正在安装 epel-release 扩展源，请稍候...)\033[0m"
        $PKG_MGR install -y epel-release >/dev/null 2>&1 || true
        
        echo -e "\033[90m   (正在拉取核心组件...)\033[0m"
        $PKG_MGR install -y $OPT_ARGS curl jq sqlite cronie procps-ng openssl
        systemctl enable crond >/dev/null 2>&1 && systemctl start crond >/dev/null 2>&1
    elif command -v apk >/dev/null 2>&1; then
        echo "Alpine 探测到系统类型为 Alpine Linux，正在执行轻量级安装..."
        apk add --no-cache curl jq sqlite cronie procps bash openssl || apk add --no-cache curl jq sqlite procps bash openssl
        mkdir -p /var/spool/cron/crontabs
        rc-update add crond default >/dev/null 2>&1
        service crond start >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm curl jq sqlite cronie procps-ng openssl >/dev/null 2>&1
        mkdir -p /root/.cache/crontab 2>/dev/null
        systemctl enable cronie >/dev/null 2>&1 && systemctl start cronie >/dev/null 2>&1
    else
        echo -e "\033[31m❌ 自动安装失败：系统未知的包管理器。\033[0m"
        echo -e "\033[33m⚠️ 请手动执行以下安装命令后重新运行本脚本：\033[0m"
        echo -e "  Debian/Ubuntu: \033[36mapt-get update && apt-get install -y --no-install-recommends curl jq sqlite3 cron procps openssl\033[0m"
        echo -e "  CentOS/RHEL:   \033[36myum install -y curl jq sqlite cronie procps-ng openssl\033[0m"
        echo -e "  Alpine Linux:  \033[36mapk add --no-cache curl jq sqlite cronie procps bash openssl\033[0m"
        echo -e "  Arch Linux:    \033[36mpacman -Sy curl jq sqlite cronie procps-ng openssl\033[0m"
        exit 1
    fi
    
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "\033[31m❌ 致命错误：核心命令 '$cmd' 仍未找到！\033[0m"
            echo -e "请手动修复您的包管理器源，或联系 VPS 供应商。"
            exit 1
        fi
    done
fi
echo -e "\033[32m✅ 基础环境检测通过。\033[0m"

mkdir -p "$MASTER_DIR"

# ==========================================================
# [配置总线] 构建交互与策略文件固化
# ==========================================================
if [ "$UPGRADE_MODE" == "false" ]; then
    echo -e "\n[2/4] 配置控制中枢机器人:"
    read -p "请输入 Telegram Bot Token: " RAW_TOKEN
    TG_TOKEN=$(echo "$RAW_TOKEN" | tr -cd 'a-zA-Z0-9_:-')
    while [ -z "$TG_TOKEN" ]; do
        read -p "⚠️ Token 不能为空或包含非法字符，请重新输入: " RAW_TOKEN
        TG_TOKEN=$(echo "$RAW_TOKEN" | tr -cd 'a-zA-Z0-9_:-')
    done
    
    echo -e "\n请选择您的部署环境身份:"
    echo "  1) 🛡️ 私有独立中枢 (默认推荐，安全版禁用 OTA)"
    echo "  2) ☁️ 官方公共网关 (安全版已禁用)"
    read -p "请输入选择 [1-2] (默认1): " GATEWAY_TYPE
    GATEWAY_TYPE=${GATEWAY_TYPE:-1}
    
    IS_OFFICIAL_GATEWAY="false"
    ENABLE_MASTER_OTA="false"
    ENABLE_INSTALL_TELEMETRY="false"
    if [ "$GATEWAY_TYPE" == "2" ]; then
        echo -e "\033[31m⛔ 安全版已禁用官方公共网关模式。请使用私有独立中枢。\033[0m"
        exit 1
    else
        echo -e "\n[2.1/4] 司令部自我进化授权"
        echo -e "🛡️ 安全版默认永久关闭司令部 OTA；中枢升级必须通过 SSH 手动执行。"
        ENABLE_MASTER_OTA="false"
    fi

    # [中枢身份生成] 提取宿主特征生成全局唯一标识
    MASTER_IP=$( (curl -4 -s -m 3 api.ip.sb/ip || curl -4 -s -m 3 ifconfig.me) 2>/dev/null | tr -d '[:space:]' )
    MASTER_HASH=$(echo "${MASTER_IP:-127.0.0.1}" | md5sum | cut -c 1-4 | tr 'a-z' 'A-Z')
    MASTER_NODE="$(hostname | tr -cd 'a-zA-Z0-9' | cut -c 1-10)-${MASTER_HASH}"
    
    echo -e "\n[2.2/4] 司令部展示别名设定 (用于面板区分多台 VPS)"
    echo -e "💡 系统底层的不可变主键为: \033[33m${MASTER_NODE}\033[0m"
    read -p "请输入中枢展示别名 (如'美西主控机', 回车使用默认): " CUSTOM_MASTER_ALIAS

    if [ -n "$CUSTOM_MASTER_ALIAS" ]; then
        MASTER_NODE_NAME=$(echo "$CUSTOM_MASTER_ALIAS" | tr -d '"'\''\`\$\|&;<>\n\r' | cut -c 1-20)
        [ -z "$MASTER_NODE_NAME" ] && MASTER_NODE_NAME="$MASTER_NODE"
    else
        MASTER_NODE_NAME="$MASTER_NODE"
    fi
    echo -e "✅ 已锁定司令部展示别名: \033[32m$MASTER_NODE_NAME\033[0m"

    cat > "${MASTER_DIR}/master.conf" << EOF
# IP-Sentinel Master 本地固化配置 (v${TARGET_VERSION})
MASTER_VERSION="$TARGET_VERSION"
MASTER_NODE_NAME="$MASTER_NODE_NAME"
TG_TOKEN="$TG_TOKEN"
DB_FILE="$DB_FILE"
MASTER_DIR="$MASTER_DIR"
IS_OFFICIAL_GATEWAY="$IS_OFFICIAL_GATEWAY"
ENABLE_MASTER_OTA="$ENABLE_MASTER_OTA"
ENABLE_REMOTE_VERSION_CHECK="false"
ENABLE_INSTALL_TELEMETRY="$ENABLE_INSTALL_TELEMETRY"
EOF
fi

if [ "$UPGRADE_MODE" == "true" ]; then
    if ! grep -q "^IS_OFFICIAL_GATEWAY=" "${MASTER_DIR}/master.conf"; then
        echo "IS_OFFICIAL_GATEWAY=\"false\"" >> "${MASTER_DIR}/master.conf"
    fi
    if ! grep -q "^ENABLE_MASTER_OTA=" "${MASTER_DIR}/master.conf"; then
        echo "ENABLE_MASTER_OTA=\"false\"" >> "${MASTER_DIR}/master.conf"
    else
        sed -i "s/^ENABLE_MASTER_OTA=.*/ENABLE_MASTER_OTA=\"false\"/" "${MASTER_DIR}/master.conf"
    fi
    if ! grep -q "^ENABLE_REMOTE_VERSION_CHECK=" "${MASTER_DIR}/master.conf"; then
        echo "ENABLE_REMOTE_VERSION_CHECK=\"false\"" >> "${MASTER_DIR}/master.conf"
    else
        sed -i "s/^ENABLE_REMOTE_VERSION_CHECK=.*/ENABLE_REMOTE_VERSION_CHECK=\"false\"/" "${MASTER_DIR}/master.conf"
    fi
    if ! grep -q "^ENABLE_INSTALL_TELEMETRY=" "${MASTER_DIR}/master.conf"; then
        echo "ENABLE_INSTALL_TELEMETRY=\"false\"" >> "${MASTER_DIR}/master.conf"
    else
        sed -i "s/^ENABLE_INSTALL_TELEMETRY=.*/ENABLE_INSTALL_TELEMETRY=\"false\"/" "${MASTER_DIR}/master.conf"
    fi
    ENABLE_INSTALL_TELEMETRY="false"
    # [热修复] 为老版本司令部平滑补齐中枢标识
    if ! grep -q "^MASTER_NODE_NAME=" "${MASTER_DIR}/master.conf"; then
        MASTER_IP=$( (curl -4 -s -m 3 api.ip.sb/ip || curl -4 -s -m 3 ifconfig.me) 2>/dev/null | tr -d '[:space:]' )
        MASTER_HASH=$(echo "${MASTER_IP:-127.0.0.1}" | md5sum | cut -c 1-4 | tr 'a-z' 'A-Z')
        MASTER_NODE_NAME="$(hostname | tr -cd 'a-zA-Z0-9' | cut -c 1-10)-${MASTER_HASH}"
        echo "MASTER_NODE_NAME=\"$MASTER_NODE_NAME\"" >> "${MASTER_DIR}/master.conf"
    fi
fi

# ----------------------------------------------------------
# [数据存储] 初始化 SQLite 表结构基线
# ----------------------------------------------------------
echo -e "\n[3/4] 正在初始化 SQLite 数据库表结构..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS nodes (
    chat_id TEXT,
    node_name TEXT,
    agent_ip TEXT,
    agent_port TEXT,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    region TEXT DEFAULT 'UNKNOWN',
    node_alias TEXT,
    enable_google TEXT DEFAULT 'true',
    enable_trust TEXT DEFAULT 'true',
    enable_ota TEXT DEFAULT 'false',
    control_secret TEXT DEFAULT '',
    PRIMARY KEY(chat_id, node_name)
);

CREATE TABLE IF NOT EXISTS ip_trend_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_name TEXT,
    check_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    scam_score INTEGER,
    goog_status TEXT,
    nf_status TEXT,
    gpt_status TEXT
);
EOF
echo "✅ 数据库创建成功: $DB_FILE"

chmod 600 "${MASTER_DIR}/master.conf"
chmod 600 "$DB_FILE"

# ==========================================================
# [原子交接] 防变砖双缓冲下载，确保执行层无断层覆写
# ==========================================================
echo -e "\n[4/4] 正在拉取新版司令部核心引擎..."

TMP_MASTER="${SECURE_TMP}/tg_master.sh"
fetch_repo_file "master/tg_master.sh" "$TMP_MASTER"

if [ ! -s "$TMP_MASTER" ]; then
    echo -e "\033[31m❌ 致命错误：中枢核心代码拉取失败！网络阻断或 GitHub Raw 异常。\033[0m"
    echo "🛡️ 防砖机制触发：已中止覆盖，旧版司令部仍在安全运行中。"
    rm -f "$TMP_MASTER"
    exit 1
fi

echo "⏳ 新引擎校验通过，正在抹杀旧版守护进程..."
if is_systemd; then
    systemctl kill --signal=SIGKILL ip-sentinel-master.service >/dev/null 2>&1 || true
    systemctl stop ip-sentinel-master.service >/dev/null 2>&1 || true
fi
pkill -9 -f "tg_master.sh" >/dev/null 2>&1 || true

mv "$TMP_MASTER" "${MASTER_DIR}/tg_master.sh"
chmod +x "${MASTER_DIR}/tg_master.sh"

if is_systemd; then
    echo "💡 检测到 Systemd 环境，正在部署原生守护服务..."
    
    cat > /etc/systemd/system/ip-sentinel-master.service << EOF
[Unit]
Description=IP-Sentinel Master Command Center Service
After=network.target

[Service]
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SyslogIdentifier=ip-sentinel
Type=simple
ExecStart=/bin/bash ${MASTER_DIR}/tg_master.sh
Restart=always
RestartSec=5
User=root
WorkingDirectory=${MASTER_DIR}
CPUSchedulingPolicy=idle
IOSchedulingClass=idle

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now ip-sentinel-master.service
    systemctl restart ip-sentinel-master.service
    
    crontab -l 2>/dev/null | grep -v "tg_master.sh" | crontab - >/dev/null 2>&1 || true
else
    echo "💡 未检测到 Systemd，回退到 Cron 看门狗调度模式..."
    crontab -l 2>/dev/null | grep -v "tg_master.sh" > "${SECURE_TMP}/cron_master" || true
    echo "* * * * * pgrep -f tg_master.sh >/dev/null || nohup bash ${MASTER_DIR}/tg_master.sh >/dev/null 2>&1 &" >> "${SECURE_TMP}/cron_master"
    [ -f "${SECURE_TMP}/cron_master" ] && crontab "${SECURE_TMP}/cron_master" 2>/dev/null
    
    pgrep -f tg_master.sh >/dev/null || { nohup bash "${MASTER_DIR}/tg_master.sh" >/dev/null 2>&1 & disown 2>/dev/null; }
fi

# ==========================================================
# [状态汇报] 根据操作场景分发回执
# ==========================================================
echo "========================================================"
if [ "$UPGRADE_MODE" == "true" ]; then
    echo "🎉 Master 控制中枢平滑热更新完成！"
    echo "🤖 新版中枢引擎已接管数据库，继续等待边缘节点汇报。"
else
    echo "🎉 Master 控制中枢部署完成！"
    echo "🤖 机器人现已开始全局接客，等待边缘节点注册。"
fi
echo "========================================================"

if [ "$UPGRADE_MODE" == "false" ]; then
    MASTER_COUNT=""
    if [ "${ENABLE_INSTALL_TELEMETRY:-false}" == "true" ]; then
        echo -e "\n📡 正在向开源社区汇报装机量 (完全匿名，不收集IP)..."
        MASTER_COUNT=$(curl -s -m 3 "https://ip-sentinel-count.samanthaestime296.workers.dev/ping/master" || echo "")
    fi

    if [ -n "$MASTER_COUNT" ] && [[ "$MASTER_COUNT" =~ ^[0-9]+$ ]]; then
        echo -e "\033[32m✅ 感谢您成为全球第 ${MASTER_COUNT} 名 IP-Sentinel 中枢管理者！\033[0m"
    else
        echo -e "\033[32m✅ 感谢您部署 IP-Sentinel 控制中枢！\033[0m"
    fi
fi

echo -e "\n========================================================"
echo -e "⭐ \033[33m开源不易，如果 IP-Sentinel 极大简化了您的多节点管理，请赐予我们一枚星标！\033[0m"
echo -e "💡 \033[32m您的每一颗 Star 都是我们持续迭代架构、开发 Web 视窗化控制台的动力源泉。\033[0m"
echo -e "👉 \033[36m\033[4m\033]8;;https://github.com/hotyue/IP-Sentinel\033\\点击此处直达 GitHub 仓库点亮 Star 🌟\033[0m\033]8;;\033\\"
echo -e "========================================================\n"
