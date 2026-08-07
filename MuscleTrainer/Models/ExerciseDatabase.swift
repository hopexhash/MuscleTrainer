import Foundation

/// The bundled exercise library. Static, immutable reference data — user data lives in SwiftData.
enum ExerciseDatabase {

    static let all: [Exercise] = chest + shoulders + back + arms + core + legs

    static func exercise(id: String) -> Exercise? {
        byID[id]
    }

    static func exercises(for muscle: Muscle) -> [Exercise] {
        all.filter { $0.primaryMuscles.contains(muscle) || $0.secondaryMuscles.contains(muscle) }
            .sorted { lhs, rhs in
                let l = lhs.primaryMuscles.contains(muscle)
                let r = rhs.primaryMuscles.contains(muscle)
                if l != r { return l }
                return lhs.name < rhs.name
            }
    }

    private static let byID: [String: Exercise] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    // MARK: - Chest

    static let chest: [Exercise] = [
        Exercise(id: "bench-press", name: "Barbell Bench Press", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps],
                 equipment: [.barbell, .bench], difficulty: .intermediate,
                 instructions: [
                    "Lie on the bench with your eyes under the bar and feet planted on the floor.",
                    "Grip the bar slightly wider than shoulder-width and unrack it.",
                    "Lower the bar under control to your mid-chest.",
                    "Press upward until your arms are extended, keeping your shoulders pinned to the bench."
                 ]),
        Exercise(id: "incline-bench-press", name: "Incline Bench Press", category: .compound, pattern: .horizontalPush,
                 primary: [.upperChest, .chest], secondary: [.frontDelts, .triceps],
                 equipment: [.barbell, .bench], difficulty: .intermediate,
                 instructions: [
                    "Set the bench to a 30–45 degree incline.",
                    "Grip the bar slightly wider than shoulder-width.",
                    "Lower the bar to your upper chest under control.",
                    "Drive the bar up and slightly back until lockout."
                 ]),
        Exercise(id: "db-bench-press", name: "Dumbbell Bench Press", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps],
                 equipment: [.dumbbell, .bench], difficulty: .beginner,
                 instructions: [
                    "Lie on a flat bench holding a dumbbell in each hand at chest level.",
                    "Press the dumbbells up until your arms are extended.",
                    "Lower them slowly until your elbows drop just below the bench.",
                    "Keep your wrists stacked over your elbows throughout."
                 ]),
        Exercise(id: "incline-db-press", name: "Incline Dumbbell Press", category: .compound, pattern: .horizontalPush,
                 primary: [.upperChest], secondary: [.frontDelts, .triceps],
                 equipment: [.dumbbell, .bench], difficulty: .beginner,
                 instructions: [
                    "Set the bench to a 30 degree incline and sit back with dumbbells at shoulder height.",
                    "Press the weights up and slightly together.",
                    "Lower under control until you feel a stretch across your upper chest.",
                    "Avoid flaring your elbows past 75 degrees."
                 ]),
        Exercise(id: "db-fly", name: "Dumbbell Fly", category: .isolation, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts],
                 equipment: [.dumbbell, .bench], difficulty: .beginner,
                 instructions: [
                    "Lie flat holding dumbbells above your chest, palms facing each other.",
                    "With a slight elbow bend, open your arms in a wide arc.",
                    "Stop when you feel a deep chest stretch.",
                    "Squeeze the dumbbells back together over your chest."
                 ]),
        Exercise(id: "cable-fly", name: "Cable Fly", category: .isolation, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Set the pulleys to chest height and grab a handle in each hand.",
                    "Step forward with a slight forward lean.",
                    "Bring your hands together in front of your chest in an arc.",
                    "Return slowly, keeping tension on the cables."
                 ]),
        Exercise(id: "low-cable-fly", name: "Low-to-High Cable Fly", category: .isolation, pattern: .horizontalPush,
                 primary: [.upperChest], secondary: [.frontDelts],
                 equipment: [.cable], difficulty: .intermediate,
                 instructions: [
                    "Set both pulleys to the lowest position.",
                    "With a slight elbow bend, sweep the handles up and together to eye level.",
                    "Squeeze the upper chest at the top.",
                    "Lower under control back to the start."
                 ]),
        Exercise(id: "push-up", name: "Push-Up", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps, .abs],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Start in a high plank with hands slightly wider than shoulders.",
                    "Keep your body in a straight line from head to heels.",
                    "Lower your chest to just above the floor.",
                    "Press back up to full arm extension."
                 ], isWeighted: false),
        Exercise(id: "incline-push-up", name: "Incline Push-Up", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Place your hands on an elevated surface like a bench or bar.",
                    "Walk your feet back until your body forms a straight line.",
                    "Lower your chest to the edge of the surface.",
                    "Push back up without letting your hips sag."
                 ], isWeighted: false),
        Exercise(id: "decline-push-up", name: "Decline Push-Up", category: .compound, pattern: .horizontalPush,
                 primary: [.upperChest, .chest], secondary: [.frontDelts, .triceps],
                 equipment: [.bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Place your feet on an elevated surface and hands on the floor.",
                    "Brace your core and keep a straight body line.",
                    "Lower your forehead toward the floor under control.",
                    "Press back up to full extension."
                 ], isWeighted: false),
        Exercise(id: "chest-press-machine", name: "Machine Chest Press", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Adjust the seat so the handles sit at mid-chest height.",
                    "Press the handles forward until your arms are extended.",
                    "Return slowly until your hands are beside your chest.",
                    "Keep your back against the pad the whole time."
                 ]),
        Exercise(id: "pec-deck", name: "Pec Deck", category: .isolation, pattern: .horizontalPush,
                 primary: [.chest], secondary: [],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Sit with your back flat against the pad and forearms on the arm pads.",
                    "Squeeze the pads together in front of your chest.",
                    "Pause briefly at peak contraction.",
                    "Open your arms slowly until you feel a chest stretch."
                 ]),
        Exercise(id: "dips-chest", name: "Chest Dips", category: .compound, pattern: .verticalPush,
                 primary: [.chest], secondary: [.triceps, .frontDelts],
                 equipment: [.bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Grab parallel bars and lift yourself to arm's length.",
                    "Lean your torso forward and bend your knees.",
                    "Lower until your shoulders dip just below your elbows.",
                    "Press back up while keeping the forward lean."
                 ], isWeighted: false),
        Exercise(id: "smith-bench-press", name: "Smith Machine Bench Press", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps],
                 equipment: [.smithMachine, .bench], difficulty: .beginner,
                 instructions: [
                    "Position a flat bench so the bar tracks to your mid-chest.",
                    "Unhook the bar with a grip slightly wider than shoulders.",
                    "Lower to your chest under control.",
                    "Press up until your arms are extended, then re-hook."
                 ]),
        Exercise(id: "band-chest-press", name: "Banded Chest Press", category: .compound, pattern: .horizontalPush,
                 primary: [.chest], secondary: [.frontDelts, .triceps],
                 equipment: [.band], difficulty: .beginner,
                 instructions: [
                    "Anchor a band behind you at chest height.",
                    "Hold a handle in each hand at chest level.",
                    "Press forward until your arms are extended.",
                    "Return slowly, resisting the band."
                 ]),
    ]

    // MARK: - Shoulders

    static let shoulders: [Exercise] = [
        Exercise(id: "ohp", name: "Overhead Press", category: .compound, pattern: .verticalPush,
                 primary: [.frontDelts, .sideDelts], secondary: [.triceps, .upperChest, .abs],
                 equipment: [.barbell], difficulty: .intermediate,
                 instructions: [
                    "Stand with the bar racked at your collarbone, hands just outside shoulders.",
                    "Brace your core and glutes.",
                    "Press the bar overhead in a straight line, moving your head back slightly.",
                    "Lock out with your biceps beside your ears, then lower under control."
                 ]),
        Exercise(id: "db-shoulder-press", name: "Dumbbell Shoulder Press", category: .compound, pattern: .verticalPush,
                 primary: [.frontDelts, .sideDelts], secondary: [.triceps],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Sit or stand with dumbbells at shoulder height, palms forward.",
                    "Press the weights overhead until your arms are extended.",
                    "Avoid arching your lower back.",
                    "Lower slowly back to shoulder height."
                 ]),
        Exercise(id: "arnold-press", name: "Arnold Press", category: .compound, pattern: .verticalPush,
                 primary: [.frontDelts, .sideDelts], secondary: [.triceps],
                 equipment: [.dumbbell], difficulty: .intermediate,
                 instructions: [
                    "Start seated with dumbbells at chest height, palms facing you.",
                    "Rotate your palms outward as you press overhead.",
                    "Finish with palms facing forward at lockout.",
                    "Reverse the rotation on the way down."
                 ]),
        Exercise(id: "lateral-raise", name: "Lateral Raise", category: .isolation, pattern: .isolation,
                 primary: [.sideDelts], secondary: [.traps],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Stand holding light dumbbells at your sides.",
                    "With a soft elbow bend, raise your arms out to shoulder height.",
                    "Lead with your elbows, not your hands.",
                    "Lower slowly — no swinging."
                 ]),
        Exercise(id: "cable-lateral-raise", name: "Cable Lateral Raise", category: .isolation, pattern: .isolation,
                 primary: [.sideDelts], secondary: [],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Set the pulley to the lowest position and stand side-on.",
                    "Grab the handle with your far hand.",
                    "Raise your arm out to shoulder height against the cable.",
                    "Lower under constant tension."
                 ]),
        Exercise(id: "front-raise", name: "Front Raise", category: .isolation, pattern: .isolation,
                 primary: [.frontDelts], secondary: [],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Hold dumbbells in front of your thighs, palms facing you.",
                    "Raise one or both arms straight in front to shoulder height.",
                    "Pause briefly at the top.",
                    "Lower with control."
                 ]),
        Exercise(id: "rear-delt-fly", name: "Rear Delt Fly", category: .isolation, pattern: .isolation,
                 primary: [.rearDelts], secondary: [.upperBack],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Hinge forward until your torso is near parallel to the floor.",
                    "Let the dumbbells hang below your chest.",
                    "Raise your arms out wide, squeezing your shoulder blades.",
                    "Lower slowly without standing up."
                 ]),
        Exercise(id: "face-pull", name: "Face Pull", category: .isolation, pattern: .horizontalPull,
                 primary: [.rearDelts], secondary: [.upperBack, .traps],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Set a rope attachment at upper-chest height.",
                    "Pull the rope toward your face, splitting the ends apart.",
                    "Finish with your hands beside your ears, elbows high.",
                    "Return slowly with control."
                 ]),
        Exercise(id: "reverse-pec-deck", name: "Reverse Pec Deck", category: .isolation, pattern: .isolation,
                 primary: [.rearDelts], secondary: [.upperBack],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Sit facing the pec deck with the handles set rearward.",
                    "Grab the handles with a neutral grip.",
                    "Sweep your arms back in a wide arc.",
                    "Pause, then return under control."
                 ]),
        Exercise(id: "upright-row", name: "Upright Row", category: .compound, pattern: .verticalPull,
                 primary: [.sideDelts, .traps], secondary: [.biceps],
                 equipment: [.barbell], difficulty: .intermediate,
                 instructions: [
                    "Hold a barbell with a shoulder-width grip in front of your thighs.",
                    "Pull the bar up along your body to chest height.",
                    "Keep your elbows above your wrists.",
                    "Lower slowly to the start."
                 ]),
        Exercise(id: "pike-push-up", name: "Pike Push-Up", category: .compound, pattern: .verticalPush,
                 primary: [.frontDelts, .sideDelts], secondary: [.triceps, .upperChest],
                 equipment: [.bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Start in a downward-dog position with hips high.",
                    "Bend your elbows to lower the top of your head toward the floor.",
                    "Keep your hips stacked over your shoulders.",
                    "Press back up to the start."
                 ], isWeighted: false),
        Exercise(id: "band-lateral-raise", name: "Banded Lateral Raise", category: .isolation, pattern: .isolation,
                 primary: [.sideDelts], secondary: [],
                 equipment: [.band], difficulty: .beginner,
                 instructions: [
                    "Stand on the middle of a band, handles at your sides.",
                    "Raise your arms out to shoulder height.",
                    "Pause at the top against band tension.",
                    "Lower slowly."
                 ]),
    ]

    // MARK: - Back

    static let back: [Exercise] = [
        Exercise(id: "pull-up", name: "Pull-Up", category: .compound, pattern: .verticalPull,
                 primary: [.lats], secondary: [.biceps, .upperBack, .rearDelts],
                 equipment: [.pullUpBar, .bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Hang from the bar with an overhand grip slightly wider than shoulders.",
                    "Pull your chest toward the bar by driving your elbows down.",
                    "Get your chin over the bar.",
                    "Lower to a full hang under control."
                 ], isWeighted: false),
        Exercise(id: "chin-up", name: "Chin-Up", category: .compound, pattern: .verticalPull,
                 primary: [.lats, .biceps], secondary: [.upperBack],
                 equipment: [.pullUpBar, .bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Hang from the bar with an underhand, shoulder-width grip.",
                    "Pull yourself up until your chin clears the bar.",
                    "Squeeze your lats and biceps at the top.",
                    "Lower slowly to a dead hang."
                 ], isWeighted: false),
        Exercise(id: "lat-pulldown", name: "Lat Pulldown", category: .compound, pattern: .verticalPull,
                 primary: [.lats], secondary: [.biceps, .upperBack],
                 equipment: [.cable, .machine], difficulty: .beginner,
                 instructions: [
                    "Sit with your thighs secured under the pads.",
                    "Grip the bar wider than shoulder-width.",
                    "Pull the bar to your upper chest, driving elbows down and back.",
                    "Return slowly until your arms are fully extended."
                 ]),
        Exercise(id: "barbell-row", name: "Barbell Row", category: .compound, pattern: .horizontalPull,
                 primary: [.upperBack, .lats], secondary: [.biceps, .lowerBack, .rearDelts],
                 equipment: [.barbell], difficulty: .intermediate,
                 instructions: [
                    "Hinge at the hips with a flat back, bar hanging at arm's length.",
                    "Pull the bar to your lower ribs.",
                    "Squeeze your shoulder blades together at the top.",
                    "Lower under control without standing up."
                 ]),
        Exercise(id: "db-row", name: "Dumbbell Row", category: .compound, pattern: .horizontalPull,
                 primary: [.lats, .upperBack], secondary: [.biceps, .rearDelts],
                 equipment: [.dumbbell, .bench], difficulty: .beginner,
                 instructions: [
                    "Place one hand and knee on a bench, holding a dumbbell in the other hand.",
                    "Keep your back flat and core braced.",
                    "Row the dumbbell to your hip.",
                    "Lower slowly to a full stretch."
                 ]),
        Exercise(id: "seated-cable-row", name: "Seated Cable Row", category: .compound, pattern: .horizontalPull,
                 primary: [.upperBack, .lats], secondary: [.biceps, .rearDelts],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Sit tall with feet braced and grab the handle.",
                    "Pull the handle to your stomach, keeping your chest up.",
                    "Squeeze your shoulder blades together.",
                    "Extend your arms slowly, letting your lats stretch."
                 ]),
        Exercise(id: "tbar-row", name: "T-Bar Row", category: .compound, pattern: .horizontalPull,
                 primary: [.upperBack, .lats], secondary: [.biceps, .lowerBack],
                 equipment: [.barbell, .machine], difficulty: .intermediate,
                 instructions: [
                    "Straddle the bar and grip the handles with a flat back.",
                    "Row the weight toward your chest.",
                    "Keep your torso angle constant.",
                    "Lower under control to a full stretch."
                 ]),
        Exercise(id: "inverted-row", name: "Inverted Row", category: .compound, pattern: .horizontalPull,
                 primary: [.upperBack, .lats], secondary: [.biceps, .rearDelts],
                 equipment: [.bodyweight, .smithMachine], difficulty: .beginner,
                 instructions: [
                    "Set a bar at waist height and hang beneath it, body straight.",
                    "Pull your chest to the bar.",
                    "Keep your hips in line with your shoulders.",
                    "Lower to straight arms."
                 ], isWeighted: false),
        Exercise(id: "deadlift", name: "Deadlift", category: .compound, pattern: .hinge,
                 primary: [.lowerBack, .glutes, .hamstrings], secondary: [.lats, .traps, .quads, .forearms],
                 equipment: [.barbell], difficulty: .advanced,
                 instructions: [
                    "Stand with the bar over mid-foot, grip just outside your legs.",
                    "Set a flat back with hips higher than knees.",
                    "Drive the floor away and stand up with the bar close to your body.",
                    "Lock out tall, then lower with control by pushing your hips back."
                 ]),
        Exercise(id: "rack-pull", name: "Rack Pull", category: .compound, pattern: .hinge,
                 primary: [.lowerBack, .traps], secondary: [.glutes, .lats, .forearms],
                 equipment: [.barbell], difficulty: .intermediate,
                 instructions: [
                    "Set the bar on rack pins at knee height.",
                    "Grip the bar and set a flat back.",
                    "Stand up tall, driving your hips forward.",
                    "Lower back to the pins under control."
                 ]),
        Exercise(id: "back-extension", name: "Back Extension", category: .isolation, pattern: .hinge,
                 primary: [.lowerBack], secondary: [.glutes, .hamstrings],
                 equipment: [.machine, .bodyweight], difficulty: .beginner,
                 instructions: [
                    "Set up on the extension bench with hips on the pad.",
                    "Lower your torso by hinging at the hips.",
                    "Raise back up until your body forms a straight line.",
                    "Avoid hyperextending at the top."
                 ], isWeighted: false),
        Exercise(id: "shrug", name: "Dumbbell Shrug", category: .isolation, pattern: .isolation,
                 primary: [.traps], secondary: [.forearms],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Stand tall holding heavy dumbbells at your sides.",
                    "Shrug your shoulders straight up toward your ears.",
                    "Pause at the top.",
                    "Lower slowly — don't roll your shoulders."
                 ]),
        Exercise(id: "straight-arm-pulldown", name: "Straight-Arm Pulldown", category: .isolation, pattern: .verticalPull,
                 primary: [.lats], secondary: [.triceps],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Stand facing a high pulley with a straight bar.",
                    "With straight arms, sweep the bar down to your thighs.",
                    "Feel your lats drive the movement.",
                    "Return slowly overhead."
                 ]),
        Exercise(id: "band-pull-apart", name: "Band Pull-Apart", category: .isolation, pattern: .horizontalPull,
                 primary: [.rearDelts, .upperBack], secondary: [.traps],
                 equipment: [.band], difficulty: .beginner,
                 instructions: [
                    "Hold a band at shoulder height with straight arms.",
                    "Pull the band apart until it touches your chest.",
                    "Squeeze your shoulder blades together.",
                    "Return slowly with tension."
                 ]),
        Exercise(id: "single-arm-lat-pulldown", name: "Single-Arm Lat Pulldown", category: .isolation, pattern: .verticalPull,
                 primary: [.lats], secondary: [.biceps],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Kneel or sit beside a high pulley with a single handle.",
                    "Pull the handle down toward your hip.",
                    "Focus on driving your elbow into your side.",
                    "Return slowly to a full stretch."
                 ]),
    ]

    // MARK: - Arms

    static let arms: [Exercise] = [
        Exercise(id: "bb-curl", name: "Barbell Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps], secondary: [.forearms],
                 equipment: [.barbell], difficulty: .beginner,
                 instructions: [
                    "Stand holding the bar with an underhand, shoulder-width grip.",
                    "Curl the bar toward your shoulders, keeping elbows at your sides.",
                    "Squeeze at the top.",
                    "Lower slowly to full extension."
                 ]),
        Exercise(id: "db-curl", name: "Dumbbell Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps], secondary: [.forearms],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Stand with dumbbells at your sides, palms forward.",
                    "Curl both weights toward your shoulders.",
                    "Keep your elbows pinned to your ribs.",
                    "Lower under control."
                 ]),
        Exercise(id: "hammer-curl", name: "Hammer Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps, .forearms], secondary: [],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Hold dumbbells with a neutral grip, palms facing each other.",
                    "Curl the weights up without rotating your wrists.",
                    "Squeeze at the top.",
                    "Lower slowly."
                 ]),
        Exercise(id: "incline-curl", name: "Incline Dumbbell Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps], secondary: [.forearms],
                 equipment: [.dumbbell, .bench], difficulty: .intermediate,
                 instructions: [
                    "Sit back on an incline bench with arms hanging straight down.",
                    "Curl the dumbbells while keeping your upper arms vertical.",
                    "Feel the stretch at the bottom of each rep.",
                    "Lower fully before the next rep."
                 ]),
        Exercise(id: "preacher-curl", name: "Preacher Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps], secondary: [.forearms],
                 equipment: [.machine, .barbell], difficulty: .beginner,
                 instructions: [
                    "Rest your upper arms on the preacher pad.",
                    "Curl the weight up until your forearms are vertical.",
                    "Squeeze, then lower slowly.",
                    "Stop just short of full lockout to protect the elbows."
                 ]),
        Exercise(id: "cable-curl", name: "Cable Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps], secondary: [.forearms],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Attach a straight bar to a low pulley.",
                    "Curl the bar to shoulder height with elbows pinned.",
                    "Squeeze at the top.",
                    "Lower under constant cable tension."
                 ]),
        Exercise(id: "band-curl", name: "Banded Curl", category: .isolation, pattern: .isolation,
                 primary: [.biceps], secondary: [.forearms],
                 equipment: [.band], difficulty: .beginner,
                 instructions: [
                    "Stand on the middle of a band holding both handles.",
                    "Curl your hands to your shoulders.",
                    "Keep your elbows still.",
                    "Lower slowly against the band."
                 ]),
        Exercise(id: "close-grip-bench", name: "Close-Grip Bench Press", category: .compound, pattern: .horizontalPush,
                 primary: [.triceps], secondary: [.chest, .frontDelts],
                 equipment: [.barbell, .bench], difficulty: .intermediate,
                 instructions: [
                    "Lie on a flat bench and grip the bar at shoulder width.",
                    "Lower the bar to your lower chest with elbows tucked.",
                    "Keep your forearms vertical.",
                    "Press up to full lockout."
                 ]),
        Exercise(id: "tricep-pushdown", name: "Tricep Pushdown", category: .isolation, pattern: .isolation,
                 primary: [.triceps], secondary: [],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Attach a rope or bar to a high pulley.",
                    "Push the attachment down until your arms are straight.",
                    "Keep your elbows pinned to your sides.",
                    "Return slowly to chest height."
                 ]),
        Exercise(id: "overhead-tricep-ext", name: "Overhead Tricep Extension", category: .isolation, pattern: .isolation,
                 primary: [.triceps], secondary: [],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Hold one dumbbell overhead with both hands.",
                    "Lower the weight behind your head by bending your elbows.",
                    "Keep your upper arms vertical.",
                    "Extend back to the top."
                 ]),
        Exercise(id: "skull-crusher", name: "Skull Crusher", category: .isolation, pattern: .isolation,
                 primary: [.triceps], secondary: [],
                 equipment: [.barbell, .bench], difficulty: .intermediate,
                 instructions: [
                    "Lie on a bench holding an EZ bar above your chest.",
                    "Bend at the elbows to lower the bar toward your forehead.",
                    "Keep your upper arms still.",
                    "Extend back up without flaring your elbows."
                 ]),
        Exercise(id: "bench-dip", name: "Bench Dip", category: .compound, pattern: .verticalPush,
                 primary: [.triceps], secondary: [.chest, .frontDelts],
                 equipment: [.bodyweight, .bench], difficulty: .beginner,
                 instructions: [
                    "Place your hands on a bench behind you, legs extended forward.",
                    "Lower your hips by bending your elbows to about 90 degrees.",
                    "Keep your back close to the bench.",
                    "Press back up to straight arms."
                 ], isWeighted: false),
        Exercise(id: "diamond-push-up", name: "Diamond Push-Up", category: .compound, pattern: .horizontalPush,
                 primary: [.triceps], secondary: [.chest, .frontDelts],
                 equipment: [.bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Form a diamond with your hands under your chest.",
                    "Keep your elbows tracking back as you lower.",
                    "Touch your chest to your hands.",
                    "Press back up to full extension."
                 ], isWeighted: false),
        Exercise(id: "wrist-curl", name: "Wrist Curl", category: .isolation, pattern: .isolation,
                 primary: [.forearms], secondary: [],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Rest your forearms on a bench with wrists hanging off the edge.",
                    "Let the weight roll toward your fingers.",
                    "Curl your wrists up as high as possible.",
                    "Lower slowly."
                 ]),
        Exercise(id: "reverse-curl", name: "Reverse Curl", category: .isolation, pattern: .isolation,
                 primary: [.forearms], secondary: [.biceps],
                 equipment: [.barbell], difficulty: .beginner,
                 instructions: [
                    "Hold the bar with an overhand grip at shoulder width.",
                    "Curl the bar up while keeping your wrists straight.",
                    "Keep your elbows at your sides.",
                    "Lower under control."
                 ]),
        Exercise(id: "farmers-carry", name: "Farmer's Carry", category: .compound, pattern: .carry,
                 primary: [.forearms, .traps], secondary: [.abs, .glutes],
                 equipment: [.dumbbell, .kettlebell], difficulty: .beginner,
                 instructions: [
                    "Pick up a heavy weight in each hand.",
                    "Stand tall with shoulders back and core braced.",
                    "Walk with short, controlled steps.",
                    "Keep your grip tight until the set ends."
                 ]),
    ]

    // MARK: - Core

    static let core: [Exercise] = [
        Exercise(id: "plank", name: "Plank", category: .core, pattern: .coreStability,
                 primary: [.abs], secondary: [.obliques, .lowerBack],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Support yourself on your forearms and toes.",
                    "Form a straight line from head to heels.",
                    "Brace your abs and squeeze your glutes.",
                    "Hold without letting your hips sag or pike."
                 ], isWeighted: false),
        Exercise(id: "crunch", name: "Crunch", category: .core, pattern: .coreFlexion,
                 primary: [.abs], secondary: [],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Lie on your back with knees bent, hands lightly behind your head.",
                    "Curl your shoulder blades off the floor.",
                    "Exhale and squeeze your abs at the top.",
                    "Lower slowly — don't pull on your neck."
                 ], isWeighted: false),
        Exercise(id: "hanging-leg-raise", name: "Hanging Leg Raise", category: .core, pattern: .coreFlexion,
                 primary: [.abs, .hipFlexors], secondary: [.obliques, .forearms],
                 equipment: [.pullUpBar, .bodyweight], difficulty: .advanced,
                 instructions: [
                    "Hang from a bar with straight arms.",
                    "Raise your legs until they're parallel to the floor or higher.",
                    "Curl your pelvis up at the top.",
                    "Lower slowly without swinging."
                 ], isWeighted: false),
        Exercise(id: "hanging-knee-raise", name: "Hanging Knee Raise", category: .core, pattern: .coreFlexion,
                 primary: [.abs, .hipFlexors], secondary: [.forearms],
                 equipment: [.pullUpBar, .bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Hang from a bar with straight arms.",
                    "Draw your knees up toward your chest.",
                    "Pause at the top.",
                    "Lower under control."
                 ], isWeighted: false),
        Exercise(id: "cable-crunch", name: "Cable Crunch", category: .core, pattern: .coreFlexion,
                 primary: [.abs], secondary: [.obliques],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Kneel below a high pulley holding a rope beside your head.",
                    "Crunch your elbows toward your knees.",
                    "Round your spine and squeeze your abs.",
                    "Return slowly to the start."
                 ]),
        Exercise(id: "russian-twist", name: "Russian Twist", category: .core, pattern: .rotation,
                 primary: [.obliques], secondary: [.abs],
                 equipment: [.bodyweight, .dumbbell], difficulty: .beginner,
                 instructions: [
                    "Sit with knees bent and lean back slightly.",
                    "Clasp your hands or hold a weight in front of your chest.",
                    "Rotate your torso side to side.",
                    "Keep your chest tall throughout."
                 ], isWeighted: false),
        Exercise(id: "side-plank", name: "Side Plank", category: .core, pattern: .coreStability,
                 primary: [.obliques], secondary: [.abs],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Lie on your side supported on one forearm.",
                    "Lift your hips to form a straight line.",
                    "Keep your shoulders and hips stacked.",
                    "Hold, then switch sides."
                 ], isWeighted: false),
        Exercise(id: "dead-bug", name: "Dead Bug", category: .core, pattern: .coreStability,
                 primary: [.abs], secondary: [.hipFlexors],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Lie on your back with arms up and knees bent at 90 degrees.",
                    "Lower your opposite arm and leg toward the floor.",
                    "Keep your lower back pressed into the ground.",
                    "Return and switch sides."
                 ], isWeighted: false),
        Exercise(id: "ab-wheel", name: "Ab Wheel Rollout", category: .core, pattern: .coreStability,
                 primary: [.abs], secondary: [.lats, .obliques],
                 equipment: [.bodyweight], difficulty: .advanced,
                 instructions: [
                    "Kneel holding the wheel beneath your shoulders.",
                    "Roll forward as far as you can control.",
                    "Keep your core braced and back flat.",
                    "Pull the wheel back using your abs."
                 ], isWeighted: false),
        Exercise(id: "mountain-climbers", name: "Mountain Climbers", category: .core, pattern: .coreStability,
                 primary: [.abs, .hipFlexors], secondary: [.obliques, .frontDelts],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Start in a high plank.",
                    "Drive one knee toward your chest.",
                    "Switch legs quickly while keeping hips level.",
                    "Maintain a steady rhythm."
                 ], isWeighted: false),
        Exercise(id: "bicycle-crunch", name: "Bicycle Crunch", category: .core, pattern: .rotation,
                 primary: [.obliques, .abs], secondary: [.hipFlexors],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Lie on your back with hands behind your head.",
                    "Bring one elbow to the opposite knee while extending the other leg.",
                    "Alternate sides in a smooth cycle.",
                    "Keep your lower back on the floor."
                 ], isWeighted: false),
        Exercise(id: "pallof-press", name: "Pallof Press", category: .core, pattern: .coreStability,
                 primary: [.obliques, .abs], secondary: [],
                 equipment: [.cable, .band], difficulty: .beginner,
                 instructions: [
                    "Stand side-on to a cable set at chest height.",
                    "Hold the handle at your chest with both hands.",
                    "Press straight out, resisting the rotation.",
                    "Return slowly and keep your hips square."
                 ]),
    ]

    // MARK: - Legs

    static let legs: [Exercise] = [
        Exercise(id: "back-squat", name: "Barbell Back Squat", category: .compound, pattern: .squat,
                 primary: [.quads, .glutes], secondary: [.hamstrings, .lowerBack, .abs, .adductors],
                 equipment: [.barbell], difficulty: .intermediate,
                 instructions: [
                    "Rest the bar on your upper back and stand shoulder-width apart.",
                    "Brace your core and sit down between your hips.",
                    "Descend until your thighs are at least parallel.",
                    "Drive through your whole foot to stand back up."
                 ]),
        Exercise(id: "front-squat", name: "Front Squat", category: .compound, pattern: .squat,
                 primary: [.quads], secondary: [.glutes, .abs, .upperBack],
                 equipment: [.barbell], difficulty: .advanced,
                 instructions: [
                    "Rack the bar across your front delts with elbows high.",
                    "Keep your torso upright as you squat down.",
                    "Descend until your thighs break parallel.",
                    "Drive up while keeping your elbows lifted."
                 ]),
        Exercise(id: "goblet-squat", name: "Goblet Squat", category: .compound, pattern: .squat,
                 primary: [.quads, .glutes], secondary: [.abs, .adductors],
                 equipment: [.dumbbell, .kettlebell], difficulty: .beginner,
                 instructions: [
                    "Hold a dumbbell vertically against your chest.",
                    "Squat down between your knees, keeping your chest tall.",
                    "Go as deep as your mobility allows.",
                    "Stand back up through your heels."
                 ]),
        Exercise(id: "leg-press", name: "Leg Press", category: .compound, pattern: .squat,
                 primary: [.quads, .glutes], secondary: [.hamstrings, .adductors],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Sit in the machine with feet shoulder-width on the platform.",
                    "Lower the platform until your knees reach about 90 degrees.",
                    "Keep your lower back against the pad.",
                    "Press back up without locking your knees hard."
                 ]),
        Exercise(id: "hack-squat", name: "Hack Squat", category: .compound, pattern: .squat,
                 primary: [.quads], secondary: [.glutes],
                 equipment: [.machine], difficulty: .intermediate,
                 instructions: [
                    "Position your shoulders under the pads, feet low on the platform.",
                    "Lower under control until your thighs pass parallel.",
                    "Keep your back flat against the pad.",
                    "Drive up through your mid-foot."
                 ]),
        Exercise(id: "bulgarian-split-squat", name: "Bulgarian Split Squat", category: .compound, pattern: .lunge,
                 primary: [.quads, .glutes], secondary: [.hamstrings, .adductors],
                 equipment: [.dumbbell, .bench, .bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Place your rear foot on a bench behind you.",
                    "Lower straight down until your rear knee nears the floor.",
                    "Keep your front knee tracking over your toes.",
                    "Drive up through your front foot."
                 ]),
        Exercise(id: "walking-lunge", name: "Walking Lunge", category: .compound, pattern: .lunge,
                 primary: [.quads, .glutes], secondary: [.hamstrings, .calves],
                 equipment: [.bodyweight, .dumbbell], difficulty: .beginner,
                 instructions: [
                    "Step forward into a lunge, lowering your back knee toward the floor.",
                    "Keep your torso upright.",
                    "Push off your front foot into the next step.",
                    "Alternate legs with each stride."
                 ], isWeighted: false),
        Exercise(id: "reverse-lunge", name: "Reverse Lunge", category: .compound, pattern: .lunge,
                 primary: [.quads, .glutes], secondary: [.hamstrings],
                 equipment: [.bodyweight, .dumbbell], difficulty: .beginner,
                 instructions: [
                    "Step one foot backward into a lunge.",
                    "Lower your back knee toward the floor.",
                    "Keep most of your weight on the front leg.",
                    "Push back up to standing and switch legs."
                 ], isWeighted: false),
        Exercise(id: "step-up", name: "Step-Up", category: .compound, pattern: .lunge,
                 primary: [.quads, .glutes], secondary: [.hamstrings, .calves],
                 equipment: [.bodyweight, .dumbbell, .bench], difficulty: .beginner,
                 instructions: [
                    "Stand facing a sturdy box or bench.",
                    "Step up, driving through the heel of your top foot.",
                    "Stand fully at the top.",
                    "Lower back down under control."
                 ], isWeighted: false),
        Exercise(id: "leg-extension", name: "Leg Extension", category: .isolation, pattern: .isolation,
                 primary: [.quads], secondary: [],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Sit in the machine with the pad on your lower shins.",
                    "Extend your legs until they're straight.",
                    "Squeeze your quads at the top.",
                    "Lower slowly to the start."
                 ]),
        Exercise(id: "rdl", name: "Romanian Deadlift", category: .compound, pattern: .hinge,
                 primary: [.hamstrings, .glutes], secondary: [.lowerBack, .forearms],
                 equipment: [.barbell], difficulty: .intermediate,
                 instructions: [
                    "Hold the bar at your thighs with a flat back.",
                    "Push your hips back, letting the bar slide down your legs.",
                    "Feel the hamstring stretch just below your knees.",
                    "Drive your hips forward to stand tall."
                 ]),
        Exercise(id: "db-rdl", name: "Dumbbell Romanian Deadlift", category: .compound, pattern: .hinge,
                 primary: [.hamstrings, .glutes], secondary: [.lowerBack],
                 equipment: [.dumbbell], difficulty: .beginner,
                 instructions: [
                    "Hold dumbbells in front of your thighs.",
                    "Hinge at the hips with a soft knee bend.",
                    "Lower the weights along your legs until you feel a stretch.",
                    "Squeeze your glutes to return to standing."
                 ]),
        Exercise(id: "leg-curl", name: "Lying Leg Curl", category: .isolation, pattern: .isolation,
                 primary: [.hamstrings], secondary: [.calves],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Lie face down with the pad on your lower calves.",
                    "Curl your heels toward your glutes.",
                    "Squeeze at the top.",
                    "Lower slowly to full extension."
                 ]),
        Exercise(id: "nordic-curl", name: "Nordic Hamstring Curl", category: .isolation, pattern: .isolation,
                 primary: [.hamstrings], secondary: [.calves],
                 equipment: [.bodyweight], difficulty: .advanced,
                 instructions: [
                    "Kneel with your ankles anchored behind you.",
                    "Lower your torso forward as slowly as possible.",
                    "Catch yourself with your hands at the bottom.",
                    "Push back lightly and pull with your hamstrings to return."
                 ], isWeighted: false),
        Exercise(id: "hip-thrust", name: "Barbell Hip Thrust", category: .compound, pattern: .hinge,
                 primary: [.glutes], secondary: [.hamstrings, .quads],
                 equipment: [.barbell, .bench], difficulty: .intermediate,
                 instructions: [
                    "Sit with your upper back against a bench, bar over your hips.",
                    "Plant your feet flat, hip-width apart.",
                    "Drive your hips up until your torso is level.",
                    "Squeeze your glutes hard at the top, then lower."
                 ]),
        Exercise(id: "glute-bridge", name: "Glute Bridge", category: .compound, pattern: .hinge,
                 primary: [.glutes], secondary: [.hamstrings, .abs],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Lie on your back with knees bent and feet flat.",
                    "Drive your hips toward the ceiling.",
                    "Squeeze your glutes at the top.",
                    "Lower slowly back down."
                 ], isWeighted: false),
        Exercise(id: "cable-kickback", name: "Cable Glute Kickback", category: .isolation, pattern: .isolation,
                 primary: [.glutes], secondary: [.hamstrings],
                 equipment: [.cable], difficulty: .beginner,
                 instructions: [
                    "Attach an ankle cuff to a low pulley.",
                    "Hinge slightly forward holding the frame.",
                    "Kick your leg straight back, squeezing the glute.",
                    "Return under control and repeat."
                 ]),
        Exercise(id: "kb-swing", name: "Kettlebell Swing", category: .compound, pattern: .hinge,
                 primary: [.glutes, .hamstrings], secondary: [.lowerBack, .abs, .frontDelts],
                 equipment: [.kettlebell], difficulty: .intermediate,
                 instructions: [
                    "Hinge and hike the kettlebell back between your legs.",
                    "Snap your hips forward to swing it to chest height.",
                    "Let the bell float — don't lift with your arms.",
                    "Guide it back into the next hinge."
                 ]),
        Exercise(id: "standing-calf-raise", name: "Standing Calf Raise", category: .isolation, pattern: .isolation,
                 primary: [.calves], secondary: [],
                 equipment: [.machine, .bodyweight, .dumbbell], difficulty: .beginner,
                 instructions: [
                    "Stand with the balls of your feet on an edge.",
                    "Lower your heels for a deep stretch.",
                    "Rise as high onto your toes as possible.",
                    "Pause at the top, then lower slowly."
                 ]),
        Exercise(id: "seated-calf-raise", name: "Seated Calf Raise", category: .isolation, pattern: .isolation,
                 primary: [.calves], secondary: [],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Sit with the pad across your knees, balls of feet on the platform.",
                    "Lower your heels to stretch the calves.",
                    "Press up through the balls of your feet.",
                    "Control the descent on every rep."
                 ]),
        Exercise(id: "tibialis-raise", name: "Tibialis Raise", category: .isolation, pattern: .isolation,
                 primary: [.tibialis], secondary: [],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Lean your back against a wall with feet out in front.",
                    "Lift your toes toward your shins as high as possible.",
                    "Pause at the top.",
                    "Lower slowly and repeat."
                 ], isWeighted: false),
        Exercise(id: "adductor-machine", name: "Adductor Machine", category: .isolation, pattern: .isolation,
                 primary: [.adductors], secondary: [],
                 equipment: [.machine], difficulty: .beginner,
                 instructions: [
                    "Sit in the machine with the pads inside your knees.",
                    "Squeeze your legs together against the resistance.",
                    "Pause at full contraction.",
                    "Open slowly to the start."
                 ]),
        Exercise(id: "copenhagen-plank", name: "Copenhagen Plank", category: .core, pattern: .coreStability,
                 primary: [.adductors], secondary: [.obliques, .abs],
                 equipment: [.bodyweight, .bench], difficulty: .advanced,
                 instructions: [
                    "Lie on your side with your top foot on a bench.",
                    "Lift your hips into a side plank supported by the top leg.",
                    "Keep your body in a straight line.",
                    "Hold, then switch sides."
                 ], isWeighted: false),
        Exercise(id: "hip-flexor-raise", name: "Standing Knee Raise", category: .isolation, pattern: .isolation,
                 primary: [.hipFlexors], secondary: [.abs],
                 equipment: [.bodyweight, .band], difficulty: .beginner,
                 instructions: [
                    "Stand tall holding something for balance if needed.",
                    "Drive one knee up above hip height.",
                    "Pause at the top without leaning back.",
                    "Lower slowly and alternate legs."
                 ], isWeighted: false),
        Exercise(id: "smith-squat", name: "Smith Machine Squat", category: .compound, pattern: .squat,
                 primary: [.quads, .glutes], secondary: [.hamstrings],
                 equipment: [.smithMachine], difficulty: .beginner,
                 instructions: [
                    "Set the bar on your upper back and place feet slightly forward.",
                    "Unhook the bar and squat down under control.",
                    "Descend to at least parallel.",
                    "Drive up and re-hook at the end of the set."
                 ]),
        Exercise(id: "jump-squat", name: "Jump Squat", category: .compound, pattern: .squat,
                 primary: [.quads, .glutes], secondary: [.calves, .hamstrings],
                 equipment: [.bodyweight], difficulty: .intermediate,
                 instructions: [
                    "Squat down to about parallel.",
                    "Explode upward into a jump.",
                    "Land softly with bent knees.",
                    "Sink straight into the next rep."
                 ], isWeighted: false),
        Exercise(id: "wall-sit", name: "Wall Sit", category: .isolation, pattern: .squat,
                 primary: [.quads], secondary: [.glutes],
                 equipment: [.bodyweight], difficulty: .beginner,
                 instructions: [
                    "Slide down a wall until your thighs are parallel to the floor.",
                    "Keep your knees at 90 degrees.",
                    "Press your back flat against the wall.",
                    "Hold for the target time."
                 ], isWeighted: false),
    ]
}
