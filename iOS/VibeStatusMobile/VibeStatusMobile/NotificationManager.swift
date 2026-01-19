// NotificationManager.swift
// VibeStatusMobile
//
// Manages push notifications for iOS

import Foundation
@preconcurrency import UserNotifications
import UIKit
import Combine
import VibeStatusShared

/// Manages push notification registration and handling
@MainActor
class NotificationManager: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Published Properties

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isRegistered = false

    // MARK: - Private Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private override init() {
        super.init()
        notificationCenter.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Requests notification permission from user
    func requestAuthorization() async throws {
        let granted = try await notificationCenter.requestAuthorization(
            options: [.alert, .sound, .badge]
        )

        if granted {
            await registerForRemoteNotifications()
        }

        await checkAuthorizationStatus()
    }

    /// Checks current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            isRegistered = settings.authorizationStatus == .authorized
        }
    }

    /// Registers for remote notifications (APNs)
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Notification Display

    /// Shows a local notification for a session status change
    func showSessionNotification(
        project: String,
        status: VibeStatusShared.VibeStatus,
        sessionId: String
    ) async {
        let content = UNMutableNotificationContent()

        switch status {
        case .idle:
            content.title = "✅ Ready"
            content.body = "\(project) has finished and is ready"
            content.sound = .default
        case .needsInput:
            content.title = "❓ Input Needed"
            content.body = "\(project) needs your response to continue"
            content.sound = .defaultCritical
            content.interruptionLevel = .timeSensitive
        case .working:
            content.title = "⚙️ Working"
            content.body = "\(project) is processing"
            content.sound = nil
        case .notRunning:
            return // Don't notify for not running
        }

        content.categoryIdentifier = "SESSION_STATUS"
        content.userInfo = [
            "sessionId": sessionId,
            "project": project,
            "status": status.rawValue
        ]

        let request = UNNotificationRequest(
            identifier: "session-\(sessionId)-\(status.rawValue)",
            content: content,
            trigger: nil // Show immediately
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("[NotificationManager] Failed to show notification: \(error)")
        }
    }

    /// Shows a critical notification for a prompt that needs immediate user response
    func showPromptNotification(project: String, message: String) async {
        let content = UNMutableNotificationContent()

        content.title = "🔴 Claude Needs Input"
        content.body = "\(project): \(message.prefix(100))"
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        content.categoryIdentifier = "PROMPT_INPUT"

        let request = UNNotificationRequest(
            identifier: "prompt-\(UUID().uuidString)",
            content: content,
            trigger: nil // Show immediately
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("[NotificationManager] Failed to show prompt notification: \(error)")
        }
    }

    /// Clears all delivered notifications
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Clears notifications for a specific session
    func clearNotifications(for sessionId: String) async {
        let notifications = await notificationCenter.deliveredNotifications()
        let identifiers = notifications
            .filter { $0.request.content.userInfo["sessionId"] as? String == sessionId }
            .map { $0.request.identifier }

        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Called when notification is received while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user taps on a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let sessionId = userInfo["sessionId"] as? String {
            // TODO: Navigate to session detail view
            print("[NotificationManager] User tapped notification for session: \(sessionId)")
        }

        completionHandler()
    }
}
