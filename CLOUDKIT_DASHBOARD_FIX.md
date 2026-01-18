# Fix: "Field 'recordName' is not marked queryable"

## The Problem

CloudKit requires fields to be marked as "Queryable" before you can query them. The error means the CloudKit schema needs to be updated.

## Quick Fix: Enable Queryable in CloudKit Dashboard

### Step 1: Go to CloudKit Dashboard
https://icloud.developer.apple.com/

### Step 2: Select Your Container
- Click: `iCloud.com.mladjan.vibestatus`

### Step 3: Select Development Environment
- Make sure you're in **Development** (not Production)

### Step 4: Enable Queryable for Session Record Type

1. Click **Schema** in left sidebar
2. Click **Record Types**
3. Find and click **Session**
4. Check the **"Queryable"** checkbox at the top
5. Click **Save**

This allows querying ALL records of this type without needing specific field indexes.

### Step 5: Test on iOS

Run the iOS app again. The error should be gone!

Expected log:
```
iCloud status: available
Fetched X active sessions
```

## Alternative: Mark Individual Fields as Queryable

If the above doesn't work, mark these fields as queryable:

1. In CloudKit Dashboard → Schema → Record Types → Session
2. For each field, click the field name
3. Check **"Queryable"**
4. Fields to mark:
   - `sessionId` ✅ (already should be indexed)
   - `status` ✅
   - `timestamp` ✅
   - `macDeviceName` ✅

5. Click **Save**

## Why This Happens

CloudKit's security model requires explicit permission to query records. By default:
- ❌ You CANNOT query all records
- ❌ You CANNOT query by arbitrary fields
- ✅ You CAN fetch individual records by recordID

To query records, you must either:
1. Mark the **record type** as Queryable (easiest)
2. Mark specific **fields** as Queryable/Indexed

## After Fixing

Once Queryable is enabled:

**iOS App will:**
- ✅ Fetch all Session records
- ✅ Display them in the list
- ✅ See sessions from macOS

**Logs you should see:**
```
iCloud status: available
Successfully created CloudKit subscription
Fetched 1 active sessions
```

## If It Still Doesn't Work

### Option 1: Wait for Schema Propagation
- CloudKit changes can take 1-2 minutes to propagate
- Close and reopen the iOS app
- Wait a minute and try again

### Option 2: Reset CloudKit Development Environment
1. CloudKit Dashboard → Development
2. Click **Reset Development Environment**
3. Confirm (this deletes all development data!)
4. Re-run macOS app to recreate schema
5. Re-run iOS app

### Option 3: Use Production Environment
1. Deploy schema to Production
2. In Xcode → Edit Scheme → Run → Options
3. Change CloudKit to "Production" instead of "Development"

## Expected Flow After Fix

```
macOS uploads → CloudKit (Development) → iOS fetches
                         ↓
                  Schema is Queryable ✅
                         ↓
                  iOS can query all records
```

Try enabling "Queryable" in the CloudKit Dashboard first - that's the quickest fix!
