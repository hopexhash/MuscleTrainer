import SwiftUI
import SwiftData

/// Editable result of AI generation: swap, remove, tune, reorder, save, start.
struct GeneratedWorkoutView: View {
    @State var workout: GeneratedWorkout
    let request: WorkoutRequest
    let onRegenerate: () -> Void
    let onUpdate: (GeneratedWorkout) -> Void
    let onDone: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var swappingItem: GeneratedWorkout.GeneratedItem?
    @State private var didSave = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    summaryHeader
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach($workout.items) { $item in
                        GeneratedItemRow(item: $item) {
                            swappingItem = item
                        }
                    }
                    .onDelete { offsets in
                        workout.items.remove(atOffsets: offsets)
                        pushUpdate()
                    }
                    .onMove { source, destination in
                        workout.items.move(fromOffsets: source, toOffset: destination)
                        pushUpdate()
                    }
                }
                .listRowBackground(AppColor.card)

                Section {
                    aiActions
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)

            bottomBar
        }
        .navigationTitle(workout.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { onDone() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $swappingItem) { item in
            SwapExerciseSheet(item: item, equipment: request.equipment) { replacement in
                if let index = workout.items.firstIndex(where: { $0.id == item.id }) {
                    workout.items[index].exercise = replacement
                }
                pushUpdate()
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func pushUpdate() {
        didSave = false
        onUpdate(workout)
    }

    // MARK: - Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            HStack(spacing: DS.spacingM) {
                Label("~\(workout.estimatedMinutes) min", systemImage: "clock")
                Label(workout.goal.displayName, systemImage: workout.goal.icon)
            }
            .font(AppFont.meta)
            .foregroundStyle(AppColor.textSecondary)
            if !workout.targetMuscles.isEmpty {
                Text(workout.targetMuscles.prefix(5).map(\.displayName).joined(separator: " • "))
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.accent)
            }
        }
        .padding(.vertical, DS.spacingS)
    }

    // MARK: - AI adjustments

    private var aiActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.spacingS) {
                aiActionChip("Make easier", icon: "tortoise.fill") { makeEasier() }
                aiActionChip("Make harder", icon: "hare.fill") { makeHarder() }
                aiActionChip("Shorten", icon: "scissors") { shorten() }
                aiActionChip("Regenerate", icon: "arrow.clockwise") { onRegenerate() }
            }
            .padding(.vertical, DS.spacingS)
        }
    }

    private func aiActionChip(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(AppFont.meta)
            }
            .foregroundStyle(AppColor.accent)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(AppColor.accent.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(PressableStyle())
    }

    private func makeEasier() {
        for index in workout.items.indices {
            var item = workout.items[index]
            item.sets = max(2, item.sets - 1)
            item.restSeconds = min(240, item.restSeconds + 15)
            workout.items[index] = item
        }
        recalcDuration()
    }

    private func makeHarder() {
        for index in workout.items.indices {
            var item = workout.items[index]
            item.sets = min(6, item.sets + 1)
            item.restSeconds = max(30, item.restSeconds - 15)
            workout.items[index] = item
        }
        recalcDuration()
    }

    private func shorten() {
        if workout.items.count > 3 {
            workout.items.removeLast()
        }
        for index in workout.items.indices {
            workout.items[index].restSeconds = max(30, workout.items[index].restSeconds - 15)
        }
        recalcDuration()
    }

    private func recalcDuration() {
        let seconds = workout.items.reduce(0) { $0 + $1.sets * (45 + $1.restSeconds) }
        workout.estimatedMinutes = max(15, seconds / 60 + 5)
        pushUpdate()
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: DS.spacingM) {
            SecondaryButton(title: didSave ? "Saved ✓" : "Save Workout", icon: didSave ? nil : "square.and.arrow.down") {
                saveWorkout()
            }
            PrimaryButton(title: "Start Workout", icon: "play.fill", isEnabled: !workout.items.isEmpty) {
                startWorkout()
            }
        }
        .padding(DS.spacing)
        .background(.ultraThinMaterial)
    }

    @discardableResult
    private func persist() -> Workout {
        let model = Workout(
            name: workout.name,
            goal: workout.goal,
            isAIGenerated: true,
            estimatedMinutes: workout.estimatedMinutes
        )
        context.insert(model)
        for (index, item) in workout.items.enumerated() {
            let we = WorkoutExercise(
                exerciseID: item.exercise.id,
                order: index,
                sets: item.sets,
                repsLow: item.repsLow,
                repsHigh: item.repsHigh,
                restSeconds: item.restSeconds
            )
            we.workout = model
            context.insert(we)
        }
        try? context.save()
        return model
    }

    private func saveWorkout() {
        guard !didSave else { return }
        persist()
        didSave = true
        Haptics.success()
    }

    private func startWorkout() {
        let model = persist()
        didSave = true
        onDone()
        appState.startWorkout(model)
    }
}

// MARK: - Row

private struct GeneratedItemRow: View {
    @Binding var item: GeneratedWorkout.GeneratedItem
    let onSwap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.exercise.name)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("\(item.exercise.primaryMuscle.displayName) • \(item.exercise.equipment.first?.displayName ?? "")")
                        .font(AppFont.metaSmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Button("Swap", action: onSwap)
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.accent)
                    .buttonStyle(.borderless)
            }
            HStack {
                Text("\(item.sets) × \(item.repsLow)–\(item.repsHigh)")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.accent)
                Spacer()
                Text("Rest: \(item.restSeconds) sec")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
            }
            HStack(spacing: DS.spacing) {
                Stepper("Sets: \(item.sets)", value: $item.sets, in: 1...8)
                    .font(AppFont.metaSmall)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Stepper("Rest: \(item.restSeconds)s", value: $item.restSeconds, in: 15...300, step: 15)
                .font(AppFont.metaSmall)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Swap sheet

private struct SwapExerciseSheet: View {
    let item: GeneratedWorkout.GeneratedItem
    let equipment: Set<Equipment>
    let onPick: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss

    private var alternatives: [Exercise] {
        ExerciseSwapper.alternatives(for: item.exercise, equipment: equipment)
    }

    var body: some View {
        NavigationStack {
            List {
                if alternatives.isEmpty {
                    Text("No similar exercises available for your equipment.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                } else {
                    ForEach(alternatives) { alternative in
                        Button {
                            Haptics.selection()
                            onPick(alternative)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(alternative.name)
                                    .font(AppFont.cardTitle)
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("\(alternative.equipment.first?.displayName ?? "") • \(alternative.difficulty.displayName)")
                                    .font(AppFont.meta)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                }
            }
            .listRowBackground(AppColor.card)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("Swap \(item.exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
