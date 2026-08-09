import SwiftUI
import UIKit

// MARK: - Color palette

/// Semantic colors that adapt to light/dark mode.
/// All app surfaces should come from here — never hardcode colors in views.
enum AppColor {
    /// #05070A dark / #F5F7FA light
    static let background = Color(
        light: Color(red: 0.961, green: 0.969, blue: 0.980),
        dark: Color(red: 0.020, green: 0.027, blue: 0.039)
    )
    /// Inner chip / thumb surface: #121A24 dark / #E9EDF2 light
    static let surface = Color(
        light: Color(red: 0.914, green: 0.929, blue: 0.949),
        dark: Color(red: 0.071, green: 0.102, blue: 0.141)
    )
    /// Cards: #0E141C dark / #FFFFFF light
    static let card = Color(
        light: .white,
        dark: Color(red: 0.055, green: 0.078, blue: 0.110)
    )
    /// Deeper pressed control: #161F2A dark
    static let control = Color(
        light: Color(red: 0.882, green: 0.902, blue: 0.925),
        dark: Color(red: 0.086, green: 0.122, blue: 0.165)
    )
    /// Progress/segmented track: #141C26 dark
    static let track = Color(
        light: Color(red: 0.898, green: 0.914, blue: 0.937),
        dark: Color(red: 0.078, green: 0.110, blue: 0.149)
    )
    /// Selected segment fill: #1B2532 dark
    static let segmentOn = Color(
        light: .white,
        dark: Color(red: 0.106, green: 0.145, blue: 0.196)
    )
    /// #1687FF — the electric-blue brand accent, same in both modes.
    static let accent = Color(red: 0.086, green: 0.529, blue: 1.0)
    /// #3BA6FF — brighter blue for glows, links and highlights.
    static let accentBright = Color(red: 0.231, green: 0.651, blue: 1.0)
    /// #FFFFFF dark / #0B1018 light
    static let textPrimary = Color(
        light: Color(red: 0.043, green: 0.063, blue: 0.094),
        dark: .white
    )
    /// #929CAA dark / #5C6672 light
    static let textSecondary = Color(
        light: Color(red: 0.361, green: 0.400, blue: 0.447),
        dark: Color(red: 0.573, green: 0.612, blue: 0.667)
    )
    /// Muted metadata: #66717F dark
    static let textTertiary = Color(
        light: Color(red: 0.541, green: 0.576, blue: 0.639),
        dark: Color(red: 0.400, green: 0.443, blue: 0.498)
    )
    /// Faintest text (timestamps, ghost numerals): #3D4855 dark
    static let textFaint = Color(
        light: Color(red: 0.702, green: 0.729, blue: 0.773),
        dark: Color(red: 0.239, green: 0.282, blue: 0.333)
    )
    /// Subtle hairline border.
    static let border = Color(
        light: Color.black.opacity(0.07),
        dark: Color.white.opacity(0.06)
    )
    /// Muscle fill when idle: #1A2430 dark
    static let muscleIdle = Color(
        light: Color(red: 0.784, green: 0.816, blue: 0.855),
        dark: Color(red: 0.102, green: 0.141, blue: 0.188)
    )
    /// Secondary-worked muscle: #17558C dark
    static let muscleSecondary = Color(
        light: Color(red: 0.478, green: 0.686, blue: 0.898),
        dark: Color(red: 0.090, green: 0.333, blue: 0.549)
    )
    /// Heat tier mid: #1663A8
    static let heatMid = Color(red: 0.086, green: 0.388, blue: 0.659)
    /// Heat tier low: #1B3550
    static let heatLow = Color(
        light: Color(red: 0.737, green: 0.816, blue: 0.894),
        dark: Color(red: 0.106, green: 0.208, blue: 0.314)
    )
    /// Body silhouette (head/torso): #101821 dark
    static let bodyFill = Color(
        light: Color(red: 0.878, green: 0.898, blue: 0.925),
        dark: Color(red: 0.063, green: 0.094, blue: 0.129)
    )
    /// Body limbs/neck, slightly darker: #0C1219 dark
    static let bodyLimb = Color(
        light: Color(red: 0.906, green: 0.922, blue: 0.941),
        dark: Color(red: 0.047, green: 0.071, blue: 0.098)
    )
    /// Anatomy line-art stroke: #5E748E dark / #55637A light
    static let anatomyLine = Color(
        light: Color(red: 0.333, green: 0.388, blue: 0.478),
        dark: Color(red: 0.369, green: 0.455, blue: 0.557)
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
