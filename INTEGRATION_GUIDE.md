# VibeStatus iOS Integration Guide

This guide explains how to complete the iOS + macOS integration using CloudKit for syncing Claude Code sessions.

## 📋 Overview

The integration uses **CloudKit** as the sync backend to share session data between your Mac and iPhone:

```
macOS App → CloudKit → iOS App
   ↓           ↓          ↓
Monitors    Syncs     Displays
Sessions    Data      + Notifies
```

## ✅ Completed Work

### Phase 1: Shared Foundation
- ✅ Created `VibeStatusShared` Swift package
- ✅ Defined `SessionRecord` and `VibeStatus` models
- ✅ Implemented `CloudKitManager` with upload/fetch/delete operations
- ✅ Set up CloudKit schema and subscription management

### Phase 2: macOS Integration
- ✅ Added CloudKit entitlements to macOS app
- ✅ Created `CloudKitSyncManager` to bridge StatusManager and CloudKit
- ✅ Modified `StatusManager` to upload sessions when they change
- ✅ Added iOS sync toggle in Settings UI

### Phase 3: iOS App
- ✅ Created iOS app with SwiftUI interface
- ✅ Implemented `SessionListView` to display active sessions
- ✅ Created `CloudKitViewModel` for session management
- ✅ Built `NotificationManager` for push notifications
- ✅ Added `SettingsView` for configuration
- ✅ Configured CloudKit entitlements and APNs

## 🚀 Next Steps to Complete Integration

### Step 1: Link Shared Package in Xcode

Both macOS and iOS projects need to reference the `VibeStatusShared` package.

**macOS App:**
1. Open `macOS/vibestatus/VibeStatus.xcodeproj`
2. Select the project in the navigator
3. Go to the **VibeStatus** target → **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** → **Add Other...** → **Add Package Dependency...**
6. Click **Add Local...** and navigate to: `VibeStatusShared`
7. Select **VibeStatusShared** library and click **Add**

**iOS App:**
1. Open `iOS/VibeStatusMobile/VibeStatusMobile.xcodeproj`
2. Follow the same steps as macOS to add `VibeStatusShared` package

### Step 2: Uncomment Integration Code

Several files have commented sections marked with:
```swift
// TODO: Uncomment when VibeStatusShared is linked
```

**macOS Files to Update:**
- `CloudKitSyncManager.swift` - Uncomment all CloudKit operations
  - Lines with `CloudKitManager.shared` calls
  - Lines with `SessionRecord` conversions

**iOS Files to Update:**
- `CloudKitViewModel.swift`
  - Remove temporary `SessionInfo` and `VibeStatus` definitions at bottom
  - Uncomment CloudKit imports and operations
  - Remove mock data in `refreshSessions()`

- `VibeStatusMobileApp.swift`
  - Uncomment `CloudKitManager.shared.setupSubscription()` call
  - Uncomment refresh call in `didReceiveRemoteNotification`

### Step 3: Configure CloudKit Container in Xcode

**For Both Apps:**

1. Select the project → Target → **Signing & Capabilities**
2. Click **+ Capability** → Add **iCloud**
3. Enable **CloudKit**
4. Check the container: `iCloud.com.mladjan.vibestatus`
5. Click **+ Capability** → Add **Push Notifications**
6. Click **+ Capability** → Add **Background Modes**
7. Enable **Remote notifications**

### Step 4: Create CloudKit Schema

The schema needs to be created in CloudKit Dashboard the first time:

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your container: `iCloud.com.mladjan.vibestatus`
3. Go to **Schema** → **Record Types** → Click **+**
4. Create `Session` record type with fields:
   - `sessionId` (String, Indexed)
   - `status` (String)
   - `project` (String)
   - `timestamp` (Date/Time)
   - `pid` (Int64)
   - `macDeviceName` (String, Indexed)
5. Click **Save**
6. Deploy to Production when ready

**Note:** The app will auto-create the schema on first run in development, but you need to manually deploy it to production.

### Step 5: Configure App Bundle IDs

Update bundle identifiers to match your Apple Developer account:

**macOS:**
- In `Info.plist` or project settings
- Current: `com.mladjan.vibestatus`
- Update to your team's identifier

**iOS:**
- In project settings
- Current: (needs to be set)
- Set to: `com.mladjan.vibestatus.mobile` or similar

### Step 6: Update Entitlements Container ID (If Needed)

If you want to use a different iCloud container:

1. Update `CloudKitConstants.containerIdentifier` in `VibeStatusShared/Sources/VibeStatusShared/Constants.swift`
2. Update both `.entitlements` files:
   - `macOS/vibestatus/VibeStatus/VibeStatus.entitlements`
   - `iOS/VibeStatusMobile/VibeStatusMobile/VibeStatusMobile.entitlements`

### Step 7: Build and Test

**macOS App:**
```bash
cd macOS/vibestatus
xcodebuild -project VibeStatus.xcodeproj -scheme VibeStatus
```

**iOS App:**
```bash
cd iOS/VibeStatusMobile
xcodebuild -project VibeStatusMobile.xcodeproj -scheme VibeStatusMobile
```

## 🧪 Testing the Integration

