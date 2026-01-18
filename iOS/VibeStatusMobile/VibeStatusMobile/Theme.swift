// Theme.swift
// VibeStatusMobile
//
// Terminal-style theme for the app

import SwiftUI

// MARK: - Terminal Colors

extension Color {
    /// Terminal green - primary accent color
    static let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.2)

    /// Dimmed green for secondary elements
    static let terminalGreenDim = Color(red: 0.0, green: 0.6, blue: 0.15)

    /// Terminal background - pure black
    static let terminalBackground = Color.black

    /// Terminal secondary text - gray
    static let terminalSecondary = Color(white: 0.5)

    /// Terminal red for errors/warnings
    static let terminalRed = Color(red: 1.0, green: 0.3, blue: 0.3)

    /// Terminal orange for working status
    static let terminalOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    /// Terminal blue for needs input
    static let terminalBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
}

// MARK: - Terminal Fonts

extension Font {
    /// Monospace font for body text
    static let terminalBody = Font.system(.body, design: .monospaced)

    /// Monospace font for headlines
    static let terminalHeadline = Font.system(.headline, design: .monospaced)

    /// Monospace font for titles
    static let terminalTitle = Font.system(.title, design: .monospaced).bold()

    /// Monospace font for large titles
    static let terminalLargeTitle = Font.system(.largeTitle, design: .monospaced).bold()

    /// Monospace font for captions
    static let terminalCaption = Font.system(.caption, design: .monospaced)

    /// Monospace font for section headers
    static let terminalSection = Font.system(.subheadline, design: .monospaced).bold()
}

// MARK: - Terminal View Modifiers

struct TerminalStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.terminalGreen)
            .font(.terminalBody)
    }
}

struct TerminalSecondaryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.terminalSecondary)
            .font(.terminalCaption)
    }
}

struct TerminalBackgroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.terminalBackground)
    }
}

extension View {
    func terminalStyle() -> some View {
        modifier(TerminalStyle())
    }

    func terminalSecondary() -> some View {
        modifier(TerminalSecondaryStyle())
    }

    func terminalBackground() -> some View {
        modifier(TerminalBackgroundStyle())
    }
}

// MARK: - Terminal Section Header

struct TerminalSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.terminalSection)
            .foregroundColor(.terminalGreen)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }
}

// MARK: - Terminal Row

struct TerminalRow<Icon: View>: View {
    let icon: Icon
    let title: String
    let subtitle: String?

    init(
        @ViewBuilder icon: () -> Icon,
        title: String,
        subtitle: String? = nil
    ) {
        self.icon = icon()
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            icon
                .foregroundColor(.terminalGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.terminalBody)
                    .foregroundColor(.terminalGreen)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.terminalCaption)
                        .foregroundColor(.terminalSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Terminal Button Style

struct TerminalButtonStyle: ButtonStyle {
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.terminalBody)
            .foregroundColor(isPrimary ? .terminalGreen : .terminalSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isPrimary ? Color.terminalGreen : Color.terminalSecondary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Terminal Divider

struct TerminalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.terminalSecondary.opacity(0.3))
            .frame(height: 1)
    }
}
