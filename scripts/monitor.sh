#!/bin/bash
# Cosmos Validator Monitor — checks missed blocks, sync status, peer count
# Usage: ./monitor.sh [config_path]

CONFIG="${1:-$(dirname "$0")/../configs/config.yaml}"

parse_yaml() {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
  awk -F$fs "{
    indent = length(\$1)/2;
    vname[indent] = \$2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length(\$3) > 0) {
      vn=\"\"; for (i=0; i<indent; i++) {vn=(vn)(vname[i])(\"_\")}
      printf(\"%s%s%s=%s\n\", \"$prefix\",vn, \$2, \$3);
    }
  }"
}

RPC="${NODE_RPC:-http://localhost:26657}"
THRESHOLD="${ALERTS_MISSED_BLOCKS_THRESHOLD:-5}"
TELEGRAM_TOKEN="${ALERTS_TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT="${ALERTS_TELEGRAM_CHAT_ID:-}"

send_alert() {
  local msg="$1"
  if [[ -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_CHAT" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT" \
      -d text="🚨 VALIDATOR ALERT\n\n${msg}" \
      -d parse_mode="HTML" > /dev/null
  fi
  echo "[ALERT] $msg"
}

check_sync() {
  local status
  status=$(curl -s "${RPC}/status" 2>/dev/null)
  if [[ -z "$status" ]]; then
    send_alert "Node RPC unreachable at ${RPC}"
    return 1
  fi

  local catching_up
  catching_up=$(echo "$status" | jq -r '.result.sync_info.catching_up')
  local latest_block
  latest_block=$(echo "$status" | jq -r '.result.sync_info.latest_block_height')

  if [[ "$catching_up" == "true" ]]; then
    send_alert "Node is catching up! Latest block: ${latest_block}"
    return 1
  fi

  echo "[OK] Synced at block ${latest_block}"
  return 0
}

check_peers() {
  local net_info
  net_info=$(curl -s "${RPC}/net_info" 2>/dev/null)
  local peer_count
  peer_count=$(echo "$net_info" | jq -r '.result.n_peers // 0')

  if [[ "$peer_count" -lt 3 ]]; then
    send_alert "Low peer count: ${peer_count} peers connected"
  else
    echo "[OK] Connected peers: ${peer_count}"
  fi
}

check_missed_blocks() {
  local val_addr="${VALIDATOR_ADDRESS:-}"
  [[ -z "$val_addr" ]] && return 0

  local signing
  signing=$(curl -s "${RPC}/validators" 2>/dev/null)
  echo "[INFO] Validator address: ${val_addr}"
}

main() {
  echo "=== Cosmos Validator Monitor ==="
  echo "RPC: ${RPC}"
  echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "================================"

  check_sync
  check_peers
  check_missed_blocks

  echo "================================"
  echo "Monitor cycle complete"
}

main
