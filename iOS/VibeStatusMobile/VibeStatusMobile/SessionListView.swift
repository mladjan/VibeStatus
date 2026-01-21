// SessionListView.swift
// VibeStatusMobile
//
// Main view displaying active Claude Code sessions with terminal aesthetic

import SwiftUI
import Combine
import VibeStatusShared

struct SessionListView: View {
    @StateObject private var viewModel = CloudKitViewModel()
    @State private var showingSettings = false
    @State private var selectedPrompt: PromptRecord?

    var body: some View {
        NavigationView {
            ZStack {
                Color.terminalBackground
                    .ignoresSafeArea()

                Group {
                    if !viewModel.sessions.isEmpty {
                        // Always show list when sessions exist (even during loading/errors)
                        SessionsListContent(viewModel: viewModel, selectedPrompt: $selectedPrompt)
                    } else if viewModel.isLoading {
                        LoadingView()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            Task {
                                await viewModel.refreshSessions()
                            }
                        }
                    } else {
                        EmptyStateView()
                    }
                }
            }
            .navigationTitle("VibeStatus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.terminalOrange)
                    }
                }
            }
            .toolbarBackground(Color.terminalBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .refreshable {
                await viewModel.refreshSessions()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(item: $selectedPrompt) { prompt in
                PromptInputView(prompt: prompt)
            }
            .task {
                await viewModel.refreshSessions()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sessions List Content

private struct SessionsListContent: View {
    @ObservedObject var viewModel: CloudKitViewModel
    @Binding var selectedPrompt: PromptRecord?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Sessions
                ForEach(viewModel.sessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture {
                            // If session needs input, find and show the prompt
                            if session.status == .needsInput {
                                // Extract session ID from filename (e.g., "vibestatus-abc123.json" -> "abc123")
                                let sessionId = extractSessionId(from: session.id)
                                print("[SessionListView] Tapped session with needsInput status")
                                print("[SessionListView] Session ID (from filename): \(session.id) -> \(sessionId)")
                                print("[SessionListView] Looking for prompt with sessionId: \(sessionId)")
                                print("[SessionListView] Available prompts: \(viewModel.pendingPrompts.map { $0.sessionId })")

                                if let prompt = viewModel.pendingPrompts.first(where: { $0.sessionId == sessionId }) {
                                    print("[SessionListView] ✅ Found matching prompt, showing modal")
                                    selectedPrompt = prompt
                                } else {
                                    print("[SessionListView] ❌ No matching prompt found")
                                }
                            }
                        }
                }

                // Loading / Sync Status Footer
                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .terminalOrange))
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                }

                // Error message if any
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.terminalCaption)
                        Text(error)
                            .font(.terminalCaption)
                    }
                    .foregroundColor(.terminalRed)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color.terminalBackground)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: VibeStatusShared.SessionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Status indicator dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                // Project name
                Text(session.project)
                    .font(.terminalHeadline)
                    .foregroundColor(.terminalText)

                Spacer()

                // Status text
                Text(statusText)
                    .font(.terminalCaption)
                    .foregroundColor(.terminalSecondary)
            }
            .padding(.bottom, 8)

            // Description/status message
            Text(statusDescription)
                .font(.terminalBody)
                .foregroundColor(.terminalSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    private var statusText: String {
        switch session.status {
        case .working: return "Working"
        case .idle: return "Ready"
        case .needsInput: return "Needs Input"
        case .notRunning: return "Stopped"
        }
    }

    private var statusDescription: String {
        switch session.status {
        case .working: return "Claude is working on your request..."
        case .idle: return "Session is ready for input"
        case .needsInput: return "Waiting for your response"
        case .notRunning: return "Session has ended"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .working: return .statusOrange
        case .idle: return .statusGreen
        case .needsInput: return .statusBlue
        case .notRunning: return .statusGray
        }
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .terminalOrange))
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.terminalBody)
                .foregroundColor(.terminalSecondary)
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.terminalRed)

            Text(message)
                .font(.terminalBody)
                .foregroundColor(.terminalSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: retry) {
                Text("Retry")
                    .font(.terminalHeadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.terminalOrange)
                    .cornerRadius(8)
            }
        }
        .padding(32)
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "desktopcomputer")
                .font(.system(size: 64))
                .foregroundColor(.terminalOrange)

            VStack(spacing: 12) {
                Text("No Active Sessions")
                    .font(.terminalTitle)
                    .foregroundColor(.terminalText)

                Text("Start Claude Code on your Mac to see sessions here")
                    .font(.terminalBody)
                    .foregroundColor(.terminalSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                InfoRow(icon: "icloud.fill", text: "Enable iOS sync in the macOS menu bar app")
                InfoRow(icon: "person.circle.fill", text: "Sign into iCloud on both devices")
                InfoRow(icon: "terminal.fill", text: "Run Claude Code to start a session")
            }
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.terminalBackground)
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.terminalOrange)
                .frame(width: 24)

            Text(text)
                .font(.terminalCaption)
                .foregroundColor(.terminalSecondary)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    SessionListView()
}
