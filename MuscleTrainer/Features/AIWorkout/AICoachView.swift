import SwiftUI
import SwiftData

struct AICoachView: View {
    @Query private var profiles: [UserProfile]
    @State private var showQuestionnaire = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                RadialGradient(
                    colors: [AppColor.accent.opacity(0.13), .clear],
                    center: UnitPoint(x: 0.5, y: 0.3),
                    startRadius: 0, endRadius: 320
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Text("AI Coach")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer()

                    AIOrb()
                        .frame(maxWidth: .infinity)

                    Spacer()

                    Text("What are we training today?")
                        .font(.system(size: 32, weight: .bold))
                        .kerning(-1)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Tell MuscleTrainer what you want and we'll build the session.")
                        .font(.system(size: 15.5))
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, DS.spacingM)

                    HStack(spacing: DS.spacingS) {
                        suggestionChip("Push day · 45 min")
                        suggestionChip("Legs · dumbbells")
                        suggestionChip("Quick core")
                    }
                    .padding(.top, DS.spacingL)

                    PrimaryButton(title: "Create My Workout") {
                        showQuestionnaire = true
                    }
                    .padding(.top, DS.spacingL)
                    .padding(.bottom, DS.spacingS)
                }
                .padding(.horizontal, DS.spacingL)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showQuestionnaire) {
                AIWorkoutFlowView(profile: profiles.first)
            }
        }
    }

    private func suggestionChip(_ label: String) -> some View {
        Button {
            showQuestionnaire = true
        } label: {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(PressableStyle())
    }
}

/// The glowing, slowly rotating AI orb.
private struct AIOrb: View {
    @State private var isSpinning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColor.accent.opacity(0.30), .clear],
                        center: .center, startRadius: 0, endRadius: 105
                    )
                )
                .frame(width: 210, height: 210)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            AppColor.accent.opacity(0.05),
                            AppColor.accentBright.opacity(0.55),
                            AppColor.accent.opacity(0.05),
                        ],
                        center: .center
                    )
                )
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(
                    reduceMotion ? nil : .linear(duration: 7).repeatForever(autoreverses: false),
                    value: isSpinning
                )

            Circle()
                .fill(AppColor.background)
                .frame(width: 112, height: 112)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.36, green: 0.72, blue: 1.0),
                            AppColor.accent,
                            Color(red: 0.043, green: 0.306, blue: 0.588),
                        ],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 2, endRadius: 60
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: AppColor.accent.opacity(0.5), radius: 20)
        }
        .onAppear { isSpinning = true }
        .accessibilityHidden(true)
    }
}
