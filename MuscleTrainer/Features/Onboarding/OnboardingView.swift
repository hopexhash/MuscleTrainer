import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    @State private var page = 0

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(DS.spacing)
                }

                TabView(selection: $page) {
                    intro1.tag(0)
                    intro2.tag(1)
                    setup.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))

                PrimaryButton(title: page < 2 ? "Continue" : "Start Training") {
                    if page < 2 {
                        withAnimation(DS.smooth) { page += 1 }
                    } else {
                        finish()
                    }
                }
                .padding(.horizontal, DS.spacingXL)
                .padding(.bottom, DS.spacingL)
            }
        }
    }

    private func finish() {
        Haptics.success()
        profile.hasCompletedOnboarding = true
        try? context.save()
    }

    private var intro1: some View {
        VStack(spacing: DS.spacingL) {
            AnatomyFigureView(side: .front, gender: .male, selectedMuscles: [.chest], isInteractive: false)
                .frame(maxHeight: 340)
            Text("Train smarter.")
                .font(AppFont.hero)
                .foregroundStyle(AppColor.textPrimary)
            Text("Tap a muscle. Find the right exercises.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DS.spacingXL)
    }

    private var intro2: some View {
        VStack(spacing: DS.spacingL) {
            ZStack {
                Circle()
                    .fill(AppColor.accent.opacity(0.12))
                    .frame(width: 180, height: 180)
                Image(systemName: "sparkles")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(AppColor.accent)
            }
            .frame(maxHeight: 340)
            Text("Workouts built for you.")
                .font(AppFont.hero)
                .foregroundStyle(AppColor.textPrimary)
            Text("Tell the AI what you want to train.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DS.spacingXL)
    }

    private var setup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.spacingL) {
                Text("About you")
                    .font(AppFont.pageTitle)
                    .foregroundStyle(AppColor.textPrimary)

                VStack(alignment: .leading, spacing: DS.spacingS) {
                    Text("Training goal")
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textSecondary)
                    optionRow(TrainingGoal.allCases, selected: profile.goal, label: \.displayName) {
                        profile.goal = $0
                    }
                }

                VStack(alignment: .leading, spacing: DS.spacingS) {
                    Text("Experience")
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textSecondary)
                    optionRow(ExperienceLevel.allCases, selected: profile.experience, label: \.displayName) {
                        profile.experience = $0
                    }
                }

                VStack(alignment: .leading, spacing: DS.spacingS) {
                    Text("Where you train")
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textSecondary)
                    optionRow(TrainingLocation.allCases, selected: profile.location, label: \.displayName) {
                        profile.location = $0
                    }
                }
            }
            .padding(DS.spacingL)
        }
    }

    private func optionRow<T: Hashable & Identifiable>(
        _ options: [T],
        selected: T,
        label: (T) -> String,
        onPick: @escaping (T) -> Void
    ) -> some View {
        FlowChips(options: options, selected: selected, label: label, onPick: onPick)
    }
}

/// Wrapping chip row used on the onboarding setup page.
private struct FlowChips<T: Hashable & Identifiable>: View {
    let options: [T]
    let selected: T
    let label: (T) -> String
    let onPick: (T) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: DS.spacingS)], alignment: .leading, spacing: DS.spacingS) {
            ForEach(options) { option in
                FilterChip(title: label(option), isSelected: option == selected) {
                    onPick(option)
                }
            }
        }
    }
}
