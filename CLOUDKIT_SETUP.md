# CloudKit Schema Setup

The VibeStatus iOS remote input feature requires a CloudKit schema with a **Prompt** record type. Follow these steps to create it.

## Prerequisites

- iCloud account signed in on your Mac
- Xcode with CloudKit capabilities enabled
- Access to CloudKit Dashboard

## Steps to Create Prompt Record Type

### Option 1: Automatic Schema Creation (Recommended)

The app will attempt to create records automatically, but CloudKit will prompt you to save the schema in Development mode:

1. Run the macOS app and trigger a Claude prompt that needs input
2. Run the iOS app - it will try to fetch prompts
3. Check Xcode console for CloudKit errors
4. Open CloudKit Dashboard (see instructions below)
5. In Development environment, you'll see the new **Prompt** record type
6. Click "Save Changes" to persist the schema
7. Deploy schema to Production when ready

### Option 2: Manual Schema Creation

1. **Open CloudKit Dashboard:**
   - Go to https://icloud.developer.apple.com/dashboard
   - Sign in with your Apple ID
   - Select `iCloud.com.mladjan.vibestatus` container
   - Select "Schema" → "Development"

2. **Create Prompt Record Type:**
   - Click "Record Types" → "+" (New Type)
   - Name: `Prompt`
   - Click "Save"

3. **Add Fields to Prompt Record:**

   Click on the `Prompt` record type and add these fields:

   | Field Name           | Field Type | Queryable | Searchable | Sortable |
   |---------------------|------------|-----------|------------|----------|
   | `promptId`          | String     | ✓         | ✓          | ✓        |
   | `sessionId`         | String     | ✓         | ✓          | ✓        |
   | `project`           | String     | ✓         | ✓          | ✓        |
   | `promptMessage`     | String     | ✗         | ✗          | ✗        |
   | `notificationType`  | String     | ✓         | ✗          | ✗        |
   | `transcriptPath`    | String     | ✗         | ✗          | ✗        |
   | `transcriptExcerpt` | String     | ✗         | ✗          | ✗        |
   | `timestamp`         | Date/Time  | ✓         | ✗          | ✓        |
   | `pid`               | Int(64)    | ✗         | ✗          | ✗        |
   | `responseText`      | String     | ✗         | ✗          | ✗        |
   | `respondedAt`       | Date/Time  | ✓         | ✗          | ✓        |
   | `respondedFromDevice` | String   | ✗         | ✗          | ✗        |
   | `responded`         | Int(64)    | ✓         | ✗          | ✗        |

4. **Create Indexes:**

   Add these indexes for efficient queries:

   - Index 1: `responded` (Queryable)
   - Index 2: `sessionId` + `responded` (Queryable, for fetchResponses)
   - Index 3: `timestamp` (Sortable, for ordering)

5. **Save Schema:**
   - Click "Save" to persist changes
   - Schema is now ready in Development environment

6. **Deploy to Production:**
   - Once tested, go to "Deployment" section
   - Click "Deploy Schema Changes"
   - Select "Development → Production"
   - Confirm deployment

## Verifying Setup

Run this command in iOS app to verify CloudKit is working:

```swift
// In Xcode console, you should see:
// [CloudKitManager] iCloud status: available
// [CloudKitManager] Successfully created prompt subscription
```

Check for these errors and their fixes:

- **"Did not find record type: Prompt"**
  → Schema not created yet, follow steps above

- **"Invalid predicate: Expected constant value in comparison expression"**
  → Make sure `responded` field exists and is marked Queryable

- **"Unable to save subscription"**
  → Delete and recreate subscription in CloudKit Dashboard

## Testing

1. Run macOS VibeStatus app
2. Start a Claude Code session that needs input
3. iOS app should receive push notification
4. Tap notification → Prompt input view appears
5. Submit response
6. macOS Terminal receives input, Claude continues

## Troubleshooting

### No notifications on iOS

1. Check iOS Settings → Notifications → VibeStatus → Allow Notifications: ON
2. Check iOS Settings → Notifications → VibeStatus → Critical Alerts: ON (optional)
3. Verify CloudKit subscription exists in Dashboard
4. Run iOS app, check console: `Successfully created prompt subscription`

### Prompts not syncing

1. Verify iCloud signed in on both devices
2. Check CloudKit Dashboard → Data → Prompt records exist
3. Check Xcode console for CloudKit errors
4. Try deleting and recreating CloudKit subscriptions:
   ```swift
   // In iOS app settings (future feature):
   // Settings → Advanced → Reset CloudKit Subscriptions
   ```

### Schema changes not working

1. Go to CloudKit Dashboard → Schema → Deployment
2. Click "Reset Development Environment" (WARNING: deletes all data)
3. Redeploy schema from Development to Production

## Container Identifier

The app uses this CloudKit container:

- **Development:** `iCloud.com.mladjan.vibestatus` (Sandbox)
- **Production:** `iCloud.com.mladjan.vibestatus`

## Security & Privacy

- All data is stored in **Private Database** (user's iCloud account)
- Only the user who creates prompts can see/respond to them
- Data never leaves Apple's iCloud infrastructure
- No third-party servers involved

## Next Steps

After CloudKit schema is set up:

1. Reinstall hooks in macOS app (Settings → Unconfigure → Configure)
2. Test with a real Claude Code session
3. Verify end-to-end flow works
4. Deploy schema to Production when ready
