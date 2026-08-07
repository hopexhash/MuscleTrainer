import Foundation

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case bodyweight
    case dumbbell
    case barbell
    case bench
    case cable
    case machine
    case smithMachine
    case band
    case kettlebell
    case pullUpBar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bodyweight: return "Bodyweight"
        case .dumbbell: return "Dumbbells"
        case .barbell: return "Barbell"
        case .bench: return "Bench"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .smithMachine: return "Smith Machine"
        case .band: return "Bands"
        case .kettlebell: return "Kettlebell"
        case .pullUpBar: return "Pull-Up Bar"
        }
    }

    var icon: String {
        switch self {
        case .bodyweight: return "figure.strengthtraining.functional"
        case .dumbbell: return "dumbbell.fill"
        case .barbell: return "figure.strengthtraining.traditional"
        case .bench: return "rectangle.portrait.fill"
        case .cable: return "cable.connector"
        case .machine: return "gearshape.2.fill"
        case .smithMachine: return "square.grid.3x1.below.line.grid.1x2"
        case .band: return "circle.dotted"
        case .kettlebell: return "scalemass.fill"
        case .pullUpBar: return "figure.play"
        }
    }
}

enum Difficulty: Int, Codable, CaseIterable, Identifiable, Comparable {
    case beginner = 0
    case intermediate = 1
    case advanced = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum MovementPattern: String, Codable {
    case horizontalPush
    case verticalPush
    case horizontalPull
    case verticalPull
    case squat
    case hinge
    case lunge
    case isolation
    case carry
    case coreFlexion
    case coreStability
    case rotation
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case compound
    case isolation
    case core
    case cardio

    var displayName: String {
        switch self {
        case .compound: return "Compound"
        case .isolation: return "Isolation"
        case .core: return "Core"
        case .cardio: return "Cardio"
        }
    }
}

/// Media abstraction — supports future bundled animations, video and remote assets.
enum ExerciseMedia: Codable, Hashable {
    case localVideo(String)
    case remoteVideo(URL)
    case image(String)
    case animation(String)
    /// No real media yet — the UI shows a clearly-labeled placeholder.
    case placeholder(systemImage: String)
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let pattern: MovementPattern
    let primaryMuscles: [Muscle]
    let secondaryMuscles: [Muscle]
    let equipment: [Equipment]
    let difficulty: Difficulty
    let instructions: [String]
    let media: ExerciseMedia
    /// True when the movement can be loaded with meaningful weight (used for volume math).
    let isWeighted: Bool

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        pattern: MovementPattern,
        primary: [Muscle],
        secondary: [Muscle] = [],
        equipment: [Equipment],
        difficulty: Difficulty,
        instructions: [String],
        isWeighted: Bool = true,
        media: ExerciseMedia? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.pattern = pattern
        self.primaryMuscles = primary
        self.secondaryMuscles = secondary
        self.equipment = equipment
        self.difficulty = difficulty
        self.instructions = instructions
        self.isWeighted = isWeighted
        self.media = media ?? .placeholder(systemImage: "figure.strengthtraining.traditional")
    }

    var primaryMuscle: Muscle { primaryMuscles.first ?? .fullBody }

    /// Text blob used by search.
    var searchText: String {
        var parts = [name]
        parts.append(contentsOf: primaryMuscles.map { $0.displayName + " " + $0.anatomicalName })
        parts.append(contentsOf: secondaryMuscles.map(\.displayName))
        parts.append(contentsOf: equipment.map(\.displayName))
        parts.append(difficulty.displayName)
        parts.append(primaryMuscle.region.displayName)
        return parts.joined(separator: " ").lowercased()
    }

    /// Sensible set/rep guidance shown on the detail screen.
    func recommendation(for goal: TrainingGoal) -> SetRecommendation {
        switch goal {
        case .strength:
            return SetRecommendation(title: "Strength", sets: "3–5 sets", reps: "3–6 reps", rest: "2–3 min rest")
        case .buildMuscle:
            return SetRecommendation(title: "Hypertrophy", sets: "3–4 sets", reps: "8–12 reps", rest: "60–90 sec rest")
        case .fatLoss:
            return SetRecommendation(title: "Fat Loss", sets: "3 sets", reps: "10–15 reps", rest: "45–60 sec rest")
        case .endurance:
            return SetRecommendation(title: "Endurance", sets: "2–3 sets", reps: "15–25 reps", rest: "30–45 sec rest")
        case .generalFitness:
            return SetRecommendation(title: "General Fitness", sets: "3 sets", reps: "10–12 reps", rest: "60 sec rest")
        }
    }
}

struct SetRecommendation {
    let title: String
    let sets: String
    let reps: String
    let rest: String
}

enum TrainingGoal: String, Codable, CaseIterable, Identifiable {
    case buildMuscle
    case strength
    case fatLoss
    case endurance
    case generalFitness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .buildMuscle: return "Build Muscle"
        case .strength: return "Strength"
        case .fatLoss: return "Fat Loss"
        case .endurance: return "Endurance"
        case .generalFitness: return "General Fitness"
        }
    }

    var icon: String {
        switch self {
        case .buildMuscle: return "figure.arms.open"
        case .strength: return "bolt.fill"
        case .fatLoss: return "flame.fill"
        case .endurance: return "figure.run"
        case .generalFitness: return "heart.fill"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var maxDifficulty: Difficulty {
        switch self {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .advanced: return .advanced
        }
    }
}

enum TrainingLocation: String, Codable, CaseIterable, Identifiable {
    case gym, home, outdoors

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gym: return "Gym"
        case .home: return "Home"
        case .outdoors: return "Outdoors"
        }
    }

    var icon: String {
        switch self {
        case .gym: return "building.2.fill"
        case .home: return "house.fill"
        case .outdoors: return "leaf.fill"
        }
    }

    /// Equipment options offered for this location in the AI questionnaire.
    var availableEquipment: [Equipment] {
        switch self {
        case .gym:
            return [.barbell, .dumbbell, .bench, .cable, .machine, .smithMachine, .kettlebell, .pullUpBar, .band, .bodyweight]
        case .home:
            return [.bodyweight, .dumbbell, .band, .kettlebell, .bench, .pullUpBar, .barbell]
        case .outdoors:
            return [.bodyweight, .band, .pullUpBar, .kettlebell]
        }
    }
}
