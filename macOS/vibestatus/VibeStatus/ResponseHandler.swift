// ResponseHandler.swift
// VibeStatus
//
// Monitors CloudKit for prompt responses from iOS and forwards them to Claude Code sessions
// Uses AppleScript to send responses to the active Terminal window

import Foundation
import AppKit
import VibeStatusShared

/// Handles forwarding of iOS responses to Claude Code sessions in Terminal
@MainActor
final class ResponseHandler: NSObject, ObservableObject, NSUserNotificationCenterDelegate {
    static let shared = ResponseHandler()

    // MARK: - Properties

    private var pollingTask: Task<Void, Never>?
    private var processedPromptIds: Set<String> = []

    /// How often to check for responses (2 seconds)
    private let pollingInterval: TimeInterval = 2.0

    // MARK: - Initialization

    override private init() {
        super.init()
        NSUserNotificationCenter.default.delegate = self
    }

    deinit {
        // Note: Cannot call stop() here as it's @MainActor isolated
        // Just cancel the task directly which is nonisolated
        pollingTask?.cancel()
    }

    // MARK: - Notification Delegate

    nonisolated func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        // User clicked on the notification - open System Settings
        Task { @MainActor in
            openSystemSettingsAutomation()
        }
    }

    // MARK: - Public API

    /// Start monitoring for responses from iOS
    func start() {
        stop() // Cancel any existing task

        pollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                await self.checkForResponses()

                try? await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
            }
        }
    }

    /// Stop monitoring for responses
    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Permission Test

    /// Test automation permission by attempting to control System Events
    /// This will trigger the permission dialog if not already granted
    func testAutomationPermission() -> Bool {
        print("[ResponseHandler] 🧪 Testing automation permission...")
        print("[ResponseHandler] This will attempt to control System Events (required for sending keystrokes)")

        // Test script that uses System Events - this is what actually needs permission
        let testScript = """
        tell application "Terminal"
            activate
            delay 0.2
            tell application "System Events"
                -- Try to get a keystroke event (this requires permission)
                -- We don't actually send anything, just test if we can access System Events
                set frontApp to name of first application process whose frontmost is true
            end tell
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: testScript) {
            scriptObject.executeAndReturnError(&error)

            if let error = error {
                let errorCode = error["NSAppleScriptErrorNumber"] as? Int ?? 0
                print("[ResponseHandler] ❌ Permission test failed with error code: \(errorCode)")
                print("[ResponseHandler] Error details: \(error)")

                if errorCode == -1743 {
                    print("[ResponseHandler] 💡 This is error -1743: Not authorized to send Apple events to System Events")
                    print("[ResponseHandler] 💡 The permission dialog should have appeared!")
                    print("[ResponseHandler] 💡 If not, you may need to grant permission manually in System Settings")
                }

                showPermissionNotification()
                return false
            }

            print("[ResponseHandler] ✅ Permission test passed - automation is working!")
            print("[ResponseHandler] ✅ System Events access confirmed")
            showNotification(
                title: "Permission Granted",
                body: "VibeStatus can now send responses from your iPhone to Terminal automatically."
            )
            return true
        }

        return false
    }

    // MARK: - Private Methods

    /// Check CloudKit for new responses and process them
    private func checkForResponses() async {
        // Get all active sessions to check for their responses
        let sessions = StatusManager.shared.sessions
        print("[ResponseHandler] 🔍 Checking for responses...")
        print("[ResponseHandler] Active sessions count: \(sessions.count)")

        for session in sessions {
            print("[ResponseHandler] Checking session: \(session.id) (\(session.project))")

            // Extract session ID from filename (e.g., "vibestatus-abc123.json" -> "abc123")
            let sessionId = extractSessionId(from: session.id)
            print("[ResponseHandler] Session ID extracted: '\(session.id)' -> '\(sessionId)'")

            // Fetch responses for this session
            let responses = await CloudKitManager.shared.fetchResponses(forSessionId: sessionId)
            print("[ResponseHandler] Found \(responses.count) responses for session \(sessionId)")

            for response in responses {
                print("[ResponseHandler] Processing response:")
                print("  Prompt ID: \(response.id)")
                print("  Session ID: \(response.sessionId)")
                print("  Response text: '\(response.responseText ?? "nil")'")
                print("  Responded from: \(response.respondedFromDevice ?? "unknown")")

                // Skip if already processed
                guard !processedPromptIds.contains(response.id) else {
                    print("[ResponseHandler] ⏭️  Skipping already processed prompt: \(response.id)")
                    continue
                }

                print("[ResponseHandler] 🚀 Processing new response...")

                // Process the response
                await processResponse(response)

                // Mark as processed
                processedPromptIds.insert(response.id)
                print("[ResponseHandler] ✅ Marked prompt as processed: \(response.id)")

                // Clean up from CloudKit after processing
                print("[ResponseHandler] 🗑️  Deleting prompt from CloudKit...")
                await CloudKitManager.shared.deletePrompt(response.id)
            }
        }
    }

    /// Process a single response by forwarding it to Terminal
    private func processResponse(_ response: PromptRecord) async {
        guard let responseText = response.responseText else { return }

        print("[ResponseHandler] Processing response for session \(response.sessionId)")
        print("[ResponseHandler] Response: \(responseText)")

        // Try to send to Terminal using AppleScript
        let success = await sendToTerminal(responseText, pid: response.pid)

        if success {
            print("[ResponseHandler] ✅ Successfully sent response to Terminal")

            // Update status file to "working" since input was provided
            updateStatusAfterResponse(sessionId: response.sessionId, project: response.project, pid: response.pid)

            // Delete the local prompt file since it's been processed
            deletePromptFile(sessionId: response.sessionId)
        } else {
            print("[ResponseHandler] ❌ Failed to send response to Terminal")
            print("[ResponseHandler] 💡 TIP: Grant VibeStatus automation permission in System Settings > Privacy & Security > Automation")
            print("[ResponseHandler] 💡 TIP: Enable 'VibeStatus → System Events' to allow automatic response forwarding")

            // Fallback: Write to response file for manual handling
            writeResponseToFile(response)

            // Show user notification about fallback
            showPermissionNotification()
        }
    }

    /// Send response text to Terminal window using AppleScript
    private func sendToTerminal(_ text: String, pid: Int?) -> Bool {
        // Escape the text for AppleScript
        let escapedText = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // AppleScript to type text in Terminal
        // We use 'keystroke' to simulate typing which will work with the active Claude session
        let script = """
        tell application "Terminal"
            activate
            delay 0.2
            tell application "System Events"
                keystroke "\(escapedText)"
                delay 0.1
                keystroke return
            end tell
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("[ResponseHandler] AppleScript error: \(error)")
                return false
            }

            return true
        }

        return false
    }

    /// Extracts the session ID from a status filename
    /// Example: "vibestatus-abc123.json" -> "abc123"
    private func extractSessionId(from filename: String) -> String {
        let prefix = "vibestatus-"
        let suffix = ".json"

        var result = filename
        if result.hasPrefix(prefix) {
            result = String(result.dropFirst(prefix.count))
        }
        if result.hasSuffix(suffix) {
            result = String(result.dropLast(suffix.count))
        }
        return result
    }

    /// Fallback: Write response to a file that can be manually copied
    private func writeResponseToFile(_ response: PromptRecord) {
        guard let responseText = response.responseText else { return }

        let responseFilePath = "/tmp/vibestatus-response-\(response.sessionId).txt"

        do {
            try responseText.write(toFile: responseFilePath, atomically: true, encoding: .utf8)
            print("[ResponseHandler] 📝 Wrote response to file: \(responseFilePath)")

            // Also copy to clipboard for convenience
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(responseText, forType: .string)
            print("[ResponseHandler] 📋 Copied response to clipboard")

            // Show notification
            showNotification(
                title: "Response Ready",
                body: "Your response is in clipboard. Paste it in Terminal."
            )

        } catch {
            print("[ResponseHandler] Failed to write response file: \(error)")
        }
    }

    /// Show a macOS notification
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }

    /// Shows notification about permission needed
    private func showPermissionNotification() {
        let notification = NSUserNotification()
        notification.title = "Permission Required"
        notification.informativeText = "Grant VibeStatus automation permission in System Settings to enable automatic response forwarding. Your response is in clipboard."
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.hasActionButton = true
        notification.actionButtonTitle = "Open Settings"

        NSUserNotificationCenter.default.deliver(notification)
    }

    /// Opens System Settings to the Automation privacy section
    private func openSystemSettingsAutomation() {
        // On macOS 13+ (Ventura), use the new Settings app
        // On macOS 12 and earlier, use System Preferences
        if #available(macOS 13, *) {
            // Modern approach for macOS Ventura and later
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
            NSWorkspace.shared.open(url)
        } else {
            // Legacy approach for macOS Monterey and earlier
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
            NSWorkspace.shared.open(url)
        }

        print("[ResponseHandler] 🔓 Opened System Settings > Privacy & Security > Automation")
    }

    /// Updates the status file after successfully sending a response
    /// This changes the status from "needs_input" back to "working"
    private func updateStatusAfterResponse(sessionId: String, project: String, pid: Int?) {
        let statusFile = "/tmp/vibestatus-\(sessionId).json"

        // Create status JSON for "working" state
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let pidValue = pid ?? 0

        let statusJSON = """
        {"state":"working","project":"\(project)","timestamp":"\(timestamp)","pid":\(pidValue)}
        """

        do {
            try statusJSON.write(toFile: statusFile, atomically: true, encoding: .utf8)
            print("[ResponseHandler] 📝 Updated status file to 'working': \(statusFile)")
        } catch {
            print("[ResponseHandler] ⚠️  Failed to update status file: \(error)")
        }
    }

    /// Deletes the local prompt file after it's been processed
    private func deletePromptFile(sessionId: String) {
        let promptFile = "/tmp/vibestatus-prompt-\(sessionId).json"

        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: promptFile) {
                try fileManager.removeItem(atPath: promptFile)
                print("[ResponseHandler] 🗑️  Deleted local prompt file: \(promptFile)")
            }
        } catch {
            print("[ResponseHandler] ⚠️  Failed to delete prompt file: \(error)")
        }
    }
}
