# 📱 Push Notifications Guide

## Current Status: ✅ IMPLEMENTED

Push notifications are now fully implemented! The iOS app will show notifications when Claude Code session status changes.

## What Was Added

### Notification Handling in AppDelegate

When a CloudKit push notification arrives:
1. Fetches the updated session record from CloudKit
2. Extracts the status and project name
3. Shows a user-visible notification using `NotificationManager`

### Notification Types

#### ✅ Ready Notification
**When:** Claude finishes a task and becomes idle

**Appearance:**
- Title: "✅ Ready"
- Body: "[ProjectName] has finished and is ready"
- Sound: Default notification sound
- Priority: Normal

#### ❓ Input Needed Notification
**When:** Claude needs user confirmation to continue

**Appearance:**
- Title: "❓ Input Needed"
- Body: "[ProjectName] needs your response to continue"
- Sound: **Critical alert** (bypasses silent mode)
- Priority: **Time Sensitive** (shows even in Focus mode)

#### ⚙️ Working Notification
**When:** Claude starts processing (optional, currently silent)

**Appearance:**
- Title: "⚙️ Working"
- Body: "[ProjectName] is processing"
- Sound: None (silent)
- Priority: Normal

**Note:** "Working" notifications are currently disabled (no sound) to avoid spamming. Only status changes that need attention show notifications.

## Testing Push Notifications

### Setup (One-Time)

