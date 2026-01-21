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
        print("  Message (raw): \(prompt.promptMessage)")
        print("  Message length: \(prompt.promptMessage.count) chars")
        print("  Transcript excerpt length: \(prompt.transcriptExcerpt?.count ?? 0)")
        print("  Notification type: \(prompt.notificationType)")

        // Check if message looks like JSON
        if prompt.promptMessage.hasPrefix("{") || prompt.promptMessage.hasPrefix("[") {
            print("  ⚠️  Warning: Message appears to be JSON format")
        }
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
            .navigationTitle("Input Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 24))
                    .foregroundColor(.terminalOrange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project)
                        .font(.terminalHeadline)
                        .foregroundColor(.terminalText)

                    Text("Claude needs your input")
                        .font(.terminalCaption)
                        .foregroundColor(.terminalSecondary)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

private struct TranscriptSection: View {
    let excerpt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Context")
                .font(.terminalSection)
                .foregroundColor(.terminalText)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(formattedMessages, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        // Role indicator
                        Text(item.roleIndicator)
                            .font(.terminalCaption)
                            .foregroundColor(item.roleColor)

                        // Message content
                        Text(item.text)
                            .font(.terminalBody)
                            .foregroundColor(.terminalSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }

    private struct FormattedMessage: Identifiable {
        let id = UUID()
        let roleIndicator: String
        let roleColor: Color
        let text: String
    }

    private var formattedMessages: [FormattedMessage] {
        // Parse JSONL to extract recent messages (both user and assistant)
        let lines = excerpt.split(separator: "\n")
        var messages: [FormattedMessage] = []

        // Process last few messages (up to 3 for context)
        for line in lines.suffix(3) {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                continue
            }

            var messageText = ""
            var roleIndicator = ""
            var roleColor: Color = .terminalText

            if type == "user" {
                // Extract user message
                if let message = json["message"] as? [String: Any],
                   let content = message["content"] as? [[String: Any]] {
                    for block in content {
                        if block["type"] as? String == "text",
                           let text = block["text"] as? String {
                            messageText = text
                            break
                        }
                    }
                }
                roleIndicator = "user:"
                roleColor = .terminalBlue

            } else if type == "assistant" {
                // Extract assistant message
                if let message = json["message"] as? [String: Any],
                   let content = message["content"] as? [[String: Any]] {
                    for block in content {
                        if block["type"] as? String == "text",
                           let text = block["text"] as? String {
                            messageText = text
                            break
                        }
                    }
                }
                roleIndicator = "assistant:"
                roleColor = .terminalGreen
            }

            if !messageText.isEmpty {
                // Truncate very long messages
                let truncated = messageText.count > 300 ? String(messageText.prefix(300)) + "..." : messageText
                messages.append(FormattedMessage(
                    roleIndicator: roleIndicator,
                    roleColor: roleColor,
                    text: truncated
                ))
            }
        }

        // If no messages parsed, show a simple fallback
        if messages.isEmpty {
            messages.append(FormattedMessage(
                roleIndicator: "context:",
                roleColor: .terminalSecondary,
                text: String(excerpt.prefix(300))
            ))
        }

        return messages
    }
}

private struct PromptQuestion: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.terminalSection)
                .foregroundColor(.terminalText)

            Text(cleanedMessage)
                .font(.terminalBody)
                .foregroundColor(.terminalText)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.terminalOrange.opacity(0.5), lineWidth: 2)
                )
        }
    }

    /// Clean and format the prompt message for display
    private var cleanedMessage: String {
        var cleaned = message

        // Unescape common JSON escape sequences
        cleaned = cleaned.replacingOccurrences(of: "\\n", with: "\n")
        cleaned = cleaned.replacingOccurrences(of: "\\\"", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "\\t", with: "\t")
        cleaned = cleaned.replacingOccurrences(of: "\\/", with: "/")
        cleaned = cleaned.replacingOccurrences(of: "\\\\", with: "\\")

        // Remove any leading/trailing whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it looks like it might be JSON, try to extract the actual message
        if cleaned.hasPrefix("{") && cleaned.hasSuffix("}") {
            if let data = cleaned.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let extractedMessage = json["message"] as? String ?? json["text"] as? String {
                return extractedMessage
            }
        }

        return cleaned
    }
}

private struct ResponseInputSection: View {
    @ObservedObject var viewModel: PromptViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Response")
                .font(.terminalSection)
                .foregroundColor(.terminalText)

