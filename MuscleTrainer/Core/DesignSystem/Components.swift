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
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: DS.buttonHeight)
            .background(isEnabled ? AppColor.accent : AppColor.accent.opacity(0.35))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
            .accentGlow()
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
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: DS.buttonHeight)
            .background(AppColor.surface)
            .foregroundStyle(AppColor.textPrimary.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

/// Small circular glassy icon button (back chevrons, close buttons).
struct CircleIconButton: View {
    let icon: String
    var label: String = "Back"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 34, height: 34)
                .background(AppColor.card)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppColor.border, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
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
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppColor.segmentOn)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(AppColor.accent.opacity(0.35), lineWidth: 1)
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
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
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
                .background(isSelected ? AppColor.accent : AppColor.surface)
                .foregroundStyle(isSelected ? .white : AppColor.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(isSelected ? .clear : AppColor.border, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 3) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .padding(.bottom, 4)
            }
            Text(value)
                .font(AppFont.statValue)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColor.textTertiary)
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

// MARK: - Exercise media

/// Exercise demo area. Plays the user's uploaded video from the media server
/// as a muted loop when one exists; otherwise shows an honest placeholder.
struct ExerciseMediaView: View {
    let exercise: Exercise
    var height: CGFloat = 180

    @Environment(MediaService.self) private var mediaService

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.surface, AppColor.bodyLimb],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            if let url = mediaService.videoURL(for: exercise.id) {
                LoopingVideoView(url: url)
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous))
                    .overlay(alignment: .bottom) { loopingBadge }
            } else {
                // No footage yet: show the figure with this exercise's muscles lit.
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColor.accent.opacity(0.14), .clear],
                                center: .center, startRadius: 0, endRadius: height * 0.55
                            )
                        )
                    ExerciseFigureThumb(exercise: exercise)
                        .padding(.vertical, DS.spacingM)
                }
            }
        }
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
        .accessibilityLabel("Exercise demonstration for \(exercise.name)")
    }

    private var loopingBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(AppColor.accentBright)
                .frame(width: 5, height: 5)
            Text("LOOPING")
                .font(.system(size: 10.5, weight: .semibold))
                .kerning(0.5)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(.black.opacity(0.5))
        .clipShape(Capsule())
        .padding(.bottom, 12)
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