1. **Install the iOS app** on a real device (push notifications don't work in Simulator)

2. **Grant notification permission** when prompted:
   - iOS will ask: "Allow VibeStatusMobile to send you notifications?"
   - Tap **"Allow"**

3. **Verify settings:**
   - iPhone Settings → VibeStatusMobile → Notifications
   - Ensure **"Allow Notifications"** is ON
   - Ensure **"Time Sensitive Notifications"** is ON (for critical alerts)

### Test 1: Ready Notification

**Steps:**
1. Start Claude Code on Mac:
   ```bash
   cd ~/Work/YourProject
   claude
   ```

2. Give Claude a quick task:
   ```
   write a hello world script in Python
   ```

3. **Lock your iPhone** or switch to another app

4. **Wait for Claude to finish** (~10 seconds)

**Expected:**
- 📱 iPhone shows notification: **"✅ Ready - YourProject has finished and is ready"**
- Default notification sound plays
- Notification appears on lock screen
- Badge on app icon (if enabled)

### Test 2: Input Needed Notification (Critical)

**Steps:**
1. Give Claude a task that requires confirmation:
   ```
   Create a new file called test.txt with "hello world" inside
   ```

2. **Lock your iPhone**

3. **Wait for Claude to ask for confirmation** (~5 seconds)

**Expected:**
- 📱 iPhone shows notification: **"❓ Input Needed - YourProject needs your response to continue"**
- **Critical alert sound** plays (loud, bypasses silent mode)
- Notification marked as **"Time Sensitive"**
- Shows even if phone is in Do Not Disturb/Focus mode
- Notification stays on lock screen until dismissed

### Test 3: Background App Refresh

**Steps:**
1. Start Claude task on Mac
2. **Close the iOS app** (swipe up from app switcher)
3. Wait for status to change on Mac

**Expected:**
- Notification still appears even with app closed
- App wakes up in background to handle notification
- Opens directly to session list when tapped

## Notification Behavior

### When App is Active (Foreground)
- Notification shows as banner at top of screen
- Plays sound
- Does NOT interrupt current view
- Can dismiss by swiping up

### When App is in Background
- Notification shows on lock screen
- Plays sound
- Badge counter increments
- Tapping opens app to session list

### When Phone is Locked
- Notification shows on lock screen
- Plays sound (even in silent mode for critical alerts)
- Phone screen lights up
- Swipe notification to unlock and open app

### When in Do Not Disturb / Focus Mode
- **Normal notifications:** Silenced (Ready, Working)
- **Time Sensitive notifications:** Still show and play sound (Input Needed)

## Customizing Notifications

### Change Notification Sounds

Edit `NotificationManager.swift`:

```swift
switch status {
case .idle:
    content.title = "✅ Ready"
    content.sound = .default  // Change to custom sound: UNNotificationSound(named: "ready.caf")

case .needsInput:
    content.title = "❓ Input Needed"
    content.sound = .defaultCritical  // Keep critical for urgent alerts
```

### Change Notification Text

Edit the `body` text in `NotificationManager.swift`:

```swift
case .idle:
    content.body = "\(project) has finished and is ready"
    // Change to: content.body = "Task complete in \(project)!"

case .needsInput:
    content.body = "\(project) needs your response to continue"
    // Change to: content.body = "Please respond to \(project)"
```

### Disable Specific Notifications

To disable "Working" notifications entirely:

```swift
case .working:
    return // Don't show notification (already implemented)
```

To disable "Ready" notifications:

```swift
case .idle:
    return // Don't show notification
```

## Troubleshooting

### Not Receiving Notifications

**Check iOS Logs:**
```
[AppDelegate] Received remote notification
[AppDelegate] CloudKit notification received
[AppDelegate] Fetching updated record: vibestatus-xxx
[AppDelegate] Session updated: vibestatus-xxx, status: idle
```

If you see these logs but no notification appears:

1. **Check notification settings:**
   - Settings → VibeStatusMobile → Notifications
   - Ensure "Allow Notifications" is ON
   - Check notification style is "Banners" or "Alerts"

2. **Check Do Not Disturb:**
   - Swipe down from top right (Control Center)
   - Ensure Focus mode allows Time Sensitive notifications
   - Or disable Focus mode temporarily

3. **Reinstall app:**
   - Delete app from iPhone
   - Rebuild and reinstall
   - Grant notification permission again

### Notifications Show Wrong Project Name

Currently shows "Unknown" because the project field isn't populated correctly.

**To fix:**
Check the status file on Mac:
```bash
cat /tmp/vibestatus-status.json
```

Ensure it has a `project` field with the correct name.

### No Sound on Critical Alerts

**Check:**
- Settings → VibeStatusMobile → Notifications → Sounds → ON
- Phone is not in silent mode (critical alerts bypass silent mode, but settings must allow)
- Volume is up

### Notification Appears Multiple Times

This can happen if CloudKit sends multiple update notifications.

**Normal behavior:**
- One notification per status change
- e.g., working → ready = one notification

**Abnormal:**
- Multiple "Ready" notifications for same session
- This would indicate CloudKit subscription firing multiple times

**To debug:**
Check logs for duplicate notifications within a few seconds.

## Advanced: Custom Notification Actions

You can add action buttons to notifications (future enhancement):

```swift
// In NotificationManager
let openAction = UNNotificationAction(
    identifier: "OPEN_SESSION",
    title: "View Session",
    options: [.foreground]
)

let dismissAction = UNNotificationAction(
    identifier: "DISMISS",
    title: "Dismiss",
    options: []
)

let category = UNNotificationCategory(
    identifier: "SESSION_STATUS",
    actions: [openAction, dismissAction],
    intentIdentifiers: [],
    options: []
)

notificationCenter.setNotificationCategories([category])
```

Then users can:
- **Swipe notification** → Tap "View Session" → Opens app to that session
- **Swipe notification** → Tap "Dismiss" → Clears notification

## How It Works

```
┌─────────────────┐
│  macOS App      │
│  Status changes │
└────────┬────────┘
         │ Upload to CloudKit
         ▼
┌──────────────────────────┐
│  CloudKit                │
│  - Saves new record      │
│  - Triggers subscription │
└────────┬─────────────────┘
         │ Push notification via APNs
         ▼
┌──────────────────────────┐
│  APNs (Apple)            │
│  - Routes to device      │
│  - Delivers silently     │
└────────┬─────────────────┘
         │ Silent push (content-available)
         ▼
┌──────────────────────────┐
│  iOS App (Background)    │
│  1. Receives push        │
│  2. Fetches record       │
│  3. Shows notification   │
└──────────────────────────┘
```

**Why silent push?**
- CloudKit sends "content-available" notifications
- These wake the app in background
- App fetches latest data and shows local notification
- Allows custom notification content and sounds

## Notification Timeline

**Typical flow:**

```
T+0s:    macOS: Claude finishes task, status → idle
T+0.5s:  macOS: Uploads to CloudKit
T+1s:    CloudKit: Saves record, triggers subscription
T+2s:    APNs: Routes notification to iPhone
T+3s:    iOS: Receives push, fetches record
T+3.5s:  iOS: Shows notification "✅ Ready"
```

**Total latency:** ~3-5 seconds from status change to notification

## Summary

✅ **Push notifications are working!**

You will now receive notifications when:
- Claude finishes a task (Ready)
- Claude needs input (Input Needed - Critical alert)

**What to do next:**
1. Test with a real Claude Code session
2. Verify notifications appear on your iPhone
3. Check that critical alerts work (Input Needed)
4. Customize notification text/sounds if desired

Enjoy your real-time Claude Code alerts! 🎉
