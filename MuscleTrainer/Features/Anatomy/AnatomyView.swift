import SwiftUI
import SwiftData

struct AnatomyView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context

    @State private var side: BodySide = .front
    @State private var gender: AnatomyGender = .male
    @State private var selectedMuscle: Muscle?
    @State private var didLoadGender = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: DS.spacing) {
                    header
                    controls
                    AnatomyFigureView(
                        side: side,
                        gender: gender,
                        selectedMuscles: selectedMuscle.map { [$0] } ?? [],
                        onTap: handleTap
                    )
                    .padding(.horizontal, DS.spacingL)
                    .padding(.bottom, selectedMuscle == nil ? DS.spacing : 132)
                }
                .padding(.top, DS.spacingS)

                if let muscle = selectedMuscle {
                    MusclePanel(muscle: muscle) {
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

    private func handleTap(_ muscle: Muscle) {
        withAnimation(DS.panelSpring) {
            selectedMuscle = selectedMuscle == muscle ? nil : muscle
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Train")
                .font(AppFont.hero)
                .foregroundStyle(AppColor.textPrimary)
            Text("Select a muscle to begin")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    }
}

// MARK: - Floating muscle panel

private struct MusclePanel: View {
    let muscle: Muscle
    let onDismiss: () -> Void

    @Environment(AppState.self) private var appState

    private var exerciseCount: Int {
        ExerciseDatabase.exercises(for: muscle).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingM) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(muscle.displayName)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(muscle.anatomicalName)
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text("\(exerciseCount) exercises")
                    .font(AppFont.metaSmall)
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColor.accent.opacity(0.12))
                    .clipShape(Capsule())
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(AppColor.surface)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close muscle panel")
            }

            HStack(spacing: DS.spacingM) {
                NavigationLink(value: muscle) {
                    Text("View Exercises")
                        .font(AppFont.bodyMedium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColor.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("View \(muscle.displayName) exercises")

                NavigationLink(value: muscle) {
                    Text("Add to Workout")
                        .font(AppFont.bodyMedium)
                        .frame(maxWidth: 150)
                        .frame(height: 48)
                        .background(AppColor.card)
                        .foregroundStyle(AppColor.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                                .strokeBorder(AppColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Choose a \(muscle.displayName) exercise to add to a workout")
            }
        }
        .cardStyle(padding: DS.spacingL)
        .padding(.horizontal, DS.spacing)
        .padding(.bottom, DS.spacingS)
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
    }
}
