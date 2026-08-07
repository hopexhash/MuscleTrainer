import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var controller: ActiveWorkoutController

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var showExitConfirmation = false
    @State private var savedSession: WorkoutSession?

    private var weightUnit: String { profiles.first?.weightUnit ?? "kg" }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                if controller.isFinished {
                    WorkoutCompleteView(
                        controller: controller,
                        session: savedSession,
                        gender: profiles.first?.anatomyGender ?? .male,
                        weightUnit: weightUnit
                    ) {
                        appState.activeWorkout = nil
                    }
                    .onAppear(perform: persistSessionIfNeeded)
                } else if controller.plan.isEmpty {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Nothing to train",
                        message: "This workout has no exercises.",
                        actionTitle: "Close"
                    ) {
                        appState.activeWorkout = nil
                    }
                } else {
                    playerContent
                }
            }
            .toolbar {
                if !controller.isFinished {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showExitConfirmation = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .accessibilityLabel("End workout")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Finish") {
                            controller.finish()
                        }
                        .font(AppFont.bodyMedium)
                        .disabled(controller.logged.isEmpty)
                    }
                }
            }
            .confirmationDialog("End this workout?", isPresented: $showExitConfirmation, titleVisibility: .visible) {
                if !controller.logged.isEmpty {
                    Button("Finish and save") { controller.finish() }
                }
                Button("Discard workout", role: .destructive) {
                    cleanUpDiscardedWorkout()
                    appState.activeWorkout = nil
                }
                Button("Keep training", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Player

    private var playerContent: some View {
        VStack(spacing: DS.spacing) {
            if let item = controller.currentItem {
                header(item: item)

                ScrollView {
                    VStack(spacing: DS.spacing) {
                        ExerciseMediaView(exercise: item.exercise, height: 150)

                        if controller.isResting {
                            restCard
                        } else {
                            setCard(item: item)
                        }

                        loggedList
                    }
                    .padding(.horizontal, DS.spacing)
                }

                Spacer(minLength: 0)

                bottomBar(item: item)
            }
        }
    }

    private func header(item: ActiveWorkoutController.PlanItem) -> some View {
        VStack(spacing: DS.spacingS) {
            Text("Exercise \(controller.exerciseIndex + 1) of \(controller.plan.count)")
                .font(AppFont.metaSmall)
                .foregroundStyle(AppColor.textSecondary)
                .textCase(.uppercase)
            Text(item.exercise.name)
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            ProgressView(value: controller.progressFraction)
                .tint(AppColor.accent)
                .padding(.horizontal, DS.spacingXL)
        }
        .padding(.horizontal, DS.spacing)
    }

    private func setCard(item: ActiveWorkoutController.PlanItem) -> some View {
        VStack(spacing: DS.spacing) {
            HStack {
                Text("SET \(controller.setNumber) / \(item.sets)")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("Target: \(item.repsLow == item.repsHigh ? "\(item.repsLow)" : "\(item.repsLow)–\(item.repsHigh)") reps")
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.accent)
            }

            if let previous = controller.previousSet {
                HStack {
                    Text("Previous")
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text(previousLabel(previous))
                        .font(AppFont.meta)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }

            HStack(spacing: DS.spacingM) {
                if item.exercise.isWeighted {
                    stepperField(
                        label: "Weight (\(weightUnit))",
                        value: formattedWeight,
                        onMinus: { controller.weightInput = max(0, controller.weightInput - 2.5) },
                        onPlus: { controller.weightInput += 2.5 }
                    )
                }
                stepperField(
                    label: "Reps",
                    value: "\(controller.repsInput)",
                    onMinus: { controller.repsInput = max(1, controller.repsInput - 1) },
                    onPlus: { controller.repsInput += 1 }
                )
            }
        }
        .cardStyle(padding: DS.spacingL)
    }

    private var formattedWeight: String {
        controller.weightInput.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(controller.weightInput))
            : String(format: "%.1f", controller.weightInput)
    }

    private func previousLabel(_ set: ActiveWorkoutController.LoggedSet) -> String {
        set.weight > 0 ? "\(Int(set.weight)) \(weightUnit) × \(set.reps)" : "\(set.reps) reps"
    }

    private func stepperField(label: String, value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        VStack(spacing: DS.spacingS) {
            Text(label)
                .font(AppFont.metaSmall)
                .foregroundStyle(AppColor.textSecondary)
            HStack(spacing: 0) {
                stepButton(icon: "minus", action: onMinus)
                Text(value)
                    .font(AppFont.statValue)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                stepButton(icon: "plus", action: onPlus)
            }
        }
        .padding(DS.spacingM)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
        .frame(maxWidth: .infinity)
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 40, height: 40)
                .background(AppColor.card)
                .clipShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(icon == "plus" ? "Increase" : "Decrease")
    }

    // MARK: - Rest

    private var restCard: some View {
        VStack(spacing: DS.spacing) {
            Text("REST")
                .font(AppFont.metaSmall)
                .foregroundStyle(AppColor.textSecondary)
                .textCase(.uppercase)
            Text(controller.restLabel)
                .font(AppFont.timer)
                .foregroundStyle(AppColor.accent)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: controller.restRemaining)
            HStack(spacing: DS.spacingM) {
                SecondaryButton(title: "+15 sec") {
                    controller.addRest(seconds: 15)
                }
                SecondaryButton(title: "Skip") {
                    Haptics.selection()
                    controller.skipRest()
                }
            }
        }
        .cardStyle(padding: DS.spacingL)
    }

    // MARK: - Logged sets

    private var loggedList: some View {
        Group {
            if let item = controller.currentItem {
                let sets = controller.logged.filter { $0.exerciseID == item.exercise.id }
                if !sets.isEmpty {
                    VStack(alignment: .leading, spacing: DS.spacingS) {
                        ForEach(sets) { set in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColor.success)
                                Text("Set \(set.setNumber)")
                                    .font(AppFont.meta)
                                    .foregroundStyle(AppColor.textSecondary)
                                Spacer()
                                Text(previousLabel(set))
                                    .font(AppFont.meta)
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                        }
                    }
                    .cardStyle(padding: DS.spacingM)
                }
            }
        }
    }

    // MARK: - Bottom bar

    private func bottomBar(item: ActiveWorkoutController.PlanItem) -> some View {
        VStack(spacing: DS.spacingS) {
            PrimaryButton(
                title: controller.isResting ? "Resting…" : "Complete Set",
                icon: controller.isResting ? nil : "checkmark",
                isEnabled: !controller.isResting
            ) {
                controller.completeSet()
            }
            Button("Skip exercise") {
                Haptics.selection()
                controller.skipExercise()
            }
            .font(AppFont.meta)
            .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, DS.spacing)
        .padding(.bottom, DS.spacingS)
    }

    // MARK: - Persistence

    private func persistSessionIfNeeded() {
        guard savedSession == nil, !controller.logged.isEmpty else { return }
        let session = WorkoutSession(workoutName: controller.workoutName, goal: controller.goal)
        session.startedAt = controller.startedAt
        session.endedAt = .now
        context.insert(session)
        for set in controller.logged {
            let completed = CompletedSet(
                exerciseID: set.exerciseID,
                exerciseName: set.exerciseName,
                setNumber: set.setNumber,
                reps: set.reps,
                weight: set.weight
            )
            completed.session = session
            context.insert(completed)
        }
        cleanUpDiscardedWorkout()
        try? context.save()
        savedSession = session
    }

    private func cleanUpDiscardedWorkout() {
        guard controller.discardWorkoutOnEnd else { return }
        let targetID = controller.workoutID
        let descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == targetID })
        if let workout = try? context.fetch(descriptor).first {
            context.delete(workout)
        }
    }
}

