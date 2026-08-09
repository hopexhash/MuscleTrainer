import SwiftUI
import SwiftData

struct AnatomyView: View {
    @Query private var profiles: [UserProfile]

    @State private var side: BodySide = .front
    @State private var gender: AnatomyGender = .male
    @State private var selectedMuscle: Muscle?
    @State private var didLoadGender = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColor.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    header
                    controls
                    figureArea
                }
                .padding(.top, DS.spacingS)

                if let muscle = selectedMuscle {
                    MuscleSheet(muscle: muscle, gender: gender) {
                        withAnimation(DS.panelSpring) { selectedMuscle = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationDestination(for: Muscle.self) { muscle in
                ExerciseLibraryView(muscle: muscle)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            // Default the figure to the user's onboarding choice, once.
            if !didLoadGender, let profile = profiles.first {
                gender = profile.anatomyGender
                didLoadGender = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                Text("Muscle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Text("Trainer")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColor.textTertiary)
            }
            Text("What are you training?")
                .font(AppFont.pageTitle)
                .kerning(-0.5)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            Text("Tap a muscle to see exercises.")
                .font(.system(size: 14))
                .foregroundStyle(AppColor.textTertiary)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, DS.spacingL)
    }

    private var controls: some View {
        HStack(spacing: DS.spacingM) {
            SegmentedSelector(
                options: AnatomyGender.allCases,
                label: { $0.displayName },
                selection: $gender
            )
            SegmentedSelector(
                options: [BodySide.front, .back],
                label: { $0 == .front ? "Front" : "Back" },
                selection: Binding(
                    get: { side },
                    set: { newValue in
                        side = newValue
                        // Clear a selection that isn't visible on the new side.
                        if let muscle = selectedMuscle,
                           !AnatomyShapeStore.regions(side: newValue, gender: gender)
                               .contains(where: { $0.muscle == muscle }) {
                            selectedMuscle = nil
                        }
                    }
                )
            )
        }
        .padding(.horizontal, DS.spacingL)
        .padding(.top, DS.spacing)
    }

    private var figureArea: some View {
        ZStack(alignment: .top) {
            // Soft blue aura behind the figure.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColor.accent.opacity(0.07), .clear],
                        center: .center, startRadius: 0, endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            AnatomyFigureView(
                side: side,
                gender: gender,
                selectedMuscles: selectedMuscle.map { [$0] } ?? [],
                onTap: handleTap
            )
            .padding(.horizontal, DS.spacingXL)
            .padding(.vertical, DS.spacingS)

            // Floating muscle name pill.
            if let muscle = selectedMuscle {
                VStack(spacing: 2) {
                    Text(muscle.displayName.uppercased())
                        .font(AppFont.micro)
                        .kerning(1.2)
                        .foregroundStyle(AppColor.accentBright)
                    Text(muscle.anatomicalName)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppColor.card.opacity(0.9))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColor.border, lineWidth: 1)
                )
                .padding(.top, DS.spacingM)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, selectedMuscle == nil ? 0 : 150)
    }

    private func handleTap(_ muscle: Muscle) {
        withAnimation(DS.panelSpring) {
            selectedMuscle = selectedMuscle == muscle ? nil : muscle
        }
    }
}

// MARK: - Floating bottom sheet

private struct MuscleSheet: View {
    let muscle: Muscle
    let gender: AnatomyGender
    let onDismiss: () -> Void

    private var exerciseCount: Int {
        ExerciseDatabase.exercises(for: muscle).count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mini figure with the muscle lit, centered.
            AnatomyFigureView(
                side: muscle.isBackFacing ? .back : .front,
                gender: gender,
                selectedMuscles: [muscle],
                isInteractive: false
            )
            .frame(width: 46, height: 58)
            .padding(4)
            .background(AppColor.bodyLimb.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
            .accessibilityHidden(true)

            Text(muscle.displayName)
                .font(.system(size: 22, weight: .bold))
                .kerning(-0.4)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, 10)
            Text(muscle.anatomicalName)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 2)
            Text("\(exerciseCount) exercises")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.accentBright)
                .padding(.top, 5)

            NavigationLink(value: muscle) {
                Text("View Exercises")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColor.accent)
                    .foregroundStyle(AppColor.onAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .accentGlow()
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("View \(muscle.displayName) exercises")
            .padding(.top, DS.spacing)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close muscle panel")
        }
        .padding(DS.spacingL)
        .background(AppColor.card.opacity(0.94))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusL + 2, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusL + 2, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 24, y: -4)
        .padding(.horizontal, DS.spacingM)
        .padding(.bottom, DS.spacingM)
    }
}
