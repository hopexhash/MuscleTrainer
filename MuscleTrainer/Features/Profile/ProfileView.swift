import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var context
    @Environment(ThemeManager.self) private var themeManager
    @Environment(MediaService.self) private var mediaService

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
        @Bindable var mediaService = mediaService
        return List {
            Section {
                HStack(spacing: DS.spacing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.118, green: 0.306, blue: 0.502),
                                        AppColor.bodyLimb,
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                        Text(initials(profile.name))
                            .font(.system(size: 22, weight: .semibold))
                            .kerning(-0.5)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Name", text: $profile.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                        HStack(spacing: 7) {
                            Text(profile.goal.displayName)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(AppColor.accentBright)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColor.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            Text(profile.experience.displayName)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        Text("\(sessions.count) workouts completed")
                            .font(AppFont.metaSmall)
                            .foregroundStyle(AppColor.textTertiary)
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

            Section {
                TextField("https://your-media-server.example", text: $mediaService.serverURLString)
                    .font(AppFont.body)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await mediaService.refresh() }
                    }
                HStack {
                    if mediaService.isLoading {
                        ProgressView()
                        Text("Checking…")
                            .font(AppFont.meta)
                            .foregroundStyle(AppColor.textSecondary)
                    } else if let error = mediaService.lastError {
                        Text(error)
                            .font(AppFont.meta)
                            .foregroundStyle(AppColor.destructive)
                    } else if !mediaService.isConfigured {
                        Text("Run the bundled media server and paste its URL to see your own demo videos.")
                            .font(AppFont.meta)
                            .foregroundStyle(AppColor.textSecondary)
                    } else {
                        Text("\(mediaService.videos.count) exercise video\(mediaService.videos.count == 1 ? "" : "s") linked")
                            .font(AppFont.meta)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    Button("Refresh") {
                        Task { await mediaService.refresh() }
                    }
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.accent)
                    .disabled(!mediaService.isConfigured || mediaService.isLoading)
                }
            } header: {
                Text("Exercise videos")
            } footer: {
                Text("Videos you upload in the server's admin page play as loops on exercise pages and in the workout player.")
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
                NavigationLink("Privacy & Terms") {
                    PrivacyPolicyView()
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
