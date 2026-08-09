import SwiftUI

/// Standardized layout and motion tokens.
enum DS {
    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacing: CGFloat = 16
    static let spacingL: CGFloat = 20
    static let spacingXL: CGFloat = 28
    static let spacingXXL: CGFloat = 40

    // Corner radius
    static let radiusS: CGFloat = 10
    static let radius: CGFloat = 16
    static let radiusCard: CGFloat = 18
    static let radiusL: CGFloat = 22
    static let radiusXL: CGFloat = 30

    // Controls
    static let buttonHeight: CGFloat = 56

    // Animation
    static let quick: Animation = .easeOut(duration: 0.18)
    static let smooth: Animation = .easeInOut(duration: 0.25)
    static let spring: Animation = .spring(response: 0.4, dampingFraction: 0.82)
    static let panelSpring: Animation = .spring(response: 0.45, dampingFraction: 0.85)
}

/// Typography scale built on SF with Dynamic Type support.
/// Big titles run tight (negative tracking) per the design language.
enum AppFont {
    static let hero = Font.system(size: 33, weight: .bold)
    static let pageTitle = Font.system(size: 30, weight: .bold)
    static let sectionTitle = Font.system(size: 20, weight: .semibold)
    static let cardTitle = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let meta = Font.system(size: 13, weight: .medium)
    static let metaSmall = Font.system(size: 11, weight: .semibold)
    static let micro = Font.system(size: 11.5, weight: .bold)
    static let timer = Font.system(size: 56, weight: .bold)
    static let statValue = Font.system(size: 24, weight: .bold)
}

/// Uppercase, letter-spaced micro label (e.g. "AI GENERATED", "WEIGHT").
struct MicroLabel: View {
    let text: String
    var color: Color = AppColor.textTertiary

    var body: some View {
        Text(text)
            .font(AppFont.micro)
            .kerning(1.0)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

// MARK: - Common view modifiers

struct CardBackground: ViewModifier {
    var padding: CGFloat = DS.spacing
    var radius: CGFloat = DS.radiusCard

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = DS.spacing, radius: CGFloat = DS.radiusCard) -> some View {
        modifier(CardBackground(padding: padding, radius: radius))
    }

    /// The signature cyan glow under primary CTAs and active controls.
    func accentGlow() -> some View {
        shadow(color: AppColor.accent.opacity(0.35), radius: 14, y: 6)
            .shadow(color: AppColor.accent.opacity(0.22), radius: 24)
    }
}

/// Subtle press-scale for buttons.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DS.quick, value: configuration.isPressed)
    }
}
