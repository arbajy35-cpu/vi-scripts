#!/usr/bin/env bash
# 🔥 VI – GitHub Actions Cache Cleaner – FINAL TERMUX-SAFE
# Author: BLACKWATCHER BL
# Mobile/Termux friendly, safe, automatic list & dry-run
# Default repo: arbajy35-cpu/VI

set -euo pipefail

# ===== CONFIG =====
: "${GITHUB_TOKEN:?❌ GITHUB_TOKEN missing (needs Actions: Read & Write)}"

DEFAULT_USER="arbajy35-cpu"
DEFAULT_REPO="VI"
API_BASE="https://api.github.com/repos/$DEFAULT_USER/$DEFAULT_REPO/actions/caches"

# ===== FLAGS =====
DRY=true       # safe default
FORCE=false    # only with --force triggers actual delete
PER_PAGE=100
RETRY=3

# ===== COLORS =====
RED="\033[1;31m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"
CYAN="\033[1;36m"; MAGENTA="\033[1;35m"; RESET="\033[0m"

AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")

# ===== SAFE START MESSAGE =====
echo -e "${CYAN}🔎 Checking GitHub Actions caches for repo: $DEFAULT_USER/$DEFAULT_REPO${RESET}"

# ===== FETCH ALL CACHES =====
ALL=()
PAGE=1
while :; do
  for ((i=1;i<=RETRY;i++)); do
    RESP=$(curl -fsS "${AUTH[@]}" "$API_BASE?per_page=$PER_PAGE&page=$PAGE" || echo "")
    [[ -n "$RESP" ]] && break || sleep 2
  done

  # ⚡ Termux-safe COUNT handling
  COUNT=$(echo "$RESP" | grep -c '"id":' || echo 0)
  COUNT=$(echo "$COUNT" | tr -d '[:space:]')
  COUNT=${COUNT:-0}

  if [[ "$COUNT" -eq 0 ]]; then
    break
  fi

  mapfile -t ITEMS < <(echo "$RESP" | tr '{' '\n' | grep '"id":' || true)
  ALL+=("${ITEMS[@]}")
  ((PAGE++))
done

# ===== SAFE EMPTY CACHE HANDLING =====
if [[ "${#ALL[@]}" -eq 0 ]]; then
  echo -e "${GREEN}✅ No caches found for $DEFAULT_USER/$DEFAULT_REPO${RESET}"
  exit 0
fi

# ===== PROCESS CACHES =====
MATCHED=()
TOTAL=0
for item in "${ALL[@]}"; do
  id=$(echo "$item" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
  key=$(echo "$item" | grep -o '"key":".*"' | cut -d'"' -f4)
  ref=$(echo "$item" | grep -o '"ref":".*"' | cut -d'"' -f4)
  size=$(echo "$item" | grep -o '"size_in_bytes":[0-9]*' | grep -o '[0-9]*')
  size_mb=$((size / 1024 / 1024))
  MATCHED+=("$id|$key|$ref|$size_mb")
  TOTAL=$((TOTAL + size_mb))
done

# ===== SHOW SUMMARY =====
echo -e "\n${MAGENTA}🗂 CACHE SUMMARY:${RESET}"
for m in "${MATCHED[@]}"; do
  IFS="|" read -r id key ref mb <<<"$m"
  echo -e " • ID:$id | $key | $ref | ${mb}MB"
done
echo -e "${CYAN}🧮 Total cache size: ${TOTAL}MB${RESET}"

# ===== DRY-RUN / PROMPT DELETE =====
if $DRY; then
  echo -e "${YELLOW}🛑 Dry-run active. No caches deleted.${RESET}"
  echo -e "${CYAN}Use --force to actually delete caches.${RESET}"
  exit 0
fi

# ===== CONFIRM DELETE =====
if ! $FORCE; then
  read -rp "🔥 DELETE all caches? (y/N): " C
  [[ "$C" != "y" ]] && { echo -e "${YELLOW}❌ Cancelled by user${RESET}"; exit 0; }
fi

# ===== DELETE =====
DELETED=0; FAILED=0
echo -e "\n${RED}🔥 Deleting caches...${RESET}"

for m in "${MATCHED[@]}"; do
  IFS="|" read -r id key ref mb <<<"$m"
  for ((i=1;i<=3;i++)); do
    curl -fsS -X DELETE "${AUTH[@]}" "$API_BASE/$id" >/dev/null && break || sleep 2
  done && DELETED=$((DELETED+1)) || FAILED=$((FAILED+1))
done

echo -e "\n${GREEN}✅ Deleted caches: $DELETED${RESET}"
[[ "$FAILED" -gt 0 ]] && echo -e "${YELLOW}⚠ Failed: $FAILED${RESET}"
echo -e "${CYAN}🚀 Cache cleanup complete${RESET}"
