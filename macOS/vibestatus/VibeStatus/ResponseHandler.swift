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
final class ResponseHandler: ObservableObject {
    static let shared = ResponseHandler()

    // MARK: - Properties

    private var pollingTask: Task<Void, Never>?
    private var processedPromptIds: Set<String> = []

    /// How often to check for responses (2 seconds)
    private let pollingInterval: TimeInterval = 2.0

    // MARK: - Initialization

    private init() {}

    deinit {
        stop()
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

    // MARK: - Private Methods

    /// Check CloudKit for new responses and process them
    private func checkForResponses() async {
        // Get all active sessions to check for their responses
        let sessions = StatusManager.shared.sessions

        for session in sessions {
            // Fetch responses for this session
            let responses = await CloudKitManager.shared.fetchResponses(forSessionId: session.id)

            for response in responses {
                // Skip if already processed
                guard !processedPromptIds.contains(response.id) else { continue }

                // Process the response
                await processResponse(response)

                // Mark as processed
                processedPromptIds.insert(response.id)

                // Clean up from CloudKit after processing
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
        } else {
            print("[ResponseHandler] ❌ Failed to send response to Terminal")

            // Fallback: Write to response file for manual handling
            writeResponseToFile(response)
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
}
