#!/bin/bash
# Собирает Coffein.app из Swift-пакета без Xcode (только Command Line Tools):
#   swift build → ручная сборка .app → иконка → Info.plist → ad-hoc подпись.
# С флагом --install также копирует в ~/Applications.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="Coffein"
BUNDLE_ID="com.coffein.app"
VERSION="1.0.0"
BUILD_NUM="1"

echo "==> swift build -c release"
swift build -c release

BIN=".build/release/$APP_NAME"
[ -f "$BIN" ] || { echo "Ошибка: бинарь не найден: $BIN"; exit 1; }

APP="$ROOT/$APP_NAME.app"
echo "==> сборка бандла $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"

echo "==> генерация иконки"
python3 scripts/make_icon.py
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> Info.plist"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$BUILD_NUM</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>© 2026 Coffein</string>
</dict>
</plist>
PLIST

echo "==> ad-hoc подпись"
codesign --force --sign - "$APP"
codesign --verify --verbose=2 "$APP"

echo "==> готово: $APP"

if [ "${1:-}" = "--install" ]; then
    DEST="$HOME/Applications/$APP_NAME.app"
    echo "==> установка в $DEST"
    mkdir -p "$HOME/Applications"
    rm -rf "$DEST"
    cp -R "$APP" "$DEST"
    echo "Установлено: $DEST"
fi
