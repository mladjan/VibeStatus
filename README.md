# VibeStatus

Monitor your Claude Code terminal sessions from anywhere - macOS menu bar app with iOS companion.

## Features

### 🖥️ macOS App
- Menu bar widget showing Claude Code session status in real-time
- Visual indicators: Working (⚙️), Ready (✅), Input Needed (❓)
- Support for multiple concurrent Claude sessions
- Optional CloudKit sync to iOS
- Sound notifications when Claude needs attention

### 📱 iOS App
- View all active Claude Code sessions from your Mac
- Real-time sync via CloudKit
- Push notifications for status changes
- Critical alerts when Claude needs input (bypasses silent mode)
- Pull-to-refresh for instant updates

## Screenshots

### macOS Menu Bar
![macOS Screenshot](docs/screenshots/macos.png)

### iOS Companion
![iOS Screenshot](docs/screenshots/ios.png)

## How It Works

```
Claude Code (Terminal)
    ↓ writes JSON
/tmp/vibestatus-*.json
    ↓ polls every 1s
macOS Menu Bar App
    ↓ syncs to CloudKit
iCloud (Private Database)
    ↓ push notifications
iOS Companion App
```

## Requirements

- **macOS:** 13.0+ (Ventura)
- **iOS:** 16.0+
- **Xcode:** 15.0+
- **iCloud:** Required for sync between devices

## Project Structure

```
VibeStatus/
├── macOS/vibestatus/        # macOS menu bar application
├── iOS/VibeStatusMobile/    # iOS companion app
├── VibeStatusShared/        # Shared Swift package (CloudKit, models)
└── VibeStatus.xcworkspace   # Xcode workspace (open this!)
```

## Setup

### 1. Clone the Repository

```bash
git clone git@github.com:mladjan/VibeStatus.git
cd VibeStatus
```

### 2. Open in Xcode

```bash
open VibeStatus.xcworkspace
```

**Important:** Always open the `.xcworkspace`, not the individual `.xcodeproj` files!

### 3. Configure CloudKit (for Sync)

If you want macOS ↔ iOS sync:

1. **Change the CloudKit container ID:**
   - Open `VibeStatusShared/Sources/VibeStatusShared/Constants.swift`
   - Change `containerIdentifier` to your own (e.g., `iCloud.com.yourname.vibestatus`)

2. **Update entitlements:**
   - macOS: `macOS/vibestatus/VibeStatus/VibeStatus.entitlements`
   - iOS: `iOS/VibeStatusMobile/VibeStatusMobile/VibeStatusMobile.entitlements`
   - Update container ID in both files

3. **Configure CloudKit Dashboard:**
   - Go to https://icloud.developer.apple.com/
   - Select your container
   - Go to Schema → Record Types → Session
   - Check fields are marked as "Queryable"

### 4. Build and Run

**macOS:**
- Select "VibeStatus" scheme
- Run (⌘+R)
- Grant permissions when prompted
- Menu bar icon appears

**iOS:**
- Select "VibeStatusMobile" scheme
- Choose your iPhone/iPad as destination
- Run (⌘+R)
- Grant notification permissions when prompted

## Usage

### macOS App

1. **Install Claude Code hooks** (if not already done):
   ```bash
   # The macOS app monitors /tmp/vibestatus-*.json files
   # These are created by Claude Code hooks
   ```

2. **Enable iOS Sync** (optional):
   - Click menu bar icon → Settings → General
   - Check "Enable iOS Sync"
   - Ensure you're signed into iCloud

3. **Start using Claude Code:**
   ```bash
   claude
   # Give Claude a task
   ```

4. **Monitor status:**
   - Menu bar shows current status
   - ⚙️ Working - Claude is processing
   - ✅ Ready - Claude finished, waiting for input
   - ❓ Input Needed - Claude needs your response

### iOS App

1. **Sign into iCloud** (same account as Mac)

2. **Open app** - Sessions appear automatically

3. **Pull to refresh** for instant updates

4. **Receive notifications:**
   - "✅ Ready" when task completes
   - "❓ Input Needed" (critical alert) when Claude needs you

## Development

### Prerequisites

- Xcode 15.0+
- Swift 5.9+
- macOS Ventura (13.0) or later for development

### Building from Source

```bash
# Open workspace
open VibeStatus.xcworkspace

# Build all targets
xcodebuild -workspace VibeStatus.xcworkspace -scheme VibeStatus build
xcodebuild -workspace VibeStatus.xcworkspace -scheme VibeStatusMobile build
```

### Running Tests

```bash
xcodebuild -workspace VibeStatus.xcworkspace -scheme VibeStatus test
```

### Shared Package

The `VibeStatusShared` Swift package contains:
- **CloudKitManager:** CloudKit sync operations
- **SessionRecord:** Data models for sessions
- **Constants:** Shared configuration
- **VibeStatus enum:** Status types (working, idle, needsInput)

Both macOS and iOS apps depend on this package.

## Architecture

### macOS App
- **StatusManager:** Polls `/tmp/vibestatus-*.json` files every second
- **CloudKitSyncManager:** Uploads changed sessions to CloudKit
- **Menu Bar UI:** SwiftUI views for menu bar widget
- **Sound Notifications:** Plays sounds on status changes

### iOS App
- **CloudKitViewModel:** Fetches sessions from CloudKit
- **SessionListView:** SwiftUI list of active sessions
- **NotificationManager:** Handles push notifications and local alerts

### Shared Package
- **CloudKitManager:** CRUD operations for CloudKit
- **Debouncing:** 0.5s debounce to prevent excessive uploads
- **Change Tracking:** Only uploads when session status changes
- **Timestamp-based Queries:** Fetches sessions from last 30 minutes

## Troubleshooting

### "No sessions showing on iOS"

1. Check macOS sync is enabled (Settings → General)
2. Verify both devices signed into same iCloud account
3. Check network connectivity
4. Pull to refresh on iOS

### "Cannot sync - iCloud not available"

1. Sign into iCloud (System Settings → Apple ID)
2. Enable iCloud Drive
3. Check network connection
4. Restart both apps

### "Field not marked queryable" error

1. Go to https://icloud.developer.apple.com/
2. Select your CloudKit container
3. Schema → Record Types → Session
4. Mark fields as "Queryable"
5. Save changes

### "No notifications on iOS"

1. Settings → VibeStatusMobile → Notifications → Allow Notifications: ON
2. Enable "Time Sensitive Notifications"
3. Check iOS logs for "Registered for remote notifications"

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built for monitoring [Claude Code](https://claude.com/claude-code) terminal sessions
- Uses Apple CloudKit for seamless sync
- SwiftUI for modern, native UI on both platforms

## Support

- **Issues:** https://github.com/mladjan/VibeStatus/issues
- **Discussions:** https://github.com/mladjan/VibeStatus/discussions

---

Made with ❤️ for Claude Code users
