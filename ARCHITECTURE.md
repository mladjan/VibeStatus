# VibeStatus iOS + macOS Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User's iCloud Account                    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              CloudKit Private Database                  │    │
│  │                                                          │    │
│  │   Session Records:                                       │    │
│  │   - sessionId: "vibestatus-abc123.json"                 │    │
│  │   - status: "working" | "idle" | "needs_input"          │    │
│  │   - project: "VibeStatus"                               │    │
│  │   - timestamp: Date                                      │    │
│  │   - pid: 12345                                           │    │
│  │   - macDeviceName: "MacBook Pro"                        │    │
│  │                                                          │    │
│  │   Subscription: "session-changes"                        │    │
│  │   → Triggers push notifications on record changes       │    │
│  └────────────────────────────────────────────────────────┘    │
│                           ↑         ↓                            │
└───────────────────────────┼─────────┼────────────────────────────┘
                            │         │
                    Upload  │         │  Fetch + Push
                            │         │
         ┌──────────────────┘         └──────────────────┐
         │                                                 │
    ┏━━━━┻━━━━━┓                                   ┏━━━━━┻━━━━━┓
    ┃  macOS   ┃                                   ┃    iOS     ┃
    ┃   App    ┃                                   ┃    App     ┃
    ┗━━━━┳━━━━━┛                                   ┗━━━━━┳━━━━━━┛
         │                                                 │
         │                                                 │
┌────────▼──────────┐                          ┌──────────▼─────────┐
│  StatusManager    │                          │ CloudKitViewModel  │
│  ┌──────────────┐ │                          │ ┌────────────────┐ │
│  │ Poll /tmp    │ │                          │ │ Fetch sessions │ │
│  │ every 1s     │ │                          │ │ every 5s       │ │
│  └──────┬───────┘ │                          │ └────────────────┘ │
│         │         │                          │                    │
│         ▼         │                          │ ┌────────────────┐ │
│  ┌──────────────┐ │                          │ │ SessionListView│ │
│  │ Parse JSON   │ │                          │ │ • Display list │ │
│  │ files        │ │                          │ │ • Pull refresh │ │
│  └──────┬───────┘ │                          │ │ • Real-time    │ │
│         │         │                          │ └────────────────┘ │
│         ▼         │                          │                    │
│  ┌──────────────┐ │                          │ ┌────────────────┐ │
│  │CloudKitSync  │ │                          │ │NotificationMgr │ │
│  │Manager       │ │                          │ │ • APNs         │ │
│  │ • Upload on  │ │                          │ │ • Local alerts │ │
│  │   change     │ │                          │ │ • Handle taps  │ │
│  │ • Debounce   │ │                          │ └────────────────┘ │
│  └──────────────┘ │                          │                    │
│                   │                          │ ┌────────────────┐ │
│  ┌──────────────┐ │                          │ │  SettingsView  │ │
│  │  SetupView   │ │                          │ │ • iCloud stat  │ │
│  │ • iOS sync   │ │                          │ │ • Permissions  │ │
│  │   toggle     │ │                          │ └────────────────┘ │
│  │ • iCloud     │ │                          └────────────────────┘
│  │   status     │ │
│  └──────────────┘ │
└───────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Shared Swift Package                          │
│                  (VibeStatusShared)                              │
│                                                                   │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐             │
│  │ VibeStatus │  │SessionRecord│  │CloudKitMgr   │             │
│  │   enum     │  │   struct    │  │  class       │             │
│  └────────────┘  └─────────────┘  └──────────────┘             │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Session Detection (macOS)
```
Claude Code Terminal
    ↓ (hook executes)
~/.claude/hooks/vibestatus.sh
    ↓ (writes JSON)
/tmp/vibestatus-{SESSION_ID}.json
    ↓ (polling)
StatusManager.readStatusFiles()
    ↓ (parses)
SessionInfo objects
    ↓ (on change)
CloudKitSyncManager.uploadSessions()
    ↓ (uploads)
CloudKit Private Database
```

