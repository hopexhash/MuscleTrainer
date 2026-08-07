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
                    } onViewProgress: {
                        appState.activeWorkout = nil
                        appState.selectedTab = .progress
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
                } else if controller.isResting {
                    restContent
                } else {
                    setContent
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

    // MARK: - Shared header

    private func progressHeader(trailing: String? = nil) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Exercise \(controller.exerciseIndex + 1) of \(controller.plan.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    Text(elapsedLabel(at: timeline.date))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                        .monospacedDigit()
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.track)
                    Capsule()
                        .fill(AppColor.accent)
                        .frame(width: max(4, proxy.size.width * controller.progressFraction))
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, DS.spacingL)
    }

    private func elapsedLabel(at date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(controller.startedAt)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Set entry

    private var setContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressHeader()

            if let item = controller.currentItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ExerciseMediaView(exercise: item.exercise, height: 190)
                            .padding(.top, DS.spacing)

                        Text(item.exercise.name)
                            .font(.system(size: 27, weight: .bold))
                            .kerning(-0.7)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.top, DS.spacingL)

                        HStack(spacing: 10) {
                            Text("Set \(controller.setNumber) of \(item.sets)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColor.accentBright)
                            Circle()
                                .fill(AppColor.textFaint)
                                .frame(width: 3, height: 3)
                            Text("Goal \(item.repsLow)–\(item.repsHigh) reps")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .padding(.top, 6)

                        if let previous = controller.previousSet {
                            Text("Previous · \(previousLabel(previous))")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColor.textTertiary)
                                .padding(.top, 4)
                        }

                        HStack(spacing: DS.spacingM) {
                            if item.exercise.isWeighted {
                                InputCard(
                                    label: "WEIGHT",
                                    value: formattedWeight,
                                    unit: weightUnit,
                                    onMinus: { controller.weightInput = max(0, controller.weightInput - 2.5) },
                                    onPlus: { controller.weightInput += 2.5 }
                                )
                            }
                            InputCard(
                                label: "REPS",
                                value: "\(controller.repsInput)",
                                unit: nil,
                                onMinus: { controller.repsInput = max(1, controller.repsInput - 1) },
                                onPlus: { controller.repsInput += 1 }
                            )
                        }
                        .padding(.top, DS.spacingL)
                    }
                    .padding(.horizontal, DS.spacingL)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: DS.spacingM) {
                PrimaryButton(title: "Complete Set", isEnabled: true) {
                    controller.completeSet()
                }
                Button("Skip exercise") {
                    Haptics.selection()
                    controller.skipExercise()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColor.textTertiary)
            }
            .padding(.horizontal, DS.spacingL)
            .padding(.bottom, DS.spacingS)
        }
    }

    private var formattedWeight: String {
        controller.weightInput.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(controller.weightInput))
            : String(format: "%.1f", controller.weightInput)
    }

    private func previousLabel(_ set: ActiveWorkoutController.LoggedSet) -> String {
        set.weight > 0 ? "\(Int(set.weight)) \(weightUnit) × \(set.reps)" : "\(set.reps) reps"
    }

    // MARK: - Rest

    private var restContent: some View {
        VStack(spacing: 0) {
            Text("Rest before your next set")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, DS.spacingS)

            Spacer()

            ZStack {
                Circle()
                    .stroke(AppColor.surface, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: controller.restFraction)
                    .stroke(AppColor.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: controller.restRemaining)
                VStack(spacing: 2) {
                    Text(controller.restLabel)
                        .font(AppFont.timer)
                        .kerning(-2)
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    MicroLabel(text: "Remaining")
                }
            }
            .frame(width: 236, height: 236)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rest timer: \(controller.restLabel) remaining")

            HStack(spacing: DS.spacingM) {
                Button {
                    controller.addRest(seconds: 15)
                } label: {
                    Text("+15 sec")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary.opacity(0.85))
                        .padding(.horizontal, 22)
                        .frame(height: 46)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableStyle())

                Button {
                    Haptics.selection()
                    controller.skipRest()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .frame(height: 46)
                        .background(AppColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.top, DS.spacingXL)

            Spacer()

            if let next = controller.upNext {
                VStack(alignment: .leading, spacing: 10) {
                    MicroLabel(text: "Up next")
                    HStack(spacing: 13) {
                        AnatomyFigureView(
                            side: next.exercise.primaryMuscle.isBackFacing ? .back : .front,
                            gender: profiles.first?.anatomyGender ?? .male,
                            selectedMuscles: Set(next.exercise.primaryMuscles),
                            isInteractive: false
                        )
                        .frame(width: 44, height: 50)
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(next.exercise.name)
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundStyle(AppColor.textPrimary)
                            Text(next.label)
                                .font(.system(size: 12.5))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        Spacer()
                    }
                    .cardStyle(padding: DS.spacingM)
                }
                .padding(.horizontal, DS.spacingL)
                .padding(.bottom, DS.spacingL)
            }
        }
        .background(
            RadialGradient(
                colors: [AppColor.accent.opacity(0.12), .clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 300
            )
        )
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

// MARK: - Weight/reps input card

private struct InputCard: View {
    let label: String
    let value: String
    let unit: String?
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MicroLabel(text: label)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .kerning(-1)
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
            .padding(.top, 6)
            HStack(spacing: 7) {
                stepButton("minus", action: onMinus)
                stepButton("plus", action: onPlus)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: DS.spacing)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(AppColor.control)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(icon == "plus" ? "Increase \(label.lowercased())" : "Decrease \(label.lowercased())")
    }
}

// MARK: - Completion screen

struct WorkoutCompleteView: View {
    let controller: ActiveWorkoutController
    let session: WorkoutSession?
    let gender: AnatomyGender
    let weightUnit: String
    let onDone: () -> Void
    var onViewProgress: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(AppColor.accent.opacity(0.14))
                    Circle()
                        .strokeBorder(AppColor.accent.opacity(0.3), lineWidth: 1)
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.accentBright)
                }
                .frame(width: 58, height: 58)
                .padding(.top, DS.spacing)

                Text("Workout complete")
                    .font(.system(size: 32, weight: .bold))
                    .kerning(-1)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.top, DS.spacingL)

                Text("Great session.")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, 6)

                statsGrid
                    .padding(.top, DS.spacingL)

                if let session, !session.muscleIntensity.isEmpty {
                    Text("Muscles trained")
                        .font(AppFont.sectionTitle)
                        .kerning(-0.5)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.top, DS.spacingXL)

                    VStack(spacing: DS.spacing) {
                        MuscleHeatmapView(gender: gender, heatmap: session.muscleIntensity, height: 230)
                        HStack(spacing: DS.spacing) {
                            legend(color: AppColor.accent, label: "Primary")
                            legend(color: AppColor.heatMid, label: "Secondary")
                            legend(color: AppColor.muscleIdle, label: "Untrained")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle(radius: DS.radiusL)
                    .padding(.top, DS.spacingM)
                }

                PrimaryButton(title: "Done") {
                    onDone()
                }
                .padding(.top, DS.spacingL)

                if let onViewProgress {
                    Button("View progress", action: onViewProgress)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DS.spacingM)
                }
            }
            .padding(.horizontal, DS.spacingL)
            .padding(.bottom, DS.spacingXL)
        }
        .background(
            RadialGradient(
                colors: [AppColor.accent.opacity(0.14), .clear],
                center: UnitPoint(x: 0.5, y: 0.05),
                startRadius: 0, endRadius: 320
            )
        )
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var statsGrid: some View {
        let duration = session?.durationSeconds ?? Int(Date.now.timeIntervalSince(controller.startedAt))
        let totalReps = controller.logged.reduce(0) { $0 + $1.reps }
        let volume = controller.logged.reduce(0.0) { $0 + $1.weight * Double($1.reps) }

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.spacingM) {
            MetricCard(value: formatDuration(duration), label: "Duration")
            MetricCard(value: "\(controller.logged.count)", label: "Sets completed")
            MetricCard(value: "\(totalReps)", label: "Total reps")
            MetricCard(value: volume > 0 ? "\(Int(volume)) \(weightUnit)" : "—", label: "Total volume")
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h \(minutes % 60) m"
    }
}
