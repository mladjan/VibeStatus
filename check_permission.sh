#!/bin/bash
# Check and help grant automation permission for VibeStatus

echo "🔍 Checking automation permission for VibeStatus..."
echo ""

BUNDLE_ID="com.vibestatus.app"

# Check if permission exists in TCC database
RESULT=$(sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
"SELECT service, client, allowed FROM access WHERE client='$BUNDLE_ID' AND service='kTCCServiceAppleEvents';" 2>/dev/null)

if [ -z "$RESULT" ]; then
    echo "❌ No permission entry found for VibeStatus"
    echo ""
    echo "This means the permission dialog hasn't appeared yet."
    echo ""
    echo "📋 Options to fix:"
    echo ""
    echo "1️⃣  Reset and try again:"
    echo "   Run: tccutil reset AppleEvents $BUNDLE_ID"
    echo "   Then: Restart VibeStatus and send a response from iOS"
    echo ""
    echo "2️⃣  Open System Settings manually:"
    echo "   Go to: System Settings → Privacy & Security → Automation"
    echo "   Enable: VibeStatus → System Events"
    echo ""
    echo "3️⃣  Try automatic reset (will prompt for permission):"
    read -p "   Reset permission now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tccutil reset AppleEvents $BUNDLE_ID
        echo "✅ Permission reset. Please restart VibeStatus and try again."
    fi
else
    # Parse result
    ALLOWED=$(echo "$RESULT" | cut -d'|' -f3)

    if [ "$ALLOWED" = "2" ] || [ "$ALLOWED" = "1" ]; then
        echo "✅ Permission is GRANTED"
        echo ""
        echo "Service: kTCCServiceAppleEvents"
        echo "Status: Allowed"
        echo ""
        echo "VibeStatus can send responses from iOS to Terminal!"
    elif [ "$ALLOWED" = "0" ]; then
        echo "❌ Permission is DENIED"
        echo ""
        echo "Service: kTCCServiceAppleEvents"
        echo "Status: Denied"
        echo ""
        echo "📋 To fix:"
        echo "1. Open System Settings → Privacy & Security → Automation"
        echo "2. Find VibeStatus in the list"
        echo "3. Check the box next to 'System Events'"
        echo ""
        echo "Or run: tccutil reset AppleEvents $BUNDLE_ID"
        echo "Then restart VibeStatus"
    else
        echo "⚠️  Unknown permission state: $ALLOWED"
        echo "Full result: $RESULT"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 TIP: If you don't want to grant permission,"
echo "   responses will be copied to your clipboard"
echo "   and you can paste them manually in Terminal."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
