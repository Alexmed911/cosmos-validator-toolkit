#!/bin/bash
# Auto-claim and restake validator rewards
# Usage: ./claim_rewards.sh <chain_binary> <key_name> <validator_address> <chain_id>

BINARY="${1:-gaiad}"
KEY="${2:-validator}"
VAL_ADDR="${3:?Validator address required}"
CHAIN_ID="${4:?Chain ID required}"
NODE="${NODE:-http://localhost:26657}"
MIN_CLAIM="${MIN_CLAIM:-1000000}"
DENOM="${DENOM:-uatom}"
GAS_PRICES="${GAS_PRICES:-0.025uatom}"
RESTAKE="${RESTAKE:-true}"

log() { echo "[$(date -u '+%H:%M:%S')] $*"; }

get_rewards() {
  local del_addr
  del_addr=$("$BINARY" keys show "$KEY" -a 2>/dev/null)
  if [[ -z "$del_addr" ]]; then
    log "ERROR: Could not get delegator address for key '$KEY'"
    return 1
  fi

  local rewards
  rewards=$("$BINARY" query distribution rewards "$del_addr" "$VAL_ADDR" \
    --node "$NODE" -o json 2>/dev/null | \
    jq -r --arg denom "$DENOM" '.rewards[] | select(.denom==$denom) | .amount | split(".")[0]')

  echo "${rewards:-0}"
}

claim_and_restake() {
  local del_addr
  del_addr=$("$BINARY" keys show "$KEY" -a 2>/dev/null)
  local amount
  amount=$(get_rewards)

  log "Pending rewards: ${amount} ${DENOM}"

  if [[ "$amount" -lt "$MIN_CLAIM" ]]; then
    log "Below minimum claim threshold (${MIN_CLAIM} ${DENOM}), skipping"
    return 0
  fi

  log "Claiming rewards from ${VAL_ADDR}..."
  "$BINARY" tx distribution withdraw-rewards "$VAL_ADDR" \
    --from "$KEY" \
    --commission \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --gas auto \
    --gas-adjustment 1.4 \
    --gas-prices "$GAS_PRICES" \
    --yes 2>&1 | tail -5

  if [[ "$RESTAKE" == "true" ]]; then
    log "Waiting 10s before restaking..."
    sleep 10

    log "Delegating ${amount} ${DENOM} to ${VAL_ADDR}..."
    "$BINARY" tx staking delegate "$VAL_ADDR" "${amount}${DENOM}" \
      --from "$KEY" \
      --chain-id "$CHAIN_ID" \
      --node "$NODE" \
      --gas auto \
      --gas-adjustment 1.4 \
      --gas-prices "$GAS_PRICES" \
      --yes 2>&1 | tail -5
  fi
}

log "=== Auto-Claim Rewards ==="
log "Chain: ${CHAIN_ID}"
log "Validator: ${VAL_ADDR}"
claim_and_restake
log "Done"
