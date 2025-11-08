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

# Create staging directory with only the app bundle
STAGING_DIR=$(mktemp -d)
echo "📦 Creating staging directory: $STAGING_DIR"

# Copy ONLY the app bundle (not the entire Release directory)
cp -R "$BUILD_PATH" "$STAGING_DIR/"
echo "✅ App copied to staging directory"

# Verify only the app bundle is in staging directory
echo "🔍 Verifying staging directory contents..."
STAGING_CONTENTS=$(ls -A "$STAGING_DIR")
if [ "$(echo "$STAGING_CONTENTS" | wc -l)" -gt 1 ] || [ "$STAGING_CONTENTS" != "$APP_BUNDLE" ]; then
    echo "⚠️  Warning: Staging directory contains more than just the app bundle"
    echo "   Contents: $STAGING_CONTENTS"
    echo "   Cleaning up..."
    rm -rf "$STAGING_DIR"
    STAGING_DIR=$(mktemp -d)
    cp -R "$BUILD_PATH" "$STAGING_DIR/"
    echo "✅ Re-copied app bundle only"
fi

echo "📋 Staging directory contains: $(ls "$STAGING_DIR")"

# Find signing certificate
echo "🔍 Looking for signing certificate..."

# Try to get team ID from Xcode project
TEAM_ID=$(grep -A 5 "DEVELOPMENT_TEAM" "macos/Runner.xcodeproj/project.pbxproj" | grep -o "[A-Z0-9]\{10\}" | head -1)

# Priority order: Developer ID (for distribution) > 3rd Party Mac Developer (App Store) > Apple Development (dev only)
if [ -n "$TEAM_ID" ]; then
    echo "📋 Found Team ID in project: $TEAM_ID"
    # Try to find certificate matching team ID
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep -i "$TEAM_ID" | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
fi

# If not found, try Developer ID Application (any team)
if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
fi

# If still not found, try 3rd Party Mac Developer (App Store)
if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "3rd Party Mac Developer Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
fi

# If still not found, try any Developer certificate (will warn later)
if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep -i "developer" | head -1 | sed 's/.*"\(.*\)".*/\1/')
fi

if [ -z "$SIGNING_IDENTITY" ]; then
    echo "❌ No signing certificate found!"
    echo "💡 Please create a signing certificate in Xcode:"
    echo "   Xcode → Preferences → Accounts → Manage Certificates"
    echo "   For distribution, create a 'Developer ID Application' certificate"
    rm -rf "$STAGING_DIR"
    exit 1
fi

# Check if it's a development certificate (warn but allow)
if echo "$SIGNING_IDENTITY" | grep -q "Apple Development"; then
    echo "⚠️  WARNING: Using 'Apple Development' certificate (for development only)"
    echo "   For distribution, you should use 'Developer ID Application' certificate"
    echo "   Xcode → Preferences → Accounts → Manage Certificates → + → Developer ID Application"
fi

echo "✅ Found signing certificate: $SIGNING_IDENTITY"

# Clean app bundle before signing
echo "🧹 Cleaning app bundle..."
xattr -cr "$STAGING_DIR/$APP_BUNDLE"

# Sign the app bundle
echo "✍️  Signing app bundle..."
codesign --force --deep --sign "$SIGNING_IDENTITY" \
         --options runtime \
         --timestamp \
         "$STAGING_DIR/$APP_BUNDLE"

# Verify signature
echo "🔍 Verifying signature..."
if codesign --verify --verbose "$STAGING_DIR/$APP_BUNDLE" 2>&1 | grep -q "valid on disk"; then
    echo "✅ App signature verified!"
    
    # Display detailed signing information
    echo ""
    echo "📋 Signing Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    codesign -dvv "$STAGING_DIR/$APP_BUNDLE" 2>&1 | grep -E "(Authority|TeamIdentifier|Identifier|Format|Signature|Timestamp)" || codesign -dvv "$STAGING_DIR/$APP_BUNDLE" 2>&1
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo "❌ App signature verification failed!"
    rm -rf "$STAGING_DIR"
    exit 1
fi

# Install create-dmg if not available
if ! command -v create-dmg &> /dev/null; then
    echo "📦 Installing create-dmg..."
    brew install create-dmg
fi

# Create DMG with polished look (like CodeEdit DMG)
# This will create a DMG with ONLY the app bundle and Applications alias
echo "🔨 Creating DMG with custom layout..."
echo "📋 DMG will contain only: $APP_BUNDLE and Applications alias"

# Remove old DMG if it exists
if [ -f "AppBuild-Dev-Cleaner.dmg" ]; then
    echo "🗑️  Removing old DMG file..."
    rm -f "AppBuild-Dev-Cleaner.dmg"
fi

create-dmg \
  --volname "AppBuild Dev Cleaner" \
  --window-pos 200 120 \
  --window-size 800 500 \
  --icon-size 120 \
  --text-size 14 \
  --icon "$APP_BUNDLE" 200 200 \
  --hide-extension "$APP_BUNDLE" \
  --app-drop-link 600 200 \
  --hdiutil-quiet \
  "AppBuild-Dev-Cleaner.dmg" \
  "$STAGING_DIR/"

# Verify DMG was created
if [ ! -f "AppBuild-Dev-Cleaner.dmg" ]; then
    echo "❌ DMG creation failed!"
    rm -rf "$STAGING_DIR"
    exit 1
fi

echo "✅ DMG created successfully with only app bundle and Applications alias"

# Sign the DMG
if [ -f "AppBuild-Dev-Cleaner.dmg" ]; then
    echo "✍️  Signing DMG..."
    codesign --force --sign "$SIGNING_IDENTITY" \
             --timestamp \
             "AppBuild-Dev-Cleaner.dmg"
    
    # Verify DMG signature
    echo "🔍 Verifying DMG signature..."
    if codesign --verify --verbose "AppBuild-Dev-Cleaner.dmg" 2>&1 | grep -q "valid on disk"; then
        echo "✅ DMG signature verified!"
    else
        echo "⚠️  DMG signature verification failed, but DMG was created."
    fi
fi

# Clean up staging directory
rm -rf "$STAGING_DIR"

# Show DMG location
if [ -f "AppBuild-Dev-Cleaner.dmg" ]; then
    DMG_PATH=$(pwd)/AppBuild-Dev-Cleaner.dmg
    DMG_SIZE=$(du -h "AppBuild-Dev-Cleaner.dmg" | cut -f1)
    
    echo "✅ DMG created successfully!"
    echo "📍 Location: $DMG_PATH"
    echo "📊 Size: $DMG_SIZE"
    echo "🚀 Ready for distribution!"
    
    # Optional: Open folder containing DMG
    open .
else
    echo "❌ DMG creation failed!"
    exit 1
fi