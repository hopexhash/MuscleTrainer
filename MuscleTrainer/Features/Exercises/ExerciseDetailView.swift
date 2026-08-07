import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.spacingL) {
                ExerciseMediaView(exercise: exercise, height: 250)

                Text(exercise.name)
                    .font(.system(size: 29, weight: .bold))
                    .kerning(-1)
                    .foregroundStyle(AppColor.textPrimary)

                tagRow

                targetSection

                instructionsSection

                recommendationSection
            }
            .padding(.horizontal, DS.spacing)
            .padding(.bottom, 120)
        }
        .background(AppColor.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard let profile else { return }
                    Haptics.selection()
                    profile.toggleFavorite(exercise.id)
                    try? context.save()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? AppColor.accent : AppColor.textSecondary)
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: DS.spacingM) {
                PrimaryButton(title: "Add to Workout") {
                    appState.exerciseToAdd = exercise
                }
                Button {
                    startQuickSession()
                } label: {
                    Text("Start")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary.opacity(0.85))
                        .frame(width: 100, height: DS.buttonHeight)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                                .strokeBorder(AppColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Start \(exercise.name) now")
            }
            .padding(.horizontal, DS.spacing)
            .padding(.top, DS.spacingS)
            .background(.ultraThinMaterial)
        }
    }

    private var isFavorite: Bool {
        profile?.isFavorite(exercise.id) ?? false
    }

    /// Creates a single-exercise session and jumps straight into the player.
    private func startQuickSession() {
        let workout = Workout(name: exercise.name, goal: profile?.goal ?? .generalFitness, estimatedMinutes: 10)
        let item = WorkoutExercise(exerciseID: exercise.id, order: 0)
        context.insert(workout)
        item.workout = workout
        context.insert(item)
        // Quick sessions are throwaway — not saved to My Workouts.
        appState.activeWorkout = ActiveWorkoutController(workout: workout, discardWorkoutOnEnd: true)
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.spacingS) {
                tag(exercise.difficulty.displayName, icon: "chart.bar.fill")
                ForEach(exercise.equipment) { equipment in
                    tag(equipment.displayName, icon: equipment.icon)
                }
                tag(exercise.category.displayName, icon: "square.grid.2x2")
            }
        }
    }

    private func tag(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(AppFont.meta)
        }
        .foregroundStyle(AppColor.textSecondary)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(AppColor.card)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(AppColor.border, lineWidth: 1))
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: DS.spacing) {
            SectionHeader(title: "How to perform")
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: DS.spacing) {
                        // Ghost numeral, per the design language.
                        Text("\(index + 1)")
                            .font(.system(size: 22, weight: .bold))
                            .kerning(-0.5)
                            .foregroundStyle(AppColor.textFaint)
                            .frame(minWidth: 30, alignment: .leading)
                            .monospacedDigit()
                        Text(step)
                            .font(.system(size: 15.5))
                            .lineSpacing(3)
                            .foregroundStyle(AppColor.textPrimary.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 3)
                    }
                }
            }
        }
    }

    private var recommendationSection: some View {
        let rec = exercise.recommendation(for: profile?.goal ?? .buildMuscle)
        return VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "Recommended sets")
            HStack(spacing: DS.spacingM) {
                MetricCard(value: rec.sets, label: rec.title)
                MetricCard(value: rec.reps, label: "Reps")
                MetricCard(value: rec.rest, label: "Rest")
            }
        }
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "Muscles worked")
            HStack(spacing: DS.spacing) {
                AnatomyFigureView(
                    side: exercise.primaryMuscle.isBackFacing ? .back : .front,
                    gender: profile?.anatomyGender ?? .male,
                    selectedMuscles: Set(exercise.primaryMuscles),
                    secondaryMuscles: Set(exercise.secondaryMuscles),
                    isInteractive: false
                )
                .frame(width: 74, height: 150)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 11) {
                    ForEach(exercise.primaryMuscles) { muscle in
                        muscleRow(muscle, role: "PRIMARY", color: AppColor.accent)
                    }
                    ForEach(exercise.secondaryMuscles) { muscle in
                        muscleRow(muscle, role: "SECONDARY", color: AppColor.muscleSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .cardStyle(radius: DS.radiusL)
        }
    }

    private func muscleRow(_ muscle: Muscle, role: String, color: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(muscle.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text(role)
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(AppColor.textTertiary)
        }
    }
}
