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
    @Query private var profiles: [UserProfile]

    @State private var swappingItem: GeneratedWorkout.GeneratedItem?
    @State private var didSave = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    header
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    ForEach($workout.items) { $item in
                        GeneratedItemRow(
                            item: $item,
                            number: (workout.items.firstIndex { $0.id == item.id } ?? 0) + 1,
                            gender: profiles.first?.anatomyGender ?? .male
                        ) {
                            swappingItem = item
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: DS.spacingL, bottom: 5, trailing: DS.spacingL))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)

            bottomBar
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                CircleIconButton(icon: "chevron.left", label: "Close") { onDone() }
                Spacer()
                MicroLabel(text: "AI Generated", color: AppColor.accentBright)
            }
            .padding(.horizontal, DS.spacingL)
            .padding(.vertical, DS.spacingS)
            .background(AppColor.background)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(workout.name)
                .font(.system(size: 32, weight: .bold))
                .kerning(-1.1)
                .foregroundStyle(AppColor.textPrimary)
            Text(workout.targetMuscles.prefix(4).map(\.displayName).joined(separator: " • "))
                .font(.system(size: 14))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 5)

            HStack(spacing: 0) {
                stat("\(workout.items.count)", "exercises")
                stat("~\(workout.estimatedMinutes)", "minutes")
                stat(workout.goal.displayName, "goal")
            }
            .padding(.vertical, DS.spacing)
            .background(
                LinearGradient(
                    colors: [AppColor.segmentOn.opacity(0.7), AppColor.card],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
            .padding(.top, DS.spacing)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    quickChip("Make easier", icon: "tortoise") { makeEasier() }
                    quickChip("Make harder", icon: "hare") { makeHarder() }
                    quickChip("Shorten", icon: "scissors") { shorten() }
                    quickChip("Regenerate", icon: "arrow.clockwise") { onRegenerate() }
                }
            }
            .padding(.top, DS.spacingM)
        }
        .padding(.horizontal, DS.spacingL)
        .padding(.bottom, DS.spacingS)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 21, weight: .bold))
                .kerning(-0.6)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(AppColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func quickChip(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .foregroundStyle(AppColor.textPrimary.opacity(0.8))
            .padding(.horizontal, 13)
            .frame(height: 32)
            .background(AppColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppColor.border, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - AI adjustments

    private func makeEasier() {
        for index in workout.items.indices {
            workout.items[index].sets = max(2, workout.items[index].sets - 1)
            workout.items[index].restSeconds = min(240, workout.items[index].restSeconds + 15)
        }
        recalcDuration()
    }

    private func makeHarder() {
        for index in workout.items.indices {
            workout.items[index].sets = min(6, workout.items[index].sets + 1)
            workout.items[index].restSeconds = max(30, workout.items[index].restSeconds - 15)
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
            PrimaryButton(title: "Start Workout", isEnabled: !workout.items.isEmpty) {
                startWorkout()
            }
            Button {
                saveWorkout()
            } label: {
                Text(didSave ? "Saved ✓" : "Save")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(didSave ? AppColor.success : AppColor.textPrimary.opacity(0.85))
                    .frame(width: 100, height: DS.buttonHeight)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                            .strokeBorder(AppColor.border, lineWidth: 1)
                    )
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, DS.spacingL)
        .padding(.vertical, DS.spacingM)
        .background(AppColor.background)
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
    let number: Int
    let gender: AnatomyGender
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(String(format: "%02d", number))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColor.textFaint)
                .monospacedDigit()

            AnatomyFigureView(
                side: item.exercise.primaryMuscle.isBackFacing ? .back : .front,
                gender: gender,
                selectedMuscles: Set(item.exercise.primaryMuscles),
                isInteractive: false
            )
            .frame(width: 46, height: 52)
            .padding(2)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .kerning(-0.3)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text("\(item.sets) sets × \(item.repsLow)–\(item.repsHigh) reps")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppColor.textSecondary)
                Text("\(item.restSeconds) sec rest")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer()

            Button("Swap", action: onSwap)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColor.accentBright)
                .buttonStyle(.borderless)

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundStyle(AppColor.textSecondary.opacity(0.4))
        }
        .padding(DS.spacingM)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusCard, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
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
                        .listRowBackground(AppColor.card)
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
                        .listRowBackground(AppColor.card)
                    }
                }
            }
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
