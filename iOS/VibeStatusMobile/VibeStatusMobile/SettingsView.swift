// SettingsView.swift
// VibeStatusMobile
//
// iOS settings screen with terminal aesthetic

import SwiftUI
import VibeStatusShared

struct SettingsView: View {
    @StateObject private var viewModel = CloudKitViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.terminalBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings")
                                .font(.terminalLargeTitle)
                                .foregroundColor(.terminalGreen)

                            Text("configure vibestatus")
                                .font(.terminalCaption)
                                .foregroundColor(.terminalSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                        // Sync Status Section
                        TerminalSectionHeader(title: "sync status")
                            .padding(.horizontal, 20)

                        TerminalRow(
                            icon: {
                                Image(systemName: viewModel.iCloudAvailable ? "checkmark.icloud" : "xmark.icloud")
                                    .foregroundColor(viewModel.iCloudAvailable ? .terminalGreen : .terminalRed)
                            },
                            title: "icloud",
                            subtitle: viewModel.iCloudAvailable ? "connected" : "not connected"
                        )
                        .padding(.horizontal, 20)

                        if !viewModel.iCloudAvailable {
                            Text("sign in to icloud in settings to sync with your mac.")
                                .font(.terminalCaption)
                                .foregroundColor(.terminalSecondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            Button(action: openSettings) {
                                Text("[ open settings ]")
                                    .font(.terminalBody)
                                    .foregroundColor(.terminalGreen)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        TerminalDivider()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Notifications Section
                        TerminalSectionHeader(title: "notifications")
                            .padding(.horizontal, 20)

                        TerminalRow(
                            icon: {
                                Image(systemName: notificationStatusIcon)
                                    .foregroundColor(notificationStatusColor)
                            },
                            title: "push notifications",
                            subtitle: notificationStatusText.lowercased()
                        )
                        .padding(.horizontal, 20)

                        if notificationManager.authorizationStatus == .notDetermined {
                            Button(action: {
                                Task {
                                    try? await notificationManager.requestAuthorization()
                                }
                            }) {
                                Text("[ enable notifications ]")
                                    .font(.terminalBody)
                                    .foregroundColor(.terminalGreen)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        } else if notificationManager.authorizationStatus == .denied {
                            Text("enable notifications in settings to get alerts when claude needs input.")
                                .font(.terminalCaption)
                                .foregroundColor(.terminalSecondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            Button(action: openSettings) {
                                Text("[ open settings ]")
                                    .font(.terminalBody)
                                    .foregroundColor(.terminalGreen)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        TerminalDivider()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // About Section
                        TerminalSectionHeader(title: "about")
                            .padding(.horizontal, 20)

                        HStack {
                            Text("version")
                                .font(.terminalBody)
                                .foregroundColor(.terminalGreen)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .font(.terminalCaption)
                                .foregroundColor(.terminalSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        TerminalDivider()
                            .padding(.horizontal, 20)

                        HStack {
                            Text("build")
                                .font(.terminalBody)
                                .foregroundColor(.terminalGreen)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                                .font(.terminalCaption)
                                .foregroundColor(.terminalSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        TerminalDivider()
                            .padding(.horizontal, 20)

                        Link(destination: URL(string: "https://vibestatus.com")!) {
                            HStack {
                                Text("website")
                                    .font(.terminalBody)
                                    .foregroundColor(.terminalGreen)
                                Spacer()
                                Text("->")
                                    .font(.terminalCaption)
                                    .foregroundColor(.terminalSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        // Debug Section
                        #if DEBUG
                        TerminalDivider()
                            .padding(.horizontal, 20)

                        TerminalSectionHeader(title: "debug")
                            .padding(.horizontal, 20)

                        Button(action: {
                            notificationManager.clearAllNotifications()
                        }) {
                            Text("[ clear all notifications ]")
                                .font(.terminalBody)
                                .foregroundColor(.terminalGreen)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        Button(action: {
                            Task {
                                await notificationManager.showSessionNotification(
                                    project: "test-project",
                                    status: .needsInput,
                                    sessionId: "test-session"
                                )
                            }
                        }) {
                            Text("[ test notification ]")
                                .font(.terminalBody)
                                .foregroundColor(.terminalGreen)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        if let lastSync = viewModel.lastSyncDate {
                            HStack {
                                Text("last sync")
                                    .font(.terminalBody)
                                    .foregroundColor(.terminalGreen)
                                Spacer()
                                Text(formatDate(lastSync))
                                    .font(.terminalCaption)
                                    .foregroundColor(.terminalSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                        #endif

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("settings")
                        .font(.terminalHeadline)
                        .foregroundColor(.terminalGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("done")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
                    }
                }
            }
            .toolbarBackground(Color.terminalBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helper Methods

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var notificationStatusIcon: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "checkmark.circle"
        case .denied:
            return "xmark.circle"
        case .notDetermined:
            return "questionmark.circle"
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
            return .terminalGreen
        case .denied:
            return .terminalRed
        case .notDetermined:
            return .terminalOrange
        case .provisional:
            return .terminalGreen
        case .ephemeral:
            return .terminalBlue
        @unknown default:
            return .terminalSecondary
        }
    }

    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "enabled"
        case .denied:
            return "disabled"
        case .notDetermined:
            return "not configured"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "temporary"
        @unknown default:
            return "unknown"
        }
    }

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
