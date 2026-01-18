//
//  VibeStatusMobileApp.swift
//  VibeStatusMobile
//
//  Created by Mladjan Antic on 18/1/26.
//

import SwiftUI
import VibeStatusShared
import CloudKit

@main
struct VibeStatusMobileApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SessionListView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request notification permissions on first launch
        Task {
            try? await NotificationManager.shared.requestAuthorization()
        }

        // Setup CloudKit subscription for push notifications
        Task {
            await CloudKitManager.shared.setupSubscription()
        }

        return true
    }

    // Called when APNs registration succeeds
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[AppDelegate] Registered for remote notifications with token: \(token)")
    }

    // Called when APNs registration fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
    }

    // Called when a remote notification is received
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("[AppDelegate] Received remote notification: \(userInfo)")

        // CloudKit notification - trigger a sync and show notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            print("[AppDelegate] CloudKit notification received: \(notification)")

            // Fetch the updated session and show notification
            Task {
                // Fetch the updated session from CloudKit
                if let recordID = notification.recordID {
                    print("[AppDelegate] Fetching updated record: \(recordID.recordName)")

                    do {
                        let container = CKContainer(identifier: "iCloud.com.mladjan.vibestatus")
                        let database = container.privateCloudDatabase
                        let record = try await database.record(for: recordID)

                        if let sessionId = record["sessionId"] as? String,
                           let statusString = record["status"] as? String,
                           let status = VibeStatusShared.VibeStatus(rawValue: statusString),
                           let project = record["project"] as? String {

                            print("[AppDelegate] Session updated: \(sessionId), status: \(statusString)")

                            // Show notification for status changes
                            await NotificationManager.shared.showSessionNotification(
                                project: project,
                                status: status,
                                sessionId: sessionId
                            )
                        }

                        completionHandler(.newData)
                    } catch {
                        print("[AppDelegate] Failed to fetch record: \(error)")
                        completionHandler(.failed)
                    }
                } else {
                    completionHandler(.newData)
                }
            }
        } else {
            completionHandler(.noData)
        }
    }
}
