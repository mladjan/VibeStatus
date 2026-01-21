# macOS Permissions Setup for iOS Response Feature

## Required Permission

For VibeStatus to send responses from your iPhone to Terminal, it needs **Automation permission** to control System Events.

## Setup Instructions

### Option 1: Automatic Permission Request (Recommended)

1. Rebuild and run the VibeStatus app
2. When you receive a response from iOS for the first time, macOS will show a permission dialog
3. Click **OK** to grant permission
4. The response will be sent to Terminal automatically

### Option 2: Manual Permission Setup

If the automatic dialog doesn't appear, you can grant permission manually:

1. Open **System Settings** (or System Preferences on older macOS)
2. Go to **Privacy & Security**
3. Scroll down and click **Automation**
4. Find **VibeStatus** in the list
5. Check the box next to **System Events**
6. Restart VibeStatus

### Option 3: If Permission is Still Denied

If you see this error in the logs:
```
Not authorized to send Apple events to System Events
```

And the permission dialog never appeared:

1. Open Terminal
2. Run this command:
   ```bash
   tccutil reset AppleEvents
   ```
3. Restart your Mac
4. Launch VibeStatus again
5. The permission dialog should now appear

## Fallback Behavior

If permission is not granted, VibeStatus will:
- ✅ Write the response to a file: `/tmp/vibestatus-response-{session-id}.txt`
- ✅ Copy the response to your clipboard
- ℹ️ You can manually paste the response into Terminal

## Verifying Permission

To check if permission is granted:
1. Check Settings > Privacy & Security > Automation
2. Look for VibeStatus → System Events (should be checked)

Or check the app logs - you should see:
```
[ResponseHandler] ✅ Successfully sent response to Terminal
```

Instead of:
```
[ResponseHandler] ❌ Failed to send response to Terminal
```

## Security Note

This permission allows VibeStatus to simulate keyboard input to send responses to Terminal. It only activates when you respond to a Claude prompt from your iPhone.
