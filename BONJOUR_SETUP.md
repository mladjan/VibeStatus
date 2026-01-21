# Bonjour Proximity Detection Setup

## Overview

VibeStatus now supports **automatic notification silencing** when your iPhone is near your Mac. This uses Bonjour/mDNS for local network discovery.

## How It Works

1. **Mac advertises** a Bonjour service (`_vibestatus._tcp.`)
2. **iPhone discovers** this service on the local network
3. **If Mac is detected** → notifications are silenced
4. **If Mac is not detected** → notifications are shown

## Benefits

- ✅ Works across **multiple WiFi networks** in same location
- ✅ Works across **different subnets**
- ✅ **Battery efficient** - quick local scan (3 second timeout)
- ✅ **Privacy friendly** - only local network, no internet
- ✅ **Apple's standard approach** - same tech as AirDrop, HomeKit

## Setup Required

### macOS App

1. **Add BonjourService.swift to Xcode project:**
   - File → Add Files to "VibeStatus"
   - Select `BonjourService.swift`
   - Check "Add to targets: VibeStatus"

2. **Add entitlement (if needed):**
   - Target → Signing & Capabilities
   - Add Bonjour services entitlement (usually not required for outgoing services)

### iOS App

1. **Add ProximityDetector.swift to Xcode project:**
   - File → Add Files to "VibeStatusMobile"
   - Select `ProximityDetector.swift`
   - Check "Add to targets: VibeStatusMobile"

2. **Add Info.plist permissions:**
   - Open project settings → Info tab
   - Add these keys:
     ```xml
     <key>NSLocalNetworkUsageDescription</key>
     <string>VibeStatus uses the local network to detect when your Mac is nearby, allowing it to automatically silence notifications when you're at your desk.</string>

     <key>NSBonjourServices</key>
     <array>
         <string>_vibestatus._tcp</string>
     </array>
     ```

3. **Add "Local Network" permission:**
   - Target → Signing & Capabilities
   - The permission will be requested automatically when proximity detection is enabled

## User Experience

### First Time Setup

1. User enables "Silence When Near Mac" in iPhone Settings
2. iOS prompts for Local Network permission
3. User grants permission
4. From now on, notifications are automatically silenced when at desk

### Daily Use

- **At desk:** No notifications on iPhone (you can see them on Mac)
- **Away from home:** Full notifications on iPhone as usual
- **Coffee shop:** Full notifications (different network)

## Testing

### Test Mac Service

```bash
# From Terminal on Mac
dns-sd -B _vibestatus._tcp
# Should show VibeStatus-Mac or your Mac's name
```

### Test iPhone Discovery

1. Open iPhone Settings
2. Enable "Silence When Near Mac"
3. Check Xcode console for logs:
   - `[ProximityDetector] Starting discovery`
   - `[ProximityDetector] Mac detected on local network`
   - `[NotificationManager] Silencing notification - Mac detected nearby`

## Implementation Details

### Mac Side (BonjourService.swift)

- Advertises on app launch
- Stops on app quit
- No actual network port opened (port 0)
- Service name: Mac's computer name

### iPhone Side (ProximityDetector.swift)

- Uses NWBrowser from Network framework
- 3-second discovery timeout
- One-time check before each notification
- Stops discovery after check (battery efficient)

### Settings

- Stored in UserDefaults: `silenceNotificationsWhenNearMac`
- Toggle in iOS Settings under Notifications section
- Only visible when notifications are authorized

## Troubleshooting

### "Mac not detected" but I'm at home

- Check both devices are on WiFi (not cellular)
- Check VibeStatus Mac app is running
- Check firewall settings (allow incoming connections)
- Try restarting both apps

### Permission prompt not appearing

- Check Info.plist has NSLocalNetworkUsageDescription
- Check Info.plist has NSBonjourServices array
- Try clean build (Product → Clean Build Folder)

### Works on some WiFi networks but not others

- Some enterprise networks block Bonjour/mDNS
- Check with network administrator
- Feature will gracefully fall back to showing all notifications
