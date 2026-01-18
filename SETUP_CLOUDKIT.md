# CloudKit Schema Setup

## Problem
Error: "Did not find record type: Session"

This means CloudKit doesn't know about the `Session` record type yet.

## Solution: Create the Schema

CloudKit will automatically create the schema when you **upload the first record** from the macOS app.

### Step 1: Enable Sync on macOS

1. Run the macOS app
2. Go to **Settings** → **General**
3. Toggle **"Enable iOS Sync"** to ON
4. Verify it shows **"iCloud Connected"** (green checkmark)

### Step 2: Create a Claude Code Session

In your terminal:
```bash
claude
```

Give Claude a simple task, like:
```
tell me a joke
```

### Step 3: Check macOS Console Logs

In Xcode, when running the macOS app, look for:
```
[CloudKit] Successfully uploaded session: vibestatus-xxx.json - ProjectName
```

Or in Console.app, filter for "CloudKit" or "vibestatus"

### Step 4: Verify Schema Was Created

The first upload will create the schema. Check iOS logs again - the error should be gone.

---

## Alternative: Manual Schema Creation via CloudKit Dashboard

If automatic creation doesn't work:

### 1. Go to CloudKit Dashboard
https://icloud.developer.apple.com/

### 2. Select Your Container
- Click on: `iCloud.com.mladjan.vibestatus`

### 3. Go to Development Environment
- Make sure you're in **Development** (not Production)
- Click **Schema** in the left sidebar

### 4. Create Record Type

Click **Record Types** → **+** (plus button)

**Create record type:**
- Name: `Session`

**Add these fields:**

| Field Name | Type | Options |
|------------|------|---------|
| `sessionId` | String | Indexed |
| `status` | String | - |
| `project` | String | - |
| `timestamp` | Date/Time | - |
| `pid` | Int(64) | - |
| `macDeviceName` | String | Indexed |

### 5. Save the Record Type

Click **Save**

### 6. Enable Queryable (Optional but Recommended)

- Select the `Session` record type
- Check the **Queryable** box
- This allows querying without indexes

### 7. Test from iOS

Now the iOS app should work!

---

## Debugging

### Check if Schema Exists

1. Go to CloudKit Dashboard
2. Select container: `iCloud.com.mladjan.vibestatus`
3. Go to **Data** → **Records**
4. You should see the `Session` record type in the dropdown

### Check Console Logs

**macOS app:**
```
[Sync] Uploaded 1 sessions to CloudKit
[CloudKit] Successfully uploaded session: vibestatus-xxx - ProjectName
```

**iOS app:**
```
[CloudKit] Fetched X active sessions
```

### If Still Not Working

Check these:

1. **Both apps using same container?**
   - macOS entitlements: `iCloud.com.mladjan.vibestatus`
   - iOS entitlements: `iCloud.com.mladjan.vibestatus`

2. **Signed into same iCloud account?**
   - Mac: System Settings → Apple ID
   - iPhone: Settings → [Your Name]

3. **Development vs Production?**
   - Both apps should use Development environment initially
   - In Xcode → Product → Scheme → Edit Scheme → Run → Options
   - Check "Use development CloudKit container"

---

## Quick Test Script

Run this to trigger schema creation:

```bash
# 1. Start macOS app with iOS Sync enabled

# 2. Run Claude Code
claude

# 3. In another terminal, check if file was created
ls -la /tmp/vibestatus-*.json

# 4. Check macOS app logs for upload confirmation

# 5. Wait 2-5 seconds for CloudKit to sync

# 6. Refresh iOS app
```

---

## Expected Flow

1. Claude Code creates: `/tmp/vibestatus-SESSION_ID.json`
2. macOS StatusManager reads it (every 1 second)
3. macOS CloudKitSyncManager uploads to CloudKit
4. **First upload creates the schema automatically**
5. CloudKit sends push notification to iOS
6. iOS CloudKitViewModel fetches sessions
7. iOS displays the session!

---

## After Schema is Created

You only need to do this once. After the first successful upload:
- Schema persists in CloudKit
- All future uploads work automatically
- iOS can query immediately

To deploy to production later:
1. Go to CloudKit Dashboard
2. Schema → Deploy Schema Changes
3. Deploy Development → Production
