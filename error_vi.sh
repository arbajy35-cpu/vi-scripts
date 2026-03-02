#!/bin/bash
# VI‑JARVIS REAL ENGINE v8 – REAL, COMPACT & POWERFUL
# Author: BLACKWATCHER BL
# Features:
# - Multi-branch monitoring
# - Real-time error detection & highlights
# - Failed tasks + root cause chain
# - Auto-suggestions for common issues
# - Interactive debug assistant
# - Temporary logs auto-clean

USER="arbajy35-cpu"
REPO="VI"
BRANCHES=("main" "dev")   # Add more branches if needed
MODE="$1"  # --interactive | --summary | --raw

: "${GITHUB_TOKEN:?❌ GITHUB_TOKEN missing}"

BASE="$HOME/.vi_real_v8"
ZIP="$BASE/logs.zip"

RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

mkdir -p "$BASE" || exit 1

# ------------------- FUNCTIONS -------------------

fetch_run_logs() {
    local branch="$1"
    echo -e "${CYAN}[+] Fetching latest workflow run for '$branch'...${RESET}"

    local RUN_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/repos/$USER/$REPO/actions/runs?branch=$branch&status=completed&per_page=1" \
        | grep -m1 '"id":' | cut -d':' -f2 | tr -d ', ')

    if [[ -z "$RUN_ID" ]]; then
        echo -e "${YELLOW}[!] No completed workflow run for $branch${RESET}"
        return 1
    fi

    echo -e "${CYAN}[+] RUN ID: $RUN_ID${RESET}"

    curl -sL -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/repos/$USER/$REPO/actions/runs/$RUN_ID/logs" \
        -o "$ZIP" || { echo -e "${RED}❌ Download failed${RESET}"; return 1; }

    unzip -qq -o "$ZIP" -d "$BASE" || { echo -e "${RED}❌ Unzip failed${RESET}"; return 1; }
}

highlight_errors() {
    sed -e "s/fatal:/$(echo -e "${RED}FATAL:${RESET}")/I" \
        -e "s/error:/$(echo -e "${RED}ERROR:${RESET}")/I" \
        -e "s/warn:/$(echo -e "${YELLOW}WARN:${RESET}")/I" \
        -e "s/Exception:/$(echo -e "${RED}EXCEPTION:${RESET}")/I" \
        -e "s/FAILURE:/$(echo -e "${RED}FAILURE:${RESET}")/I"
}

display_summary() {
    echo -e "\n${CYAN}================ REAL BUILD RESULT ================${RESET}"

    local failed_logs=$(grep -Rl "BUILD FAILED\|Execution failed for task" "$BASE")
    if [[ -z "$failed_logs" ]]; then
        echo -e "${GREEN}✅ BUILD PASSED${RESET}"
        return
    fi

    echo -e "${RED}❌ BUILD FAILED${RESET}\n"

    echo -e "${MAGENTA}1️⃣  FAILED TASKS:${RESET}"
    grep -R "Execution failed for task" "$BASE" | sed 's/^/   - /' || echo "   - None"

    echo -e "\n${MAGENTA}2️⃣  ROOT CAUSE CHAIN:${RESET}"
    grep -R -A5 "Caused by:" "$BASE" | sed 's/^/   /' || echo "   - None"

    echo -e "\n${MAGENTA}3️⃣  ERROR LINE(S):${RESET}"
    grep -R -m20 -E "error:|Exception|FAILURE:" "$BASE" | highlight_errors || echo "   - None"

    echo -e "\n${YELLOW}4️⃣  SUGGESTIONS:${RESET}"
    grep -q "package androidx.appcompat.app does not exist" "$BASE" && echo "   - Add implementation 'androidx.appcompat:appcompat:1.6.1'"
    grep -q "R cannot be resolved" "$BASE" && echo "   - Try Build -> Clean Project -> Rebuild"
    grep -q "cannot find symbol" "$BASE" && echo "   - Check class/method names or missing imports"
    grep -q "CompilationFailedException" "$BASE" && echo "   - Compilation failed: Check syntax & dependencies"

    echo -e "\n${CYAN}=================================================${RESET}"
}

display_raw() {
    echo -e "${CYAN}================ RAW LOGS =================${RESET}"
    find "$BASE" -type f -name "*.txt" -exec cat {} +
    echo -e "${CYAN}==========================================${RESET}"
}

interactive_mode() {
    while true; do
        echo
        echo -e "${CYAN}📋 VI-JARVIS INTERACTIVE MENU${RESET}"
        echo "1️⃣  Build summary"
        echo "2️⃣  Error lines"
        echo "3️⃣  Root cause chain"
        echo "4️⃣  Filter by file"
        echo "5️⃣  Show raw logs"
        echo "6️⃣  Exit"
        read -p "Choose: " choice
        case $choice in
            1) display_summary ;;
            2) grep -R -m50 -E "error:|Exception|FAILURE:" "$BASE" | highlight_errors ;;
            3) grep -R -A5 "Caused by:" "$BASE" | sed 's/^/   /' ;;
            4) read -p "Enter filename or path: " file; grep -R "$file" "$BASE" | highlight_errors ;;
            5) display_raw ;;
            6) break ;;
            *) echo -e "${RED}❌ Invalid choice${RESET}" ;;
        esac
    done
}

# ------------------- RUN -------------------
for branch in "${BRANCHES[@]}"; do
    fetch_run_logs "$branch"
done

case "$MODE" in
    --interactive) interactive_mode ;;
    --raw) display_raw ;;
esac

# 🔔 FINAL NOTIFICATION-STYLE SUMMARY
display_summary

# ------------------- CLEANUP -------------------
rm -rf "$BASE"
echo -e "${GREEN}[+] Temporary logs cleaned, storage safe.${RESET}"
echo -e "${CYAN}=======================================${RESET}"
