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
                        SessionsListContent(viewModel: viewModel, selectedPrompt: $selectedPrompt)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("vibestatus")
                        .font(.terminalHeadline)
                        .foregroundColor(.terminalGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Text("settings")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
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
            .onChange(of: viewModel.pendingPrompts) { prompts in
                // Auto-show prompt input when new prompt arrives
                if let firstPrompt = prompts.first, selectedPrompt == nil {
                    selectedPrompt = firstPrompt
                }
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
            LazyVStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("vibestatus")
                        .font(.terminalLargeTitle)
                        .foregroundColor(.terminalGreen)

                    Text("claude code session monitor")
                        .font(.terminalCaption)
                        .foregroundColor(.terminalSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

                // Active Sessions Section
                TerminalSectionHeader(title: "active sessions")
                    .padding(.horizontal, 20)

                ForEach(viewModel.sessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture {
                            // If session needs input, find and show the prompt
                            if session.status == .needsInput,
                               let prompt = viewModel.pendingPrompts.first(where: { $0.sessionId == session.id }) {
                                selectedPrompt = prompt
                            }
                        }

                    TerminalDivider()
                        .padding(.horizontal, 20)
                }

                // Last Sync Section
                if let lastSync = viewModel.lastSyncDate {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.terminalCaption)
                        Text("synced \(formatRelativeTime(lastSync))")
                            .font(.terminalCaption)
                    }
                    .foregroundColor(.terminalSecondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.terminalBackground)
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
        HStack(alignment: .top, spacing: 16) {
            // Status indicator
            Text(statusSymbol)
                .font(.terminalBody)
                .foregroundColor(statusColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 6) {
                // Project name
                Text(session.project.lowercased())
                    .font(.terminalHeadline)
                    .foregroundColor(.terminalGreen)

                // Status line
                HStack(spacing: 8) {
                    Text(session.status.displayName.lowercased())
                        .font(.terminalCaption)
                        .foregroundColor(statusColor)

                    Text("•")
                        .foregroundColor(.terminalSecondary)

                    Text(formatTimestamp(session.timestamp))
                        .font(.terminalCaption)
                        .foregroundColor(.terminalSecondary)
                }

                // Action needed badge
                if session.status == .needsInput {
                    Text("[ input required ]")
                        .font(.terminalCaption)
                        .foregroundColor(.terminalBlue)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.terminalBackground)
    }

    private var statusSymbol: String {
        switch session.status {
        case .working: return ">"
        case .idle: return "*"
        case .needsInput: return "?"
        case .notRunning: return "-"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .working: return .terminalOrange
        case .idle: return .terminalGreen
        case .needsInput: return .terminalBlue
        case .notRunning: return .terminalSecondary
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    @State private var dots = ""
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("loading\(dots)")
                .font(.terminalBody)
                .foregroundColor(.terminalGreen)
                .onReceive(timer) { _ in
                    if dots.count >= 3 {
                        dots = ""
                    } else {
                        dots += "."
                    }
                }
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("!")
                    .font(.terminalTitle)
                    .foregroundColor(.terminalRed)

                Text("error")
                    .font(.terminalHeadline)
                    .foregroundColor(.terminalRed)
            }

            Text(message.lowercased())
                .font(.terminalCaption)
                .foregroundColor(.terminalSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: retry) {
                Text("[ retry ]")
                    .font(.terminalBody)
                    .foregroundColor(.terminalGreen)
            }
            .padding(.top, 8)
        }
        .padding(24)
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("vibestatus")
                        .font(.terminalLargeTitle)
                        .foregroundColor(.terminalGreen)

                    Text("claude code session monitor")
                        .font(.terminalCaption)
                        .foregroundColor(.terminalSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

                TerminalSectionHeader(title: "no active sessions")
                    .padding(.horizontal, 20)

                Text("start claude code on your mac to see sessions here.")
                    .font(.terminalCaption)
                    .foregroundColor(.terminalSecondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                TerminalSectionHeader(title: "setup")
                    .padding(.horizontal, 20)

                TerminalRow(
                    icon: { Image(systemName: "icloud") },
                    title: "icloud sync",
                    subtitle: "enable ios sync in the macos menu bar app"
                )
                .padding(.horizontal, 20)

                TerminalDivider()
                    .padding(.horizontal, 20)

                TerminalRow(
                    icon: { Image(systemName: "person.circle") },
                    title: "icloud account",
                    subtitle: "sign into icloud on both devices"
                )
                .padding(.horizontal, 20)

                TerminalDivider()
                    .padding(.horizontal, 20)

                TerminalRow(
                    icon: { Image(systemName: "terminal") },
                    title: "run claude code",
                    subtitle: "start a session on your mac"
                )
                .padding(.horizontal, 20)

                TerminalSectionHeader(title: "features")
                    .padding(.horizontal, 20)

                TerminalRow(
                    icon: { Image(systemName: "bell") },
                    title: "notifications",
                    subtitle: "get notified when claude needs input"
                )
                .padding(.horizontal, 20)

                TerminalDivider()
                    .padding(.horizontal, 20)

                TerminalRow(
                    icon: { Image(systemName: "arrow.triangle.2.circlepath") },
                    title: "real-time sync",
                    subtitle: "sessions sync via icloud automatically"
                )
                .padding(.horizontal, 20)

                TerminalDivider()
                    .padding(.horizontal, 20)

                TerminalRow(
                    icon: { Image(systemName: "lock.shield") },
                    title: "privacy",
                    subtitle: "data stays in your private icloud"
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .background(Color.terminalBackground)
    }
}

// MARK: - Preview

#Preview {
    SessionListView()
}
