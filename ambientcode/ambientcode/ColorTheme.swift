import SwiftUI
import Combine

/// Theme types available in the app
enum ThemeType: String, CaseIterable {
    case standard = "Standard"
    case retro = "Retro Synthwave"

    var icon: String {
        switch self {
        case .standard: return "paintbrush.fill"
        case .retro: return "waveform"
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
/// Supports multiple theme presets (Standard, Retro Synthwave)
struct AppColorTheme {

    // MARK: - Theme Selection

    static var current: ThemeType = .standard

    // MARK: - Primary Colors

    /// Main brand color - used for primary actions and key UI elements
    static var primary: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.0, green: 0.48, blue: 0.99),   // Blue #007AFF
                dark: Color(red: 0.04, green: 0.52, blue: 1.0)     // Lighter blue #0A85FF
            )
        case .retro:
            return Color(red: 0.37, green: 0.98, blue: 0.95)  // Cyan #5FFBF1
        }
    }

    /// Secondary brand color - used for secondary actions
    static var secondary: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.35, green: 0.34, blue: 0.84),  // Indigo #5A57D5
                dark: Color(red: 0.42, green: 0.40, blue: 0.88)    // Lighter indigo #6B66E0
            )
        case .retro:
            return Color(red: 0.31, green: 0.80, blue: 0.77)  // Teal #4ECDC4
        }
    }

    /// Accent color - used for highlights and special states
    static var accent: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.35, green: 0.78, blue: 0.98),  // Cyan #59C8FA
                dark: Color(red: 0.39, green: 0.82, blue: 1.0)     // Lighter cyan #64D2FF
            )
        case .retro:
            return Color(red: 0.91, green: 0.44, blue: 0.32)  // Coral #E76F51
        }
    }

    // MARK: - Semantic Colors

    /// Success color - used for positive actions and confirmations
    static var success: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.20, green: 0.78, blue: 0.35),  // Green #34C759
                dark: Color(red: 0.19, green: 0.82, blue: 0.35)    // Green #30D158
            )
        case .retro:
            return Color(red: 0.37, green: 0.98, blue: 0.95)  // Cyan #5FFBF1
        }
    }

    /// Warning color - used for caution states
    static var warning: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 1.0, green: 0.58, blue: 0.0),    // Orange #FF9500
                dark: Color(red: 1.0, green: 0.62, blue: 0.04)     // Orange #FF9F0A
            )
        case .retro:
            return Color(red: 1.0, green: 0.73, blue: 0.42)   // Orange #FFBA6B
        }
    }

    /// Danger color - used for destructive actions and errors
    static var danger: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 1.0, green: 0.23, blue: 0.19),   // Red #FF3B30
                dark: Color(red: 1.0, green: 0.27, blue: 0.23)     // Red #FF453A
            )
        case .retro:
            return Color(red: 1.0, green: 0.42, blue: 0.42)   // Coral Red #FF6B6B
        }
    }

    // MARK: - Recording States

    /// Recording indicator - bright red for active recording
    static var recording: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 1.0, green: 0.27, blue: 0.23),   // Red #FF453A
                dark: Color(red: 1.0, green: 0.31, blue: 0.27)     // Lighter red #FF4F45
            )
        case .retro:
            return Color(red: 1.0, green: 0.42, blue: 0.42)   // Coral Red #FF6B6B
        }
    }

    /// Inactive/ready state color
    static var inactive: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.56, green: 0.56, blue: 0.58),  // Gray #8E8E93
                dark: Color(red: 0.56, green: 0.56, blue: 0.58)    // Gray #8E8E93
            )
        case .retro:
            return Color(red: 0.40, green: 0.50, blue: 0.50)  // Muted teal
        }
    }

    // MARK: - Background Colors

    /// Primary background - main app background
    static var backgroundPrimary: Color {
        switch current {
        case .standard:
            return Color(NSColor.windowBackgroundColor)
        case .retro:
            return Color(red: 0.10, green: 0.24, blue: 0.24)  // Dark teal #1A3D3D
        }
    }

    /// Secondary background - cards and elevated surfaces
    static var backgroundSecondary: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.95, green: 0.95, blue: 0.97),  // Light gray #F2F2F7
                dark: Color(red: 0.11, green: 0.11, blue: 0.12)    // Dark gray #1C1C1E
            )
        case .retro:
            return Color(red: 0.15, green: 0.32, blue: 0.32)  // Medium dark teal #264D4D
        }
    }

    /// Tertiary background - subtle backgrounds and borders
    static var backgroundTertiary: Color {
        switch current {
        case .standard:
            return Color.adaptive(
                light: Color(red: 0.92, green: 0.92, blue: 0.94),  // Lighter gray #EBEBF0
                dark: Color(red: 0.17, green: 0.17, blue: 0.18)    // Dark gray #2C2C2E
            )
        case .retro:
            return Color(red: 0.97, green: 0.97, blue: 0.95)  // Cream #F7F7F2
        }
    }

    /// Sidebar background
    static var sidebarBackground: Color {
        switch current {
        case .standard:
            return Color(NSColor.controlBackgroundColor)
        case .retro:
            return Color(red: 0.13, green: 0.28, blue: 0.28)  // Dark teal sidebar
        }
    }

    // MARK: - Text Colors

    /// Primary text - main content
    static var textPrimary: Color {
        switch current {
        case .standard:
            return Color(NSColor.labelColor)
        case .retro:
            return Color(red: 0.97, green: 0.97, blue: 0.95)  // Cream text
        }
    }

    /// Secondary text - supporting content
    static var textSecondary: Color {
        switch current {
        case .standard:
            return Color(NSColor.secondaryLabelColor)
        case .retro:
            return Color(red: 0.70, green: 0.85, blue: 0.85)  // Light cyan
        }
    }

    /// Tertiary text - least emphasized content
    static var textTertiary: Color {
        switch current {
        case .standard:
            return Color(NSColor.tertiaryLabelColor)
        case .retro:
            return Color(red: 0.50, green: 0.65, blue: 0.65)  // Muted cyan
        }
    }

    // MARK: - Special Effects

    /// Overlay for transcription display areas
    static func transcriptionBackground(opacity: Double = 0.1) -> Color {
        switch current {
        case .standard:
            return Color.gray.opacity(opacity)
        case .retro:
            return Color(red: 0.20, green: 0.35, blue: 0.35).opacity(0.3)  // Teal overlay
        }
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
