# Xcode Setup Instructions

## Issue 1: Enable Push Notifications

The `aps-environment` error means you need to add the Push Notifications capability in Xcode:

1. Open `VibeStatusMobile.xcodeproj` in Xcode
2. Select the **VibeStatusMobile** project in the navigator
3. Select the **VibeStatusMobile** target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability** button
6. Add **Push Notifications**
7. Add **Background Modes** and check:
   - ✅ Remote notifications
8. Build and run again

## Issue 2: Link VibeStatusShared Package

1. In Xcode, with the project open
2. Select the **VibeStatusMobile** project in the navigator
3. Select the **VibeStatusMobile** target
4. Go to **General** tab
5. Scroll down to **Frameworks, Libraries, and Embedded Content**
6. Click the **+** button
7. Click **Add Other...** → **Add Package Dependency...**
8. Click **Add Local...**
9. Navigate to and select: `/Users/mladjanantic/Work/VibeStatus/VibeStatusShared`
10. Click **Add Package**
11. Select **VibeStatusShared** library
12. Click **Add**

## Issue 3: Uncomment Integration Code

Once the package is linked, search for "TODO: Uncomment" in these files and uncomment the code:

### iOS Files:
- `CloudKitViewModel.swift` - Remove temporary types at bottom, uncomment CloudKit operations
- `VibeStatusMobileApp.swift` - Uncomment CloudKit setup calls

### Steps:
1. In Xcode, press Cmd+Shift+F (Find in Project)
2. Search for: `TODO: Uncomment`
3. For each result, uncomment the code as instructed

## Issue 4: Configure iCloud

1. Go to **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add **iCloud**
4. Check:
   - ✅ CloudKit
5. Select container: `iCloud.com.mladjan.vibestatus`

## After All Changes

Clean and rebuild:
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
3. Product → Run (Cmd+R)

The app should now:
- ✅ Register for push notifications successfully
- ✅ Show sessions synced from your Mac
- ✅ Send notifications when status changes
