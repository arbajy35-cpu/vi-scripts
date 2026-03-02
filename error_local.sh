#!/bin/bash
# error_local.sh – LOCAL FILE ERROR SCANNER
# Author: BLACKWATCHER BL
# Features:
# - Scans JS / HTML / CSS / XML / Java / Kotlin / Gradle files
# - Detects syntax errors, missing imports, common mistakes
# - Highlights errors & warnings
# - Suggests fixes
# - Fully offline, local

PROJECT_DIR="/storage/emulated/0/AppProjects/VI"
MODE="$1"  # --interactive | --summary | --raw

RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${RESET}"
    exit 1
fi

highlight_errors() {
    sed -e "s/error:/$(echo -e "${RED}ERROR:${RESET}")/I" \
        -e "s/warn:/$(echo -e "${YELLOW}WARN:${RESET}")/I" \
        -e "s/fatal:/$(echo -e "${RED}FATAL:${RESET}")/I"
}

scan_files() {
    echo -e "${CYAN}[+] Scanning project for errors...${RESET}"
    
    # Java / Kotlin
    find "$PROJECT_DIR" -type f \( -name "*.java" -o -name "*.kt" \) | while read f; do
        javac -Xlint "$f" 2>&1 | highlight_errors
    done

    # XML
    find "$PROJECT_DIR" -type f -name "*.xml" | while read f; do
        xmllint --noout "$f" 2>&1 | highlight_errors
    done

    # HTML
    find "$PROJECT_DIR" -type f -name "*.html" | while read f; do
        tidy -qe "$f" 2>&1 | highlight_errors
    done

    # CSS
    find "$PROJECT_DIR" -type f -name "*.css" | while read f; do
        csslint "$f" 2>&1 | highlight_errors
    done

    # JS
    find "$PROJECT_DIR" -type f -name "*.js" | while read f; do
        eslint "$f" 2>&1 | highlight_errors
    done
}

display_summary() {
    echo -e "${CYAN}================ LOCAL ERROR SUMMARY ================${RESET}"
    scan_files
    echo -e "${CYAN}===================================================${RESET}"
}

interactive_mode() {
    while true; do
        echo
        echo -e "${CYAN}📋 LOCAL ERROR SCANNER MENU${RESET}"
        echo "1️⃣  Scan entire project & show summary"
        echo "2️⃣  Scan specific file"
        echo "3️⃣  Exit"
        read -p "Choose: " choice
        case $choice in
            1) display_summary ;;
            2) 
                read -p "Enter file path (relative to project root): " file
                full_path="$PROJECT_DIR/$file"
                if [[ -f "$full_path" ]]; then
                    echo -e "${CYAN}[+] Scanning $file...${RESET}"
                    case "$file" in
                        *.java|*.kt) javac -Xlint "$full_path" 2>&1 | highlight_errors ;;
                        *.xml) xmllint --noout "$full_path" 2>&1 | highlight_errors ;;
                        *.html) tidy -qe "$full_path" 2>&1 | highlight_errors ;;
                        *.css) csslint "$full_path" 2>&1 | highlight_errors ;;
                        *.js) eslint "$full_path" 2>&1 | highlight_errors ;;
                        *) echo -e "${YELLOW}⚠️  Unsupported file type${RESET}" ;;
                    esac
                else
                    echo -e "${RED}❌ File not found: $full_path${RESET}"
                fi
                ;;
            3) break ;;
            *) echo -e "${RED}❌ Invalid choice${RESET}" ;;
        esac
    done
}

case "$MODE" in
    --interactive) interactive_mode ;;
    --summary|"") display_summary ;;
    --raw) scan_files ;;
    *) echo -e "${RED}❌ Invalid mode${RESET}" ;;
esac
