import Foundation

// MARK: - Request / result types

struct WorkoutRequest {
    var focus: TrainingFocus = .fullBody
    var customMuscles: Set<Muscle> = []
    var goal: TrainingGoal = .buildMuscle
    var experience: ExperienceLevel = .beginner
    var location: TrainingLocation = .gym
    var equipment: Set<Equipment> = [.bodyweight]
    var durationMinutes: Int = 45
    /// 0 = easy … 3 = brutal
    var intensity: Int = 1

    var targetMuscles: [Muscle] {
        switch focus {
        case .fullBody:
            return [.chest, .lats, .frontDelts, .quads, .hamstrings, .glutes, .abs, .biceps, .triceps]
        case .upperBody:
            return [.chest, .lats, .upperBack, .frontDelts, .sideDelts, .biceps, .triceps]
        case .lowerBody, .legs:
            return [.quads, .hamstrings, .glutes, .calves, .adductors]
        case .push:
            return [.chest, .upperChest, .frontDelts, .sideDelts, .triceps]
        case .pull:
            return [.lats, .upperBack, .traps, .rearDelts, .biceps, .forearms]
        case .custom:
            return Array(customMuscles)
        }
    }
}

enum TrainingFocus: String, CaseIterable, Identifiable {
    case fullBody, upperBody, lowerBody, push, pull, legs, custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .custom: return "Select Muscles"
        }
    }

    var icon: String {
        switch self {
        case .fullBody: return "figure.arms.open"
        case .upperBody: return "figure.strengthtraining.traditional"
        case .lowerBody: return "figure.walk"
        case .push: return "arrow.up.circle"
        case .pull: return "arrow.down.circle"
        case .legs: return "figure.run"
        case .custom: return "hand.tap"
        }
    }
}

struct GeneratedWorkout {
    var name: String
    var goal: TrainingGoal
    var estimatedMinutes: Int
    var items: [GeneratedItem]

    struct GeneratedItem: Identifiable {
        let id = UUID()
        var exercise: Exercise
        var sets: Int
        var repsLow: Int
        var repsHigh: Int
        var restSeconds: Int
    }

    var targetMuscles: [Muscle] {
        var seen = Set<Muscle>()
        var result: [Muscle] = []
        for item in items {
            for m in item.exercise.primaryMuscles where !seen.contains(m) {
                seen.insert(m)
                result.append(m)
            }
        }
        return result
    }
}

enum AIGenerationError: LocalizedError {
    case noExercisesAvailable

    var errorDescription: String? {
        switch self {
        case .noExercisesAvailable:
            return "No exercises match your equipment and muscle selection. Try adding more equipment or muscle groups."
        }
    }
}

// MARK: - Service abstraction

/// Abstraction point for workout generation. The local rule-based generator
/// ships today; a remote LLM-backed implementation can be swapped in later
/// without touching any UI.
protocol AIWorkoutService {
    func generateWorkout(for request: WorkoutRequest) async throws -> GeneratedWorkout
}

// MARK: - Local deterministic generator

struct LocalWorkoutGenerator: AIWorkoutService {

    func generateWorkout(for request: WorkoutRequest) async throws -> GeneratedWorkout {
        // Brief, honest pause so the generation screen can show its progress states.
        try? await Task.sleep(for: .milliseconds(1600))

        let candidates = candidateExercises(for: request)
        guard !candidates.isEmpty else { throw AIGenerationError.noExercisesAvailable }

        let exerciseCount = targetExerciseCount(for: request)
        let picked = pickBalanced(from: candidates, targets: request.targetMuscles, count: exerciseCount)
        guard !picked.isEmpty else { throw AIGenerationError.noExercisesAvailable }

        let items = picked.map { prescription(for: $0, request: request) }
        let estimated = estimateMinutes(items: items)

        return GeneratedWorkout(
            name: workoutName(for: request),
            goal: request.goal,
            estimatedMinutes: estimated,
            items: items
        )
    }

    // MARK: Candidate filtering

    private func candidateExercises(for request: WorkoutRequest) -> [Exercise] {
        let targets = Set(request.targetMuscles)
        return ExerciseDatabase.all.filter { exercise in
            guard exercise.difficulty <= request.experience.maxDifficulty else { return false }
            guard exercise.equipment.contains(where: { request.equipment.contains($0) }) else { return false }
            return exercise.primaryMuscles.contains(where: targets.contains)
        }
    }

