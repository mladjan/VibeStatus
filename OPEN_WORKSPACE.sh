#!/bin/bash
# Quick script to open the VibeStatus workspace

cd /Users/mladjanantic/Work/VibeStatus

echo "🚀 Opening VibeStatus Workspace..."
echo ""
echo "This workspace contains:"
echo "  - macOS app (VibeStatus)"
echo "  - iOS app (VibeStatusMobile)"
echo "  - Shared package (VibeStatusShared)"
echo ""
echo "Now you can build both apps with the shared package!"
echo ""

open VibeStatus.xcworkspace

echo "✅ Workspace opened!"
echo ""
echo "Next steps in Xcode:"
echo "1. Both projects should now see VibeStatusShared"
echo "2. Build each app (they should both work now)"
echo "3. If still having issues, remove and re-add the package to each target"
