# 🛡️ IP-Sentinel (分布式 IP 哨兵集群)

![Agent Installs](https://img.shields.io/endpoint?url=https://ip-sentinel-count.samanthaestime296.workers.dev/stats/agent)
![Master Commands](https://img.shields.io/endpoint?url=https://ip-sentinel-count.samanthaestime296.workers.dev/stats/master)
![License](https://img.shields.io/github/license/hotyue/IP-Sentinel)

> **一个极度轻量、零感知、支持中枢遥控的 VPS IP 自动化养护与区域纠偏引擎。**
> **💡 提示：如果本项目提升了您的节点稳定性，请点击右上角点亮 🌟 Star！您的支持是我们持续研发和维护指纹库的核心动力。**

> 🛡️ **安全加固版说明**：本地维护版已禁用公共网关与远程 OTA，远程控制改用随机高强度 `CONTROL_SECRET`，第三方 IPQuality 探针默认不再下载执行。安装器默认只使用本地已审计 checkout，远程数据/版本检查与安装计数遥测也默认关闭。部署前请先阅读 [SECURITY_HARDENING.md](./SECURITY_HARDENING.md)。

📢 官方战术交流频道: 🛰️ [IP-Sentinel Matrix](https://t.me/IP_Sentinel_Matrix)

专为解决 VPS IP 被 Google 等数据库错误定位到中国大陆/香港（俗称“送中”）等问题而生。IP-Sentinel 已从单机脚本全面跃升为 **Master-Agent 分布式架构**。它像影子一样潜伏在全球各地的服务器后台，通过高度拟真的真实用户行为为你默默积累 IP 权重，并允许你通过 Telegram 随时随地对整个舰队进行毫秒级“点名”与“遥控”。

## ✨ 核心极客特性 (Core Architecture)

- 📊 **深海声呐全维探针 (Deep Sea Sonar v4.0.4)**：内嵌强效正则去污的 JSON 提取引擎，无损展现免掩码的真实 IP 情报。聚合 Scamalytics、AbuseIPDB 等五大权威防欺诈库，精准嗅探代理/VPN特征、25端口及流媒体原生解锁状态，并自带 Google “送中”高危预警与污染趋势图谱。
- ⚡ **无损高并发引擎 (WAL Concurrency)**：司令部 SQLite 数据库全面激活 `WAL` (Write-Ahead Logging) 模式与毫秒级排队算法。即使对 500 台边缘节点发起全军总攻，也能完美规避 `database is locked` 与 Telegram `429` 拦截。
- 🪶 **抽脂级极简部署 (Zero-Bloat Native)**：全栈剔除第三方依赖，基于 Python3 原生标准库运行。安装强制注入 `--no-install-recommends` 防捆绑参数。无论是 128MB 内存的极简 NAT，还是 Alpine 游击队容器，均可如丝般顺滑运行。
- 🎛️ **扁平化指挥矩阵 (Flat Command Matrix)**：引入扁平化四级战区降维视图与双轨身份制。深度定制 Inline Keyboard 逃生舱交互，支持原位丝滑重绘 (In-place UI Edit)，实现毫秒级模块热启停与跨地域深海声呐投放。
- 🔒 **安全加固远程控制 (Hardened Remote Control)**：安全版永久熔断远程 OTA 与公共网关；Agent 只接受由随机 `CONTROL_SECRET` 签名的短时效 HMAC 指令。
- 🛡️ **SSOT 溯源与热更新装甲 (Smooth Upgrade Engine)**：全系脚本彻底消灭硬编码，动态抓取云端版本信标。自带状态机嗅探逻辑，即便是手动在老节点执行安装，也仅需回车瞬间完成配置继承与无损换代。
- 🗺️ **全球拓扑矩阵与活体词库 (Global Nexus)**：接入 GitHub Actions 云端兵工厂，每日静默同步全球各大区真实热搜榜单与高权重本土站点，让伪装行为永远贴合当地网络脉搏。
- 👻 **绝对时空对齐与高频错峰 (UTC-Seeded Scheduling)**：摒弃传统随机轮询，全栈强制接管底层时钟为**绝对 UTC 时间**。全舰队以 **20 分钟 (每日 72 次)** 的极高密度进行养护巡逻，叠加基于部署锚点的天然削峰与随机防并发休眠，完美化解十万级集群的“惊群效应”与 API 熔断。
- 🖧 **极速预检与三级容灾架构 (Fail-Fast & Fallback)**：底层引擎强力接管发包参数 (`--interface`) 的同时，创新引入 **4 秒极速预检 (Fail-Fast)** 雷达与**三级阶梯脱壳**机制。无论是纯 IPv6 孤岛、WARP 劫持死锁还是复杂 NAT 嵌套，系统均能瞬间避开网络黑洞，彻底杜绝探针假死与流量溢出。

**—— 💎 骨干基建特征 ——**
- 🏭 **全自动云端军工厂 (CI/CD Data Factory)**：依托 GitHub Actions 构建双轨无人值守流水线。**每月 1 日**批量锻造 4000+ 带有绝对物理分区的原生终端指纹库；**每日凌晨 (UTC)** 实时抓取全球各战区 Google 真实热搜榜单与本土骨干新闻 RSS。为前线舰队源源不断地输送最鲜活的伪装弹药。
- 🔒 **叹息之墙 (Zero-Trust HMAC)**：底层通讯引入 时间戳 + HMAC-SHA256 军用级动态签名。指令有效期仅 60 秒（阅后即焚），未授权请求直接触发系统级 403 物理熔断，彻底免疫中间人抓包与重放攻击。
- ☁️ **云端中枢 (Public Master)**：安全加固版已禁用官方公共网关，仅支持私有化 SQLite 分布式部署。
- 👁️‍🗨️ **玻璃房透明遥测 (Glasshouse)**：基于 Cloudflare Workers 的全透明计数中枢，绝对零隐私收集，仅作原子累加，底层网关源码全开源。

## 📂 项目架构 (Monorepo)

本项目采用企业级的“主从控制”与“冷热数据分离”双重架构：

```text
📦 IP-Sentinel
 ┣ 📂 .github/workflows/      # 🏭 自动化兵工厂：每月定时触发指纹生成的 CI/CD 流水线
 ┣ 📂 master/                 # 🧠 司令部：SQLite 存储 (含 ip_trend_log 趋势跟踪表)、TG 监听与 Webhook 调度
 ┣ 📂 core/                   # 🛡️ 边缘哨兵：Webhook 被动监听、哈希锚定执行引擎 (集成深海声呐探测模块)
 ┣ 📂 scripts/                # 🐍 兵工厂引擎：基于 Python 的多物理分区 UA 生成器
 ┣ 📂 data/                   # 🗂️ 全球数据规则库 (动态拓扑)
 ┃  ┣ 📜 map.json             # 🌍 全球区域大脑 (v3.5.0 大洲战区拓扑)
 ┃  ┣ 📂 regions/             # 🧊 冷数据：按 [国家/省州/城市] 深度细分的 LBS 锚点
 ┃  ┣ 📂 keywords/            # 🔥 热数据：按国家归类的动态搜索词库 (安全版默认关闭远程热更新)
 ┃  ┗ 📜 user_agents.txt      # 🔥 热数据：由兵工厂每月锻造的绝对坐标专属设备库
 ┣ 📜 version.txt             # 🚩 双端版本信标：Agent/Master 独立解耦的 KV 环境配置
 ┗ 📂 telemetry/              # 👁️‍🗨️ 玻璃房计划：Cloudflare Workers 透明计数器网关源码（安全版默认不上报）
```

## 🚀 极速部署 (Quick Start)
> 🛡️ **跨平台装甲支持**：Debian / Ubuntu / CentOS / RHEL / Alpine Linux / Arch Linux
系统现提供两种接入模式，请根据您的战术需求选择：

### 🔹 模式 A：私有独立模式 (全自主、强烈推荐)
适合追求绝对数据隐私与舰队最高控制权的领主。

> 🛡️ **安全版策略**：采用私有部署，远程控制可用；OTA 远程静默升级已禁用，升级必须通过 SSH 手动执行。

- **部署 Master (中枢大脑)**：找一台 VPS 作为司令部（仅需部署一台），执行：
- [官方部署教程](https://blog.iot-architect.com/engineering-practice/ip-sentinel-master-deployment-guide/)
```bash
git clone <your-reviewed-fork> IP-Sentinel
cd IP-Sentinel
sudo bash master/install_master.sh
```
- 部署 Agent (边缘哨兵)：在需要养护的机器上执行 Agent 脚本，安装时选择私有独立中枢，并分别输入您自建机器人的 [Token](https://blog.iot-architect.com/engineering-practice/create-private-telegram-bot-via-botfather) 以及您的个人 [Chat ID](https://blog.iot-architect.com/engineering-practice/get-telegram-personal-id-via-userinfobot) ：
- [官方部署教程](https://blog.iot-architect.com/engineering-practice/ip-sentinel-installation-and-upgrade-guide/)
```Bash
cd IP-Sentinel
sudo bash core/install.sh
```
- 激活节点：安装完成后，您的手机会收到一条 #REGISTER# 注册暗号，将其转发给您自己的机器人即可完成编队入库。

### 🔸 模式 B：官方公共模式
安全加固版已禁用官方公共模式。请使用私有 Master 与私有 Telegram Bot。

## 🆙 架构级无损热升级指引 (Upgrade Guide)

### 💻 SSH 终端平滑直装
如果需要升级 Master 或 Agent：

- 登录目标节点的 SSH 终端，进入已审计的本地仓库，再次运行 `core/install.sh` 或 `master/install_master.sh`。

- 安装引擎自带状态机嗅探逻辑，它会自动读取老旧数据，您只需一路回车，3 秒即可在本地完成配置继承、数据同步与新内核的无损覆盖热重载！

## 🗑️ 一键无痕卸载
如果你需要清理某个边缘节点，只需重新运行 `core/install.sh` 并选择 **[2]**，或直接在节点终端执行：

```Bash
bash /opt/ip_sentinel/core/uninstall.sh

```

## 🧓 传家宝老旧系统专用通道 (Debian 9)

如果你的小鸡系统版本过低（如 Debian 9），由于官方 APT 源已关闭且 Python 版本过旧，无法使用主线版本，请使用 **Legacy 兼容分支** 部署。
*(注意：该分支仅作基础维护，不享受新功能迭代，请尽可能升级你的系统)*

```bash
git checkout legacy
sudo bash core/install.sh
```

## 📡 战术联络 (Community)

如果你在使用过程中遇到任何疑难杂症，或者想围观大佬们的养护战报，欢迎加入我们的基地：
- Telegram 频道: [@IP_Sentinel_Matrix](https://t.me/IP_Sentinel_Matrix)

## 🤝 参与贡献 (Contributors)

**🌟 感谢以下所有为 IP-Sentinel 添砖加瓦的指挥官们！** 你们的每一次 PR 都在让这艘战舰的全球雷达覆盖得更广。

<a href="https://github.com/hotyue/IP-Sentinel/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hotyue/IP-Sentinel" alt="Contributors" />
</a>

如果你想为项目增加新的节点区域（例如德国、英国、大洋洲等），或者提供更丰富的本土化搜索词库，非常欢迎提交 Pull Request！


> - 感谢 @xykt 本项目IP质量检测采用[xykt/IPQuality](https://github.com/xykt/IPQuality) 脚本！

**💡 全球节点贡献规范：**
1. 在 `data/regions/国家代码/省州代码/` 目录下新增对应城市的配置 `.json`。
2. 在 `data/keywords/` 目录下新增或完善配套国家的词库 `kw_XX.txt`。
3. **最重要的一步：** 在 `data/map.json` 中登记你的国家、省州与城市信息。安装脚本将自动读取地图，在全球雷达中点亮你的节点！

## ⚠️ 免责声明

本项目仅供网络原理研究、个人 VPS 维护学习使用。请遵守当地法律法规及目标服务商的 TOS（服务条款），切勿用于恶意高频请求或任何非法用途。使用者需自行承担因不当使用造成的 IP 封禁或其他相关风险。

## 保持联系

[![Blog](https://img.shields.io/badge/Blog-个人博客-blue)](https://blog.iot-architect.com)

如果你觉得这个项目对你有帮助，欢迎关注我的个人博客，我会定期分享技术教程。


## Stargazers over time
[![Stargazers over time](https://starchart.cc/hotyue/IP-Sentinel.svg?variant=adaptive)](https://starchart.cc/hotyue/IP-Sentinel)
