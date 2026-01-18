# Git Repository Strategy for VibeStatus

## Current Situation

You currently have:
- ✅ **macOS app** in git: `/Users/mladjanantic/Work/VibeStatus/macOS/vibestatus/.git`
- ❌ **iOS app** NOT in git: `/Users/mladjanantic/Work/VibeStatus/iOS/`
- ❌ **Shared package** NOT in git: `/Users/mladjanantic/Work/VibeStatus/VibeStatusShared/`
- ❌ **Workspace** NOT in git: `/Users/mladjanantic/Work/VibeStatus/VibeStatus.xcworkspace/`
- ❌ **Documentation** NOT in git: All the `.md` files in root

## Recommended Strategy: Monorepo

I recommend creating a **parent git repository** at `/Users/mladjanantic/Work/VibeStatus/` that contains everything.

### Why Monorepo?

**Advantages:**
- ✅ Single source of truth for the entire project
- ✅ Shared code (VibeStatusShared) versioned with both apps
- ✅ Workspace configuration under version control
- ✅ Documentation in one place
- ✅ Easier to sync changes across iOS/macOS
- ✅ Single commit can update both apps + shared code

**The Challenge:**
- The macOS app already has its own git repo
- We need to preserve its history or migrate it

## Option 1: Fresh Monorepo (Recommended)

Create a new repo at the root and move macOS repo content.

### Steps:

```bash
# 1. Navigate to VibeStatus root
cd /Users/mladjanantic/Work/VibeStatus

# 2. Initialize new git repo
git init

# 3. Create comprehensive .gitignore
cat > .gitignore << 'EOF'
# Xcode
*.xcodeproj/project.xcworkspace/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# Swift Package Manager
.build/
.swiftpm/

# Build artifacts
build/
export/
release/
macOS/vibestatus/build/
macOS/vibestatus/export/
macOS/vibestatus/release/

# Sparkle
*.delta
*.dmg

# Temporary files
*.swp
*~

# Documentation (optional - you might want to commit these)
# ARCHITECTURE.md
# CLOUDKIT_DASHBOARD_FIX.md
# etc...

# Claude Code
.claude/
EOF

# 4. Stage all files
git add .

# 5. Create initial commit
git commit -m "Initial monorepo with macOS, iOS, and shared package

- macOS app with CloudKit sync
- iOS companion app
- VibeStatusShared Swift package
- Xcode workspace
- Documentation
"

# 6. (Optional) Remove old macOS git repo
rm -rf macOS/vibestatus/.git

# 7. (Optional) Add remote if you have one
# git remote add origin <your-repo-url>
# git push -u origin main
```

**Pros:**
- Clean, simple structure
- Everything in one place
- Easy to manage

**Cons:**
- Loses macOS git history (can be preserved separately if needed)

## Option 2: Keep Separate Repos (Not Recommended)

Keep three separate repositories:

```
VibeStatus/
├── macOS/vibestatus/        (existing repo)
├── iOS/VibeStatusMobile/    (new repo)
└── VibeStatusShared/        (new repo)
```

**Setup:**

```bash
# iOS repo
cd /Users/mladjanantic/Work/VibeStatus/iOS/VibeStatusMobile
git init
# ... add files and commit

# Shared package repo
cd /Users/mladjanantic/Work/VibeStatus/VibeStatusShared
git init
# ... add files and commit
```

**Pros:**
- Preserves macOS git history as-is
- Independent versioning

**Cons:**
- ❌ Harder to keep in sync
- ❌ Shared package changes require commits in 3 repos
- ❌ Workspace not under version control
- ❌ Documentation scattered

## Option 3: Git Submodules (Complex, Not Recommended)

Create a parent repo with macOS/iOS/Shared as submodules.

**Don't do this unless:**
- You have multiple teams working independently
- You need truly independent versioning
- You're already familiar with submodules

**Why avoid:**
- Submodules are complex
- Easy to mess up
- Overkill for a single developer

## Recommended: Option 1 (Monorepo)

Here's exactly what to do:

### Step-by-Step Guide

#### 1. Backup Current macOS Git History (Optional)

If you want to preserve the macOS git history separately:

