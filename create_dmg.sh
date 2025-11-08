#!/opt/homebrew/bin/bash

# Load notarization credentials from config file (if it exists)
if [ -f "notarization.config" ]; then
    echo "📋 Loading notarization credentials from config file..."
    source notarization.config
    echo "✅ Credentials loaded"
else
    echo "⚠️  No notarization.config file found - notarization will be skipped"
    echo "   Create notarization.config with APPLE_ID, APPLE_APP_PASSWORD, and TEAM_ID"
fi

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

# Try to get team ID from Xcode project (only if not already set from config file)
if [ -z "$TEAM_ID" ]; then
    TEAM_ID=$(grep -A 5 "DEVELOPMENT_TEAM" "macos/Runner.xcodeproj/project.pbxproj" | grep -o "[A-Z0-9]\{10\}" | head -1)
fi

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

# Notarization (optional - requires Developer ID certificate and credentials)
# TEAM_ID should already be set from config file or extracted from project above

if [ -n "$APPLE_ID" ] && [ -n "$APPLE_APP_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
    echo "📤 Starting notarization process..."
    
    # Check if using Developer ID certificate (required for notarization)
    if echo "$SIGNING_IDENTITY" | grep -q "Developer ID Application"; then
        echo "✅ Using Developer ID certificate - proceeding with notarization"
        
        # Create ZIP for notarization
        ZIP_PATH=$(mktemp -t "AppBuild-Dev-Cleaner-XXXXXX.zip")
        echo "📦 Creating ZIP for notarization..."
        ditto -c -k --keepParent "$STAGING_DIR/$APP_BUNDLE" "$ZIP_PATH"
        
        # Submit for notarization
        echo "📤 Submitting to Apple for notarization..."
        echo "⏳ This may take 2-5 minutes. Please wait..."
        
        # Submit without --wait first to get the submission ID
        SUBMIT_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APPLE_APP_PASSWORD" 2>&1)
        
        if [ $? -ne 0 ]; then
            echo "❌ Failed to submit for notarization!"
            echo "$SUBMIT_OUTPUT"
            echo "⚠️  Continuing without notarization - app will show security warning"
            rm -f "$ZIP_PATH"
        else
            # Extract submission ID if available
            SUBMISSION_ID=$(echo "$SUBMIT_OUTPUT" | grep -i "id:" | head -1 | awk '{print $NF}' | tr -d '[:space:]')
            
            if [ -n "$SUBMISSION_ID" ]; then
                echo "✅ Submission ID: $SUBMISSION_ID"
                echo "⏳ Waiting for notarization to complete (this may take 2-5 minutes)..."
                echo "💡 Tip: You can press Ctrl+C to skip notarization and continue"
                
                # Wait for notarization with progress (with timeout handling)
                NOTARIZATION_OUTPUT=$(timeout 600 xcrun notarytool wait "$SUBMISSION_ID" \
                    --apple-id "$APPLE_ID" \
                    --team-id "$TEAM_ID" \
                    --password "$APPLE_APP_PASSWORD" 2>&1) || NOTARIZATION_TIMEOUT=1
            else
                # Fallback: use --wait flag
                echo "⏳ Waiting for notarization to complete (this may take 2-5 minutes)..."
                echo "💡 Tip: You can press Ctrl+C to skip notarization and continue"
                
                # Use timeout if available, otherwise just wait
                if command -v timeout &> /dev/null; then
                    NOTARIZATION_OUTPUT=$(timeout 600 xcrun notarytool submit "$ZIP_PATH" \
                        --apple-id "$APPLE_ID" \
                        --team-id "$TEAM_ID" \
                        --password "$APPLE_APP_PASSWORD" \
                        --wait 2>&1) || NOTARIZATION_TIMEOUT=1
                else
                    NOTARIZATION_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
                        --apple-id "$APPLE_ID" \
                        --team-id "$TEAM_ID" \
                        --password "$APPLE_APP_PASSWORD" \
                        --wait 2>&1)
                fi
            fi
            
            # Handle timeout
            if [ -n "$NOTARIZATION_TIMEOUT" ]; then
                echo "⏱️  Notarization timeout (10 minutes) - continuing without notarization"
                echo "⚠️  You can check notarization status later with: xcrun notarytool history"
                NOTARIZATION_OUTPUT=""
            fi
            
            if echo "$NOTARIZATION_OUTPUT" | grep -qi "status: Accepted\|accepted"; then
                echo "✅ Notarization successful!"
                
                # Staple the notarization ticket to the app
                echo "📎 Stapling notarization ticket..."
                xcrun stapler staple "$STAGING_DIR/$APP_BUNDLE"
                
                # Verify stapling
                if xcrun stapler validate "$STAGING_DIR/$APP_BUNDLE" 2>&1 | grep -q "validated"; then
                    echo "✅ Notarization ticket stapled successfully!"
                else
                    echo "⚠️  Warning: Could not verify stapling, but notarization was accepted"
                fi
            elif echo "$NOTARIZATION_OUTPUT" | grep -qi "status: Invalid\|invalid"; then
                echo "❌ Notarization failed - Invalid!"
                echo "$NOTARIZATION_OUTPUT"
                echo "⚠️  Continuing without notarization - app will show security warning"
            else
                echo "⚠️  Notarization status unclear. Output:"
                echo "$NOTARIZATION_OUTPUT"
                echo "⚠️  Continuing - you may need to check notarization status manually"
            fi
        fi
        
        # Clean up ZIP
        rm -f "$ZIP_PATH"
    else
        echo "⚠️  Skipping notarization - requires 'Developer ID Application' certificate"
        echo "   Current certificate: $SIGNING_IDENTITY"
        echo "   For notarization, use: Xcode → Preferences → Accounts → Manage Certificates → + → Developer ID Application"
    fi
