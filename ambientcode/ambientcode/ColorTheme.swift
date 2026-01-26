import SwiftUI
import Combine

/// Theme types available in the app
enum ThemeType: String, CaseIterable {
    case standard = "Standard"

    var icon: String {
        switch self {
        case .standard: return "paintbrush.fill"
        }
    }
}

/// Theme manager for storing and retrieving current theme
class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeType {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        self.currentTheme = ThemeType(rawValue: savedTheme ?? "") ?? .standard
    }
}

/// Professional color theme system for Voice Capture app
struct AppColorTheme {

    // MARK: - Theme Selection

    static var current: ThemeType = .standard

    // MARK: - Primary Colors

    /// Main brand color - used for primary actions and key UI elements
    static var primary: Color {
        return Color.adaptive(
            light: Color(red: 0.0, green: 0.48, blue: 0.99),   // Blue #007AFF
            dark: Color(red: 0.04, green: 0.52, blue: 1.0)     // Lighter blue #0A85FF
        )
    }

    /// Secondary brand color - used for secondary actions
    static var secondary: Color {
        return Color.adaptive(
            light: Color(red: 0.35, green: 0.34, blue: 0.84),  // Indigo #5A57D5
            dark: Color(red: 0.42, green: 0.40, blue: 0.88)    // Lighter indigo #6B66E0
        )
    }

    /// Accent color - used for highlights and special states
    static var accent: Color {
        return Color.adaptive(
            light: Color(red: 0.35, green: 0.78, blue: 0.98),  // Cyan #59C8FA
            dark: Color(red: 0.39, green: 0.82, blue: 1.0)     // Lighter cyan #64D2FF
        )
    }

    // MARK: - Semantic Colors

    /// Success color - used for positive actions and confirmations
    static var success: Color {
        return Color.adaptive(
            light: Color(red: 0.20, green: 0.78, blue: 0.35),  // Green #34C759
            dark: Color(red: 0.19, green: 0.82, blue: 0.35)    // Green #30D158
        )
    }

    /// Warning color - used for caution states
    static var warning: Color {
        return Color.adaptive(
            light: Color(red: 1.0, green: 0.58, blue: 0.0),    // Orange #FF9500
            dark: Color(red: 1.0, green: 0.62, blue: 0.04)     // Orange #FF9F0A
        )
    }

    /// Danger color - used for destructive actions and errors
    static var danger: Color {
        return Color.adaptive(
            light: Color(red: 1.0, green: 0.23, blue: 0.19),   // Red #FF3B30
            dark: Color(red: 1.0, green: 0.27, blue: 0.23)     // Red #FF453A
        )
    }

    // MARK: - Recording States

    /// Recording indicator - bright red for active recording
    static var recording: Color {
        return Color.adaptive(
            light: Color(red: 1.0, green: 0.27, blue: 0.23),   // Red #FF453A
            dark: Color(red: 1.0, green: 0.31, blue: 0.27)     // Lighter red #FF4F45
        )
    }

    /// Inactive/ready state color
    static var inactive: Color {
        return Color.adaptive(
            light: Color(red: 0.56, green: 0.56, blue: 0.58),  // Gray #8E8E93
            dark: Color(red: 0.56, green: 0.56, blue: 0.58)    // Gray #8E8E93
        )
    }

    // MARK: - Background Colors

    /// Primary background - main app background
    static var backgroundPrimary: Color {
        return Color(NSColor.windowBackgroundColor)
    }

    /// Secondary background - cards and elevated surfaces
    static var backgroundSecondary: Color {
        return Color.adaptive(
            light: Color(red: 0.95, green: 0.95, blue: 0.97),  // Light gray #F2F2F7
            dark: Color(red: 0.11, green: 0.11, blue: 0.12)    // Dark gray #1C1C1E
        )
    }

    /// Tertiary background - subtle backgrounds and borders
    static var backgroundTertiary: Color {
        return Color.adaptive(
            light: Color(red: 0.92, green: 0.92, blue: 0.94),  // Lighter gray #EBEBF0
            dark: Color(red: 0.17, green: 0.17, blue: 0.18)    // Dark gray #2C2C2E
        )
    }

    /// Sidebar background
    static var sidebarBackground: Color {
        return Color(NSColor.controlBackgroundColor)
    }

    // MARK: - Text Colors

    /// Primary text - main content
    static var textPrimary: Color {
        return Color(NSColor.labelColor)
    }

    /// Secondary text - supporting content
    static var textSecondary: Color {
        return Color(NSColor.secondaryLabelColor)
    }

    /// Tertiary text - least emphasized content
    static var textTertiary: Color {
        return Color(NSColor.tertiaryLabelColor)
    }

    // MARK: - Special Effects

    /// Overlay for transcription display areas
    static func transcriptionBackground(opacity: Double = 0.1) -> Color {
        return Color.gray.opacity(opacity)
    }

    /// Border color for focused elements
    static var focusBorder: Color {
        primary
    }

    /// Shadow color
    static let shadow = Color.black.opacity(0.1)
}

// MARK: - Color Extension

extension Color {
    /// Create adaptive color that responds to light/dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        #if os(macOS)
        return Color(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
        #else
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(dark)
            } else {
                return UIColor(light)
            }
        })
        #endif
    }
}

// MARK: - Button Styles with Theme

/// Primary action button style (e.g., Start Recording)
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(isDestructive ? AppColorTheme.danger : AppColorTheme.primary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary action button style (e.g., Copy, Clear)
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = AppColorTheme.secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Success button style (e.g., Send to Claude, Save & Learn)
struct SuccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(AppColorTheme.success)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Danger button style (e.g., Delete, Clear)
struct DangerButtonStyle: ButtonStyle {
    var isText: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isText ? AppColorTheme.danger : .white)
            .padding(.horizontal, isText ? 0 : 12)
            .padding(.vertical, isText ? 0 : 6)
            .background(isText ? Color.clear : AppColorTheme.danger)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply card-like styling to a view
    func cardStyle() -> some View {
        self
            .padding()
            .background(AppColorTheme.backgroundSecondary)
            .cornerRadius(12)
            .shadow(color: AppColorTheme.shadow, radius: 4, x: 0, y: 2)
    }

    /// Apply transcription display styling
    func transcriptionStyle() -> some View {
        self
            .padding()
            .background(AppColorTheme.transcriptionBackground())
            .cornerRadius(8)
    }
}
