# 🔐 Cosmos Validator Toolkit

> Production-grade scripts for Cosmos SDK validator operations — monitoring, alerting, automation, and maintenance.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cosmos SDK](https://img.shields.io/badge/Cosmos_SDK-Compatible-1B1E36?logo=cosmos)](https://cosmos.network)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash)](https://www.gnu.org/software/bash/)

## Features

- 🚨 **Missed block alerts** — Telegram notifications when your validator misses blocks
- 🔄 **Auto-restart** — systemd watchdog for node process recovery
- 📊 **Uptime tracker** — log and visualize validator uptime over time
- 💰 **Auto-claim rewards** — scheduled reward claiming and restaking
- 🗳️ **Governance watcher** — alerts for new proposals, auto-vote support
- 📦 **Snapshot manager** — automated snapshot download and apply
- 🔍 **Peer health check** — monitor peer connectivity and sync status

## Quick Start

```bash
git clone https://github.com/Alexmed911/cosmos-validator-toolkit
cd cosmos-validator-toolkit
cp configs/config.example.yaml configs/config.yaml
# Edit config.yaml with your node details
./scripts/setup.sh
```

## Scripts

| Script | Description |
|--------|-------------|
| `monitor.sh` | Main monitoring loop — blocks, peers, sync |
| `alert_missed.sh` | Telegram alert on missed blocks |
| `auto_restart.sh` | Systemd-aware process watchdog |
| `claim_rewards.sh` | Auto-claim and restake rewards |
| `governance.sh` | Watch for new proposals and alert |
| `snapshot_sync.sh` | Download latest snapshot and sync |
| `peer_check.sh` | Verify peer connections |
| `upgrade_watcher.sh` | Alert on upcoming chain upgrades |

## Supported Networks

Works with any Cosmos SDK chain. Tested on:
- Cosmos Hub · Osmosis · Sei · Injective · Persistence · Evmos
- Uptick · Archway · Neutron · dYdX · Celestia · Stargaze

## Config

```yaml
# configs/config.yaml
node:
  rpc: "http://localhost:26657"
  grpc: "http://localhost:9090"
  chain_id: "cosmoshub-4"
  validator_address: "cosmosvaloper1..."

alerts:
  telegram_bot_token: ""
  telegram_chat_id: ""
  missed_blocks_threshold: 5

rewards:
  auto_claim: true
  claim_interval_hours: 24
  restake: true
  min_claim_amount: "1000000uatom"
```

## Requirements

- `bash` 4+
- `curl`, `jq`
- Cosmos SDK node (any version)
- Telegram bot (for alerts)

## License

MIT — free to use and modify.
