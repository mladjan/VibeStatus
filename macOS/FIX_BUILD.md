# macOS App Build Fix

## Problem
`CloudKitSyncManager.swift` exists but isn't in the Xcode project, causing "Cannot find 'CloudKitSyncManager' in scope" errors.

## Solution: Add the file in Xcode

### Step 1: Open Xcode
```bash
cd /Users/mladjanantic/Work/VibeStatus/macOS/vibestatus
open VibeStatus.xcodeproj
```

### Step 2: Add CloudKitSyncManager.swift

**Method A: Drag and Drop (Easiest)**
1. Open Finder
2. Navigate to: `/Users/mladjanantic/Work/VibeStatus/macOS/vibestatus/VibeStatus/`
3. Find `CloudKitSyncManager.swift`
4. Drag it from Finder into Xcode's Project Navigator (into the "VibeStatus" folder)
5. In the dialog that appears:
   - ⬜ **UNCHECK** "Copy items if needed"
   - ✅ **CHECK** "Create groups"
   - ✅ **CHECK** "Add to targets: VibeStatus"
6. Click **Finish**

**Method B: Add Files Menu**
1. In Xcode Project Navigator, right-click the **VibeStatus** folder
2. Choose **Add Files to "VibeStatus"...**
3. Navigate to: `/Users/mladjanantic/Work/VibeStatus/macOS/vibestatus/VibeStatus/`
4. Select `CloudKitSyncManager.swift`
5. **Important checkbox settings:**
   - ⬜ **UNCHECK** "Copy items if needed" (file already in correct location)
   - ✅ **CHECK** "Create groups"
   - ✅ **CHECK** "Add to targets: VibeStatus"
6. Click **Add**

### Step 3: Verify File is Added

Check that `CloudKitSyncManager.swift` now appears in the Project Navigator with a file icon (not grayed out).

### Step 4: Build

1. Clean build folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
2. Build: **Product** → **Build** (Cmd+B)
3. Should succeed with no errors!

## What the file does

`CloudKitSyncManager.swift` is the bridge between your macOS app and CloudKit:
- Uploads session data to iCloud
- Cleans up stale sessions
- Manages sync state

The file is already updated with all the correct imports and code - it just needs to be added to the Xcode project!

## If Still Having Issues

Make sure the **VibeStatusShared** package is properly linked:
1. Select project → target → **General** tab
2. Under **Frameworks, Libraries, and Embedded Content**
3. You should see **VibeStatusShared**
4. If not, add it (see main INTEGRATION_GUIDE.md)
