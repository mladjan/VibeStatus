// SettingsView.swift
// VibeStatusMobile
//
// iOS settings screen

import SwiftUI
import VibeStatusShared

struct SettingsView: View {
    @StateObject private var viewModel = CloudKitViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // iCloud Status Section
                Section {
                    HStack {
                        Image(systemName: viewModel.iCloudAvailable ? "checkmark.icloud.fill" : "xmark.icloud.fill")
                            .foregroundColor(viewModel.iCloudAvailable ? .green : .red)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud")
                                .font(.headline)
                            Text(viewModel.iCloudAvailable ? "Connected" : "Not Connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if !viewModel.iCloudAvailable {
                        Text("Sign in to iCloud in Settings to sync with your Mac.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } header: {
                    Text("Sync Status")
                }

                // Notifications Section
                Section {
                    HStack {
                        Image(systemName: notificationStatusIcon)
                            .foregroundColor(notificationStatusColor)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                                .font(.headline)
                            Text(notificationStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if notificationManager.authorizationStatus == .notDetermined {
                        Button("Enable Notifications") {
                            Task {
                                try? await notificationManager.requestAuthorization()
                            }
                        }
                    } else if notificationManager.authorizationStatus == .denied {
                        Text("Enable notifications in Settings to get alerts when Claude needs input.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://vibestatus.com")!) {
                        HStack {
                            Text("Website")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                }

                // Debug Section
                #if DEBUG
                Section {
                    Button("Clear All Notifications") {
                        notificationManager.clearAllNotifications()
                    }

                    Button("Test Notification") {
                        Task {
                            await notificationManager.showSessionNotification(
                                project: "Test Project",
                                status: .needsInput,
                                sessionId: "test-session"
                            )
                        }
                    }

                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(formatDate(lastSync))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var notificationStatusIcon: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .provisional:
            return "checkmark.circle"
        case .ephemeral:
            return "clock.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional:
            return .yellow
        case .ephemeral:
            return .blue
        @unknown default:
            return .gray
        }
    }

    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Configured"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Temporary"
        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
