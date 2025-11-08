#!/opt/homebrew/bin/bash

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for macOS
flutter build macos --release

# Check if build was successful
APP_NAME="AppBuild Dev Cleaner"
APP_BUNDLE="$APP_NAME.app"
BUILD_PATH="build/macos/Build/Products/Release/$APP_BUNDLE"

if [ ! -d "$BUILD_PATH" ]; then
    echo "❌ Build failed - app not found!"
    exit 1
fi

# Create staging directory
STAGING_DIR=$(mktemp -d)
echo "📦 Creating staging directory: $STAGING_DIR"

# Copy only the app bundle to staging directory
cp -R "$BUILD_PATH" "$STAGING_DIR/"
echo "✅ App copied to staging directory"

# Get app version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
echo "📋 App version: $VERSION"

# Create installer package (.pkg)
INSTALLER_PKG="AppBuild-Dev-Cleaner-Installer.pkg"
echo "🔨 Creating installer package..."

# Create temporary component plist file
COMPONENT_PLIST=$(mktemp)
cat > "$COMPONENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
  <dict>
    <key>BundleHasStrictIdentifier</key>
    <true/>
    <key>BundleIsRelocatable</key>
    <false/>
    <key>BundleIsVersionChecked</key>
    <true/>
    <key>BundleOverwriteAction</key>
    <string>upgrade</string>
    <key>RootRelativeBundlePath</key>
    <string>$APP_BUNDLE</string>
  </dict>
</array>
</plist>
EOF

pkgbuild \
  --root "$STAGING_DIR" \
  --identifier "com.whoamie.flutterCleaner" \
  --version "$VERSION" \
  --install-location "/Applications" \
  --component-plist "$COMPONENT_PLIST" \
  "$INSTALLER_PKG"

# Clean up component plist
rm -f "$COMPONENT_PLIST"

# Clean up staging directory
rm -rf "$STAGING_DIR"

# Check if package was created
if [ -f "$INSTALLER_PKG" ]; then
    PKG_PATH=$(pwd)/$INSTALLER_PKG
    PKG_SIZE=$(du -h "$INSTALLER_PKG" | cut -f1)
    
    echo ""
    echo "✅ Installer package created successfully!"
    echo "📍 Location: $PKG_PATH"
    echo "📊 Size: $PKG_SIZE"
    echo "🚀 Ready for distribution!"
    echo ""
    echo "💡 Users can double-click the .pkg file to install the app."
    echo ""
    
    # Optional: Open folder containing package
    open .
else
    echo "❌ Installer package creation failed!"
    exit 1
fi

