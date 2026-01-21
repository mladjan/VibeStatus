// SettingsView.swift
// VibeStatusMobile
//
// iOS settings screen with terminal aesthetic

import SwiftUI
import VibeStatusShared

struct SettingsView: View {
    @StateObject private var viewModel = CloudKitViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var proximityDetector = ProximityDetector.shared
    @Environment(\.dismiss) private var dismiss
    @State private var silenceWhenNearby: Bool = NotificationManager.shared.silenceWhenNearby
    @State private var isTestingProximity: Bool = false

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

                        // Proximity-based silencing toggle
                        if notificationManager.authorizationStatus == .authorized {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: Binding(
                                    get: { silenceWhenNearby },
                                    set: { newValue in
                                        silenceWhenNearby = newValue
                                        notificationManager.silenceWhenNearby = newValue
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Silence When Near Mac")
                                            .font(.terminalBody)
                                            .foregroundColor(.terminalText)
                                        Text("Automatically silence notifications when your iPhone detects your Mac on the same network")
                                            .font(.terminalCaption)
                                            .foregroundColor(.terminalSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .terminalOrange))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)

                                if silenceWhenNearby {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.terminalBlue)
                                            .font(.caption)
                                        Text("Works across multiple WiFi networks in the same location using Bonjour discovery")
                                            .font(.terminalCaption)
                                            .foregroundColor(.terminalSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 8)

                                    // Mac Detection Status
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Mac Detection Status")
                                            .font(.terminalSection)
                                            .foregroundColor(.terminalText)

                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(proximityDetector.isMacNearby ? Color.statusGreen : Color.terminalSecondary)
                                                .frame(width: 12, height: 12)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(proximityDetector.isMacNearby ? "Mac Detected" : "Mac Not Detected")
                                                    .font(.terminalBody)
                                                    .foregroundColor(.terminalText)

                                                if let lastDetection = proximityDetector.lastDetectionDate {
                                                    Text("Last detected: \(formatRelativeTime(lastDetection))")
                                                        .font(.terminalCaption)
                                                        .foregroundColor(.terminalSecondary)
                                                }

                                                if proximityDetector.servicesFound > 0 {
                                                    Text("\(proximityDetector.servicesFound) service(s) found")
                                                        .font(.terminalCaption)
                                                        .foregroundColor(.terminalSecondary)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color.cardBackground)
                                        .cornerRadius(8)

                                        Button(action: {
                                            Task {
                                                isTestingProximity = true
                                                _ = await proximityDetector.checkMacProximity()
                                                isTestingProximity = false
                                            }
                                        }) {
                                            HStack {
                                                if isTestingProximity {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                        .scaleEffect(0.8)
                                                } else {
                                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                                }
                                                Text(isTestingProximity ? "Searching..." : "Test Mac Detection")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(12)
                                            .background(Color.terminalOrange)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                        }
                                        .disabled(isTestingProximity)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 8)
                                }
                            }

                            TerminalDivider()
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }

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

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
