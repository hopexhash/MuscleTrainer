import SwiftUI

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.spacingS) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? AppColor.accent : AppColor.accent.opacity(0.35))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(!isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.spacingS) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColor.card)
            .foregroundStyle(AppColor.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Segmented selector

struct SegmentedSelector<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    @Namespace private var segmentNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Button {
                    guard option != selection else { return }
                    Haptics.selection()
                    withAnimation(DS.spring) { selection = option }
                } label: {
                    Text(label(option))
                        .font(AppFont.meta)
                        .foregroundStyle(option == selection ? AppColor.textPrimary : AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background {
                            if option == selection {
                                RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                                    .fill(AppColor.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                                            .strokeBorder(AppColor.accent.opacity(0.5), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "segment", in: segmentNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(option))
                .accessibilityAddTraits(option == selection ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusS + 3, style: .continuous))
    }
}

// MARK: - Chips

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(AppFont.meta)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(isSelected ? AppColor.accent : AppColor.card)
                .foregroundStyle(isSelected ? .white : AppColor.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(isSelected ? .clear : AppColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Metric card

struct MetricCard: View {
    let value: String
    let label: String
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }
            Text(value)
                .font(AppFont.statValue)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(AppFont.meta)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DS.spacing) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppColor.textSecondary)
            Text(title)
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(AppColor.accent)
                    .padding(.top, DS.spacingS)
            }
        }
        .padding(DS.spacingXL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Media placeholder

/// Honest placeholder for exercise media that hasn't shipped yet.
struct ExerciseMediaView: View {
    let media: ExerciseMedia
    var height: CGFloat = 180

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                .fill(AppColor.surface)
            switch media {
            case .placeholder(let systemImage):
                VStack(spacing: DS.spacingS) {
                    Image(systemName: systemImage)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppColor.accent.opacity(0.7))
                    Text("Demo coming soon")
                        .font(AppFont.metaSmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
            case .image(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
            case .localVideo, .remoteVideo, .animation:
                // Playback support lands with real media assets.
                VStack(spacing: DS.spacingS) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppColor.accent.opacity(0.7))
                    Text("Video demo")
                        .font(AppFont.metaSmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Difficulty badge

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index <= difficulty.rawValue ? AppColor.accent : AppColor.border)
                    .frame(width: 10, height: 4)
            }
        }
        .accessibilityLabel("Difficulty: \(difficulty.displayName)")
    }
}
