# How to Grant Automation Permission Manually

Since the permission dialog didn't appear automatically, follow these steps to grant it manually:

## Step 1: Open System Settings

1. Click the Apple menu () → **System Settings** (or **System Preferences** on older macOS)
2. Click **Privacy & Security** in the sidebar

## Step 2: Navigate to Automation

1. Scroll down in the Privacy & Security section
2. Click **Automation**

## Step 3: Check for VibeStatus

**Look for "VibeStatus" in the list of apps.**

### If You See VibeStatus:
1. Expand it by clicking the disclosure triangle
2. Look for **System Events** underneath
3. **Check the box** next to System Events
4. Close System Settings
5. The permission is now granted!

### If You DON'T See VibeStatus:

This means the system hasn't registered the app yet. Try this:

#### Option A: Reset and Trigger Permission Request
```bash
# Open Terminal and run:
tccutil reset AppleEvents com.mladjan.vibestatus

# This resets any previous decisions about AppleScript permissions
# Now quit and relaunch VibeStatus
# Send a response from iOS again - the dialog should appear
```

#### Option B: Force Register the App
```bash
# Add the permission manually using Terminal:
sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
"INSERT or REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.mladjan.vibestatus',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,1687924800);"

# Then restart VibeStatus
```

## Step 4: Verify It's Working

1. Make sure VibeStatus is running
2. Open Claude Code in Terminal
3. Trigger a prompt that needs input
4. Respond from your iPhone
5. Check the macOS logs - you should see:
   ```
   [ResponseHandler] ✅ Successfully sent response to Terminal
   ```
   Instead of:
   ```
   [ResponseHandler] ❌ Failed to send response to Terminal
   ```

## Quick Check Script

Run this in Terminal to check if the permission is granted:

```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
"SELECT service, client, allowed FROM access WHERE client='com.mladjan.vibestatus';"
```

You should see a line like:
```
kTCCServiceAppleEvents|com.mladjan.vibestatus|2
```

The `2` means permission is granted (allowed).

## Still Not Working?

If none of the above works:

1. **Complete clean reset:**
   ```bash
   # Reset all TCC permissions for VibeStatus
   tccutil reset All com.mladjan.vibestatus

   # Restart your Mac
   sudo reboot
   ```

2. After restart, launch VibeStatus
3. The permission dialog should appear on next response

## Manual Fallback

If you still can't get automatic forwarding to work, VibeStatus already has a fallback:
- ✅ Response is written to file: `/tmp/vibestatus-response-{session-id}.txt`
- ✅ Response is copied to clipboard
- ✅ You get a notification
- 📋 Just paste (Cmd+V) in Terminal where Claude is waiting
