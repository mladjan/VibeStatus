// CloudKitManager.swift
// VibeStatusShared
//
// Manages CloudKit operations for syncing sessions

import Foundation
import CloudKit
import os.log

private let logger = Logger(subsystem: "com.mladjan.vibestatus", category: "CloudKit")

/// Manages CloudKit sync operations for session data
@MainActor
public class CloudKitManager: ObservableObject {
    // MARK: - Singleton

    public static let shared = CloudKitManager()

    // MARK: - Published Properties

    @Published public var iCloudAvailable = false
    @Published public var lastSyncDate: Date?
    @Published public var syncError: Error?

    // MARK: - Private Properties

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    /// Tracks pending uploads to prevent duplicates
    private var pendingUploads: Set<String> = []

    /// Debounce timers for uploads per session
    private var uploadTimers: [String: Task<Void, Never>] = [:]

    // MARK: - Initialization

    private init() {
        self.container = CKContainer(identifier: CloudKitConstants.containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase

        Task {
            await checkiCloudStatus()
        }
    }

    // MARK: - iCloud Status

    /// Checks if iCloud is available and user is signed in
    public func checkiCloudStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                iCloudAvailable = (status == .available)
            }
            logger.info("iCloud status: \(status == .available ? "available" : "unavailable")")
        } catch {
            logger.error("Failed to check iCloud status: \(error.localizedDescription)")
            await MainActor.run {
                iCloudAvailable = false
                syncError = error
            }
        }
    }

    // MARK: - Upload Operations

    /// Uploads a session to CloudKit with debouncing
    /// - Parameter session: The session record to upload
    public func uploadSession(_ session: SessionRecord) async {
        // Check iCloud status first if not already available
        if !iCloudAvailable {
            await checkiCloudStatus()
        }

        guard iCloudAvailable else {
            logger.warning("Cannot upload session - iCloud not available")
            return
        }

        // Cancel existing timer for this session
        if let existingTask = uploadTimers[session.id] {
            existingTask.cancel()
        }

        // Create new debounced upload task
        uploadTimers[session.id] = Task {
            // Wait for debounce interval
            try? await Task.sleep(nanoseconds: UInt64(CloudKitConstants.uploadDebounceInterval * 1_000_000_000))

            guard !Task.isCancelled else {
                return
            }

            // Perform upload in detached task to prevent cancellation mid-upload
            await Task.detached {
                await self.performUpload(session)
            }.value
        }
    }

    /// Performs the actual upload to CloudKit
    private func performUpload(_ session: SessionRecord) async {
        guard !pendingUploads.contains(session.id) else {
            logger.debug("Upload already pending for session \(session.id)")
            return
        }

        pendingUploads.insert(session.id)
        defer { pendingUploads.remove(session.id) }

        do {
            let recordID = CKRecord.ID(recordName: session.id)

            // Try to fetch existing record first
            let existingRecord: CKRecord
            do {
                existingRecord = try await privateDatabase.record(for: recordID)
                // Update existing record
                session.updateCKRecord(existingRecord)
            } catch let error as CKError where error.code == .unknownItem {
                // Record doesn't exist, create new one
                existingRecord = session.toCKRecord()
            }

            // Save (insert or update)
            _ = try await privateDatabase.save(existingRecord)

            await MainActor.run {
                lastSyncDate = Date()
                UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastSyncDate)
            }

            logger.info("Successfully uploaded session: \(session.id) - \(session.project)")
        } catch {
            logger.error("Failed to upload session \(session.id): \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
        }
    }

    /// Uploads multiple sessions at once
    /// - Parameter sessions: Array of session records to upload
    public func uploadSessions(_ sessions: [SessionRecord]) async {
        guard iCloudAvailable else {
            logger.warning("Cannot upload sessions - iCloud not available")
            return
        }

        await withTaskGroup(of: Void.self) { group in
            for session in sessions {
                group.addTask {
                    await self.uploadSession(session)
                }
            }
        }
    }

    // MARK: - Fetch Operations

    /// Fetches all active sessions from CloudKit
    /// - Returns: Array of session records
    public func fetchSessions() async -> [SessionRecord] {
        // Check iCloud status first if not already available
        if !iCloudAvailable {
            await checkiCloudStatus()
        }

        guard iCloudAvailable else {
            logger.warning("Cannot fetch sessions - iCloud not available")
            return []
        }

        do {
            // Query using a field-based predicate since individual fields are marked queryable
            // Use timestamp field to get all sessions from the last 30 minutes
            let thirtyMinutesAgo = Date().addingTimeInterval(-CloudKitConstants.sessionExpirationInterval)

            let query = CKQuery(
                recordType: SessionRecord.recordType,
                predicate: NSPredicate(format: "timestamp >= %@", thirtyMinutesAgo as NSDate)
            )
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            var sessions: [SessionRecord] = []
            var cursor: CKQueryOperation.Cursor?

            repeat {
                let (results, nextCursor) = try await privateDatabase.records(
                    matching: query,
                    resultsLimit: 100
                )

                cursor = nextCursor

                // results is [(CKRecord.ID, Result<CKRecord, Error>)]
                for (_, result) in results {
                    do {
                        let record = try result.get()
                        if let session = SessionRecord(from: record) {
                            // Query already filters by timestamp, so all results are valid
                            sessions.append(session)
                        }
                    } catch {
                        logger.error("Failed to parse session record: \(error.localizedDescription)")
                    }
                }
            } while cursor != nil

            await MainActor.run {
                lastSyncDate = Date()
            }

            logger.info("Fetched \(sessions.count) active sessions")

            // Already sorted by query's sortDescriptor (timestamp descending)
            return sessions

        } catch {
            logger.error("Failed to fetch sessions: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
            return []
        }
    }

    // MARK: - Delete Operations

    /// Deletes a session from CloudKit
    /// - Parameter sessionId: The ID of the session to delete
    public func deleteSession(_ sessionId: String) async {
        guard iCloudAvailable else {
            logger.warning("Cannot delete session - iCloud not available")
            return
        }

        do {
            let recordID = CKRecord.ID(recordName: sessionId)
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            logger.info("Successfully deleted session: \(sessionId)")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, that's fine
            logger.debug("Session \(sessionId) already deleted")
        } catch {
            logger.error("Failed to delete session \(sessionId): \(error.localizedDescription)")
        }
    }

    /// Deletes multiple sessions at once
    /// - Parameter sessionIds: Array of session IDs to delete
    public func deleteSessions(_ sessionIds: [String]) async {
        guard iCloudAvailable else { return }

        await withTaskGroup(of: Void.self) { group in
            for sessionId in sessionIds {
                group.addTask {
                    await self.deleteSession(sessionId)
                }
            }
        }
    }

    // MARK: - Subscription Management

    /// Sets up CloudKit subscription for push notifications
    /// Should be called once on iOS app launch
    public func setupSubscription() async {
        // Check iCloud status first if not already available
        if !iCloudAvailable {
            await checkiCloudStatus()
        }

        guard iCloudAvailable else {
            logger.warning("Cannot setup subscription - iCloud not available")
            return
        }

        do {
            // Check if subscription already exists
            let subscriptions = try await privateDatabase.allSubscriptions()

            let subscriptionExists = subscriptions.contains { subscription in
                subscription.subscriptionID == CloudKitConstants.sessionSubscriptionID
            }

            if subscriptionExists {
                logger.info("CloudKit subscription already exists")
                return
            }

            // Create new subscription
            let subscription = CKQuerySubscription(
                recordType: SessionRecord.recordType,
                predicate: NSPredicate(value: true),
                subscriptionID: CloudKitConstants.sessionSubscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )

            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo

            _ = try await privateDatabase.save(subscription)
            logger.info("Successfully created CloudKit subscription")

        } catch {
            logger.error("Failed to setup subscription: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
        }
    }

    /// Removes the CloudKit subscription
    public func removeSubscription() async {
        guard iCloudAvailable else { return }

        do {
            _ = try await privateDatabase.deleteSubscription(
                withID: CloudKitConstants.sessionSubscriptionID
            )
            logger.info("Successfully removed CloudKit subscription")
        } catch {
            logger.error("Failed to remove subscription: \(error.localizedDescription)")
        }
    }
}
