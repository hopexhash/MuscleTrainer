import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles: [UserProfile]

    var body: some View {
        @Bindable var appState = appState
        Group {
            if let profile = profiles.first, !profile.hasCompletedOnboarding {
                OnboardingView(profile: profile)
            } else {
                mainTabs
            }
        }
        .fullScreenCover(item: $appState.activeWorkout) { controller in
            ActiveWorkoutView(controller: controller)
        }
        .sheet(item: $appState.exerciseToAdd) { exercise in
            AddToWorkoutSheet(exercise: exercise)
                .presentationDetents([.medium, .large])
        }
    }

    private var mainTabs: some View {
        @Bindable var appState = appState
        return TabView(selection: $appState.selectedTab) {
            AnatomyView()
                .tabItem { Label("Body", systemImage: "figure.stand") }
                .tag(AppState.Tab.body)

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "list.bullet.rectangle.fill") }
                .tag(AppState.Tab.workouts)

            AICoachView()
                .tabItem { Label("AI Coach", systemImage: "sparkles") }
                .tag(AppState.Tab.aiCoach)

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(AppState.Tab.progress)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppState.Tab.profile)
        }
    }
}
