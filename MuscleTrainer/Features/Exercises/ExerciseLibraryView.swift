import SwiftUI
import SwiftData

/// Exercise list for a muscle, or the full searchable library when `muscle` is nil.
struct ExerciseLibraryView: View {
    var muscle: Muscle?

    @State private var searchText = ""
    @State private var filter: LibraryFilter = .all

    enum LibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case bodyweight = "Bodyweight"
        case dumbbells = "Dumbbells"
        case barbell = "Barbell"
        case machine = "Machine"
        case cable = "Cable"

        var id: String { rawValue }

        func matches(_ exercise: Exercise) -> Bool {
            switch self {
            case .all: return true
            case .beginner: return exercise.difficulty == .beginner
            case .intermediate: return exercise.difficulty == .intermediate
            case .advanced: return exercise.difficulty == .advanced
            case .bodyweight: return exercise.equipment.contains(.bodyweight)
            case .dumbbells: return exercise.equipment.contains(.dumbbell)
            case .barbell: return exercise.equipment.contains(.barbell)
            case .machine: return exercise.equipment.contains(.machine)
            case .cable: return exercise.equipment.contains(.cable)
            }
        }
    }

    private var baseExercises: [Exercise] {
        if let muscle {
            return ExerciseDatabase.exercises(for: muscle)
        }
        return ExerciseDatabase.all.sorted { $0.name < $1.name }
    }

    private var filtered: [Exercise] {
        var result = baseExercises.filter { filter.matches($0) }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            let terms = query.split(separator: " ").map(String.init)
            result = result.filter { exercise in
                terms.allSatisfy { exercise.searchText.contains($0) }
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DS.spacingM, pinnedViews: []) {
                filterChips
                if filtered.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No exercises found",
                        message: "Try a different search or filter."
                    )
                    .padding(.top, DS.spacingXXL)
                } else {
                    ForEach(filtered) { exercise in
                        NavigationLink(value: exercise.id) {
                            ExerciseCard(exercise: exercise)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            .padding(.horizontal, DS.spacing)
            .padding(.bottom, DS.spacingXL)
        }
        .background(AppColor.background)
        .navigationTitle(muscle?.displayName ?? "Exercises")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search exercises")
        .navigationDestination(for: String.self) { exerciseID in
            if let exercise = ExerciseDatabase.exercise(id: exerciseID) {
                ExerciseDetailView(exercise: exercise)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if muscle != nil {
                Text("\(baseExercises.count) exercises")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.spacingL)
                    .padding(.bottom, DS.spacingXS)
                    .background(AppColor.background)
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.spacingS) {
                ForEach(LibraryFilter.allCases) { option in
                    FilterChip(title: option.rawValue, isSelected: filter == option) {
                        withAnimation(DS.quick) { filter = option }
                    }
                }
            }
            .padding(.vertical, DS.spacingS)
        }
    }
}

// MARK: - Exercise card

struct ExerciseCard: View {
    let exercise: Exercise
    var showsAddButton: Bool = true

    @Environment(AppState.self) private var appState
    @Environment(MediaService.self) private var mediaService
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context

    private var profile: UserProfile? { profiles.first }

    private var hasVideo: Bool {
        mediaService.videoURL(for: exercise.id) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Media header: the user's looping video when uploaded, else the figure.
            ZStack {
                LinearGradient(
                    colors: [AppColor.surface, AppColor.bodyLimb],
                    startPoint: .top, endPoint: .bottom
                )
                if let url = mediaService.videoURL(for: exercise.id) {
                    LoopingVideoView(url: url)
                } else {
                    ExerciseFigureThumb(exercise: exercise, gender: profile?.anatomyGender ?? .male)
                        .padding(.vertical, 8)
                }
            }
            .frame(height: 132)
            .clipped()
            .overlay(alignment: .topTrailing) {
                Button {
                    guard let profile else { return }
                    Haptics.selection()
                    profile.toggleFavorite(exercise.id)
                    try? context.save()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isFavorite ? AppColor.accentBright : AppColor.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColor.background.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(12)
                .accessibilityLabel(isFavorite ? "Remove \(exercise.name) from favorites" : "Add \(exercise.name) to favorites")
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .kerning(-0.4)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if showsAddButton {
                        Button {
                            appState.exerciseToAdd = exercise
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColor.accentBright)
                                .frame(width: 28, height: 28)
                                .background(AppColor.accent.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(exercise.name) to a workout")
                    }
                }
                HStack(spacing: 7) {
                    infoChip(exercise.equipment.first?.displayName ?? "—")
                    infoChip(exercise.difficulty.displayName)
                }
                .padding(.top, 8)
                Text(targetLine)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(1)
                    .padding(.top, 9)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
        }
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusL - 2, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusL - 2, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
    }

    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var isFavorite: Bool {
        profile?.isFavorite(exercise.id) ?? false
    }

    private var targetLine: String {
        (exercise.primaryMuscles + exercise.secondaryMuscles)
            .prefix(3)
            .map(\.displayName)
            .joined(separator: " • ")
    }
}
