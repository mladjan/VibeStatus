# Fix "Missing package product 'VibeStatusShared'" Error

## Problem
You're getting: `Missing package product 'VibeStatusShared'`

This happens when the package is referenced but Xcode can't properly resolve it.

## Solution: Remove and Re-add the Package

### Step 1: Remove the Broken Package Reference

1. Open `VibeStatus.xcodeproj` in Xcode
2. Select the **VibeStatus** project (top of navigator)
3. Go to **Project** (not Target) settings
4. Select **Package Dependencies** tab
5. Find `VibeStatusShared` in the list
6. Select it and click **-** (minus button) to remove it
7. Confirm removal

### Step 2: Clean Derived Data

Close Xcode, then run:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/VibeStatus*
```

Or in Xcode:
- **Xcode** → **Settings** → **Locations** → Click arrow next to DerivedData path
- Delete the `VibeStatus...` folders

### Step 3: Re-open and Add Package Correctly

1. Open `VibeStatus.xcodeproj` in Xcode again
2. Select the **VibeStatus** project in navigator
3. Select the **VibeStatus** TARGET (not project)
4. Go to **General** tab
5. Scroll down to **Frameworks, Libraries, and Embedded Content**
6. Click **+** button
7. Click **Add Other...** → **Add Package Dependency...**
8. At the top right, click **Add Local...**
9. Navigate to and select: `/Users/mladjanantic/Work/VibeStatus/VibeStatusShared`
10. Click **Add Package**
11. In the next dialog, select **VibeStatusShared** product
12. Make sure it's being added to the **VibeStatus** target
13. Click **Add**

### Step 4: Verify Package is Linked

1. Select the **VibeStatus** target
2. Go to **General** tab
3. Under **Frameworks, Libraries, and Embedded Content**
4. You should see `VibeStatusShared` with path showing `VibeStatusShared`

### Step 5: Build

1. Clean Build Folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
2. Build: **Product** → **Build** (Cmd+B)

## Alternative: Check Package Path

If still having issues:

1. Select **VibeStatus** project (not target)
2. Go to **Package Dependencies** tab
3. Select `VibeStatusShared`
4. Check the **Location** field shows:
   `/Users/mladjanantic/Work/VibeStatus/VibeStatusShared`
5. If path is wrong or shows "Unable to resolve", remove and re-add

## Verify Package Structure

The package should have this structure:
```
VibeStatusShared/
├── Package.swift
└── Sources/
    └── VibeStatusShared/
        ├── VibeStatusShared.swift
        ├── Constants.swift
        ├── Models/
        │   ├── VibeStatus.swift
        │   └── SessionRecord.swift
        └── Managers/
            └── CloudKitManager.swift
```

You can verify with:
```bash
cd /Users/mladjanantic/Work/VibeStatus/VibeStatusShared
swift build
```

Should output: `Build complete!`

## Still Not Working?

Try this nuclear option:

1. Close Xcode
2. Delete the package reference manually:
```bash
cd /Users/mladjanantic/Work/VibeStatus/macOS/vibestatus
# Edit VibeStatus.xcodeproj/project.pbxproj and remove VibeStatusShared references
# OR just remove and re-add in Xcode
```
3. Clean everything:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```
4. Open Xcode and add package as described above
