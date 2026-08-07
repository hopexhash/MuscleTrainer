import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var showBuilder = false

    private var favorites: [Exercise] {
        (profiles.first?.favoriteExerciseIDs ?? []).compactMap(ExerciseDatabase.exercise(id:))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.spacingL) {
                    if workouts.isEmpty && sessions.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No workouts yet",
                            message: "Build one manually or let the AI Coach create one for you.",
                            actionTitle: "Create Workout"
                        ) {
                            showBuilder = true
                        }
                        .padding(.top, DS.spacingXXL)
                    }

                    if !workouts.isEmpty {
                        SectionHeader(title: "My Workouts", subtitle: "\(workouts.count) saved")
                        ForEach(workouts) { workout in
                            NavigationLink(value: workout.id) {
                                WorkoutCard(workout: workout)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }

                    if !favorites.isEmpty {
                        SectionHeader(title: "Favorites")
                        ForEach(favorites) { exercise in
                            NavigationLink(value: exercise.id) {
                                ExerciseCard(exercise: exercise)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }

                    if !sessions.isEmpty {
                        SectionHeader(title: "Recent")
                        ForEach(sessions.prefix(5)) { session in
                            SessionRow(session: session, weightUnit: profiles.first?.weightUnit ?? "kg")
                        }
                    }
                }
                .padding(.horizontal, DS.spacing)
                .padding(.bottom, DS.spacingXL)
            }
            .background(AppColor.background)
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBuilder = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel("Create workout")
                }
            }
            .sheet(isPresented: $showBuilder) {
                WorkoutBuilderView()
            }
            .navigationDestination(for: UUID.self) { workoutID in
                if let workout = workouts.first(where: { $0.id == workoutID }) {
                    WorkoutDetailView(workout: workout)
                }
            }
            .navigationDestination(for: String.self) { exerciseID in
                if let exercise = ExerciseDatabase.exercise(id: exerciseID) {
                    ExerciseDetailView(exercise: exercise)
                }
            }
        }
    }
}

// MARK: - Cards

struct WorkoutCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            HStack {
                Text(workout.name)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                if workout.isAIGenerated {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.accent)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Text("\(workout.exercises.count) exercises • ~\(workout.estimatedMinutes) min")
                .font(AppFont.meta)
                .foregroundStyle(AppColor.textSecondary)
            if !workout.targetMuscles.isEmpty {
                Text(workout.targetMuscles.prefix(4).map(\.displayName).joined(separator: " • "))
                    .font(AppFont.metaSmall)
                    .foregroundStyle(AppColor.accent)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    let weightUnit: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutName)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.totalSets) sets")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textPrimary)
                if session.totalVolume > 0 {
                    Text("\(Int(session.totalVolume)) \(weightUnit)")
                        .font(AppFont.metaSmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .cardStyle(padding: DS.spacingM)
    }
}

// MARK: - Workout detail

struct WorkoutDetailView: View {
    @Bindable var workout: Workout

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                HStack(spacing: DS.spacingM) {
                    MetricCard(value: "\(workout.exercises.count)", label: "Exercises")
                    MetricCard(value: "~\(workout.estimatedMinutes) min", label: "Duration")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Exercises") {
                ForEach(workout.orderedExercises) { item in
                    WorkoutExerciseRow(item: item)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .listRowBackground(AppColor.card)
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    EditButton()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(workout)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Start Workout", icon: "play.fill", isEnabled: !workout.exercises.isEmpty) {
                appState.startWorkout(workout)
            }
            .padding(.horizontal, DS.spacing)
            .padding(.top, DS.spacingS)
            .background(.ultraThinMaterial)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let ordered = workout.orderedExercises
        for index in offsets {
            context.delete(ordered[index])
        }
        reindex(excluding: offsets.map { ordered[$0].id })
        try? context.save()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var ordered = workout.orderedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in ordered.enumerated() {
            item.order = index
        }
        try? context.save()
    }

    private func reindex(excluding deletedIDs: [UUID]) {
        let remaining = workout.orderedExercises.filter { !deletedIDs.contains($0.id) }
        for (index, item) in remaining.enumerated() {
            item.order = index
        }
    }
}

struct WorkoutExerciseRow: View {
    @Bindable var item: WorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            HStack {
                Text(item.exercise?.name ?? "Unknown exercise")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(item.sets) × \(item.repsLabel)")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.accent)
            }
            HStack(spacing: DS.spacing) {
                Stepper("Sets: \(item.sets)", value: $item.sets, in: 1...10)
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
            }
            HStack(spacing: DS.spacing) {
                Stepper("Reps: \(item.repsLabel)", value: Binding(
                    get: { item.repsHigh },
                    set: { newValue in
                        item.repsHigh = max(1, newValue)
                        item.repsLow = max(1, min(item.repsLow, item.repsHigh))
                    }
                ), in: 1...50)
                .font(AppFont.meta)
                .foregroundStyle(AppColor.textSecondary)
            }
            Stepper("Rest: \(item.restSeconds) sec", value: $item.restSeconds, in: 15...300, step: 15)
                .font(AppFont.meta)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, 2)
    }
}
