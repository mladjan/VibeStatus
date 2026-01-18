# macOS App - Xcode Setup Instructions

## Issue: CloudKitSyncManager.swift not in Xcode project

The file exists on disk but needs to be added to the Xcode project.

### Option 1: Add via Xcode (Recommended)

1. Open `VibeStatus.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), find the **VibeStatus** folder
3. Right-click on the **VibeStatus** folder → **Add Files to "VibeStatus"...**
4. Navigate to: `/Users/mladjanantic/Work/VibeStatus/macOS/vibestatus/VibeStatus/`
5. Select `CloudKitSyncManager.swift`
6. Make sure these are checked:
   - ✅ **Copy items if needed** (UNCHECK this - file is already in the right location)
   - ✅ **Create groups**
   - ✅ **Add to targets: VibeStatus**
7. Click **Add**
8. Build again (Cmd+B)

### Option 2: Quick Command Line Fix

Run this command to add the file to the project:

```bash
cd /Users/mladjanantic/Work/VibeStatus/macOS/vibestatus
# Simply rebuild - Xcode should pick it up if you reopen
```

Actually, the better approach is to drag and drop:

1. Open Finder
2. Navigate to `/Users/mladjanantic/Work/VibeStatus/macOS/vibestatus/VibeStatus/`
3. Find `CloudKitSyncManager.swift`
4. In Xcode, open the project
5. Drag `CloudKitSyncManager.swift` from Finder into the Project Navigator
6. In the dialog:
   - ✅ **Create groups**
   - ✅ **Add to targets: VibeStatus**
   - ⬜ **Copy items if needed** (UNCHECK - already in place)
7. Click **Finish**

## Then: Link VibeStatusShared Package

After adding the file, you also need to link the shared package:

1. Select the **VibeStatus** project in the navigator
2. Select the **VibeStatus** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** → **Add Other...** → **Add Package Dependency...** → **Add Local...**
6. Navigate to: `/Users/mladjanantic/Work/VibeStatus/VibeStatusShared`
7. Click **Add Package**
8. Select **VibeStatusShared** library
9. Click **Add**

## Uncomment Integration Code

Search for "TODO: Uncomment" in `CloudKitSyncManager.swift` and uncomment all the CloudKit code.

## Build

1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
3. Product → Run (Cmd+R)

The macOS app should now build successfully!
