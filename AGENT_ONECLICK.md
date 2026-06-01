# Agent One-Click Deploy

The hardened Agent installer supports a non-interactive mode:

```bash
sudo env \
  IPS_TG_TOKEN='123456:YOUR_BOT_TOKEN' \
  IPS_CHAT_ID='123456789' \
  IPS_REGION='US/CA/Los_Angeles' \
  IPS_ALIAS='la-agent-1' \
  IPS_AGENT_PORT='35271' \
  IPS_OPEN_FIREWALL='true' \
  bash -c 'set -e
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y --no-install-recommends git curl jq cron procps python3 openssl bash
elif command -v yum >/dev/null 2>&1; then
  yum install -y git curl jq cronie procps-ng python3 openssl bash
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y git curl jq cronie procps-ng python3 openssl bash
elif command -v apk >/dev/null 2>&1; then
  apk add --no-cache git curl jq cronie procps python3 openssl bash
fi
git clone --depth 1 https://github.com/restaurant8/IP-Sentinel.git /opt/IP-Sentinel 2>/dev/null || git -C /opt/IP-Sentinel pull --ff-only
cd /opt/IP-Sentinel
bash core/install.sh --agent-oneclick'
```

Required variables:

- `IPS_TG_TOKEN`: your private Telegram bot token.
- `IPS_CHAT_ID`: your Telegram chat ID.
- `IPS_REGION`: deployment region in `COUNTRY/STATE/CITY` format from `data/map.json`.

Optional variables:

- `IPS_ALIAS`: display name in the Master panel.
- `IPS_AGENT_PORT`: fixed Agent webhook port. If omitted, a random high port is selected.
- `IPS_PUBLIC_IP`: manually pin the public IP when auto-detection is wrong.
- `IPS_IP_VERSION`: set to `6` to prefer IPv6 when available. Defaults to IPv4.
- `IPS_OPEN_FIREWALL`: set to `true` to attempt local firewall opening.

Common region examples:

```text
US/CA/Los_Angeles
US/NY/New_York
SG/Default/Singapore
JP/Default/Tokyo
HK/Default/HongKong
```

After installation, open the selected TCP port in the cloud provider security group and forward the `#REGISTER#...` message to your private Master bot.
