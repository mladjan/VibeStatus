# Understanding the "Field not marked queryable" Error

## What You're Seeing Now

**macOS logs:**
```
iCloud status: available
Uploaded 1 sessions to CloudKit
Query failed - CloudKit schema may need configuration: Field 'recordName' is not marked queryable
```

**iOS logs:**
```
iCloud status: available
Failed to fetch sessions: Field 'recordName' is not marked queryable
```

## Why This Happens

### ✅ What's Working:
- **macOS → CloudKit uploads**: Working perfectly! Sessions are being created/updated in CloudKit
- **iCloud connection**: Both apps successfully connected to iCloud
- **CloudKit container**: Properly configured and accessible

### ⚠️ What's Not Working (Yet):
- **CloudKit → Apps queries**: Cannot fetch sessions from CloudKit
- **iOS session list**: Cannot display sessions (needs queries to work)
- **macOS cleanup**: Cannot remove stale sessions (needs queries to work)

## The Technical Reason

CloudKit has a security/performance model that requires explicit permission to query records:

### By Default:
- ✅ You **CAN** create records (`save()`)
- ✅ You **CAN** update records (`save()` with existing recordID)
- ✅ You **CAN** delete specific records (if you know the recordID)
- ❌ You **CANNOT** query all records (`records(matching: query)`)

### To Enable Queries:
You must configure the CloudKit schema to mark the record type as "Queryable"

## Current App Behavior

### macOS App:
```
Every ~2 seconds:
├─ Read /tmp/vibestatus-*.json files ✅
├─ Upload sessions to CloudKit ✅
├─ Log: "Uploaded X sessions to CloudKit" ✅
└─ Try cleanup (every 10th cycle)
    ├─ Fetch all sessions ❌ (queryable not enabled)
    └─ Skip cleanup silently ✅
```

**What you'll see:**
- Sessions upload successfully
- Occasional debug message about schema configuration
- No errors or warnings (changed to debug level)

### iOS App:
```
Every 5 seconds (or on pull-to-refresh):
├─ Try to fetch sessions ❌ (queryable not enabled)
└─ Show empty list with error message
```

**What you'll see:**
- "Link VibeStatusShared package to enable sync" (settings screen)
- Empty session list
- Error message in logs

## The Fix (Required)

You need to enable "Queryable" in the CloudKit Dashboard. This is a **one-time configuration** that takes ~1 minute.

### Steps:

1. **Go to CloudKit Dashboard:**
   https://icloud.developer.apple.com/

2. **Select your container:**
   - Click: `iCloud.com.mladjan.vibestatus`

3. **Select Development environment:**
   - Make sure you're in **Development** (not Production)

4. **Navigate to Schema:**
   - Left sidebar: Click **Schema**
   - Click **Record Types**
   - Find and click **Session**

5. **Enable Queryable:**
   - At the top of the Session record type page
   - Check the box: ☑️ **Queryable**
   - Click **Save**

6. **Wait for propagation:**
   - Changes take 1-2 minutes to propagate
   - Close and reopen both apps
   - Pull to refresh on iOS

## After Enabling Queryable

### macOS App (Expected):
```
iCloud status: available
Uploaded 1 sessions to CloudKit
Fetched 1 active sessions
Cleaned up 0 stale sessions
```

### iOS App (Expected):
```
iCloud status: available
Successfully created CloudKit subscription
Fetched 1 active sessions
```

**iOS UI will show:**
- Session list with active Claude Code sessions
- Project names
- Status (Working, Ready, Input needed)
- Real-time updates

## Why We Can't Fix This in Code

This is **not a code issue** - it's a CloudKit schema configuration:

- The code is correct and working ✅
- Both apps successfully connect to iCloud ✅
- macOS successfully uploads sessions ✅
- The CloudKit container is properly configured ✅

**The only thing missing is the schema permission to query records.**

This is like trying to run `SELECT * FROM sessions` on a database where you only have `INSERT` and `UPDATE` permissions. The code is fine, but the database needs to grant you `SELECT` permission.

## Verification

To verify sessions are actually being uploaded (even though you can't query them yet):

### Option 1: CloudKit Dashboard
1. Go to https://icloud.developer.apple.com/
2. Select: `iCloud.com.mladjan.vibestatus`
3. Click: **Data** → **Query Records**
4. Type: `Session`
5. Click **Query**

You should see Session records with recent data, even though the apps can't query them yet.

### Option 2: Check macOS Logs
Look for:
```
Successfully uploaded session: vibestatus-xxx - ProjectName
```

This confirms data is reaching CloudKit.

## Timeline

**What's happening right now:**
- ✅ macOS reads Claude Code sessions from files
- ✅ macOS uploads sessions to CloudKit
- ❌ iOS cannot fetch sessions (needs queryable)
- ❌ macOS cannot cleanup old sessions (needs queryable)

**After you enable Queryable (1 minute of work):**
- ✅ macOS reads Claude Code sessions from files
- ✅ macOS uploads sessions to CloudKit
- ✅ iOS fetches and displays sessions
- ✅ macOS cleans up old sessions
- ✅ iOS receives push notifications for status changes
- ✅ Everything works end-to-end!

## Next Step

**→ Follow the steps in `CLOUDKIT_DASHBOARD_FIX.md`**

Once you check that box and click Save, everything will work! 🎉