```bash
cd /Users/mladjanantic/Work/VibeStatus/macOS/vibestatus
git log --oneline > ~/vibestatus-macos-history.txt
```

#### 2. Create Root .gitignore

```bash
cd /Users/mladjanantic/Work/VibeStatus

cat > .gitignore << 'EOF'
# Xcode
*.xcodeproj/project.xcworkspace/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM
*.xccheckout
*.moved-aside

# macOS
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes

# Swift Package Manager
.build/
.swiftpm/
*.resolved

# Build artifacts
build/
export/
release/
*/build/
*/export/
*/release/

# Sparkle
*.delta
*.dmg

# Temporary files
*.swp
*~
.#*

# Development documentation (optional - you can commit if you want)
# These are development notes, you may or may not want them in repo
ARCHITECTURE.md
CLOUDKIT_DASHBOARD_FIX.md
FINAL_FIX.md
FINAL_SUMMARY.md
FIX_BOTH_APPS.md
INTEGRATION_GUIDE.md
PUSH_NOTIFICATIONS_GUIDE.md
QUERYABLE_ERROR_EXPLAINED.md
QUERY_FIX_APPLIED.md
SETUP_CLOUDKIT.md
SUCCESS.md
SYNC_FIXES.md
SYNC_IS_WORKING.md
TEST_NOW.md
VERIFICATION_STEPS.md
GIT_STRATEGY.md
OPEN_WORKSPACE.sh

# Claude Code
.claude/
EOF
```

**Note:** I've excluded the documentation `.md` files by default since they're development notes. You can remove those lines from `.gitignore` if you want to commit them.

#### 3. Initialize Repository

```bash
cd /Users/mladjanantic/Work/VibeStatus
git init
```

#### 4. Review What Will Be Committed

```bash
git status
```

You should see:
- `iOS/` directory (new)
- `VibeStatusShared/` directory (new)
- `VibeStatus.xcworkspace/` (new)
- `macOS/vibestatus/` (modified - includes CloudKitSyncManager.swift)

#### 5. Stage and Commit

```bash
# Add everything
git add .

# Review what's staged
git status

# Create initial commit
git commit -m "Add iOS app and CloudKit sync to VibeStatus

- iOS companion app for monitoring Claude Code sessions
- VibeStatusShared Swift package for common code
- CloudKit integration for real-time sync
- Push notifications for status changes
- Xcode workspace for unified development

macOS app updates:
- CloudKitSyncManager for sync coordination
- CloudKit entitlements
- Settings UI for iOS sync toggle

iOS app features:
- Session list view with real-time updates
- CloudKit integration
- Push notifications (Ready, Input Needed)
- Pull-to-refresh

Shared package:
- CloudKitManager for CloudKit operations
- SessionRecord models
- Constants and utilities
"
```

#### 6. Clean Up Old Git Repo

```bash
# Remove the old macOS-only git repo
rm -rf macOS/vibestatus/.git

# Remove macOS .gitignore (now using root one)
rm macOS/vibestatus/.gitignore
```

#### 7. Verify

```bash
git status
# Should show: nothing to commit, working tree clean

git log --oneline
# Should show your initial commit

ls -la .git
# Should show git repo at root
```

#### 8. Add Remote (Optional)

If you have a GitHub/GitLab repo:

```bash
git remote add origin https://github.com/yourusername/vibestatus.git
git branch -M main
git push -u origin main
```

## File Structure After Setup

```
VibeStatus/                           (git repo root)
├── .git/                            ✅ New git repo
├── .gitignore                       ✅ Root gitignore
├── README.md                        (create new one)
│
├── macOS/
│   └── vibestatus/
│       ├── VibeStatus.xcodeproj/
│       ├── VibeStatus/              (macOS source code)
│       └── (no .git anymore)        ✅ Removed
│
├── iOS/
│   └── VibeStatusMobile/
│       ├── VibeStatusMobile.xcodeproj/
│       └── VibeStatusMobile/        (iOS source code)
│
├── VibeStatusShared/
│   ├── Package.swift
│   └── Sources/
│       └── VibeStatusShared/
│
└── VibeStatus.xcworkspace/          ✅ Committed
    └── contents.xcworkspacedata
```

## What to Commit

