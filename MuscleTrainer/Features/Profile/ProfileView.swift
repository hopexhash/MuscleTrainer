import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var context
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    profileContent(profile)
                } else {
                    LoadingErrorView()
                }
            }
            .background(AppColor.background)
            .navigationTitle("Profile")
        }
    }

    private func profileContent(_ profile: UserProfile) -> some View {
        @Bindable var profile = profile
        @Bindable var themeManager = themeManager
        return List {
            Section {
                HStack(spacing: DS.spacing) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accent.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Text(initials(profile.name))
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.accent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        TextField("Name", text: $profile.name)
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("\(profile.goal.displayName) • \(profile.experience.displayName)")
                            .font(AppFont.meta)
                            .foregroundStyle(AppColor.textSecondary)
                        Text("\(sessions.count) workouts completed")
                            .font(AppFont.metaSmall)
                            .foregroundStyle(AppColor.accent)
                    }
                }
                .padding(.vertical, DS.spacingS)
            }
            .listRowBackground(AppColor.card)

            Section("Appearance") {
                Picker("Theme", selection: $themeManager.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Anatomy figure", selection: $profile.anatomyGender) {
                    ForEach(AnatomyGender.allCases) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
            }
            .listRowBackground(AppColor.card)

            Section("Training") {
                Picker("Goal", selection: $profile.goal) {
                    ForEach(TrainingGoal.allCases) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
                Picker("Experience", selection: $profile.experience) {
                    ForEach(ExperienceLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                Picker("Location", selection: $profile.location) {
                    ForEach(TrainingLocation.allCases) { location in
                        Text(location.displayName).tag(location)
                    }
                }
                Toggle("Use metric units (kg)", isOn: $profile.usesMetric)
            }
            .listRowBackground(AppColor.card)

            Section("Coming soon") {
                disabledRow("Notifications", icon: "bell.fill")
                disabledRow("Apple Health", icon: "heart.fill")
                disabledRow("Account & Cloud Sync", icon: "icloud.fill")
                disabledRow("Premium", icon: "crown.fill")
            }
            .listRowBackground(AppColor.card)

            Section("About") {
                LabeledContent("Version", value: "1.0")
                Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                    Text("Privacy")
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            .listRowBackground(AppColor.card)
        }
        .scrollContentBackground(.hidden)
        .onChange(of: profile.name) { try? context.save() }
        .onChange(of: profile.goalRaw) { try? context.save() }
        .onChange(of: profile.experienceRaw) { try? context.save() }
        .onChange(of: profile.locationRaw) { try? context.save() }
        .onChange(of: profile.usesMetric) { try? context.save() }
        .onChange(of: profile.anatomyGenderRaw) { try? context.save() }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "A" : letters.uppercased()
    }

    private func disabledRow(_ title: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text("Soon")
                .font(AppFont.metaSmall)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppColor.surface)
                .clipShape(Capsule())
        }
    }
}

/// Shown in the unlikely case the profile store failed to load.
struct LoadingErrorView: View {
    var body: some View {
        EmptyStateView(
            icon: "exclamationmark.icloud",
            title: "Couldn't load your data",
            message: "Please restart the app. If this keeps happening, reinstall to reset local data."
        )
    }
}
