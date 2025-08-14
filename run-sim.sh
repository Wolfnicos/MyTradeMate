#!/usr/bin/env bash
set -euo pipefail

PROJ="MyTradeMate.xcodeproj"
SCHEME="MyTradeMate"
DEVICE_NAME="iPhone 16 Pro Max"
DEST="platform=iOS Simulator,name=${DEVICE_NAME}"

echo "🔨 Build Debug pentru simulator..."
xcodebuild \
  -project "$PROJ" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DEST" \
  build

echo "🔎 Găsesc calea .app..."
APP_PATH=$(ls -dt ~/Library/Developer/Xcode/DerivedData/MyTradeMate-*/Build/Products/Debug-iphonesimulator/MyTradeMate.app | head -n1)
if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  echo "❌ Nu am găsit .app. Verifică build-ul."
  exit 1
fi
echo "APP_PATH=$APP_PATH"

echo "📦 Citește bundle id..."
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
echo "BUNDLE_ID=$BUNDLE_ID"

echo "📱 Pornește simulatorul..."
open -a Simulator
xcrun simctl boot "$DEVICE_NAME" || true

echo "🧹 Dezinstalez vechea versiune..."
xcrun simctl uninstall booted "$BUNDLE_ID" || true

echo "⬇️ Instalez aplicația..."
xcrun simctl install booted "$APP_PATH"

echo "▶️ Lansare aplicație..."
xcrun simctl launch booted "$BUNDLE_ID"

echo "✅ Gata!"
