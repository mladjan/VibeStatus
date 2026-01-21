// Theme.swift
// VibeStatusMobile
//
// Modern clean theme for the app

import SwiftUI

// MARK: - App Colors

extension Color {
    /// Primary accent color - warm copper/orange
    static let terminalGreen = Color(red: 0.843, green: 0.478, blue: 0.322) // #D77A52

    /// Dimmed accent for secondary elements
    static let terminalGreenDim = Color(red: 0.7, green: 0.4, blue: 0.3)

    /// App background - dark but not pure black
    static let terminalBackground = Color(red: 0.1, green: 0.1, blue: 0.1)

    /// Secondary text - medium gray
    static let terminalSecondary = Color(white: 0.6)

    /// Red for errors/warnings
    static let terminalRed = Color(red: 1.0, green: 0.3, blue: 0.3)

    /// Orange/copper for working status and accents
    static let terminalOrange = Color(red: 0.843, green: 0.478, blue: 0.322) // #D77A52

    /// Blue for needs input
    static let terminalBlue = Color(red: 0.4, green: 0.7, blue: 1.0)

    /// Primary text - white
    static let terminalText = Color.white

    /// Card background - slightly lighter than app background
    static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.15)

    /// Status indicator colors
    static let statusGreen = Color(red: 0.3, green: 0.85, blue: 0.4) // Bright green dot
    static let statusOrange = Color(red: 0.843, green: 0.478, blue: 0.322) // Orange dot
    static let statusBlue = Color(red: 0.4, green: 0.7, blue: 1.0) // Blue dot
    static let statusGray = Color(white: 0.5) // Gray dot
}

// MARK: - App Fonts

extension Font {
    /// Regular body text
    static let terminalBody = Font.system(.body, design: .rounded)

    /// Headline text
    static let terminalHeadline = Font.system(.headline, design: .rounded).weight(.semibold)

    /// Title text
    static let terminalTitle = Font.system(.title2, design: .rounded).weight(.bold)

    /// Large title
    static let terminalLargeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)

    /// Small caption text
    static let terminalCaption = Font.system(.caption, design: .rounded)

    /// Section header
    static let terminalSection = Font.system(.subheadline, design: .rounded).weight(.semibold)
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
