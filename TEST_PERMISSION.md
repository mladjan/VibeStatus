# How to Trigger the Permission Dialog

I've added a test feature to force the permission dialog to appear!

## Steps to Get Permission Dialog

### 1. Rebuild the App
```bash
# In Xcode:
# 1. Product → Clean Build Folder (Shift+Cmd+K)
# 2. Product → Build (Cmd+B)
# 3. Product → Run (Cmd+R)
```

### 2. Use the Test Menu Item

Once the app is running:

1. Click the **VibeStatus menu bar icon** (should show your session status)
2. Look for the menu item: **"Test iOS Response Permission..."**
3. Click it

### 3. What Should Happen

**Option A - If permission not granted yet:**
- macOS will show a permission dialog asking:
  > **"VibeStatus would like to control Terminal"**
  >
  > VibeStatus needs permission to send responses from your iPhone to Terminal when Claude needs input.
- Click **OK** to grant permission
- You'll see a success notification
- Check the Console logs - should see: `✅ Permission test passed`

**Option B - If permission is denied:**
- Terminal will briefly activate but nothing else happens
- You'll see an error in Console: `❌ Permission test failed`
- You'll get a notification to grant permission in System Settings

**Option C - If permission already granted:**
- Terminal will activate
- You'll see: `✅ Permission test passed - automation is working!`
- Future iOS responses will be automatically sent to Terminal

### 4. Check System Settings

After clicking the test menu item:
1. Open **System Settings** → **Privacy & Security** → **Automation**
2. VibeStatus should now appear in the list
3. Expand it to see **Terminal** (should be checked)

## Why This Should Work

The test menu item:
- ✅ Executes AppleScript to activate Terminal
- ✅ This triggers macOS to show the permission dialog
- ✅ Uses the `NSAppleEventsUsageDescription` we added to Info.plist
- ✅ Works even if no Claude session is running

## Troubleshooting

### If the dialog still doesn't appear:

1. **Check app is signed:**
   ```bash
   codesign -dv /path/to/VibeStatus.app
   ```
   Should show signing information, not "code object is not signed"

2. **Try running from Xcode with Console open:**
   - Open Console.app
   - Filter for "VibeStatus"
   - Run the test
   - Look for TCC (Transparency, Consent, Control) related messages

3. **Nuclear option - Full reset:**
   ```bash
   # Kill the app
   killall VibeStatus

   # Reset ALL permissions for the app
   tccutil reset All com.vibestatus.app

   # Clear all app state
   rm -rf ~/Library/Saved\ Application\ State/com.vibestatus.app.savedState
   rm -rf ~/Library/Preferences/com.vibestatus.app.plist

   # Rebuild and run from Xcode
   # Then use the Test menu item
   ```

## Success Indicators

You know it's working when:
- ✅ Dialog appeared and you clicked OK
- ✅ VibeStatus appears in System Settings → Automation
- ✅ Test shows: `✅ Permission test passed`
- ✅ Terminal is checked under VibeStatus in Automation settings

## Current Fallback

Remember: Even without permission, VibeStatus still works! It just copies responses to your clipboard instead of typing them automatically.
