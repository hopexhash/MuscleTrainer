import Foundation
import SwiftData

// MARK: - Saved workout template

@Model
final class Workout {
    var id: UUID
    var name: String
    var createdAt: Date
    var isAIGenerated: Bool
    var goalRaw: String
    var estimatedMinutes: Int
    /// File name of the user's looping cover video (in WorkoutCoverStore.directory).
    var coverVideoFileName: String?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]

    init(
        name: String,
        goal: TrainingGoal = .generalFitness,
        isAIGenerated: Bool = false,
        estimatedMinutes: Int = 45
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.isAIGenerated = isAIGenerated
        self.goalRaw = goal.rawValue
        self.estimatedMinutes = estimatedMinutes
        self.coverVideoFileName = nil
        self.exercises = []
    }

    var goal: TrainingGoal {
        get { TrainingGoal(rawValue: goalRaw) ?? .generalFitness }
        set { goalRaw = newValue.rawValue }
    }

    var orderedExercises: [WorkoutExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var targetMuscles: [Muscle] {
        var seen = Set<Muscle>()
        var result: [Muscle] = []
        for we in orderedExercises {
            if let ex = we.exercise {
                for m in ex.primaryMuscles where !seen.contains(m) {
                    seen.insert(m)
                    result.append(m)
                }
            }
        }
        return result
    }
}

@Model
final class WorkoutExercise {
    var id: UUID
    var exerciseID: String
    var order: Int
    var sets: Int
    var repsLow: Int
    var repsHigh: Int
    var restSeconds: Int
    var targetWeight: Double?
    var workout: Workout?

    init(
        exerciseID: String,
        order: Int,
        sets: Int = 3,
        repsLow: Int = 8,
        repsHigh: Int = 12,
        restSeconds: Int = 75,
        targetWeight: Double? = nil
    ) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.order = order
        self.sets = sets
        self.repsLow = repsLow
        self.repsHigh = repsHigh
        self.restSeconds = restSeconds
        self.targetWeight = targetWeight
    }

    var exercise: Exercise? {
        ExerciseDatabase.exercise(id: exerciseID)
    }

    var repsLabel: String {
        repsLow == repsHigh ? "\(repsLow)" : "\(repsLow)–\(repsHigh)"
    }
}

// MARK: - Completed session history

@Model
final class WorkoutSession {
    var id: UUID
    var workoutName: String
    var startedAt: Date
    var endedAt: Date?
    var goalRaw: String
    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.session)
    var completedSets: [CompletedSet]

    init(workoutName: String, goal: TrainingGoal = .generalFitness) {
        self.id = UUID()
        self.workoutName = workoutName
        self.startedAt = .now
        self.endedAt = nil
        self.goalRaw = goal.rawValue
        self.completedSets = []
    }

    var goal: TrainingGoal {
        get { TrainingGoal(rawValue: goalRaw) ?? .generalFitness }
        set { goalRaw = newValue.rawValue }
    }

    var durationSeconds: Int {
        Int((endedAt ?? .now).timeIntervalSince(startedAt))
    }

    var totalSets: Int { completedSets.count }

    var totalReps: Int { completedSets.reduce(0) { $0 + $1.reps } }

    /// Total volume in kg (weight × reps for weighted sets).
    var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    var trainedMuscles: [Muscle] {
        var counts: [Muscle: Int] = [:]
        for set in completedSets {
            guard let ex = ExerciseDatabase.exercise(id: set.exerciseID) else { continue }
            for m in ex.primaryMuscles { counts[m, default: 0] += 2 }
            for m in ex.secondaryMuscles { counts[m, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }

    /// Muscle → normalized intensity (0...1) for heatmaps.
    var muscleIntensity: [Muscle: Double] {
        var counts: [Muscle: Double] = [:]
        for set in completedSets {
            guard let ex = ExerciseDatabase.exercise(id: set.exerciseID) else { continue }
            for m in ex.primaryMuscles { counts[m, default: 0] += 1 }
            for m in ex.secondaryMuscles { counts[m, default: 0] += 0.4 }
        }
        guard let maxValue = counts.values.max(), maxValue > 0 else { return [:] }
        return counts.mapValues { $0 / maxValue }
    }
}

@Model
final class CompletedSet {
    var id: UUID
    var exerciseID: String
    var exerciseName: String
    var setNumber: Int
    var reps: Int
    var weight: Double
    var completedAt: Date
    var session: WorkoutSession?

    init(exerciseID: String, exerciseName: String, setNumber: Int, reps: Int, weight: Double) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.completedAt = .now
    }
}

// MARK: - User profile & preferences

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var goalRaw: String
    var experienceRaw: String
    var locationRaw: String
    var usesMetric: Bool
    var themeRaw: String
    var anatomyGenderRaw: String
    var hasCompletedOnboarding: Bool
    var favoriteExerciseIDs: [String]

    init() {
        self.id = UUID()
        self.name = "Athlete"
        self.goalRaw = TrainingGoal.buildMuscle.rawValue
        self.experienceRaw = ExperienceLevel.beginner.rawValue
        self.locationRaw = TrainingLocation.gym.rawValue
        self.usesMetric = true
        self.themeRaw = AppTheme.system.rawValue
        self.anatomyGenderRaw = AnatomyGender.male.rawValue
        self.hasCompletedOnboarding = false
        self.favoriteExerciseIDs = []
    }

    var goal: TrainingGoal {
        get { TrainingGoal(rawValue: goalRaw) ?? .buildMuscle }
        set { goalRaw = newValue.rawValue }
    }

    var experience: ExperienceLevel {
        get { ExperienceLevel(rawValue: experienceRaw) ?? .beginner }
        set { experienceRaw = newValue.rawValue }
    }

    var location: TrainingLocation {
        get { TrainingLocation(rawValue: locationRaw) ?? .gym }
        set { locationRaw = newValue.rawValue }
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }

    var anatomyGender: AnatomyGender {
        get { AnatomyGender(rawValue: anatomyGenderRaw) ?? .male }
        set { anatomyGenderRaw = newValue.rawValue }
    }

    var weightUnit: String { usesMetric ? "kg" : "lb" }

    func isFavorite(_ exerciseID: String) -> Bool {
        favoriteExerciseIDs.contains(exerciseID)
    }

    func toggleFavorite(_ exerciseID: String) {
        if let index = favoriteExerciseIDs.firstIndex(of: exerciseID) {
            favoriteExerciseIDs.remove(at: index)
        } else {
            favoriteExerciseIDs.append(exerciseID)
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
