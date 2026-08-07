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
                ExerciseMediaView(media: exercise.media)

                tagRow

                instructionsSection

                recommendationSection

                targetSection
            }
            .padding(.horizontal, DS.spacing)
            .padding(.bottom, 120)
        }
        .background(AppColor.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
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
                SecondaryButton(title: "Add to Workout", icon: "plus") {
                    appState.exerciseToAdd = exercise
                }
                PrimaryButton(title: "Start Exercise", icon: "play.fill") {
                    startQuickSession()
                }
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
        VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "How to perform")
            VStack(alignment: .leading, spacing: DS.spacingM) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: DS.spacingM) {
                        Text("\(index + 1)")
                            .font(AppFont.metaSmall)
                            .foregroundStyle(AppColor.accent)
                            .frame(width: 24, height: 24)
                            .background(AppColor.accent.opacity(0.12))
                            .clipShape(Circle())
                        Text(step)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .cardStyle()
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
            SectionHeader(title: "Target muscles")
            VStack(alignment: .leading, spacing: DS.spacing) {
                MuscleHeatmapView(
                    gender: profile?.anatomyGender ?? .male,
                    heatmap: targetHeatmap,
                    height: 200
                )
                HStack(spacing: DS.spacingL) {
                    legend(color: AppColor.accent, label: "Primary")
                    legend(color: AppColor.accent.opacity(0.4), label: "Secondary")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Primary: " + exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textPrimary)
                    if !exercise.secondaryMuscles.isEmpty {
                        Text("Secondary: " + exercise.secondaryMuscles.map(\.displayName).joined(separator: ", "))
                            .font(AppFont.meta)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .cardStyle()
        }
    }

    private var targetHeatmap: [Muscle: Double] {
        var map: [Muscle: Double] = [:]
        for m in exercise.primaryMuscles { map[m] = 1.0 }
        for m in exercise.secondaryMuscles { map[m] = 0.4 }
        return map
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(AppFont.metaSmall)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}
