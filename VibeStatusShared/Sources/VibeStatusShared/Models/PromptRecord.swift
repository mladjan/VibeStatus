// PromptRecord.swift
// VibeStatusShared
//
// CloudKit-compatible prompt record model for iOS remote input

import Foundation
import CloudKit

/// Represents a Claude Code input prompt in CloudKit
/// Used for iOS-to-macOS remote input when Claude needs user interaction
public struct PromptRecord: Identifiable, Equatable, Codable {
    public let id: String // Unique prompt ID
    public let sessionId: String // Associated session
    public let project: String
    public let promptMessage: String // The question/prompt from Claude
    public let notificationType: String // e.g., "idle_prompt"
    public let transcriptPath: String?
    public let transcriptExcerpt: String? // Last few messages for context
    public let timestamp: Date
    public let pid: Int?

    // Response fields (written by iOS, read by macOS)
    public let responseText: String?
    public let respondedAt: Date?
    public let respondedFromDevice: String?
    public let responded: Bool // Boolean flag for efficient CloudKit queries

    public init(
        id: String,
        sessionId: String,
        project: String,
        promptMessage: String,
        notificationType: String,
        transcriptPath: String?,
        transcriptExcerpt: String?,
        timestamp: Date,
        pid: Int?,
        responseText: String? = nil,
        respondedAt: Date? = nil,
        respondedFromDevice: String? = nil,
        responded: Bool = false
    ) {
        self.id = id
        self.sessionId = sessionId
        self.project = project
        self.promptMessage = promptMessage
        self.notificationType = notificationType
        self.transcriptPath = transcriptPath
        self.transcriptExcerpt = transcriptExcerpt
        self.timestamp = timestamp
        self.pid = pid
        self.responseText = responseText
        self.respondedAt = respondedAt
        self.respondedFromDevice = respondedFromDevice
        self.responded = responded
    }

    // MARK: - CloudKit Conversion

    /// CloudKit record type identifier
    public static let recordType = "Prompt"

    /// Creates a PromptRecord from a CloudKit CKRecord
    public init?(from record: CKRecord) {
        guard
            let promptId = record["promptId"] as? String,
            let sessionId = record["sessionId"] as? String,
            let project = record["project"] as? String,
            let promptMessage = record["promptMessage"] as? String,
            let notificationType = record["notificationType"] as? String,
            let timestamp = record["timestamp"] as? Date
        else {
            return nil
        }

        self.id = promptId
        self.sessionId = sessionId
        self.project = project
        self.promptMessage = promptMessage
        self.notificationType = notificationType
        self.transcriptPath = record["transcriptPath"] as? String
        self.transcriptExcerpt = record["transcriptExcerpt"] as? String
        self.timestamp = timestamp
        self.pid = record["pid"] as? Int
        self.responseText = record["responseText"] as? String
        self.respondedAt = record["respondedAt"] as? Date
        self.respondedFromDevice = record["respondedFromDevice"] as? String
        self.responded = (record["responded"] as? Int == 1) // CloudKit stores booleans as Int64
    }

    /// Converts this PromptRecord to a CloudKit CKRecord
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        record["promptId"] = id as CKRecordValue
        record["sessionId"] = sessionId as CKRecordValue
        record["project"] = project as CKRecordValue
        record["promptMessage"] = promptMessage as CKRecordValue
        record["notificationType"] = notificationType as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue

        if let transcriptPath = transcriptPath {
            record["transcriptPath"] = transcriptPath as CKRecordValue
        }
        if let transcriptExcerpt = transcriptExcerpt {
            record["transcriptExcerpt"] = transcriptExcerpt as CKRecordValue
        }
        if let pid = pid {
            record["pid"] = pid as CKRecordValue
        }
        if let responseText = responseText {
            record["responseText"] = responseText as CKRecordValue
        }
        if let respondedAt = respondedAt {
            record["respondedAt"] = respondedAt as CKRecordValue
        }
        if let respondedFromDevice = respondedFromDevice {
            record["respondedFromDevice"] = respondedFromDevice as CKRecordValue
        }

        // Store boolean as Int64 for CloudKit compatibility
        record["responded"] = (responded ? 1 : 0) as CKRecordValue

        return record
    }

    /// Updates an existing CKRecord with this PromptRecord's data
    public func updateCKRecord(_ record: CKRecord) {
        record["promptId"] = id as CKRecordValue
        record["sessionId"] = sessionId as CKRecordValue
        record["project"] = project as CKRecordValue
        record["promptMessage"] = promptMessage as CKRecordValue
        record["notificationType"] = notificationType as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue

        if let transcriptPath = transcriptPath {
            record["transcriptPath"] = transcriptPath as CKRecordValue
        }
        if let transcriptExcerpt = transcriptExcerpt {
            record["transcriptExcerpt"] = transcriptExcerpt as CKRecordValue
        }
        if let pid = pid {
            record["pid"] = pid as CKRecordValue
        }
        if let responseText = responseText {
            record["responseText"] = responseText as CKRecordValue
        }
        if let respondedAt = respondedAt {
            record["respondedAt"] = respondedAt as CKRecordValue
        }
        if let respondedFromDevice = respondedFromDevice {
            record["respondedFromDevice"] = respondedFromDevice as CKRecordValue
        }

        // Store boolean as Int64 for CloudKit compatibility
        record["responded"] = (responded ? 1 : 0) as CKRecordValue
    }

    /// Returns whether this prompt has been responded to
    public var isResponded: Bool {
        responseText != nil && respondedAt != nil
    }
}

/// Raw prompt data as written by the Claude Code hook script.
/// This structure matches the JSON format written to /tmp/vibestatus-prompt-*.json
public struct PromptData: Codable {
    public let session_id: String
    public let project: String
    public let prompt_message: String
    public let notification_type: String
    public let transcript_path: String?
    public let transcript_excerpt: String?
    public let timestamp: String
    public let pid: Int?

    public init(
        session_id: String,
        project: String,
        prompt_message: String,
        notification_type: String,
        transcript_path: String? = nil,
        transcript_excerpt: String? = nil,
        timestamp: String,
        pid: Int? = nil
    ) {
        self.session_id = session_id
        self.project = project
        self.prompt_message = prompt_message
        self.notification_type = notification_type
        self.transcript_path = transcript_path
        self.transcript_excerpt = transcript_excerpt
        self.timestamp = timestamp
        self.pid = pid
    }
}
