#!/opt/homebrew/bin/bash

# Notarization Status Checker Script
# This script helps you check the status of your notarization submissions

# Load notarization credentials from config file (if it exists)
if [ -f "notarization.config" ]; then
    echo "📋 Loading notarization credentials from config file..."
    source notarization.config
    echo "✅ Credentials loaded"
else
    echo "❌ No notarization.config file found!"
    echo "   Please create notarization.config with APPLE_ID, APPLE_APP_PASSWORD, and TEAM_ID"
    exit 1
fi

# Check if credentials are set
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
    echo "❌ Missing credentials in notarization.config!"
    echo "   Required: APPLE_ID, APPLE_APP_PASSWORD, TEAM_ID"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Notarization Status Checker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to check notarization history
check_history() {
    echo "📜 Checking notarization history..."
    echo ""
    xcrun notarytool history \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APPLE_APP_PASSWORD"
}

# Function to check status of a specific submission
check_submission() {
    if [ -z "$1" ]; then
        echo ""
        echo "📝 Please enter the submission ID to check:"
        read -r SUBMISSION_ID
        if [ -z "$SUBMISSION_ID" ]; then
            echo "❌ No submission ID provided"
            return 1
        fi
    else
        SUBMISSION_ID="$1"
    fi
    
    echo "🔍 Checking status of submission: $SUBMISSION_ID"
    echo ""
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APPLE_APP_PASSWORD"
}

# Function to check if an app is notarized
check_app() {
    if [ -z "$1" ]; then
        APP_PATH="build/macos/Build/Products/Release/AppBuild Dev Cleaner.app"
        if [ ! -d "$APP_PATH" ]; then
            echo ""
            echo "📝 Please enter the path to the app bundle:"
            read -r APP_PATH
            if [ -z "$APP_PATH" ]; then
                echo "❌ No app path provided"
                return 1
            fi
        fi
    else
        APP_PATH="$1"
    fi
    
    if [ ! -d "$APP_PATH" ]; then
        echo "❌ App not found: $APP_PATH"
        return 1
    fi
    
    echo "🔍 Checking notarization status of: $APP_PATH"
    echo ""
    
    # Check signing info
    echo "📋 Signing Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    codesign -dvv "$APP_PATH" 2>&1 | grep -E "(Authority|TeamIdentifier|Identifier|Format|Signature|Timestamp|Notarized)" || codesign -dvv "$APP_PATH" 2>&1 | head -20
    echo ""
    
    # Check if stapled
    echo "📎 Stapling Status:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if xcrun stapler validate "$APP_PATH" 2>&1 | grep -q "validated"; then
        echo "✅ Notarization ticket is stapled and valid"
    else
        echo "⚠️  Notarization ticket not stapled or invalid"
        xcrun stapler validate "$APP_PATH" 2>&1
    fi
    echo ""
    
    # Check Gatekeeper status
    echo "🛡️  Gatekeeper Status:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    spctl --assess --verbose "$APP_PATH" 2>&1
    echo ""
}

# Function to check DMG notarization
check_dmg() {
    DMG_PATH="AppBuild-Dev-Cleaner.dmg"
    if [ -n "$1" ]; then
        DMG_PATH="$1"
    fi
    
    if [ ! -f "$DMG_PATH" ]; then
        echo ""
        echo "📝 Please enter the path to the DMG file:"
        read -r DMG_PATH
        if [ -z "$DMG_PATH" ]; then
            echo "❌ No DMG path provided"
            return 1
        fi
    fi
    
    if [ ! -f "$DMG_PATH" ]; then
        echo "❌ DMG not found: $DMG_PATH"
        return 1
    fi
    
    echo "🔍 Checking DMG: $DMG_PATH"
    echo ""
    
    # Check DMG signature
    echo "📋 DMG Signature:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    codesign -dvv "$DMG_PATH" 2>&1 | grep -E "(Authority|TeamIdentifier|Identifier|Format|Signature|Timestamp)" || codesign -dvv "$DMG_PATH" 2>&1 | head -20
    echo ""
    
    # Verify DMG signature
    echo "✅ DMG Signature Verification:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if codesign --verify --verbose "$DMG_PATH" 2>&1 | grep -q "valid on disk"; then
        echo "✅ DMG signature is valid"
    else
        echo "❌ DMG signature verification failed"
        codesign --verify --verbose "$DMG_PATH" 2>&1
    fi
    echo ""
}

# Interactive menu function
show_menu() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Notarization Status Checker - Menu"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Select an option:"
    echo ""
    echo "  1) 📜 Check Notarization History"
    echo "  2) 🔍 Check Specific Submission Status"
    echo "  3) 📱 Check App Notarization Status"
    echo "  4) 💿 Check DMG Signature & Status"
    echo "  5) ❌ Exit"
    echo ""
    echo -n "Enter your choice [1-5]: "
    read -r choice
    echo ""
    
    case "$choice" in
        1)
            check_history
            ;;
        2)
            check_submission
            ;;
        3)
            check_app
            ;;
        4)
            check_dmg
            ;;
        5)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please select 1-5."
            show_menu
            ;;
    esac
}

# Main menu - support both interactive and command-line modes
if [ $# -eq 0 ]; then
    # No arguments - show interactive menu
    show_menu
else
    # Command-line mode
    case "$1" in
        history|hist|h)
            check_history
            ;;
        check|c)
            check_submission "$2"
            ;;
        app|a)
            check_app "$2"
            ;;
        dmg|d)
            check_dmg "$2"
            ;;
        menu|m|interactive|i)
            show_menu
            ;;
        *)
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  (no args)                - Show interactive menu"
            echo "  history, hist, h          - Show notarization history"
            echo "  check [SUBMISSION_ID], c  - Check status of a specific submission"
            echo "  app [PATH], a             - Check notarization status of an app"
            echo "  dmg [PATH], d             - Check DMG signature and status"
            echo "  menu, m, interactive, i    - Show interactive menu"
            echo ""
            echo "Examples:"
            echo "  $0                        - Show interactive menu"
            echo "  $0 history                - Show all recent submissions"
            echo "  $0 check abc123           - Check submission ID abc123"
            echo "  $0 app                    - Check built app (interactive)"
            echo "  $0 app /path/to/app.app   - Check specific app"
            echo "  $0 dmg                    - Check AppBuild-Dev-Cleaner.dmg (interactive)"
            echo "  $0 dmg /path/to/file.dmg  - Check specific DMG"
            echo ""
            exit 1
            ;;
    esac
fi

