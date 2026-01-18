// Constants.swift
// VibeStatusShared
//
// Shared constants used by both macOS and iOS apps

import Foundation

public enum CloudKitConstants {
    /// CloudKit container identifier
    /// NOTE: This must match the identifier in both app's entitlements
    public static let containerIdentifier = "iCloud.com.mladjan.vibestatus"

    /// Subscription ID for push notifications
    public static let sessionSubscriptionID = "session-changes"

    /// Zone name for custom CloudKit zone (optional, using default for now)
    public static let zoneName = "VibeStatusZone"

    /// Maximum age for sessions before considering them stale (30 minutes)
    public static let sessionExpirationInterval: TimeInterval = 30 * 60

    /// Debounce interval for uploads (prevent too frequent syncs)
    /// Set to 0.5s to allow uploads to complete before next polling cycle (StatusManager polls every 1s)
    public static let uploadDebounceInterval: TimeInterval = 0.5
}

public enum UserDefaultsKeys {
    /// Whether iOS sync is enabled
    public static let iOSSyncEnabled = "ios_sync_enabled"

    /// Last sync timestamp
    public static let lastSyncDate = "last_sync_date"

    /// Device name for identification
    public static let deviceName = "device_name"
}
