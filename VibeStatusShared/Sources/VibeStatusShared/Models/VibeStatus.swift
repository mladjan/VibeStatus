// VibeStatus.swift
// VibeStatusShared
//
// Shared status enum used by both macOS and iOS apps

import Foundation

/// Represents the current operational state of a Claude Code session.
/// These states map directly to the hook events emitted by Claude Code.
public enum VibeStatus: String, Codable, Equatable, CaseIterable {
    /// Claude is actively processing a request
    case working
    /// Claude has finished processing and is waiting for new input
    case idle
    /// Claude requires user input to continue (e.g., confirmation prompt)
    case needsInput = "needs_input"
    /// No active Claude session detected
    case notRunning = "not_running"

    /// Human-readable display name for UI
    public var displayName: String {
        switch self {
        case .working: return "Working"
        case .idle: return "Ready"
        case .needsInput: return "Needs Input"
        case .notRunning: return "Not Running"
        }
    }

    /// Short status text for compact displays
    public var shortName: String {
        switch self {
        case .working: return "Working..."
        case .idle: return "Ready"
        case .needsInput: return "Input needed"
        case .notRunning: return "Not running"
        }
    }

    /// Emoji representation for notifications
    public var emoji: String {
        switch self {
        case .working: return "⚙️"
        case .idle: return "✅"
        case .needsInput: return "❓"
        case .notRunning: return "⭕"
        }
    }
}
