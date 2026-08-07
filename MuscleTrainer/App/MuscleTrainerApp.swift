import SwiftUI
import SwiftData

@main
struct MuscleTrainerApp: App {
    let container: ModelContainer
    @State private var themeManager = ThemeManager()
    @State private var appState = AppState()
    @State private var mediaService = MediaService()

    init() {
        do {
            container = try ModelContainer(
                for: Workout.self, WorkoutExercise.self, WorkoutSession.self,
                CompletedSet.self, UserProfile.self
            )
            SeedService.seedIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(themeManager)
                .environment(appState)
                .environment(mediaService)
                .preferredColorScheme(themeManager.colorScheme)
                .tint(AppColor.accent)
        }
        .modelContainer(container)
    }
}
