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

    // MARK: - Prompt Operations

    /// Uploads a prompt to CloudKit (macOS → Cloud)
    /// Called when Claude needs input from user
    public func uploadPrompt(_ prompt: PromptRecord) async {
        guard iCloudAvailable else {
            logger.warning("Cannot upload prompt - iCloud not available")
            return
        }

        do {
            let record = prompt.toCKRecord()
            _ = try await privateDatabase.save(record)
            logger.info("Successfully uploaded prompt: \(prompt.id)")

            await MainActor.run {
                lastSyncDate = Date()
            }
        } catch {
            logger.error("Failed to upload prompt: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
        }
    }

    /// Fetches pending prompts (iOS fetches from Cloud)
    /// Returns prompts that haven't been responded to yet
    public func fetchPendingPrompts() async -> [PromptRecord] {
        guard iCloudAvailable else {
            logger.warning("Cannot fetch prompts - iCloud not available")
            return []
        }

        do {
            // Query for prompts without responses using boolean field
            let predicate = NSPredicate(format: "responded == 0")
            let query = CKQuery(recordType: PromptRecord.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            let results = try await privateDatabase.records(matching: query)
            let prompts = results.matchResults.compactMap { (_, result) -> PromptRecord? in
                guard case .success(let record) = result else { return nil }
                return PromptRecord(from: record)
            }

            logger.info("Fetched \(prompts.count) pending prompts")
            return prompts

        } catch {
            logger.error("Failed to fetch prompts: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
            return []
        }
    }

    /// Submits a response to a prompt (iOS → Cloud)
    /// Updates the prompt record with user's response
    public func submitResponse(promptId: String, responseText: String, deviceName: String) async -> Bool {
        guard iCloudAvailable else {
            logger.warning("Cannot submit response - iCloud not available")
            return false
        }

        do {
            // Fetch the existing prompt record
            let recordID = CKRecord.ID(recordName: promptId)
            let record = try await privateDatabase.record(for: recordID)

            // Update with response
            record["responseText"] = responseText as CKRecordValue
            record["respondedAt"] = Date() as CKRecordValue
            record["respondedFromDevice"] = deviceName as CKRecordValue
            record["responded"] = 1 as CKRecordValue // Mark as responded

            _ = try await privateDatabase.save(record)
            logger.info("Successfully submitted response for prompt: \(promptId)")

            await MainActor.run {
                lastSyncDate = Date()
            }

            return true

        } catch {
            logger.error("Failed to submit response: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
            return false
        }
    }

    /// Fetches responses to prompts (macOS fetches from Cloud)
    /// Returns prompts that have been responded to
    public func fetchResponses(forSessionId sessionId: String) async -> [PromptRecord] {
        guard iCloudAvailable else {
            logger.warning("Cannot fetch responses - iCloud not available")
            return []
        }

        do {
            // Query for prompts with responses for this session using boolean field
            let predicate = NSPredicate(format: "sessionId == %@ AND responded == 1", sessionId)
            let query = CKQuery(recordType: PromptRecord.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "respondedAt", ascending: false)]

            let results = try await privateDatabase.records(matching: query)
            let prompts = results.matchResults.compactMap { (_, result) -> PromptRecord? in
                guard case .success(let record) = result else { return nil }
                return PromptRecord(from: record)
            }

            logger.info("Fetched \(prompts.count) responses for session \(sessionId)")
            return prompts

        } catch {
            logger.error("Failed to fetch responses: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
            return []
        }
    }

    /// Deletes a prompt record (cleanup after response is processed)
    public func deletePrompt(_ promptId: String) async {
        guard iCloudAvailable else { return }

        do {
            let recordID = CKRecord.ID(recordName: promptId)
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            logger.info("Successfully deleted prompt: \(promptId)")
        } catch {
            logger.error("Failed to delete prompt: \(error.localizedDescription)")
        }
    }

    /// Convenience method for iOS to refresh prompts
    public func refreshPrompts() async {
        _ = await fetchPendingPrompts()
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
            // Check if subscriptions already exist
            let subscriptions = try await privateDatabase.allSubscriptions()

            let sessionSubExists = subscriptions.contains { subscription in
                subscription.subscriptionID == CloudKitConstants.sessionSubscriptionID
            }

            let promptSubExists = subscriptions.contains { subscription in
                subscription.subscriptionID == CloudKitConstants.promptSubscriptionID
            }

            // Create session subscription if it doesn't exist
            if !sessionSubExists {
                let sessionSub = CKQuerySubscription(
                    recordType: SessionRecord.recordType,
                    predicate: NSPredicate(value: true),
                    subscriptionID: CloudKitConstants.sessionSubscriptionID,
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
                )

                let sessionNotif = CKSubscription.NotificationInfo()
                sessionNotif.shouldSendContentAvailable = true
                sessionSub.notificationInfo = sessionNotif

                _ = try await privateDatabase.save(sessionSub)
                logger.info("Successfully created session subscription")
            }

            // Create prompt subscription if it doesn't exist
            if !promptSubExists {
                let promptSub = CKQuerySubscription(
                    recordType: PromptRecord.recordType,
                    predicate: NSPredicate(value: true),
                    subscriptionID: CloudKitConstants.promptSubscriptionID,
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
                )

                let promptNotif = CKSubscription.NotificationInfo()
                promptNotif.shouldSendContentAvailable = true
                promptNotif.alertBody = "Claude needs your input"
                promptNotif.soundName = "default"
                promptSub.notificationInfo = promptNotif

                _ = try await privateDatabase.save(promptSub)
                logger.info("Successfully created prompt subscription")
            }

            if sessionSubExists && promptSubExists {
                logger.info("CloudKit subscriptions already exist")
            }

        } catch {
            logger.error("Failed to setup subscription: \(error.localizedDescription)")
            await MainActor.run {
                syncError = error
            }
        }
    }

    /// Removes the CloudKit subscriptions
    public func removeSubscription() async {
        guard iCloudAvailable else { return }

        do {
            _ = try await privateDatabase.deleteSubscription(
                withID: CloudKitConstants.sessionSubscriptionID
            )
            _ = try await privateDatabase.deleteSubscription(
                withID: CloudKitConstants.promptSubscriptionID
            )
            logger.info("Successfully removed CloudKit subscriptions")
        } catch {
            logger.error("Failed to remove subscription: \(error.localizedDescription)")
        }
    }
}