else
    echo "⚠️  Skipping notarization"
    if [ ! -f "notarization.config" ]; then
        echo "   Create notarization.config file with:"
        echo "   export APPLE_ID='your@email.com'"
        echo "   export APPLE_APP_PASSWORD='app-specific-password'"
        echo "   export TEAM_ID='YOUR_TEAM_ID'"
        echo "   Note: App-specific password from appleid.apple.com → Security → App-Specific Passwords"
    else
        echo "   Missing credentials in notarization.config or environment variables"
        echo "   Required: APPLE_ID, APPLE_APP_PASSWORD, TEAM_ID"
    fi
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

# Create temporary DMG first (writable)
TEMP_DMG="AppBuild-Dev-Cleaner-temp.dmg"
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
  "$TEMP_DMG" \
  "$STAGING_DIR/"

# Verify DMG was created
if [ ! -f "$TEMP_DMG" ]; then
    echo "❌ DMG creation failed!"
    rm -rf "$STAGING_DIR"
    exit 1
fi

echo "✅ DMG created successfully"

# Mount the DMG to add background text
echo "📝 Adding background text to DMG..."
DMG_MOUNT=$(hdiutil attach -nobrowse -noverify "$TEMP_DMG" | grep "Volumes" | awk '{print $3}')
if [ -z "$DMG_MOUNT" ]; then
    echo "❌ Failed to mount DMG"
    rm -f "$TEMP_DMG"
    rm -rf "$STAGING_DIR"
    exit 1
fi

# Create background directory
BACKGROUND_DIR="$DMG_MOUNT/.background"
mkdir -p "$BACKGROUND_DIR"

# Create background image with text using Python (PIL/Pillow) if available
if command -v python3 &> /dev/null && python3 -c "from PIL import Image, ImageDraw, ImageFont" 2>/dev/null; then
    echo "🎨 Creating background image with text using Python..."
    python3 <<PYTHON_SCRIPT
from PIL import Image, ImageDraw, ImageFont
import os

# Create image
width, height = 800, 500
img = Image.new('RGB', (width, height), color='white')
draw = ImageDraw.Draw(img)

# Try to use system font, fallback to default
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 24)
except:
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 24)
    except:
        font = ImageFont.load_default()

# Draw text
text = "Move the application to the applications folder to be installed"
# Center text
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (width - text_width) / 2
y = height - 100

draw.text((x, y), text, fill='black', font=font)
img.save("$BACKGROUND_DIR/background.png")
PYTHON_SCRIPT
    BACKGROUND_IMAGE="$BACKGROUND_DIR/background.png"
elif command -v convert &> /dev/null; then
    # Use ImageMagick if available
    echo "🎨 Creating background image with text using ImageMagick..."
    convert -size 800x500 xc:white \
        -pointsize 24 -fill black -gravity south \
        -annotate +0+100 "Move the application to the applications folder to be installed" \
        "$BACKGROUND_DIR/background.png" 2>/dev/null
    BACKGROUND_IMAGE="$BACKGROUND_DIR/background.png"
else
    # Fallback: create a simple white background (text will be added via AppleScript)
    echo "⚠️  Python PIL or ImageMagick not found - creating simple background"
    # Create a simple white PNG using sips
    sips -c 800 500 --setProperty format png /System/Library/CoreServices/DefaultDesktop.heic --out "$BACKGROUND_DIR/background.png" 2>/dev/null || \
    echo "⚠️  Could not create background image - will proceed without custom background"
    BACKGROUND_IMAGE="$BACKGROUND_DIR/background.png"
fi

# Set background and layout using AppleScript
echo "🎨 Setting DMG background and layout..."
osascript <<EOF
tell application "Finder"
    tell disk "$DMG_MOUNT"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 1000, 620}
        set position of item "$APP_BUNDLE" of container window to {200, 200}
        set position of item "Applications" of container window to {600, 200}
        if exists file ".background:background.png" then
            set background picture of container window to file ".background:background.png"
        end if
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Add text overlay using AppleScript if background image exists
if [ -f "$BACKGROUND_IMAGE" ]; then
    echo "✅ Background image created successfully"
else
    echo "⚠️  Background image not created - DMG will work but without custom background text"
fi

# Unmount the DMG
hdiutil detach "$DMG_MOUNT"

# Convert to read-only compressed DMG
echo "🔒 Converting DMG to read-only format..."
hdiutil convert "$TEMP_DMG" -format UDZO -o "AppBuild-Dev-Cleaner.dmg" -ov

# Remove temporary DMG
rm -f "$TEMP_DMG"

# Verify final DMG was created
if [ ! -f "AppBuild-Dev-Cleaner.dmg" ]; then
    echo "❌ Failed to create read-only DMG!"
    rm -rf "$STAGING_DIR"
    exit 1
fi

echo "✅ Read-only DMG created successfully with background text"

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