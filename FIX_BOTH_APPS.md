# Fix VibeStatusShared Package for Both macOS and iOS

## Problem
The package works for macOS but shows as a "shortcut" in iOS and gives "Missing package product" error.

## Root Cause
When you add a local package via Xcode's "Add Local..." it can sometimes create file system references that conflict between projects.

## Solution: Use Xcode Workspaces (Recommended) OR Manual Fix

### Option 1: Create an Xcode Workspace (Best Solution)

This allows both projects to share the same package cleanly.

#### Step 1: Create Workspace
```bash
cd /Users/mladjanantic/Work/VibeStatus
mkdir -p VibeStatus.xcworkspace
```

#### Step 2: Create workspace file

Create `/Users/mladjanantic/Work/VibeStatus/VibeStatus.xcworkspace/contents.xcworkspacedata`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:macOS/vibestatus/VibeStatus.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:iOS/VibeStatusMobile/VibeStatusMobile.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:VibeStatusShared">
   </FileRef>
</Workspace>
```

#### Step 3: Open the workspace
```bash
open VibeStatus.xcworkspace
```

#### Step 4: Add package to both targets
1. In the workspace, you'll see both projects
2. For **macOS app**: Select VibeStatus target → General → Add VibeStatusShared
3. For **iOS app**: Select VibeStatusMobile target → General → Add VibeStatusShared

This way both apps can use the same package without conflicts.

---

### Option 2: Quick Fix (Remove and Re-add in iOS)

If you don't want to use a workspace:

#### For iOS App:

1. **Close Xcode completely**

2. **Clean everything:**
```bash
cd /Users/mladjanantic/Work/VibeStatus/iOS/VibeStatusMobile
rm -rf ~/Library/Developer/Xcode/DerivedData/VibeStatusMobile*
```

3. **Remove broken package reference manually:**
```bash
# Backup first
cp VibeStatusMobile.xcodeproj/project.pbxproj VibeStatusMobile.xcodeproj/project.pbxproj.backup

# Remove VibeStatusShared references (we'll add back properly)
# This is done in Xcode - see below
```

4. **Open Xcode:**
```bash
open VibeStatusMobile.xcodeproj
```

5. **Remove package reference:**
   - Select **VibeStatusMobile** project
   - Go to **Package Dependencies** tab (at project level, not target)
   - Find `VibeStatusShared`
   - Select it and click **-** (minus)
   - Confirm removal

6. **Close Xcode again**

7. **Re-open and add package correctly:**
   - Open `VibeStatusMobile.xcodeproj`
   - Select **VibeStatusMobile** TARGET
   - Go to **General** tab
   - Scroll to **Frameworks, Libraries, and Embedded Content**
   - Click **+**
   - Click **Add Other...** → **Add Package Dependency...**
   - Click **Add Local...** (top right)
   - Navigate to: `/Users/mladjanantic/Work/VibeStatus/VibeStatusShared`
   - Click **Add Package**
   - Select **VibeStatusShared** product
   - Click **Add**

8. **Verify it's a package, not a shortcut:**
   - In Project Navigator, you should see the package icon (📦) not a folder/alias icon
   - Under **Package Dependencies** section, not in the file tree

9. **Build:**
   - Clean (Cmd+Shift+K)
   - Build (Cmd+B)

---

### Option 3: Symlink Issue (If still showing as shortcut)

The shortcut icon suggests Xcode is treating it as a file reference instead of a package. This can happen if:

1. **Check for symlinks:**
```bash
ls -la /Users/mladjanantic/Work/VibeStatus/iOS/VibeStatusMobile/
```

If you see a `VibeStatusShared` symlink there, remove it:
```bash
rm /Users/mladjanantic/Work/VibeStatus/iOS/VibeStatusMobile/VibeStatusShared
```

2. **Then add the package again as described in Option 2**

---

## Verify Package Structure

Both apps should reference the SAME package at:
```
/Users/mladjanantic/Work/VibeStatus/VibeStatusShared
```

**NOT:**
- A copy in the iOS folder
- A copy in the macOS folder
- A symlink

## After Fix: Both Apps Should Have

In **Frameworks, Libraries, and Embedded Content**:
```
VibeStatusShared (package icon, not folder icon)
```

In **Package Dependencies** (project level):
```
VibeStatusShared
Location: /Users/mladjanantic/Work/VibeStatus/VibeStatusShared
```

## Test Both Apps

After fixing:

**macOS:**
```bash
cd /Users/mladjanantic/Work/VibeStatus/macOS/vibestatus
xcodebuild -project VibeStatus.xcodeproj -scheme VibeStatus build
```

**iOS:**
```bash
cd /Users/mladjanantic/Work/VibeStatus/iOS/VibeStatusMobile
xcodebuild -project VibeStatusMobile.xcodeproj -scheme VibeStatusMobile -sdk iphonesimulator build
```

Both should build successfully!

---

## My Recommendation

Use **Option 1 (Workspace)**. It's the cleanest solution for multi-project setups sharing a common package.
