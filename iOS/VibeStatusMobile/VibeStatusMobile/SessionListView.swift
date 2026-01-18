// SessionListView.swift
// VibeStatusMobile
//
// Main view displaying active Claude Code sessions

import SwiftUI
import VibeStatusShared

struct SessionListView: View {
    @StateObject private var viewModel = CloudKitViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    LoadingView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.refreshSessions()
                        }
                    }
                } else if viewModel.sessions.isEmpty {
                    EmptyStateView()
                } else {
                    SessionsListContent(viewModel: viewModel)
                }
            }
            .navigationTitle("Claude Code")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshSessions()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await viewModel.refreshSessions()
            }
        }
    }
}

// MARK: - Sessions List Content

private struct SessionsListContent: View {
    @ObservedObject var viewModel: CloudKitViewModel

    var body: some View {
        List {
            ForEach(Array(viewModel.sessionsByDevice.keys.sorted()), id: \.self) { deviceName in
                Section(header: Text(deviceName)) {
                    if let sessions = viewModel.sessionsByDevice[deviceName] {
                        ForEach(sessions) { session in
                            SessionRowView(session: session)
                        }
                    }
                }
            }

            if let lastSync = viewModel.lastSyncDate {
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Last updated \(formatRelativeTime(lastSync))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: VibeStatusShared.SessionInfo

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(session.statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(session.statusColor.opacity(0.3), lineWidth: 4)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.project)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(session.statusEmoji)
                        .font(.caption)
                    Text(session.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formatTimestamp(session.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status badge for needs input
            if session.status == .needsInput {
                Text("ACTION NEEDED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading sessions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: retry) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Active Sessions")
                .font(.headline)

            Text("Start Claude Code on your Mac to see sessions here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("Enable iOS Sync in the macOS app")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("Make sure you're signed into iCloud")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("Run Claude Code on your Mac")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    SessionListView()
}
