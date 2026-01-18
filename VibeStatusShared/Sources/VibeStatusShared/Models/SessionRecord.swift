// SessionRecord.swift
// VibeStatusShared
//
// CloudKit-compatible session record model

import Foundation
import CloudKit

/// Represents a Claude Code session in CloudKit
public struct SessionRecord: Identifiable, Equatable, Codable {
    public let id: String
    public let status: VibeStatus
    public let project: String
    public let timestamp: Date
    public let pid: Int?
    public let macDeviceName: String

    public init(
        id: String,
        status: VibeStatus,
        project: String,
        timestamp: Date,
        pid: Int?,
        macDeviceName: String
    ) {
        self.id = id
        self.status = status
        self.project = project
        self.timestamp = timestamp
        self.pid = pid
        self.macDeviceName = macDeviceName
    }

    // MARK: - CloudKit Conversion

    /// CloudKit record type identifier
    public static let recordType = "Session"

    /// Creates a SessionRecord from a CloudKit CKRecord
    public init?(from record: CKRecord) {
        guard
            let sessionId = record["sessionId"] as? String,
            let statusString = record["status"] as? String,
            let status = VibeStatus(rawValue: statusString),
            let project = record["project"] as? String,
            let timestamp = record["timestamp"] as? Date,
            let macDeviceName = record["macDeviceName"] as? String
        else {
            return nil
        }

        self.id = sessionId
        self.status = status
        self.project = project
        self.timestamp = timestamp
        self.pid = record["pid"] as? Int
        self.macDeviceName = macDeviceName
    }

    /// Converts this SessionRecord to a CloudKit CKRecord
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        record["sessionId"] = id as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["project"] = project as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
        record["macDeviceName"] = macDeviceName as CKRecordValue

        if let pid = pid {
            record["pid"] = pid as CKRecordValue
        }

        return record
    }

    /// Updates an existing CKRecord with this SessionRecord's data
    public func updateCKRecord(_ record: CKRecord) {
        record["sessionId"] = id as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["project"] = project as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
        record["macDeviceName"] = macDeviceName as CKRecordValue

        if let pid = pid {
            record["pid"] = pid as CKRecordValue
        }
    }
}

/// Raw status data as written by the Claude Code hook script.
/// This structure matches the JSON format written to /tmp/vibestatus-*.json
public struct StatusData: Codable {
    public let state: VibeStatus
    public let message: String?
    public let timestamp: Date?
    public let project: String?
    public let pid: Int?

    public init(
        state: VibeStatus,
        message: String? = nil,
        timestamp: Date? = nil,
        project: String? = nil,
        pid: Int? = nil
    ) {
        self.state = state
        self.message = message
        self.timestamp = timestamp
        self.project = project
        self.pid = pid
    }
}

/// Session info for local display (legacy compatibility with macOS app)
public struct SessionInfo: Equatable, Identifiable {
    public let id: String
    public let status: VibeStatus
    public let project: String
    public let timestamp: Date

    public init(
        id: String,
        status: VibeStatus,
        project: String,
        timestamp: Date
    ) {
        self.id = id
        self.status = status
        self.project = project
        self.timestamp = timestamp
    }

    /// Converts a SessionRecord to SessionInfo
    public init(from record: SessionRecord) {
        self.id = record.id
        self.status = record.status
        self.project = record.project
        self.timestamp = record.timestamp
    }
}
