import Foundation

/// Every selectable muscle group in the app.
/// This is the single source of truth linking anatomy regions to exercises.
enum Muscle: String, Codable, CaseIterable, Identifiable, Hashable {
    // Front
    case chest
    case upperChest
    case frontDelts
    case sideDelts
    case biceps
    case forearms
    case abs
    case obliques
    case quads
    case hipFlexors
    case adductors
    case tibialis

    // Back
    case rearDelts
    case traps
    case upperBack
    case lats
    case lowerBack
    case triceps
    case glutes
    case hamstrings
    case calves

    // Other
    case neck
    case fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .upperChest: return "Upper Chest"
        case .frontDelts: return "Front Delts"
        case .sideDelts: return "Side Delts"
        case .rearDelts: return "Rear Delts"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .abs: return "Abs"
        case .obliques: return "Obliques"
        case .quads: return "Quads"
        case .hipFlexors: return "Hip Flexors"
        case .adductors: return "Adductors"
        case .tibialis: return "Tibialis"
        case .calves: return "Calves"
        case .traps: return "Traps"
        case .upperBack: return "Upper Back"
        case .lats: return "Lats"
        case .lowerBack: return "Lower Back"
        case .glutes: return "Glutes"
        case .hamstrings: return "Hamstrings"
        case .neck: return "Neck"
        case .fullBody: return "Full Body"
        }
    }

    var anatomicalName: String {
        switch self {
        case .chest: return "Pectoralis Major"
        case .upperChest: return "Clavicular Pectoralis"
        case .frontDelts: return "Anterior Deltoid"
        case .sideDelts: return "Lateral Deltoid"
        case .rearDelts: return "Posterior Deltoid"
        case .biceps: return "Biceps Brachii"
        case .triceps: return "Triceps Brachii"
        case .forearms: return "Brachioradialis & Flexors"
        case .abs: return "Rectus Abdominis"
        case .obliques: return "External Obliques"
        case .quads: return "Quadriceps Femoris"
        case .hipFlexors: return "Iliopsoas"
        case .adductors: return "Adductor Group"
        case .tibialis: return "Tibialis Anterior"
        case .calves: return "Gastrocnemius & Soleus"
        case .traps: return "Trapezius"
        case .upperBack: return "Rhomboids & Mid Traps"
        case .lats: return "Latissimus Dorsi"
        case .lowerBack: return "Erector Spinae"
        case .glutes: return "Gluteus Maximus"
        case .hamstrings: return "Biceps Femoris & Semitendinosus"
        case .neck: return "Sternocleidomastoid"
        case .fullBody: return "Multiple Muscle Groups"
        }
    }

    /// Broad region used for grouping and workout splits.
    var region: BodyRegion {
        switch self {
        case .chest, .upperChest: return .chest
        case .frontDelts, .sideDelts, .rearDelts: return .shoulders
        case .biceps, .triceps, .forearms: return .arms
        case .abs, .obliques: return .core
        case .traps, .upperBack, .lats, .lowerBack, .neck: return .back
        case .quads, .hipFlexors, .adductors, .tibialis, .calves, .glutes, .hamstrings: return .legs
        case .fullBody: return .fullBody
        }
    }

    /// Muscles that count as "push", "pull" or "legs" for split logic.
    var splitGroup: SplitGroup {
        switch self {
        case .chest, .upperChest, .frontDelts, .sideDelts, .triceps: return .push
        case .lats, .upperBack, .traps, .rearDelts, .biceps, .forearms, .lowerBack, .neck: return .pull
        case .quads, .hamstrings, .glutes, .calves, .adductors, .hipFlexors, .tibialis: return .legs
        case .abs, .obliques, .fullBody: return .core
        }
    }
}

enum BodyRegion: String, Codable, CaseIterable {
    case chest, shoulders, arms, core, back, legs, fullBody

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        case .back: return "Back"
        case .legs: return "Legs"
        case .fullBody: return "Full Body"
        }
    }
}

enum SplitGroup: String, Codable {
    case push, pull, legs, core
}

enum BodySide: String, Codable {
    case front, back
}

enum AnatomyGender: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var displayName: String { self == .male ? "Male" : "Female" }
}