### Always Commit:
- ✅ Source code (`.swift` files)
- ✅ Project files (`.xcodeproj/project.pbxproj`)
- ✅ Workspace (`.xcworkspace/contents.xcworkspacedata`)
- ✅ Package manifests (`Package.swift`)
- ✅ Entitlements files
- ✅ Info.plist files
- ✅ Assets.xcassets
- ✅ Storyboards/XIBs (if any)
- ✅ README.md

### Never Commit:
- ❌ `DerivedData/`
- ❌ `.DS_Store`
- ❌ `*.xcuserdata/`
- ❌ Build artifacts
- ❌ `.swiftpm/` (Swift Package Manager cache)
- ❌ Personal workspace settings

### Optional (Your Choice):
- ⚠️ Development documentation (`.md` files)
- ⚠️ Test scripts
- ⚠️ Build scripts (probably yes)
- ⚠️ `.claude/` directory (Claude Code settings)

## Creating a README

Create a proper README for the repo:

```bash
cd /Users/mladjanantic/Work/VibeStatus

cat > README.md << 'EOF'
# VibeStatus

Monitor your Claude Code terminal sessions from anywhere.

## Features

### macOS App
- Menu bar widget showing Claude Code session status
- Real-time status updates (Working, Ready, Input Needed)
- Multiple concurrent session support
- CloudKit sync to iOS (optional)

### iOS App
- View all active Claude Code sessions
- Real-time sync from macOS via CloudKit
- Push notifications for status changes
- Critical alerts for input needed

## Project Structure

```
VibeStatus/
├── macOS/vibestatus/        # macOS menu bar app
├── iOS/VibeStatusMobile/    # iOS companion app
├── VibeStatusShared/        # Shared Swift package
└── VibeStatus.xcworkspace   # Xcode workspace
```

## Requirements

- macOS 13.0+ (Ventura)
- iOS 16.0+
- Xcode 15.0+
- iCloud account (for sync)

## Setup

1. Open `VibeStatus.xcworkspace` in Xcode
2. Select target (VibeStatus for macOS, VibeStatusMobile for iOS)
3. Build and run

### CloudKit Setup

For sync to work:
1. Enable iCloud capability in both apps
2. Configure CloudKit container: `iCloud.com.mladjan.vibestatus`
3. Enable "Queryable" for Session record type in CloudKit Dashboard

## How It Works

1. macOS app monitors `/tmp/vibestatus-*.json` files created by Claude Code hooks
2. Displays status in menu bar
3. Optionally uploads to CloudKit for iOS sync
4. iOS app queries CloudKit every 5 seconds + receives push notifications
5. Shows notifications when status changes

## License

[Your License Here]
EOF
```

## Post-Setup Tasks

### 1. Update macOS Repo (If Public)

If your macOS repo is already public on GitHub:

1. Archive the old repo or add a notice:
   ```
   This repo has been merged into the main VibeStatus monorepo at:
   https://github.com/yourusername/vibestatus
   ```

2. Or redirect the old repo:
   - Rename old repo to `vibestatus-macos-legacy`
   - Create new monorepo as `vibestatus`

### 2. Set Up Branch Protection

If using GitHub:
- Protect `main` branch
- Require pull requests for changes
- Enable CI/CD (optional)

### 3. Add Git Hooks (Optional)

Pre-commit hook to ensure code compiles:

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# Build macOS app
xcodebuild -workspace VibeStatus.xcworkspace -scheme VibeStatus -configuration Debug build

if [ $? -ne 0 ]; then
    echo "❌ macOS build failed"
    exit 1
fi

echo "✅ All checks passed"
exit 0
```

## Summary

**Recommended:** Create a monorepo at the root with everything.

**Quick commands:**
```bash
cd /Users/mladjanantic/Work/VibeStatus
git init
# Copy .gitignore from above
git add .
git commit -m "Initial monorepo commit"
rm -rf macOS/vibestatus/.git
```

**Result:**
- ✅ Single repo for all code
- ✅ Shared package versioned with apps
- ✅ Workspace under version control
- ✅ Clean, simple structure
- ✅ Easy to sync and deploy

This is the industry-standard approach for multi-platform Apple projects! 🎉
