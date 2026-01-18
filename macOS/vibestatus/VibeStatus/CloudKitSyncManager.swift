// CloudKitSyncManager.swift
// VibeStatus
//
// Manages CloudKit sync for macOS app
// Bridges between StatusManager and CloudKit

import Foundation
import Combine
import os.log
import VibeStatusShared

private let logger = Logger(subsystem: "com.mladjan.vibestatus", category: "Sync")

/// Manages CloudKit sync operations for the macOS app
@MainActor
final class CloudKitSyncManager: ObservableObject {
    // MARK: - Singleton

    static let shared = CloudKitSyncManager()

    // MARK: - Published Properties

    @Published var syncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(syncEnabled, forKey: "ios_sync_enabled")
            if syncEnabled {
                Task {
                    await CloudKitManager.shared.checkiCloudStatus()
                }
            }
        }
    }

    @Published var iCloudAvailable = false
    @Published var lastSyncDate: Date?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let deviceName: String

    /// Tracks last uploaded session states to prevent unnecessary uploads
    private var lastUploadedStates: [String: String] = [:]

    // MARK: - Initialization

    private init() {
        // Load sync enabled preference
        self.syncEnabled = UserDefaults.standard.bool(forKey: "ios_sync_enabled")

        // Get device name
        self.deviceName = ProcessInfo.processInfo.hostName

        observeCloudKitManager()
    }

    // MARK: - CloudKit Observation

    private func observeCloudKitManager() {
        CloudKitManager.shared.$iCloudAvailable
            .receive(on: DispatchQueue.main)
            .assign(to: &$iCloudAvailable)

        CloudKitManager.shared.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastSyncDate)
    }

    // MARK: - Sync Operations

    /// Uploads sessions to CloudKit
    /// - Parameter sessions: Array of SessionInfo to upload
    func uploadSessions(_ sessions: [SessionInfo]) async {
        guard syncEnabled else { return }

        guard CloudKitManager.shared.iCloudAvailable else {
            logger.warning("Cannot sync - iCloud not available")
            return
        }

        // Convert SessionInfo to SessionRecord
        // Only upload sessions whose status has changed to avoid notification spam
        let currentTimestamp = Date()
        var recordsToUpload: [SessionRecord] = []

        for session in sessions {
            let statusKey = "\(session.id):\(session.status.rawValue)"

            // Check if status has changed since last upload
            if lastUploadedStates[session.id] != statusKey {
                let record = SessionRecord(
                    id: session.id,
                    status: VibeStatusShared.VibeStatus(rawValue: session.status.rawValue) ?? .notRunning,
                    project: session.project,
                    timestamp: currentTimestamp,
                    pid: nil,
                    macDeviceName: deviceName
                )
                recordsToUpload.append(record)

                // Update last uploaded state
                lastUploadedStates[session.id] = statusKey
            }
        }

        // Also clean up states for sessions that no longer exist
        let currentSessionIds = Set(sessions.map { $0.id })
        lastUploadedStates = lastUploadedStates.filter { currentSessionIds.contains($0.key) }

        // Upload only changed sessions
        if !recordsToUpload.isEmpty {
            await CloudKitManager.shared.uploadSessions(recordsToUpload)
            logger.info("Uploaded \(recordsToUpload.count) changed sessions to CloudKit")
        }
    }

    /// Deletes stale sessions from CloudKit
    /// - Parameter activeSessionIds: IDs of sessions that are still active
    func cleanupStaleSessions(keeping activeSessionIds: Set<String>) async {
        guard syncEnabled else { return }

        guard CloudKitManager.shared.iCloudAvailable else { return }

        // Fetch all sessions - will fail silently if queryable not enabled
        let allSessions = await CloudKitManager.shared.fetchSessions()

        // If fetch failed (returns empty array), skip cleanup
        // This prevents errors when CloudKit schema isn't configured yet
        guard !allSessions.isEmpty else { return }

        let staleSessionIds = allSessions
            .filter { !activeSessionIds.contains($0.id) }
            .map { $0.id }

        if !staleSessionIds.isEmpty {
            await CloudKitManager.shared.deleteSessions(staleSessionIds)
            logger.info("Cleaned up \(staleSessionIds.count) stale sessions")
        }
    }

    /// Manually triggers a sync
    func triggerManualSync() async {
        await CloudKitManager.shared.checkiCloudStatus()
        logger.info("Manual sync triggered")
    }
}
