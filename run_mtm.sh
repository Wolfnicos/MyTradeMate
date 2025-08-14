set -e
cd ~/Desktop/MyTradeMate
NEW_BUNDLE_ID="com.nicolaslupu.MyTradeMate"
PBX="MyTradeMate.xcodeproj/project.pbxproj"
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*/PRODUCT_BUNDLE_IDENTIFIER = ${NEW_BUNDLE_ID}/g" "$PBX"
PLIST_SRC=$(find . -type f -name "Info.plist" -maxdepth 3 | head -n1)
if [ -n "$PLIST_SRC" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier \$(PRODUCT_BUNDLE_IDENTIFIER)" "$PLIST_SRC" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string \$(PRODUCT_BUNDLE_IDENTIFIER)" "$PLIST_SRC"
fi
rm -rf ~/Library/Developer/Xcode/DerivedData/MyTradeMate-*
xcodebuild -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' clean build
APP_PATH=$(ls -dt ~/Library/Developer/Xcode/DerivedData/MyTradeMate-*/Build/Products/Debug-iphonesimulator/MyTradeMate.app | head -n1)
if [ ! -d "$APP_PATH" ]; then
  echo "No .app found"; exit 1
fi
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
open -a Simulator
xcrun simctl boot "iPhone 16 Pro Max" || true
xcrun simctl uninstall booted "$BUNDLE_ID" || true
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"
echo "Launched $BUNDLE_ID"
