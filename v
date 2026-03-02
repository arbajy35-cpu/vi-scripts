#!/data/data/com.termux/files/usr/bin/bash

ROOT="/storage/emulated/0/AppProjects"

if [ -z "$1" ]; then
    read -p "Enter file name: " NAME
else
    NAME="$1"
fi

echo "Searching in AppProjects..."

mapfile -t FILES < <(find "$ROOT" -type f -iname "$NAME" 2>/dev/null)

COUNT=${#FILES[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "❌ File not found"
    exit
fi

echo ""
echo "Select file:"
for i in "${!FILES[@]}"; do
    echo "$((i+1))) ${FILES[$i]#$ROOT/}"
done

echo ""
read -p "Enter number: " NUM

nano "${FILES[$((NUM-1))]}"
