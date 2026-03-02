#!/bin/bash
# Path to your app
APP_ROOT=~/AppProjects/VI/app
ASSETS="$APP_ROOT/src/main/assets"
BACKUP="$APP_ROOT/src/main/assets_backup"

echo "🔒 Creating temporary clean assets..."

# Backup original assets
mv "$ASSETS" "$BACKUP"

# Create new minimal assets
mkdir -p "$ASSETS"

# Copy ONLY index.enc
cp "$BACKUP/index.enc" "$ASSETS/"

echo "🚀 Building APK..."
cd "$APP_ROOT"
./gradlew clean assembleDebug --no-daemon

echo "♻ Restoring original assets..."
rm -rf "$ASSETS"
mv "$BACKUP" "$ASSETS"

echo "✅ Done. APK contains only index.enc"
