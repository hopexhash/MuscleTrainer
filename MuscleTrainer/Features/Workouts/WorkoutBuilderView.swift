import SwiftUI
import SwiftData

/// Manual workout creation: name → pick muscles → pick exercises → save.
struct WorkoutBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var selectedMuscles: Set<Muscle> = []
    @State private var selectedExerciseIDs: [String] = []
    @State private var step: Step = .name

    enum Step {
        case name, muscles, exercises
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                switch step {
                case .name: nameStep
                case .muscles: muscleStep
                case .exercises: exerciseStep
                }
            }
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: Steps

    private var nameStep: some View {
        VStack(spacing: DS.spacingL) {
            Spacer()
            Text("Name your workout")
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
            TextField("e.g. Chest + Arms", text: $name)
                .font(AppFont.body)
                .padding(DS.spacing)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                        .strokeBorder(AppColor.border, lineWidth: 1)
                )
                .padding(.horizontal, DS.spacingXL)
                .submitLabel(.next)
                .onSubmit(advanceFromName)
            Spacer()
            PrimaryButton(title: "Next", isEnabled: !trimmedName.isEmpty) {
                advanceFromName()
            }
            .padding(.horizontal, DS.spacing)
            .padding(.bottom, DS.spacing)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func advanceFromName() {
        guard !trimmedName.isEmpty else { return }
        withAnimation(DS.smooth) { step = .muscles }
    }

    private var muscleStep: some View {
        VStack(spacing: DS.spacing) {
            Text("Choose muscles")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("Tap the figure to select target muscles.")
                .font(AppFont.meta)
                .foregroundStyle(AppColor.textSecondary)

            MultiSelectAnatomy(selection: $selectedMuscles)

            PrimaryButton(title: selectedMuscles.isEmpty ? "Select at least one muscle" : "Next (\(selectedMuscles.count) selected)", isEnabled: !selectedMuscles.isEmpty) {
                withAnimation(DS.smooth) { step = .exercises }
            }
            .padding(.horizontal, DS.spacing)
            .padding(.bottom, DS.spacing)
        }
    }

    private var exerciseStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DS.spacingM) {
                    ForEach(Array(selectedMuscles).sorted { $0.displayName < $1.displayName }) { muscle in
                        SectionHeader(title: muscle.displayName)
                        ForEach(ExerciseDatabase.exercises(for: muscle).filter { $0.primaryMuscles.contains(muscle) }) { exercise in
                            selectableRow(exercise)
                        }
                    }
                }
                .padding(.horizontal, DS.spacing)
                .padding(.bottom, DS.spacing)
            }
            PrimaryButton(
                title: selectedExerciseIDs.isEmpty ? "Pick your exercises" : "Save Workout (\(selectedExerciseIDs.count))",
                icon: "checkmark",
                isEnabled: !selectedExerciseIDs.isEmpty
            ) {
                save()
            }
            .padding(DS.spacing)
        }
    }

    private func selectableRow(_ exercise: Exercise) -> some View {
        let isSelected = selectedExerciseIDs.contains(exercise.id)
        return Button {
            Haptics.selection()
            if isSelected {
                selectedExerciseIDs.removeAll { $0 == exercise.id }
            } else {
                selectedExerciseIDs.append(exercise.id)
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppColor.accent : AppColor.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("\(exercise.equipment.first?.displayName ?? "") • \(exercise.difficulty.displayName)")
                        .font(AppFont.metaSmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
            }
            .cardStyle(padding: DS.spacingM)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func save() {
        let workout = Workout(name: trimmedName, estimatedMinutes: max(20, selectedExerciseIDs.count * 8))
        context.insert(workout)
        for (index, exerciseID) in selectedExerciseIDs.enumerated() {
            let item = WorkoutExercise(exerciseID: exerciseID, order: index)
            item.workout = workout
            context.insert(item)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

// MARK: - Multi-select anatomy picker

/// Front + back anatomy with multi-muscle selection, used by the builder and AI questionnaire.
struct MultiSelectAnatomy: View {
    @Binding var selection: Set<Muscle>
    @State private var side: BodySide = .front
    @State private var gender: AnatomyGender = .male

    var body: some View {
        VStack(spacing: DS.spacingM) {
            HStack(spacing: DS.spacingM) {
                SegmentedSelector(options: [BodySide.front, .back], label: { $0 == .front ? "Front" : "Back" }, selection: $side)
                SegmentedSelector(options: AnatomyGender.allCases, label: { $0.displayName }, selection: $gender)
            }
            .padding(.horizontal, DS.spacingL)

            AnatomyFigureView(
                side: side,
                gender: gender,
                selectedMuscles: selection
            ) { muscle in
                if selection.contains(muscle) {
                    selection.remove(muscle)
                } else {
                    selection.insert(muscle)
                }
            }

            if !selection.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.spacingS) {
                        ForEach(Array(selection).sorted { $0.displayName < $1.displayName }) { muscle in
                            FilterChip(title: muscle.displayName, isSelected: true) {
                                selection.remove(muscle)
                            }
                        }
                    }
                    .padding(.horizontal, DS.spacing)
                }
                .frame(height: 36)
            }
        }
    }
}
