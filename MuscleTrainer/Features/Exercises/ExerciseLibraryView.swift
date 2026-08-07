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
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        HStack(spacing: DS.spacingM) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                    .fill(AppColor.surface)
                    .frame(width: 56, height: 56)
                Image(systemName: mediaIcon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(AppColor.accent.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                DifficultyBadge(difficulty: exercise.difficulty)
            }

            Spacer()

            VStack(spacing: DS.spacingM) {
                Button {
                    guard let profile else { return }
                    Haptics.selection()
                    profile.toggleFavorite(exercise.id)
                    try? context.save()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isFavorite ? AppColor.accent : AppColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove \(exercise.name) from favorites" : "Add \(exercise.name) to favorites")

                if showsAddButton {
                    Button {
                        appState.exerciseToAdd = exercise
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(exercise.name) to a workout")
                }
            }
        }
        .cardStyle(padding: DS.spacingM)
    }

    private var isFavorite: Bool {
        profile?.isFavorite(exercise.id) ?? false
    }

    private var subtitle: String {
        let equipment = exercise.equipment.first?.displayName ?? "—"
        return "\(equipment) • \(exercise.primaryMuscle.displayName)"
    }

    private var mediaIcon: String {
        if case .placeholder(let icon) = exercise.media { return icon }
        return "figure.strengthtraining.traditional"
    }
}
