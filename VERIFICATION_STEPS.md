# ✅ Verification Steps After Enabling Queryable

## Before Testing

### 1. Enable Queryable in CloudKit Dashboard
Follow the steps in `CLOUDKIT_DASHBOARD_FIX.md`:

1. Go to https://icloud.developer.apple.com/
2. Select container: `iCloud.com.mladjan.vibestatus`
3. Select **Development** environment
4. Click **Schema** → **Record Types** → **Session**
5. Check the **"Queryable"** checkbox at the top
6. Click **Save**
7. Wait 1-2 minutes for changes to propagate

## Testing the Fix

### Step 1: Clean Existing Data (Optional)
If you have duplicate/corrupted records from testing:

**Option A: Dashboard Cleanup**
1. CloudKit Dashboard → Data → Query Records
2. Type: `Session`
3. Delete any old records

**Option B: Let Auto-Cleanup Work**
- Sessions expire after 30 minutes automatically
- Just wait for them to clean up naturally

### Step 2: Start Fresh

**macOS:**
1. Open VibeStatus from workspace
2. Build and run (⌘+R)
3. Enable iOS Sync in Settings
4. Should see: `iCloud status: available`

**iOS:**
1. Open VibeStatusMobile from workspace
2. Build and run on device (⌘+R)
3. Should see: `iCloud status: available`

### Step 3: Create Test Session

```bash
# In terminal:
cd ~/Work/VibeStatus
claude
```

Then give Claude a task:
```
create a simple hello world python script
```

### Step 4: Verify macOS Upload

**Expected macOS Logs:**
```
iCloud status: available
Creating new session: vibestatus-xxx
Successfully uploaded session: vibestatus-xxx - VibeStatus
```

**NOT Expected:**
```
❌ Cannot sync - iCloud not available
❌ record to insert already exists
```

### Step 5: Verify iOS Fetch

**Pull to refresh on iOS** (swipe down on session list)

**Expected iOS Logs:**
```
iCloud status: available
Successfully created CloudKit subscription
Fetched 1 active sessions
```

**Expected iOS UI:**
- Session appears in list
- Project name: "VibeStatus"
- Status: "Working..." (orange/yellow)
- Timestamp shows current time

**NOT Expected:**
```
❌ Failed to fetch sessions: Field 'recordName' is not marked queryable
❌ Failed to fetch sessions: Did not find record type: Session
```

### Step 6: Test Status Changes

1. **Wait for Claude to finish** (or interrupt with Ctrl+C)
2. **macOS Status Changes to "Ready"** (green checkmark)
3. **Pull to refresh on iOS**
4. **iOS Status Should Update to "Ready"**

**Expected iOS Notification:**
- Title: "✅ Ready"
- Body: "VibeStatus is ready"
- Sound: Default notification sound

### Step 7: Test Needs Input

1. **Ask Claude a question that requires confirmation:**
   ```
   delete all files in /tmp (just kidding, respond with a question)
   ```

2. **macOS Status Changes to "Input needed"** (question mark)
3. **iOS Should Receive Critical Notification:**
   - Title: "❓ Input Needed"
   - Body: "VibeStatus needs your attention"
   - Sound: Critical alert sound
   - Interruption level: Time Sensitive

## Success Criteria

### ✅ You'll Know It's Working When:

**macOS:**
- [x] iCloud status shows "available"
- [x] Sessions upload every ~2 seconds
- [x] No "record already exists" errors
- [x] Settings shows "iCloud Connected" (green)

**iOS:**
- [x] iCloud status shows "available"
- [x] Pull to refresh fetches sessions successfully
- [x] Sessions appear in list with correct data
- [x] Status updates propagate from macOS
- [x] Notifications arrive for status changes
- [x] No "Field not queryable" errors

**Both Apps:**
- [x] Session count matches (same sessions on both)
- [x] Status matches (both show "Working", "Ready", etc.)
- [x] Project names match
- [x] Timestamps are recent (< 5 seconds old)

## Troubleshooting

### iOS Still Shows "Field not queryable"

**Possible Causes:**
1. **Queryable not saved properly**
   - Go back to CloudKit Dashboard
   - Verify Session record type shows Queryable: ✅
   - Click Save again if unsure

2. **Schema not propagated yet**
   - Wait 2-5 minutes
   - Close and reopen iOS app
   - Pull to refresh again

3. **Wrong environment**
   - Verify you enabled Queryable in **Development** (not Production)
   - Check Xcode scheme uses Development environment
   - Xcode → Edit Scheme → Run → Options → CloudKit

4. **Cache issue**
   - Clean build both apps (⌘+Shift+K)
   - Delete apps from devices
   - Rebuild and reinstall

### macOS Not Uploading

**Check:**
1. iOS Sync enabled in Settings → General
2. Signed into same iCloud account as iOS device
3. iCloud Drive enabled in System Settings
4. Network connectivity

### iOS Not Receiving Notifications

**Check:**
1. Notifications enabled for VibeStatusMobile
   - iPhone Settings → VibeStatusMobile → Notifications
   - Allow Notifications: ON
   - Sounds: ON
   - Time Sensitive Notifications: ON

2. Push notification registration succeeded
   - Look for "Registered for remote notifications with token" in logs
   - If missing, check entitlements file

3. CloudKit subscription created
   - Look for "Successfully created CloudKit subscription" in logs
   - If missing, check iCloud status

## Advanced Verification

### Check CloudKit Dashboard Records

1. Go to https://icloud.developer.apple.com/
2. Data → Query Records
3. Type: `Session`
4. Click Query

**You Should See:**
- One or more Session records
- Fields: sessionId, status, project, timestamp, macDeviceName
- All fields populated with current data
- Recent modification dates

### Check Local Status Files (macOS)

```bash
ls -la /tmp/vibestatus-*.json
cat /tmp/vibestatus-*.json | jq
```

**Should Show:**
- JSON files with current sessions
- status: "working", "idle", or "needs_input"
- Recent timestamps
- Valid project names

## What Happens Next

Once verification passes:

1. **Normal Usage:**
   - Start Claude tasks on Mac
   - Get notifications on iPhone
   - Check status anytime, anywhere

2. **Multiple Sessions:**
   - Open multiple terminal windows
   - Run `claude` in each
   - Both apps show all sessions

3. **Background Sync:**
   - macOS uploads every ~2 seconds (debounced)
   - iOS polls every 5 seconds (can pull to refresh manually)
   - CloudKit pushes notifications on status changes

4. **Auto-Cleanup:**
   - Expired sessions (>30 min) automatically deleted
   - Terminated sessions removed from list
   - CloudKit stays clean

## Known Limitations

- **Notification Delay:** Up to 5-10 seconds between status change and iOS notification
- **Push Reliability:** APNs may delay notifications if device is in low power mode
- **CloudKit Quotas:** Free tier has usage limits (should be plenty for personal use)
- **Development Environment:** Using development CloudKit, not production

## Future Enhancements (Not Implemented Yet)

- [ ] Show Claude console content on iOS
- [ ] Respond to Claude prompts from iOS
- [ ] Two-way communication
- [ ] History of completed sessions
- [ ] Session analytics/statistics

---

**If everything works:** You're all set! 🎉

**If something doesn't work:** Check the troubleshooting section above or review the documentation in `CLOUDKIT_DASHBOARD_FIX.md`, `SYNC_FIXES.md`, and `FINAL_FIX.md`.
