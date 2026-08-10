import SwiftUI
import UIKit

// MARK: - Color palette

/// Semantic colors that adapt to light/dark mode.
/// All app surfaces should come from here — never hardcode colors in views.
enum AppColor {
    /// #05070A dark / #F5F7FA light
    static let background = Color(
        light: Color(red: 0.961, green: 0.969, blue: 0.980),
        dark: Color(red: 0.020, green: 0.035, blue: 0.043)
    )
    /// Inner chip / thumb surface: #121A24 dark / #E9EDF2 light
    static let surface = Color(
        light: Color(red: 0.914, green: 0.929, blue: 0.949),
        dark: Color(red: 0.063, green: 0.110, blue: 0.137)
    )
    /// Cards: #0E141C dark / #FFFFFF light
    static let card = Color(
        light: .white,
        dark: Color(red: 0.051, green: 0.086, blue: 0.106)
    )
    /// Deeper pressed control: #161F2A dark
    static let control = Color(
        light: Color(red: 0.882, green: 0.902, blue: 0.925),
        dark: Color(red: 0.082, green: 0.145, blue: 0.180)
    )
    /// Progress/segmented track: #141C26 dark
    static let track = Color(
        light: Color(red: 0.898, green: 0.914, blue: 0.937),
        dark: Color(red: 0.059, green: 0.102, blue: 0.129)
    )
    /// Selected segment fill: #1B2532 dark
    static let segmentOn = Color(
        light: .white,
        dark: Color(red: 0.078, green: 0.200, blue: 0.239)
    )
    /// #2BD4EE — the glowing cyan brand accent, same in both modes.
    static let accent = Color(red: 0.169, green: 0.831, blue: 0.933)
    /// #66E0F4 — brighter cyan for glows, links and highlights.
    static let accentBright = Color(red: 0.400, green: 0.878, blue: 0.957)
    /// Dark ink used on cyan-filled controls: #04252C
    static let onAccent = Color(red: 0.016, green: 0.145, blue: 0.173)
    /// #FFFFFF dark / #0B1018 light
    static let textPrimary = Color(
        light: Color(red: 0.043, green: 0.063, blue: 0.094),
        dark: .white
    )
    /// #929CAA dark / #5C6672 light
    static let textSecondary = Color(
        light: Color(red: 0.361, green: 0.400, blue: 0.447),
        dark: Color(red: 0.576, green: 0.635, blue: 0.675)
    )
    /// Muted metadata: #66717F dark
    static let textTertiary = Color(
        light: Color(red: 0.541, green: 0.576, blue: 0.639),
        dark: Color(red: 0.396, green: 0.467, blue: 0.506)
    )
    /// Faintest text (timestamps, ghost numerals): #3D4855 dark
    static let textFaint = Color(
        light: Color(red: 0.702, green: 0.729, blue: 0.773),
        dark: Color(red: 0.239, green: 0.310, blue: 0.345)
    )
    /// Subtle hairline border.
    static let border = Color(
        light: Color.black.opacity(0.07),
        dark: Color.white.opacity(0.06)
    )
    /// Muscle fill when idle — a faint wash so regions stay tappable-looking.
    static let muscleIdle = Color(
        light: Color.black.opacity(0.05),
        dark: Color.white.opacity(0.04)
    )
    /// Secondary-worked muscle: #17558C dark
    static let muscleSecondary = Color(
        light: Color(red: 0.478, green: 0.686, blue: 0.898),
        dark: Color(red: 0.082, green: 0.439, blue: 0.529)
    )
    /// Heat tier mid: #1663A8
    static let heatMid = Color(red: 0.082, green: 0.502, blue: 0.627)
    /// Heat tier low — light cyan wash on the white figure.
    static let heatLow = Color(
        light: Color(red: 0.663, green: 0.902, blue: 0.949),
        dark: Color(red: 0.663, green: 0.902, blue: 0.949)
    )
    /// Anatomy figure ground — transparent wash; the background shows through.
    static let bodyFill = Color(
        light: Color.black.opacity(0.03),
        dark: Color.white.opacity(0.02)
    )
    /// Body limbs/neck, slightly darker: #0C1219 dark
    static let bodyLimb = Color(
        light: Color(red: 0.906, green: 0.922, blue: 0.941),
        dark: Color(red: 0.047, green: 0.078, blue: 0.102)
    )
    /// Anatomy line-art ink: light on dark, dark on light.
    static let anatomyLine = Color(
        light: Color(red: 0.180, green: 0.271, blue: 0.318),
        dark: Color(red: 0.616, green: 0.706, blue: 0.749)
    )
    static let success = Color(red: 0.20, green: 0.78, blue: 0.47)
    static let destructive = Color(red: 1.0, green: 0.32, blue: 0.32)
}

extension Color {
    /// Builds a dynamic color that resolves per-appearance.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Theme manager

/// Central theme state. Changing `theme` re-renders the whole app instantly.
@Observable
final class ThemeManager {
    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey) }
    }

    private static let storageKey = "app.theme"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        self.theme = stored.flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
