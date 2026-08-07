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
    /// #0C1118 dark / #EDF0F4 light
    static let surface = Color(
        light: Color(red: 0.929, green: 0.941, blue: 0.957),
        dark: Color(red: 0.047, green: 0.067, blue: 0.094)
    )
    /// #111821 dark / #FFFFFF light
    static let card = Color(
        light: .white,
        dark: Color(red: 0.067, green: 0.094, blue: 0.129)
    )
    /// #1687FF — the electric-blue brand accent, same in both modes.
    static let accent = Color(red: 0.086, green: 0.529, blue: 1.0)
    /// #39A7FF — brighter blue for glows and highlights.
    static let accentBright = Color(red: 0.224, green: 0.655, blue: 1.0)
    /// #FFFFFF dark / #0B1018 light
    static let textPrimary = Color(
        light: Color(red: 0.043, green: 0.063, blue: 0.094),
        dark: .white
    )
    /// #8D98A8 dark / #667085 light
    static let textSecondary = Color(
        light: Color(red: 0.400, green: 0.439, blue: 0.522),
        dark: Color(red: 0.553, green: 0.596, blue: 0.659)
    )
    /// Subtle hairline border.
    static let border = Color(
        light: Color.black.opacity(0.07),
        dark: Color.white.opacity(0.06)
    )
    /// Muscle fill when idle.
    static let muscleIdle = Color(
        light: Color(red: 0.784, green: 0.816, blue: 0.855),
        dark: Color(red: 0.165, green: 0.208, blue: 0.263)
    )
    /// Body silhouette behind muscles.
    static let bodyFill = Color(
        light: Color(red: 0.878, green: 0.898, blue: 0.925),
        dark: Color(red: 0.090, green: 0.118, blue: 0.153)
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
