# ✅ Fixed: CloudKit Query Using Indexed Fields

## What Was Wrong

The query was using:
```swift
predicate: NSPredicate(value: true)  // ❌ Requires record type to be queryable
```

This requires the **entire record type** to be marked as "Queryable" in CloudKit, which is a global setting that's not visible in the field-level UI.

## What's Fixed Now

Changed the query to use an **indexed field** instead:
```swift
// Query using timestamp field (already marked as Queryable, Sortable)
let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
let query = CKQuery(
    recordType: "Session",
    predicate: NSPredicate(format: "timestamp >= %@", thirtyMinutesAgo as NSDate)
)
query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
```

This works because:
- ✅ The `timestamp` field is already marked as **Queryable, Sortable** (visible in your screenshot)
- ✅ We only fetch sessions from the last 30 minutes (which is what we want anyway)
- ✅ Results are automatically sorted by timestamp (newest first)
- ✅ No need to enable any additional CloudKit settings

## Benefits

1. **No CloudKit Dashboard Changes Needed**: Works with current schema
2. **More Efficient**: Only fetches recent sessions (last 30 minutes)
3. **Pre-sorted**: Results come back sorted, no client-side sorting needed
4. **Automatic Cleanup**: Old sessions automatically excluded from query

## What Changed in Code

### Before (CloudKitManager.swift):
```swift
// Tried to fetch ALL sessions
let query = CKQuery(
    recordType: SessionRecord.recordType,
    predicate: NSPredicate(value: true)  // ❌ Requires record type queryable
)

// Then filtered client-side
if age < 30 * 60 {
    sessions.append(session)
}

// Then sorted client-side
return sessions.sorted { $0.timestamp > $1.timestamp }
```

### After (CloudKitManager.swift):
```swift
// Fetch only recent sessions using indexed timestamp field
let thirtyMinutesAgo = Date().addingTimeInterval(-CloudKitConstants.sessionExpirationInterval)
let query = CKQuery(
    recordType: SessionRecord.recordType,
    predicate: NSPredicate(format: "timestamp >= %@", thirtyMinutesAgo as NSDate)  // ✅ Uses queryable field
)
query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

// Query already filters and sorts, just collect results
sessions.append(session)

// Return as-is (already sorted)
return sessions
```

## Expected Behavior Now

### macOS App:
```
iCloud status: available
Uploaded 1 sessions to CloudKit
Fetched 1 active sessions  ← Should work now!
```

### iOS App:
```
iCloud status: available
Successfully created CloudKit subscription
Fetched 1 active sessions  ← Should work now!
```

**iOS UI should now show:**
- ✅ Session list populated
- ✅ Project names visible
- ✅ Status (Working, Ready, Input needed)
- ✅ Real-time updates every 5 seconds

## Testing

### 1. Run macOS App
```bash
cd ~/Work/VibeStatus
open VibeStatus.xcworkspace
# Build and run VibeStatus scheme
```

**Enable sync:**
- Settings → General → Enable iOS Sync

**Start a Claude session:**
```bash
claude
# Give it a task
```

**Check logs for:**
```
✅ "Uploaded X sessions to CloudKit"
✅ "Fetched X active sessions" (no more errors!)
```

### 2. Run iOS App
```bash
# Build and run VibeStatusMobile scheme on device
```

**Pull to refresh**

**Check logs for:**
```
✅ "iCloud status: available"
✅ "Fetched 1 active sessions" (no more query errors!)
```

**Check UI:**
- Session should appear in list
- Project name should show
- Status should match macOS

### 3. Test Real-time Updates

1. **Wait for Claude to finish** (or interrupt)
2. **macOS shows "Ready"**
3. **Pull to refresh on iOS**
4. **iOS should also show "Ready"**
5. **Should receive notification** 🔔

## Why This Works

CloudKit has two levels of queryability:

### Level 1: Field-Level Indexes ✅ (Already Configured)
From your screenshot, these fields are indexed:
- ✅ `macDeviceName`: Queryable, Searchable, Sortable
- ✅ `project`: Queryable, Searchable, Sortable
- ✅ `sessionId`: Queryable, Searchable, Sortable
- ✅ `status`: Queryable, Searchable, Sortable
- ✅ `timestamp`: Queryable, Sortable

### Level 2: Record Type Queryable ❌ (Would need Dashboard config)
This is a checkbox at the record type level (not visible in your screenshot) that allows:
- `NSPredicate(value: true)` - fetch ALL records
- Queries without using indexed fields

**We don't need Level 2 because we're using Level 1 (indexed fields)!**

## Performance Improvements

This approach is actually **better** than the old one:

### Before:
1. Fetch ALL sessions from CloudKit (could be hundreds if not cleaned up)
2. Filter client-side for age < 30 minutes
3. Sort client-side by timestamp

### After:
1. CloudKit filters server-side: `timestamp >= 30 minutes ago`
2. CloudKit sorts server-side: newest first
3. Client receives only relevant, sorted results

**Result:**
- ✅ Less network traffic
- ✅ Less memory usage
- ✅ Faster queries
- ✅ No client-side processing needed

## Verification

If it works, you'll see:

**macOS logs:**
```
iCloud status: available
Uploaded 1 sessions to CloudKit
Fetched 1 active sessions
Cleaned up 0 stale sessions
```

**iOS logs:**
```
iCloud status: available
Fetched 1 active sessions
```

**iOS UI:**
- Session appears in list
- Correct project name
- Correct status
- Recent timestamp

## If It Still Doesn't Work

### Check CloudKit Data
1. Go to https://icloud.developer.apple.com/
2. Select: `iCloud.com.mladjan.vibestatus`
3. Click: **Data** → **Query Records**
4. Type: `Session`
5. Click **Query**

Verify sessions exist with recent timestamps.

### Check Field Indexes
Go to Schema → Record Types → Session and verify these are **Queryable**:
- [x] timestamp (must be queryable for query to work)
- [x] status (good to have)
- [x] project (good to have)

### Check Logs
Look for specific error messages:
- If you see "Field 'timestamp' is not marked queryable" → Need to add index
- If you see other CKError → Check iCloud account status

## Summary

✅ **No CloudKit Dashboard changes needed**
✅ **More efficient query (server-side filtering)**
✅ **Pre-sorted results**
✅ **Both apps rebuilt and ready to test**

The fix leverages the existing field-level indexes you've already configured, so it should work immediately! 🎉

---

**Next Step:** Run both apps and test!