### Test Scenario 1: Basic Sync

1. **macOS:**
   - Run the macOS app
   - Open Settings → General
   - Enable "Enable iOS Sync"
   - Verify "iCloud Connected" shows green checkmark
   - Start a Claude Code session

2. **iOS:**
   - Launch the iOS app on device/simulator
   - Grant notification permissions
   - Pull to refresh
   - Should see the Claude Code session appear

### Test Scenario 2: Status Changes

1. Start Claude Code and give it a task
2. iOS should show status as "Working" (⚙️)
3. When Claude finishes, iOS should show "Ready" (✅)
4. iOS should display a notification

### Test Scenario 3: Needs Input

1. In Claude Code, trigger a prompt that requires user input
2. macOS status should change to "Needs Input"
3. iOS should receive a critical notification
4. iOS app should show "❓ Input Needed" badge

### Test Scenario 4: Multiple Sessions

1. Open 3 different terminal windows
2. Start Claude Code in each
3. Both macOS and iOS should show all 3 sessions
4. Each session should have independent status

## 🐛 Troubleshooting

### Issue: "iCloud Not Available"

**Solutions:**
- Ensure you're signed into iCloud on Mac/iPhone
- Check System Settings → Apple ID → iCloud → iCloud Drive is enabled
- Verify CloudKit is enabled in Xcode capabilities
- Check entitlements file has correct container identifier

### Issue: Push Notifications Not Working

**Solutions:**
- Ensure you're testing on a real device (not simulator for APNs)
- Check iOS Settings → VibeStatus → Notifications are enabled
- Verify "Push Notifications" capability is added
- Check CloudKit subscription was created (check logs)

### Issue: Sessions Not Syncing

**Solutions:**
- Check macOS Settings shows "Enable iOS Sync" is ON
- Verify "iCloud Connected" shows green checkmark
- Check console logs for CloudKit errors
- Try triggering manual sync in iOS (pull to refresh)
- Verify CloudKit schema matches expected structure

### Issue: Build Errors

**Common fixes:**
- Clean build folder (Cmd+Shift+K)
- Delete DerivedData folder
- Verify VibeStatusShared package is properly linked
- Check all imports are correct
- Ensure deployment target is macOS 13+ / iOS 16+

## 📱 iOS App Features

### Session List View
- Displays all active Claude Code sessions
- Color-coded status indicators
- Grouped by Mac device name
- Pull to refresh
- Real-time updates via CloudKit push

### Settings View
- iCloud connection status
- Notification configuration
- Version and build info
- Debug tools (in debug builds)

### Notifications
- **Idle notification**: "✅ Ready - ProjectName has finished"
- **Needs Input notification**: "❓ Input Needed - ProjectName needs your response"
- Critical alerts for input needed (bypasses Do Not Disturb)

## 🔮 Future Enhancements (Phase 4)

These features are planned but not yet implemented:

### Bidirectional Communication
- Capture console output/prompts on macOS
- Display full prompt text in iOS app
- Allow responding to prompts from iPhone
- Send response back to Claude Code session

### Implementation Notes:
1. Extend hook script to capture prompt text
2. Create new CloudKit record type: `Prompt`
3. Add response interface in iOS app
4. Implement IPC mechanism on macOS to inject responses

## 📁 Project Structure

```
VibeStatus/
├── VibeStatusShared/              # Shared Swift package
│   ├── Package.swift
│   └── Sources/
│       └── VibeStatusShared/
│           ├── Models/
│           │   ├── VibeStatus.swift
│           │   └── SessionRecord.swift
│           ├── Managers/
│           │   └── CloudKitManager.swift
│           └── Constants.swift
│
├── macOS/
│   └── vibestatus/
│       └── VibeStatus/
│           ├── StatusManager.swift         # (Modified for CloudKit)
│           ├── CloudKitSyncManager.swift   # (New)
│           ├── SetupView.swift             # (Modified - added sync toggle)
│           └── VibeStatus.entitlements     # (Modified for CloudKit)
│
└── iOS/
    └── VibeStatusMobile/
        └── VibeStatusMobile/
            ├── SessionListView.swift       # Main UI
            ├── CloudKitViewModel.swift     # Session management
            ├── NotificationManager.swift   # Push notifications
            ├── SettingsView.swift          # Settings UI
            ├── VibeStatusMobileApp.swift   # App entry point
            └── VibeStatusMobile.entitlements  # CloudKit config
```

## 🔐 Privacy & Security

- All data stored in user's personal iCloud account
- No third-party servers or analytics
- Data never leaves Apple's infrastructure
- Can be deleted by user through iCloud settings
- CloudKit encryption at rest and in transit

## 📞 Support

If you encounter issues:
1. Check console logs in Xcode
2. Verify iCloud and notification permissions
3. Review CloudKit Dashboard for sync errors
4. Test with fresh CloudKit container if needed

## ✨ Summary

You now have:
- ✅ Complete shared data models
- ✅ CloudKit sync infrastructure
- ✅ macOS app with upload capability
- ✅ iOS app with session list and notifications
- ✅ Push notification support
- ✅ Settings interfaces on both platforms

**Next:** Follow the steps above to link the shared package and test the integration!
