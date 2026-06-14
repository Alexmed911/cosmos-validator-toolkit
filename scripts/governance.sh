#!/bin/bash
# Governance proposal watcher — alerts on new proposals and auto-votes
# Usage: ./governance.sh [--vote yes|no|abstain|no_with_veto]

BINARY="${BINARY:-gaiad}"
NODE="${NODE:-http://localhost:26657}"
KEY="${KEY:-validator}"
CHAIN_ID="${CHAIN_ID:-cosmoshub-4}"
AUTO_VOTE="${AUTO_VOTE:-}"
GAS_PRICES="${GAS_PRICES:-0.025uatom}"
STATE_FILE="/tmp/gov_last_proposal_${CHAIN_ID}"
TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
TELEGRAM_CHAT="${TELEGRAM_CHAT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vote) AUTO_VOTE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

send_alert() {
  local msg="$1"
  echo "[GOV] $msg"
  if [[ -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_CHAT" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT" \
      -d text="🗳️ GOVERNANCE\n\n${msg}" \
      -d parse_mode="HTML" > /dev/null
  fi
}

get_latest_proposal_id() {
  "$BINARY" query gov proposals \
    --node "$NODE" \
    --status voting_period \
    -o json 2>/dev/null | \
    jq -r '.proposals | sort_by(.id | tonumber) | last | .id // "0"'
}

vote_on_proposal() {
  local proposal_id="$1"
  local vote_option="${AUTO_VOTE:-yes}"

  echo "[GOV] Voting '$vote_option' on proposal #${proposal_id}..."
  "$BINARY" tx gov vote "$proposal_id" "$vote_option" \
    --from "$KEY" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --gas auto \
    --gas-adjustment 1.4 \
    --gas-prices "$GAS_PRICES" \
    --yes 2>&1 | tail -3
}

main() {
  local last_id=0
  [[ -f "$STATE_FILE" ]] && last_id=$(cat "$STATE_FILE")

  local latest_id
  latest_id=$(get_latest_proposal_id)

  if [[ "$latest_id" != "0" && "$latest_id" -gt "$last_id" ]]; then
    local title
    title=$("$BINARY" query gov proposal "$latest_id" --node "$NODE" -o json 2>/dev/null | \
      jq -r '.content.title // .title // "Unknown"')

    send_alert "New proposal #${latest_id} in voting period:\n<b>${title}</b>\n\nChain: ${CHAIN_ID}"

    echo "$latest_id" > "$STATE_FILE"

    if [[ -n "$AUTO_VOTE" ]]; then
      vote_on_proposal "$latest_id"
    fi
  else
    echo "[OK] No new proposals. Latest: #${latest_id}"
  fi
}

main
