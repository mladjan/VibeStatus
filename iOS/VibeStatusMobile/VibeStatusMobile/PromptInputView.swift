// PromptInputView.swift
// VibeStatusMobile
//
// Full-screen modal for responding to Claude Code input prompts
// Shows conversation context and allows user to send response back to macOS

import SwiftUI
import Combine
import VibeStatusShared

struct PromptInputView: View {
    let prompt: PromptRecord
    @StateObject private var viewModel: PromptViewModel
    @Environment(\.dismiss) private var dismiss

    init(prompt: PromptRecord) {
        self.prompt = prompt
        _viewModel = StateObject(wrappedValue: PromptViewModel(prompt: prompt))

        // Debug: Print prompt data
        print("[PromptInputView] Showing prompt:")
        print("  Project: \(prompt.project)")
        print("  Message: \(prompt.promptMessage)")
        print("  Transcript excerpt length: \(prompt.transcriptExcerpt?.count ?? 0)")
        print("  Notification type: \(prompt.notificationType)")
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.terminalBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Project header
                        ProjectHeader(project: prompt.project)

                        // Transcript context (if available)
                        if let excerpt = prompt.transcriptExcerpt, !excerpt.isEmpty {
                            TranscriptSection(excerpt: excerpt)
                        }

                        // Main prompt question
                        PromptQuestion(message: prompt.promptMessage)

                        // Response input area
                        ResponseInputSection(viewModel: viewModel)

                        // Submit button
                        SubmitButton(viewModel: viewModel) {
                            Task {
                                let success = await viewModel.submitResponse()
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.terminalCaption)
                    .foregroundColor(.terminalGreen)
                }

                ToolbarItem(placement: .principal) {
                    Text("input required")
                        .font(.terminalHeadline)
                        .foregroundColor(.terminalOrange)
                }
            }
            .toolbarBackground(Color.terminalBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Subviews

private struct ProjectHeader: View {
    let project: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("> \(project)")
                .font(.terminalHeadline)
                .foregroundColor(.terminalGreen)

            Text("claude needs your input")
                .font(.terminalCaption)
                .foregroundColor(.terminalGreenDim)
        }
        .padding(.bottom, 8)
    }
}

private struct TranscriptSection: View {
    let excerpt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("recent context:")
                .font(.terminalCaption)
                .foregroundColor(.terminalGreenDim)

            Text(cleanExcerpt)
                .font(.terminalBody)
                .foregroundColor(.terminalText)
                .padding(12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
        }
    }

    private var cleanExcerpt: String {
        // Parse JSONL to extract last assistant message
        let lines = excerpt.split(separator: "\n")
        var lastAssistantMessage = ""

        // Find last assistant message in JSONL
        for line in lines.reversed() {
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String,
               type == "assistant",
               let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {

                // Extract text from content blocks
                for block in content {
                    if let text = block["text"] as? String {
                        lastAssistantMessage = text
                        break
                    }
                }

                if !lastAssistantMessage.isEmpty {
                    break
                }
            }
        }

        if !lastAssistantMessage.isEmpty {
            // Limit to reasonable length
            return String(lastAssistantMessage.prefix(500))
        }

        // Fallback: show raw but truncated
        return String(excerpt.prefix(300)) + "..."
    }
}

private struct PromptQuestion: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("prompt:")
                .font(.terminalCaption)
                .foregroundColor(.terminalOrange)

            Text(message)
                .font(.terminalBody)
                .foregroundColor(.terminalText)
                .padding(12)
                .background(Color.terminalOrange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.terminalOrange.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

private struct ResponseInputSection: View {
    @ObservedObject var viewModel: PromptViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("your response:")
                .font(.terminalCaption)
                .foregroundColor(.terminalGreen)

            // Show parsed options as buttons if available
            if !viewModel.parsedOptions.isEmpty {
                OptionsButtons(options: viewModel.parsedOptions, selection: $viewModel.responseText)
            }

            // Text input (always available as fallback)
            TextField("type your response...", text: $viewModel.responseText, axis: .vertical)
                .font(.terminalBody)
                .foregroundColor(.terminalText)
                .padding(12)
                .background(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.terminalGreen.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
                .lineLimit(5...10)
        }
    }
}

private struct OptionsButtons: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    HStack {
                        Text(option)
                            .font(.terminalBody)
                        Spacer()
                        if selection == option {
                            Text("✓")
                                .font(.terminalBody)
                        }
                    }
                    .foregroundColor(selection == option ? .terminalBackground : .terminalGreen)
                    .padding(12)
                    .background(selection == option ? Color.terminalGreen : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.terminalGreen, lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
            }
        }
    }
}

private struct SubmitButton: View {
    @ObservedObject var viewModel: PromptViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .terminalBackground))
                } else {
                    Text("send response →")
                        .font(.terminalHeadline)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.terminalBackground)
            .padding()
            .background(viewModel.canSubmit ? Color.terminalGreen : Color.gray)
            .cornerRadius(8)
        }
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }
}

// MARK: - ViewModel

@MainActor
class PromptViewModel: ObservableObject {
    let prompt: PromptRecord

    @Published var responseText: String = ""
    @Published var isSubmitting: Bool = false
    @Published var parsedOptions: [String] = []

    var canSubmit: Bool {
        !responseText.isEmpty && !isSubmitting
    }

    init(prompt: PromptRecord) {
        self.prompt = prompt
        self.parsedOptions = Self.parseOptions(from: prompt.promptMessage)
    }

    func submitResponse() async -> Bool {
        guard canSubmit else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let deviceName = UIDevice.current.name
        let success = await CloudKitManager.shared.submitResponse(
            promptId: prompt.id,
            responseText: responseText,
            deviceName: deviceName
        )

        return success
    }

    /// Parse options from prompt message
    /// Detects patterns like:
    /// - "1) Option A\n2) Option B"
    /// - "- Option A\n- Option B"
    /// - "[y/n]", "[yes/no]"
    static func parseOptions(from message: String) -> [String] {
        var options: [String] = []

        // Check for [y/n] or [yes/no] pattern
        if message.lowercased().contains("[y/n]") {
            return ["y", "n"]
        }
        if message.lowercased().contains("[yes/no]") {
            return ["yes", "no"]
        }

        // Check for numbered list: "1) Option" or "1. Option"
        let numberedPattern = #/(\d+)[\.)]\s+([^\n]+)/#
        let numberedMatches = message.matches(of: numberedPattern)
        if !numberedMatches.isEmpty {
            options = numberedMatches.map { String($0.2) }
            if options.count >= 2 {
                return options
            }
        }

        // Check for bulleted list: "- Option" or "* Option"
        let bulletPattern = #/^[\-\*]\s+([^\n]+)/#
        let lines = message.split(separator: "\n")
        let bulletOptions = lines.compactMap { line in
            if let match = String(line).firstMatch(of: bulletPattern) {
                return String(match.1)
            }
            return nil
        }
        if bulletOptions.count >= 2 {
            return bulletOptions
        }

        return []
    }
}
