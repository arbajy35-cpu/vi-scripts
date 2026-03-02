#!/bin/bash

echo "==== ADB Wireless Installer ===="
echo ""

echo "Enter Pairing IP:Port (example 192.168.1.8:37123)"
read pairip
adb pair $pairip

echo ""
echo "Enter Connect IP:Port (example 192.168.1.8:42789)"
read connectip
adb connect $connectip

echo ""
adb devices

echo ""
echo "Enter full APK path (example /sdcard/Download/app-debug.apk)"
read apkpath

echo ""
echo "Trying uninstall old version (if exists)..."
adb uninstall com.nexora.vi 2>/dev/null

echo ""
echo "Installing APK..."
adb install "$apkpath"

echo ""
echo "Done ✅"
