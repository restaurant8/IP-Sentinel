# IP-Sentinel Hardened Build

This fork changes the project to a safer default posture. It is not a guarantee of perfect security, but it removes the highest-risk defaults found in the upstream workflow.

## Security Defaults

- Public gateway mode is disabled. Use a private Telegram bot and private Master only.
- Remote OTA is disabled for Agent and Master. Upgrade over SSH after reviewing the diff.
- Agent command authentication uses a randomly generated `CONTROL_SECRET`, not `CHAT_ID`; signed requests cover both the route and action parameters.
- Legacy nodes without `CONTROL_SECRET` must re-register before Master can send commands.
- Installers copy scripts and data from the local checkout by default. Floating-branch remote fetches are refused unless explicitly allowed.
- Remote data/version checks, install telemetry, public gateway mode, and third-party IP quality probing are disabled by default.
- Third-party IP quality probing requires a locally audited `ip_probe.sh`; automatic third-party downloads require an additional explicit override.

## Manual Upgrade Policy

Do not run floating-branch installers such as:

```bash
curl -fsSL https://raw.githubusercontent.com/hotyue/IP-Sentinel/main/core/install.sh | sudo bash
```

Instead, clone or fetch a reviewed commit, inspect the changes, then run the local script:

```bash
git clone <your-reviewed-fork> IP-Sentinel
cd IP-Sentinel
sudo bash core/install.sh
```

For Master:

```bash
sudo bash master/install_master.sh
```

If you intentionally need remote fetches, pin `REPO_RAW_URL` to an audited commit or tag and set:

```bash
ALLOW_REMOTE_FETCH=true
REPO_RAW_URL="https://raw.githubusercontent.com/<owner>/<repo>/<audited-commit>"
```

Fetching from `main` or `master` is still blocked unless `ALLOW_FLOATING_REMOTE=true` is also set.

## Optional Third-Party Probe

The IP quality probe remains available only as an explicit opt-in. Before enabling it, audit the exact script that will be executed:

```bash
curl -fsSL https://raw.githubusercontent.com/xykt/IPQuality/main/ip.sh -o /tmp/ipquality.sh
less /tmp/ipquality.sh
sha256sum /tmp/ipquality.sh
```

Only after accepting that risk, install the reviewed local copy and enable the module:

```bash
sudo install -m 700 /tmp/ipquality.sh /opt/ip_sentinel/core/ip_probe.sh
ENABLE_THIRD_PARTY_PROBE="true"
```

The updater and module will not auto-download the third-party script unless `ALLOW_THIRD_PARTY_PROBE_DOWNLOAD="true"` is also set.

## Optional Network Features

These remain off by default:

```bash
ENABLE_REMOTE_DATA_UPDATES="false"
ENABLE_REMOTE_VERSION_CHECK="false"
ENABLE_INSTALL_TELEMETRY="false"
```

Turn them on only after deciding the privacy and supply-chain tradeoff is acceptable. For remote data/version checks, prefer a pinned `REPO_RAW_URL`.

## Re-register Existing Nodes

Existing nodes created before this hardened build do not have a strong control secret in the Master database. Re-run the hardened Agent installer and send the new `#REGISTER#` message to the private Master bot.