    /// Compounds first, then isolation, while spreading volume across all targets.
    private func pickBalanced(from candidates: [Exercise], targets: [Muscle], count: Int) -> [Exercise] {
        var remaining = candidates
        var picked: [Exercise] = []
        var muscleLoad: [Muscle: Int] = [:]

        func score(_ exercise: Exercise) -> Int {
            var s = 0
            if exercise.category == .compound { s += 30 }
            // Prefer under-served target muscles.
            let load = exercise.primaryMuscles
                .filter { targets.contains($0) }
                .map { muscleLoad[$0, default: 0] }
                .min() ?? 3
            s += max(0, 25 - load * 12)
            return s
        }

        while picked.count < count, !remaining.isEmpty {
            guard let best = remaining.max(by: { score($0) < score($1) }) else { break }
            picked.append(best)
            remaining.removeAll { $0.id == best.id }
            for m in best.primaryMuscles { muscleLoad[m, default: 0] += 1 }
            // Avoid stacking many movements with the identical pattern.
            let patternCount = picked.filter { $0.pattern == best.pattern }.count
            if patternCount >= 3 {
                remaining.removeAll { $0.pattern == best.pattern }
            }
        }

        // Order: compounds → isolation/core.
        return picked.sorted { lhs, rhs in
            let l = lhs.category == .compound ? 0 : 1
            let r = rhs.category == .compound ? 0 : 1
            if l != r { return l < r }
            return lhs.name < rhs.name
        }
    }

    private func targetExerciseCount(for request: WorkoutRequest) -> Int {
        let base: Int
        switch request.durationMinutes {
        case ..<25: base = 4
        case ..<35: base = 5
        case ..<50: base = 6
        case ..<65: base = 7
        default: base = 8
        }
        let intensityBonus = request.intensity >= 3 ? 1 : 0
        let beginnerPenalty = request.experience == .beginner ? -1 : 0
        return max(3, base + intensityBonus + beginnerPenalty)
    }

    // MARK: Set/rep prescription

    private func prescription(for exercise: Exercise, request: WorkoutRequest) -> GeneratedWorkout.GeneratedItem {
        var sets: Int
        var repsLow: Int
        var repsHigh: Int
        var rest: Int

        switch request.goal {
        case .strength:
            sets = 4; repsLow = 4; repsHigh = 6; rest = 150
        case .buildMuscle:
            sets = exercise.category == .compound ? 4 : 3
            repsLow = exercise.category == .compound ? 8 : 10
            repsHigh = exercise.category == .compound ? 10 : 12
            rest = exercise.category == .compound ? 90 : 60
        case .fatLoss:
            sets = 3; repsLow = 12; repsHigh = 15; rest = 45
        case .endurance:
            sets = 3; repsLow = 15; repsHigh = 20; rest = 40
        case .generalFitness:
            sets = 3; repsLow = 10; repsHigh = 12; rest = 60
        }

        // Isolation work never goes ultra-heavy, even on strength days.
        if request.goal == .strength && exercise.category != .compound {
            repsLow = 8; repsHigh = 10; rest = 90
        }

        // Intensity nudges volume, never past safe bounds.
        switch request.intensity {
        case 0: sets = max(2, sets - 1); rest += 15
        case 2: rest = max(30, rest - 15)
        case 3: sets += 1; rest = max(30, rest - 15)
        default: break
        }

        if request.experience == .beginner {
            sets = min(sets, 3)
        }

        return GeneratedWorkout.GeneratedItem(
            exercise: exercise, sets: sets, repsLow: repsLow, repsHigh: repsHigh, restSeconds: rest
        )
    }

    private func estimateMinutes(items: [GeneratedWorkout.GeneratedItem]) -> Int {
        let seconds = items.reduce(0) { total, item in
            total + item.sets * (45 + item.restSeconds)
        }
        return max(15, Int((Double(seconds) / 60).rounded()) + 5)
    }

    private func workoutName(for request: WorkoutRequest) -> String {
        switch request.focus {
        case .fullBody: return "Full Body Session"
        case .upperBody: return "Upper Body Session"
        case .lowerBody: return "Lower Body Session"
        case .push: return "Push Day"
        case .pull: return "Pull Day"
        case .legs: return "Leg Day"
        case .custom:
            let names = request.targetMuscles.prefix(2).map(\.displayName)
            return names.isEmpty ? "Custom Session" : names.joined(separator: " + ")
        }
    }
}

// MARK: - Smart swap suggestions

enum ExerciseSwapper {
    /// Suggests replacements sharing the primary muscle, preferring the same
    /// movement pattern and the user's available equipment.
    static func alternatives(
        for exercise: Exercise,
        equipment: Set<Equipment>?,
        limit: Int = 6
    ) -> [Exercise] {
        let primary = exercise.primaryMuscle
        return ExerciseDatabase.all
            .filter { $0.id != exercise.id && $0.primaryMuscles.contains(primary) }
            .sorted { lhs, rhs in swapScore(lhs, like: exercise, equipment: equipment) > swapScore(rhs, like: exercise, equipment: equipment) }
            .prefix(limit)
            .map { $0 }
    }

    private static func swapScore(_ candidate: Exercise, like original: Exercise, equipment: Set<Equipment>?) -> Int {
        var score = 0
        if candidate.pattern == original.pattern { score += 40 }
        if candidate.category == original.category { score += 15 }
        if candidate.difficulty == original.difficulty { score += 10 }
        if let equipment, candidate.equipment.contains(where: equipment.contains) { score += 25 }
        return score
    }
}
