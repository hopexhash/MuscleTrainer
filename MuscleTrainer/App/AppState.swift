import Foundation
import SwiftUI
import SwiftData

/// App-wide navigation and cross-feature state.
@Observable
final class AppState {
    enum Tab: Hashable {
        case body, workouts, aiCoach, progress, profile
    }

    var selectedTab: Tab = .body

    /// Workout currently being performed — presented as a full-screen cover.
    var activeWorkout: ActiveWorkoutController?

    /// Exercise the user wants to add to a workout — presents the picker sheet.
    var exerciseToAdd: Exercise?

    func startWorkout(_ workout: Workout) {
        Haptics.medium()
        activeWorkout = ActiveWorkoutController(workout: workout)
    }
}

// MARK: - First-launch seeding

enum SeedService {
    static func seedIfNeeded(context: ModelContext) {
        let profileCount = (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        if profileCount == 0 {
            context.insert(UserProfile())
        }

        let workoutCount = (try? context.fetchCount(FetchDescriptor<Workout>())) ?? 0
        guard workoutCount == 0 else { return }

        for template in sampleWorkouts {
            let workout = Workout(name: template.name, goal: template.goal, estimatedMinutes: template.minutes)
            context.insert(workout)
            for (index, item) in template.items.enumerated() {
                guard ExerciseDatabase.exercise(id: item.exerciseID) != nil else { continue }
                let we = WorkoutExercise(
                    exerciseID: item.exerciseID, order: index,
                    sets: item.sets, repsLow: item.repsLow, repsHigh: item.repsHigh,
                    restSeconds: item.rest
                )
                we.workout = workout
                context.insert(we)
            }
        }
        try? context.save()
    }

    private struct Template {
        struct Item {
            let exerciseID: String
            let sets: Int
            let repsLow: Int
            let repsHigh: Int
            let rest: Int
        }
        let name: String
        let goal: TrainingGoal
        let minutes: Int
        let items: [Item]
    }

    private static let sampleWorkouts: [Template] = [
        Template(name: "Push Day", goal: .buildMuscle, minutes: 55, items: [
            .init(exerciseID: "bench-press", sets: 4, repsLow: 8, repsHigh: 10, rest: 90),
            .init(exerciseID: "incline-db-press", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "db-shoulder-press", sets: 3, repsLow: 8, repsHigh: 12, rest: 75),
            .init(exerciseID: "cable-fly", sets: 3, repsLow: 12, repsHigh: 15, rest: 60),
            .init(exerciseID: "lateral-raise", sets: 3, repsLow: 12, repsHigh: 15, rest: 60),
            .init(exerciseID: "tricep-pushdown", sets: 3, repsLow: 10, repsHigh: 12, rest: 60),
        ]),
        Template(name: "Pull Day", goal: .buildMuscle, minutes: 55, items: [
            .init(exerciseID: "pull-up", sets: 4, repsLow: 6, repsHigh: 10, rest: 90),
            .init(exerciseID: "barbell-row", sets: 4, repsLow: 8, repsHigh: 10, rest: 90),
            .init(exerciseID: "seated-cable-row", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "face-pull", sets: 3, repsLow: 12, repsHigh: 15, rest: 60),
            .init(exerciseID: "db-curl", sets: 3, repsLow: 10, repsHigh: 12, rest: 60),
            .init(exerciseID: "hammer-curl", sets: 3, repsLow: 10, repsHigh: 12, rest: 60),
        ]),
        Template(name: "Leg Day", goal: .buildMuscle, minutes: 60, items: [
            .init(exerciseID: "back-squat", sets: 4, repsLow: 6, repsHigh: 8, rest: 120),
            .init(exerciseID: "rdl", sets: 3, repsLow: 8, repsHigh: 10, rest: 90),
            .init(exerciseID: "leg-press", sets: 3, repsLow: 10, repsHigh: 12, rest: 90),
            .init(exerciseID: "leg-curl", sets: 3, repsLow: 10, repsHigh: 12, rest: 60),
            .init(exerciseID: "standing-calf-raise", sets: 4, repsLow: 12, repsHigh: 15, rest: 45),
        ]),
        Template(name: "Upper Body", goal: .generalFitness, minutes: 50, items: [
            .init(exerciseID: "db-bench-press", sets: 3, repsLow: 8, repsHigh: 12, rest: 75),
            .init(exerciseID: "lat-pulldown", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "db-shoulder-press", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "db-row", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "db-curl", sets: 2, repsLow: 12, repsHigh: 15, rest: 60),
            .init(exerciseID: "tricep-pushdown", sets: 2, repsLow: 12, repsHigh: 15, rest: 60),
        ]),
        Template(name: "Full Body", goal: .generalFitness, minutes: 45, items: [
            .init(exerciseID: "goblet-squat", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "push-up", sets: 3, repsLow: 10, repsHigh: 15, rest: 60),
            .init(exerciseID: "db-row", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "db-rdl", sets: 3, repsLow: 10, repsHigh: 12, rest: 75),
            .init(exerciseID: "plank", sets: 3, repsLow: 30, repsHigh: 45, rest: 45),
        ]),
    ]
}