            // Show parsed options as buttons if available
            if !viewModel.parsedOptions.isEmpty {
                OptionsButtons(options: viewModel.parsedOptions, selection: $viewModel.responseText)
            }

            // Text input (always available as fallback)
            TextField("Type your response...", text: $viewModel.responseText, axis: .vertical)
                .font(.terminalBody)
                .foregroundColor(.terminalText)
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .lineLimit(3...8)
        }
    }
}

private struct OptionsButtons: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    HStack {
                        Text(option)
                            .font(.terminalBody)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                        }
                    }
                    .foregroundColor(selection == option ? .white : .terminalText)
                    .padding(16)
                    .background(selection == option ? Color.terminalOrange : Color.cardBackground)
                    .cornerRadius(12)
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
            HStack(spacing: 12) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Response")
                        .font(.terminalHeadline)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding()
            .background(viewModel.canSubmit ? Color.terminalOrange : Color.terminalSecondary)
            .cornerRadius(12)
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

        print("[PromptViewModel] Initialized with prompt:")
        print("  Prompt ID: \(prompt.id)")
        print("  Session ID: \(prompt.sessionId)")
        print("  Message: \(prompt.promptMessage)")
        print("  Parsed options: \(self.parsedOptions)")
    }

    func submitResponse() async -> Bool {
        guard canSubmit else {
            print("[PromptViewModel] ❌ Cannot submit - validation failed")
            return false
        }

        print("[PromptViewModel] 🚀 Starting response submission...")
        print("  Prompt ID: \(prompt.id)")
        print("  Session ID: \(prompt.sessionId)")
        print("  Response text: '\(responseText)'")

        isSubmitting = true
        defer { isSubmitting = false }

        let deviceName = UIDevice.current.name
        print("[PromptViewModel] Device name: \(deviceName)")

        let success = await CloudKitManager.shared.submitResponse(
            promptId: prompt.id,
            responseText: responseText,
            deviceName: deviceName
        )

        if success {
            print("[PromptViewModel] ✅ Response submitted successfully")
        } else {
            print("[PromptViewModel] ❌ Response submission failed")
        }

        return success
    }

    /// Parse options from prompt message
    /// Detects patterns like:
    /// - Permission requests: "needs your permission to use X"
    /// - "1) Option A\n2) Option B"
    /// - "- Option A\n- Option B"
    /// - "[y/n]", "[yes/no]"
    static func parseOptions(from message: String) -> [String] {
        var options: [String] = []

        print("[PromptViewModel] Parsing options from message:")
        print("  Message: \(message)")

        // Check for permission request - match Claude Code's exact format
        if message.lowercased().contains("permission") {
            print("[PromptViewModel] Detected permission prompt, using: Yes, No, Always")
            return ["Yes", "No", "Always"]
        }

        // Check for [y/n] pattern - match exact case
        if message.contains("[y/n]") {
            print("[PromptViewModel] Detected [y/n] prompt")
            return ["y", "n"]
        }

        // Check for [Y/n] pattern (common in CLI)
        if message.contains("[Y/n]") {
            print("[PromptViewModel] Detected [Y/n] prompt")
            return ["Y", "n"]
        }

        // Check for [yes/no] pattern
        if message.lowercased().contains("[yes/no]") {
            print("[PromptViewModel] Detected [yes/no] prompt")
            return ["yes", "no"]
        }

        // Check for numbered list: "1) Option" or "1. Option"
        let numberedPattern = #/(\d+)[\.)]\s+([^\n]+)/#
        let numberedMatches = message.matches(of: numberedPattern)
        if !numberedMatches.isEmpty {
            options = numberedMatches.map { String($0.2).trimmingCharacters(in: .whitespaces) }
            if options.count >= 2 {
                print("[PromptViewModel] Detected numbered list: \(options)")
                return options
            }
        }

        // Check for bulleted list: "- Option" or "* Option"
        let bulletPattern = #/^[\-\*]\s+([^\n]+)/#
        let lines = message.split(separator: "\n")
        let bulletOptions = lines.compactMap { line in
            if let match = String(line).firstMatch(of: bulletPattern) {
                return String(match.1).trimmingCharacters(in: .whitespaces)
            }
            return nil
        }
        if bulletOptions.count >= 2 {
            print("[PromptViewModel] Detected bulleted list: \(bulletOptions)")
            return bulletOptions
        }

        print("[PromptViewModel] No options pattern detected")
        return []
    }
}