### 2. iOS Sync
```
CloudKit Private Database
    ↓ (silent push via APNs)
iOS App (background)
    ↓ (triggers)
CloudKitViewModel.refreshSessions()
    ↓ (fetches)
CloudKitManager.fetchSessions()
    ↓ (returns)
[SessionRecord]
    ↓ (converts to)
[SessionInfo]
    ↓ (displays)
SessionListView
```

### 3. Status Change Notification
```
StatusManager detects: working → idle
    ↓ (uploads)
CloudKit: status = "idle"
    ↓ (push notification)
iOS App receives APNs
    ↓ (fetches update)
CloudKitViewModel.refreshSessions()
    ↓ (shows notification)
NotificationManager.showSessionNotification()
    ↓ (displays)
"✅ Ready - ProjectName has finished"
```

## Key Components

### Shared Package (`VibeStatusShared`)

**Models:**
- `VibeStatus` enum: working, idle, needsInput, notRunning
- `SessionRecord`: CloudKit-compatible record with full session data
- `SessionInfo`: Legacy-compatible display model
- `StatusData`: Raw JSON format from hook script

**Managers:**
- `CloudKitManager`: Handles all CloudKit operations
  - Upload/fetch/delete sessions
  - Subscription management
  - iCloud availability checking
  - Debounced uploads (2 second interval)
  - Auto-cleanup of stale sessions (30 min timeout)

**Constants:**
- CloudKit container ID
- Subscription ID
- Timeouts and intervals

### macOS App

**New Files:**
- `CloudKitSyncManager.swift`: Bridge between StatusManager and CloudKit
  - Converts SessionInfo → SessionRecord
  - Manages sync enabled state
  - Provides device name for records

**Modified Files:**
- `StatusManager.swift`: Added CloudKit upload on session changes
- `SetupView.swift`: Added iOS sync toggle and status display
- `VibeStatus.entitlements`: Added iCloud and push notification capabilities

**Features:**
- Toggle iOS sync on/off in Settings
- Shows iCloud connection status
- Displays last sync time
- Auto-cleanup of stale CloudKit records

### iOS App

**Core Views:**
- `SessionListView`: Main screen showing active sessions
  - Grouped by Mac device
  - Pull to refresh
  - Empty state with setup instructions
  - Real-time updates

- `SessionRowView`: Individual session display
  - Color-coded status dot
  - Project name
  - Status badge
  - Relative timestamp
  - "ACTION NEEDED" badge for needsInput

- `SettingsView`: Configuration screen
  - iCloud connection status
  - Notification permissions
  - App version info
  - Debug tools

**View Models:**
- `CloudKitViewModel`: Session data management
  - Fetches from CloudKit every 5 seconds
  - Handles iCloud availability
  - Groups sessions by device
  - Error handling and loading states

**Managers:**
- `NotificationManager`: Push notification handling
  - Permission requests
  - APNs registration
  - Local notification display
  - Notification tap handling
  - Different alerts for idle vs needsInput

**App Delegate:**
- Sets up notifications on launch
- Registers CloudKit subscription
- Handles remote notifications
- Triggers sync on push received

## Communication Protocol

### macOS → CloudKit

**Upload Trigger:**
- Sessions array changes in StatusManager
- Debounced to prevent spam (2 second window)

**Data Sent:**
```json
{
  "sessionId": "vibestatus-abc123.json",
  "status": "working",
  "project": "VibeStatus",
  "timestamp": "2025-01-18T10:30:45Z",
  "pid": 12345,
  "macDeviceName": "MacBook Pro"
}
```

**Cleanup:**
- Every 10 updates, macOS removes stale sessions from CloudKit
- Sessions older than 30 minutes are deleted

### CloudKit → iOS

**Push Notification:**
```json
{
  "aps": {
    "content-available": 1
  },
  "ck": {
    "qry": {
      "sid": "session-changes"
    }
  }
}
```

**Fetch Response:**
```json
[
  {
    "sessionId": "vibestatus-abc123.json",
    "status": "idle",
    "project": "VibeStatus",
    "timestamp": "2025-01-18T10:31:00Z",
    "macDeviceName": "MacBook Pro"
  }
]
```