// MARK: - Completion screen

struct WorkoutCompleteView: View {
    let controller: ActiveWorkoutController
    let session: WorkoutSession?
    let gender: AnatomyGender
    let weightUnit: String
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: DS.spacingL) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColor.accent)
                    .padding(.top, DS.spacingXL)

                Text("Workout Complete")
                    .font(AppFont.pageTitle)
                    .foregroundStyle(AppColor.textPrimary)

                Text(controller.workoutName)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)

                statsGrid

                if let session, !session.muscleIntensity.isEmpty {
                    VStack(alignment: .leading, spacing: DS.spacingM) {
                        SectionHeader(title: "Muscles trained")
                        MuscleHeatmapView(gender: gender, heatmap: session.muscleIntensity, height: 240)
                    }
                    .cardStyle()
                }

                PrimaryButton(title: "Done", icon: "checkmark") {
                    onDone()
                }
                .padding(.top, DS.spacingS)
            }
            .padding(DS.spacing)
        }
    }

    private var statsGrid: some View {
        let duration = session?.durationSeconds ?? Int(Date.now.timeIntervalSince(controller.startedAt))
        let totalReps = controller.logged.reduce(0) { $0 + $1.reps }
        let volume = controller.logged.reduce(0.0) { $0 + $1.weight * Double($1.reps) }

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.spacingM) {
            MetricCard(value: formatDuration(duration), label: "Duration", icon: "clock.fill")
            MetricCard(value: "\(controller.logged.count)", label: "Total Sets", icon: "square.stack.3d.up.fill")
            MetricCard(value: "\(totalReps)", label: "Total Reps", icon: "repeat")
            MetricCard(value: volume > 0 ? "\(Int(volume)) \(weightUnit)" : "—", label: "Total Volume", icon: "scalemass.fill")
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h \(minutes % 60) m"
    }
}
