import SwiftUI
import SwiftData

struct AICoachView: View {
    @Query private var profiles: [UserProfile]
    @State private var showQuestionnaire = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: DS.spacingL) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(AppColor.accent.opacity(0.12))
                            .frame(width: 140, height: 140)
                        Image(systemName: "sparkles")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(AppColor.accent)
                    }

                    Text("What are we training today?")
                        .font(AppFont.hero)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Tell me your goal and I'll build the session.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    PrimaryButton(title: "Create Workout", icon: "sparkles") {
                        showQuestionnaire = true
                    }
                    .padding(.horizontal, DS.spacingXL)
                    .padding(.bottom, DS.spacingXL)
                }
                .padding(.horizontal, DS.spacing)
            }
            .navigationTitle("AI Coach")
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showQuestionnaire) {
                AIWorkoutFlowView(profile: profiles.first)
            }
        }
    }
}