**Local Notification:**
- Title: "✅ Ready" or "❓ Input Needed"
- Body: "ProjectName has finished and is ready"
- Sound: default or critical
- Tap action: Opens app to session

## Security & Privacy

### iCloud Private Database
- Data stored in user's personal iCloud account
- Not accessible by other users
- Encrypted at rest by Apple
- Encrypted in transit (TLS)
- No third-party access

### Permissions Required
- **macOS**: iCloud, CloudKit (automatic with entitlements)
- **iOS**: iCloud, CloudKit, Push Notifications, Background Modes

### Data Lifecycle
1. Created: When Claude Code session starts
2. Updated: On status changes (working → idle → needsInput)
3. Deleted: After 30 minutes of inactivity or session ends
4. User Control: Can delete all data via iCloud settings

## Performance Characteristics

### macOS
- Polling interval: 1 second (local file system)
- Upload debounce: 2 seconds per session
- Cleanup frequency: Every 10 updates
- Overhead: Minimal (async uploads, background priority)

### iOS
- Sync interval: 5 seconds (when app active)
- Push latency: 2-5 seconds (CloudKit → APNs → Device)
- Fetch size: Small (typically 1-5 sessions)
- Battery impact: Low (silent push, not polling)

### CloudKit
- Free tier: 10 GB storage, 200 MB/day transfer, 40 requests/sec
- Expected usage: ~1 KB per session, <100 requests/day
- Well within free tier for personal use

## Error Handling

### macOS
- iCloud unavailable → Queues uploads for later
- Upload fails → Retries on next change
- Network timeout → Graceful degradation
- Invalid data → Logs error, continues

### iOS
- iCloud unavailable → Shows error, retry button
- Fetch fails → Displays last known state
- Push fails → Falls back to polling
- Parse error → Skips invalid record

## Future Enhancements

### Phase 4: Bidirectional Communication

**Required Changes:**

1. **Hook Script**: Capture prompt text
```bash
# Add to vibestatus.sh
PROMPT_TEXT=$(jq -r '.prompt' <<< "$stdin")
echo "$PROMPT_TEXT" > "/tmp/vibestatus-prompt-$SESSION_ID.txt"
```

2. **CloudKit Schema**: Add Prompt record type
```swift
struct PromptRecord {
    let promptId: String
    let sessionId: String
    let text: String
    let options: [String]
    let timestamp: Date
}
```

3. **iOS UI**: Prompt detail view
```swift
struct PromptDetailView {
    // Display full prompt text
    // Show available options
    // Text input for response
    // Submit button
}
```

4. **macOS IPC**: Response handling
```swift
// Watch for responses in CloudKit
// Write to named pipe or temp file
// Claude Code reads response
```

## Testing Strategy

### Unit Tests
- CloudKitManager upload/fetch/delete
- Session record conversion
- Status aggregation logic
- Notification formatting

### Integration Tests
- macOS → CloudKit upload
- CloudKit → iOS sync
- Push notification delivery
- Session cleanup

### Manual Tests
- Multiple sessions
- Status transitions
- Network interruption
- iCloud sign out/in
- Background/foreground

## Deployment

### Development
1. Use development CloudKit environment
2. Test with development APNs
3. Enable verbose logging

### Production
1. Deploy CloudKit schema to production
2. Switch to production APNs
3. Disable debug tools
4. Test with TestFlight

## Monitoring

### Logs to Watch
- `[CloudKit]` - Upload/fetch operations
- `[NotificationManager]` - Push delivery
- `[StatusManager]` - Session changes
- `[AppDelegate]` - App lifecycle

### Metrics to Track
- Sync latency (macOS upload to iOS display)
- Notification delivery rate
- CloudKit quota usage
- Error frequency

## Summary

This architecture provides:
- ✅ Real-time sync via CloudKit
- ✅ Push notifications for status changes
- ✅ Works anywhere (internet-based)
- ✅ Private and secure (iCloud)
- ✅ Low battery impact (push-based)
- ✅ Scalable (CloudKit infrastructure)
- ✅ Future-proof (bidirectional ready)

The foundation is complete and ready for testing once the shared package is linked in Xcode!
