import SwiftUI
import SwiftData

/// Adds an exercise to an existing workout, or creates a new one with it.
struct AddToWorkoutSheet: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]

    @State private var newWorkoutName = ""
    @State private var isCreatingNew = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: DS.spacingM) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(AppColor.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(AppFont.cardTitle)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(exercise.primaryMuscle.displayName)
                                .font(AppFont.meta)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .listRowBackground(AppColor.card)

                Section("Add to") {
                    if isCreatingNew {
                        HStack {
                            TextField("Workout name", text: $newWorkoutName)
                                .font(AppFont.body)
                                .submitLabel(.done)
                                .onSubmit(createNewWorkout)
                            Button("Create", action: createNewWorkout)
                                .font(AppFont.bodyMedium)
                                .foregroundStyle(AppColor.accent)
                                .disabled(newWorkoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } else {
                        Button {
                            isCreatingNew = true
                        } label: {
                            Label("New Workout", systemImage: "plus.circle.fill")
                                .font(AppFont.bodyMedium)
                                .foregroundStyle(AppColor.accent)
                        }
                    }

                    ForEach(workouts) { workout in
                        Button {
                            add(to: workout)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workout.name)
                                        .font(AppFont.body)
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text("\(workout.exercises.count) exercises")
                                        .font(AppFont.meta)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                Spacer()
                                if workout.exercises.contains(where: { $0.exerciseID == exercise.id }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColor.success)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(AppColor.card)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("Add to Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func createNewWorkout() {
        let name = newWorkoutName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let workout = Workout(name: name)
        context.insert(workout)
        add(to: workout)
    }

    private func add(to workout: Workout) {
        guard !workout.exercises.contains(where: { $0.exerciseID == exercise.id }) else {
            dismiss()
            return
        }
        let item = WorkoutExercise(exerciseID: exercise.id, order: workout.exercises.count)
        item.workout = workout
        context.insert(item)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
