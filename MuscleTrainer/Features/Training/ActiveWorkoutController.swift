import Foundation
import SwiftUI

/// Drives an in-progress workout: exercise/set position, logged sets and the rest timer.
/// Persistence happens once at the end, when the hosting view saves the session.
@Observable
final class ActiveWorkoutController: Identifiable {

    struct PlanItem: Identifiable {
        let id = UUID()
        let exercise: Exercise
        let sets: Int
        let repsLow: Int
        let repsHigh: Int
        let restSeconds: Int
        let targetWeight: Double?
    }

    struct LoggedSet: Identifiable {
        let id = UUID()
        let exerciseID: String
        let exerciseName: String
        let setNumber: Int
        let reps: Int
        let weight: Double
    }

    let id = UUID()
    let workoutName: String
    let goal: TrainingGoal
    let plan: [PlanItem]
    let startedAt = Date.now
    /// True for throwaway quick sessions whose backing Workout should be deleted afterwards.
    let discardWorkoutOnEnd: Bool
    let workoutID: UUID

    private(set) var exerciseIndex = 0
    private(set) var setNumber = 1
    private(set) var logged: [LoggedSet] = []
    var isFinished = false

    // Inputs for the current set.
    var weightInput: Double = 0
    var repsInput: Int = 10

    // Rest timer.
    private(set) var restRemaining: Int = 0
    private(set) var restTotal: Int = 0
    var isResting: Bool { restRemaining > 0 }
    private var restTask: Task<Void, Never>?

    var restFraction: Double {
        guard restTotal > 0 else { return 0 }
        return Double(restRemaining) / Double(restTotal)
    }

    /// What comes after this rest: the next set of the current exercise, or the next exercise.
    var upNext: (exercise: Exercise, label: String)? {
        guard let item = currentItem else { return nil }
        if setNumber <= item.sets {
            return (item.exercise, "Set \(setNumber) of \(item.sets) · \(item.repsLow)–\(item.repsHigh) reps")
        }
        return nil
    }

    init(workout: Workout, discardWorkoutOnEnd: Bool = false) {
        self.workoutName = workout.name
        self.goal = workout.goal
        self.workoutID = workout.id
        self.discardWorkoutOnEnd = discardWorkoutOnEnd
        self.plan = workout.orderedExercises.compactMap { item in
            guard let exercise = item.exercise else { return nil }
            return PlanItem(
                exercise: exercise,
                sets: item.sets,
                repsLow: item.repsLow,
                repsHigh: item.repsHigh,
                restSeconds: item.restSeconds,
                targetWeight: item.targetWeight
            )
        }
        self.repsInput = plan.first?.repsLow ?? 10
        self.weightInput = plan.first?.targetWeight ?? 0
    }

    var currentItem: PlanItem? {
        plan.indices.contains(exerciseIndex) ? plan[exerciseIndex] : nil
    }

    /// The most recent logged set for the current exercise, shown as "Previous".
    var previousSet: LoggedSet? {
        guard let item = currentItem else { return nil }
        return logged.last { $0.exerciseID == item.exercise.id }
    }

    var progressFraction: Double {
        let totalSets = plan.reduce(0) { $0 + $1.sets }
        guard totalSets > 0 else { return 0 }
        return Double(logged.count) / Double(totalSets)
    }

    // MARK: - Set flow

    func completeSet() {
        guard let item = currentItem else { return }
        Haptics.success()
        logged.append(LoggedSet(
            exerciseID: item.exercise.id,
            exerciseName: item.exercise.name,
            setNumber: setNumber,
            reps: repsInput,
            weight: item.exercise.isWeighted ? weightInput : 0
        ))

        if setNumber < item.sets {
            setNumber += 1
            startRest(seconds: item.restSeconds)
        } else {
            advanceExercise()
        }
    }

    func skipExercise() {
        cancelRest()
        advanceExercise()
    }

    private func advanceExercise() {
        if exerciseIndex + 1 < plan.count {
            exerciseIndex += 1
            setNumber = 1
            let next = plan[exerciseIndex]
            repsInput = next.repsLow
            weightInput = next.targetWeight ?? 0
            startRest(seconds: currentRestSecondsBetweenExercises())
        } else {
            finish()
        }
    }

    private func currentRestSecondsBetweenExercises() -> Int {
        max(60, currentItem?.restSeconds ?? 60)
    }

    func finish() {
        cancelRest()
        isFinished = true
        Haptics.success()
    }

    // MARK: - Rest timer

    func startRest(seconds: Int) {
        cancelRest()
        restRemaining = seconds
        restTotal = seconds
        restTask = Task { [weak self] in
            while let self, self.restRemaining > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.restRemaining = max(0, self.restRemaining - 1)
                    if self.restRemaining == 0 {
                        Haptics.medium()
                    }
                }
            }
        }
    }

    func addRest(seconds: Int) {
        guard isResting else { return }
        restRemaining += seconds
    }

    func skipRest() {
        cancelRest()
        restRemaining = 0
    }

    private func cancelRest() {
        restTask?.cancel()
        restTask = nil
        restRemaining = 0
    }

    var restLabel: String {
        String(format: "%02d:%02d", restRemaining / 60, restRemaining % 60)
    }
}
