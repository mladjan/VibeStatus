# iOS Info.plist Entries for Local Network Permission

## Required Entries

Add these entries to your iOS app's Info.plist to enable Bonjour discovery:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>VibeStatus uses the local network to detect when your Mac is nearby, allowing it to automatically silence notifications when you're at your desk.</string>

<key>NSBonjourServices</key>
<array>
    <string>_vibestatus._tcp</string>
</array>
```

## How to Add in Xcode

### Method 1: Using Info Tab (Recommended)

1. Open `VibeStatusMobile.xcodeproj` in Xcode
2. Select the **VibeStatusMobile** target
3. Go to the **Info** tab
4. Click the **+** button next to any key
5. Add these two entries:

   **Entry 1:**
   - Key: `Privacy - Local Network Usage Description`
   - Type: `String`
   - Value: `VibeStatus uses the local network to detect when your Mac is nearby, allowing it to automatically silence notifications when you're at your desk.`

   **Entry 2:**
   - Key: `Bonjour services`
   - Type: `Array`
   - Click the arrow to expand, then click **+** to add item
   - Item 0: `_vibestatus._tcp`

### Method 2: Edit Info.plist Directly

1. In Xcode, find `Info.plist` in Project Navigator
2. Right-click → Open As → Source Code
3. Add the XML entries above before the closing `</dict>` tag
4. Save the file

## What Happens Next

1. **Clean build** the iOS app (Product → Clean Build Folder)
2. **Rebuild** and run on device or simulator
3. **First time** the app tries to discover Bonjour services, iOS will show a permission prompt:

   ```
   "VibeStatusMobile" Would Like to Find and Connect to Devices on Your Local Network

   VibeStatus uses the local network to detect when your Mac is nearby, allowing it to automatically silence notifications when you're at your desk.

   [Don't Allow]  [OK]
   ```

4. **Tap OK** to grant permission
5. The proximity detection will start working immediately

## Verification

After granting permission, you should see in logs:

```
[🔇 PROXIMITY] ✅ Browser ready - scanning for services...
[🔇 PROXIMITY] 📡 Services found: 1
[🔇 PROXIMITY] ✅ Mac detected on local network!
[🔇 PROXIMITY] Service 1: Mladjan's MacBook Pro._vibestatus._tcp.local.
```

## Troubleshooting

### Permission prompt doesn't appear
- Make sure Info.plist has both entries
- Clean build and rebuild
- Reset privacy permissions: Settings → General → Transfer or Reset → Reset Location & Privacy

### Still getting -65555: NoAuth error
- Check Info.plist entries are correct
- Verify `_vibestatus._tcp` matches exactly (no spaces, no trailing dot)
- Make sure both Mac and iPhone are on the same WiFi network
- Try restarting both devices
