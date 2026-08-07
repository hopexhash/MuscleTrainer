import SwiftUI

/// Sequential questionnaire → generation → editable result.
struct AIWorkoutFlowView: View {
    let profile: UserProfile?

    @Environment(\.dismiss) private var dismiss
    @State private var request = WorkoutRequest()
    @State private var stepIndex = 0
    @State private var phase: Phase = .questions
    @State private var generated: GeneratedWorkout?
    @State private var generationError: String?

    private let service: AIWorkoutService = LocalWorkoutGenerator()

    enum Phase {
        case questions, generating, result
    }

    private var steps: [QuestionStep] {
        var list: [QuestionStep] = [.focus]
        if request.focus == .custom { list.append(.muscles) }
        list.append(contentsOf: [.goal, .experience, .location, .equipment, .duration, .intensity])
        return list
    }

    enum QuestionStep {
        case focus, muscles, goal, experience, location, equipment, duration, intensity
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                switch phase {
                case .questions:
                    questionContent
                case .generating:
                    AIGeneratingView(error: generationError, onRetry: generate, onCancel: { dismiss() })
                case .result:
                    if let generated {
                        GeneratedWorkoutView(
                            workout: generated,
                            request: request,
                            onRegenerate: generate,
                            onUpdate: { self.generated = $0 },
                            onDone: { dismiss() }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if phase == .questions {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: stepIndex == 0 ? "xmark" : "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .accessibilityLabel(stepIndex == 0 ? "Close" : "Back")
                    }
                }
                ToolbarItem(placement: .principal) {
                    if phase == .questions {
                        ProgressView(value: Double(stepIndex + 1), total: Double(steps.count))
                            .tint(AppColor.accent)
                            .frame(width: 140)
                    }
                }
            }
        }
        .onAppear(perform: prefillFromProfile)
    }

    private func prefillFromProfile() {
        guard let profile else { return }
        request.goal = profile.goal
        request.experience = profile.experience
        request.location = profile.location
        request.equipment = Set(profile.location.availableEquipment.prefix(profile.location == .gym ? 10 : 3))
    }

    private func goBack() {
        if stepIndex == 0 {
            dismiss()
        } else {
            withAnimation(DS.smooth) { stepIndex -= 1 }
        }
    }

    private func advance() {
        Haptics.selection()
        if stepIndex + 1 < steps.count {
            withAnimation(DS.smooth) { stepIndex += 1 }
        } else {
            generate()
        }
    }

    private func generate() {
        generationError = nil
        withAnimation(DS.smooth) { phase = .generating }
        Task {
            do {
                let workout = try await service.generateWorkout(for: request)
                await MainActor.run {
                    generated = workout
                    withAnimation(DS.smooth) { phase = .result }
                    Haptics.success()
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Question rendering

    @ViewBuilder
    private var questionContent: some View {
        let step = steps[min(stepIndex, steps.count - 1)]
        VStack(spacing: DS.spacingL) {
            switch step {
            case .focus:
                QuestionCard(title: "What do you want to train?") {
                    optionGrid(TrainingFocus.allCases, label: \.displayName, icon: \.icon, selected: request.focus) { choice in
                        request.focus = choice
                        advance()
                    }
                }
            case .muscles:
                QuestionCard(title: "Pick your muscles", subtitle: "Tap the figure. Select as many as you like.") {
                    VStack(spacing: DS.spacing) {
                        MultiSelectAnatomy(selection: $request.customMuscles)
                        PrimaryButton(title: "Continue", isEnabled: !request.customMuscles.isEmpty) {
                            advance()
                        }
                        .padding(.horizontal, DS.spacing)
                    }
                }
            case .goal:
                QuestionCard(title: "What's your goal?") {
                    optionGrid(TrainingGoal.allCases, label: \.displayName, icon: \.icon, selected: request.goal) { choice in
                        request.goal = choice
                        advance()
                    }
                }
            case .experience:
                QuestionCard(title: "How experienced are you?") {
                    optionGrid(ExperienceLevel.allCases, label: \.displayName, icon: { _ in "chart.bar.fill" }, selected: request.experience) { choice in
                        request.experience = choice
                        advance()
                    }
                }
            case .location:
                QuestionCard(title: "Where are you training?") {
                    optionGrid(TrainingLocation.allCases, label: \.displayName, icon: \.icon, selected: request.location) { choice in
                        request.location = choice
                        request.equipment = choice == .gym ? Set(choice.availableEquipment) : [.bodyweight]
                        advance()
                    }
                }
            case .equipment:
                QuestionCard(title: "What equipment do you have?", subtitle: "Select all that apply.") {
                    VStack(spacing: DS.spacing) {
                        equipmentGrid
                        PrimaryButton(title: "Continue", isEnabled: !request.equipment.isEmpty) {
                            advance()
                        }
                        .padding(.horizontal, DS.spacing)
                    }
                }
            case .duration:
                QuestionCard(title: "How long do you have?") {
                    optionGrid([20, 30, 45, 60, 75], label: { $0 >= 75 ? "75+ min" : "\($0) min" }, icon: { _ in "clock" }, selected: request.durationMinutes) { choice in
                        request.durationMinutes = choice
                        advance()
                    }
                }
            case .intensity:
                QuestionCard(title: "How hard should it be?") {
                    intensitySlider
                }
            }
        }
        .padding(.horizontal, DS.spacing)
        .id(stepIndex)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private func optionGrid<T: Hashable>(
        _ options: [T],
        label: (T) -> String,
        icon: (T) -> String,
        selected: T?,
        onPick: @escaping (T) -> Void
    ) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.spacingM) {
                ForEach(options, id: \.self) { option in
                    Button {
                        onPick(option)
                    } label: {
                        VStack(spacing: DS.spacingS) {
                            Image(systemName: icon(option))
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(option == selected ? .white : AppColor.accent)
                            Text(label(option))
                                .font(AppFont.bodyMedium)
                                .foregroundStyle(option == selected ? .white : AppColor.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 104)
                        .background(option == selected ? AppColor.accent : AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                                .strokeBorder(option == selected ? .clear : AppColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(option == selected ? [.isSelected] : [])
                }
            }
            .padding(.vertical, DS.spacingS)
        }
    }

    private var equipmentGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.spacingS) {
                ForEach(request.location.availableEquipment) { equipment in
                    let isSelected = request.equipment.contains(equipment)
                    Button {
                        Haptics.selection()
                        if isSelected {
                            request.equipment.remove(equipment)
                        } else {
                            request.equipment.insert(equipment)
                        }
                    } label: {
                        HStack(spacing: DS.spacingS) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? AppColor.accent : AppColor.textSecondary)
                            Text(equipment.displayName)
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                        }
                        .padding(DS.spacingM)
                        .background(AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                                .strokeBorder(isSelected ? AppColor.accent.opacity(0.5) : AppColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.vertical, DS.spacingS)
        }
    }

    private var intensitySlider: some View {
        VStack(spacing: DS.spacingL) {
            Text(intensityLabel)
                .font(AppFont.hero)
                .foregroundStyle(AppColor.accent)
                .contentTransition(.opacity)
                .animation(DS.quick, value: request.intensity)

            Slider(
                value: Binding(
                    get: { Double(request.intensity) },
                    set: { newValue in
                        let rounded = Int(newValue.rounded())
                        if rounded != request.intensity {
                            Haptics.selection()
                            request.intensity = rounded
                        }
                    }
                ),
                in: 0...3,
                step: 1
            )
            .tint(AppColor.accent)
            .padding(.horizontal, DS.spacing)
            .accessibilityLabel("Workout intensity")
            .accessibilityValue(intensityLabel)

            HStack {
                Text("Easy")
                Spacer()
                Text("Brutal")
            }
            .font(AppFont.metaSmall)
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, DS.spacing)

            PrimaryButton(title: "Build my workout", icon: "sparkles") {
                generate()
            }
            .padding(.top, DS.spacing)
        }
        .padding(.top, DS.spacingXL)
    }

    private var intensityLabel: String {
        switch request.intensity {
        case 0: return "Easy"
        case 1: return "Moderate"
        case 2: return "Hard"
        default: return "Brutal"
        }
    }
}

// MARK: - Question card shell

struct QuestionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacing) {
            Text(title)
                .font(AppFont.pageTitle)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, DS.spacing)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            content
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Generation screen

struct AIGeneratingView: View {
    var error: String?
    let onRetry: () -> Void
    let onCancel: () -> Void

    @State private var messageIndex = 0
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let messages = [
        "Analyzing your goal...",
        "Selecting exercises...",
        "Balancing muscle volume...",
        "Building your workout..."
    ]

    var body: some View {
        VStack(spacing: DS.spacingL) {
            Spacer()
            if let error {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn't build your workout",
                    message: error,
                    actionTitle: "Try Again",
                    action: onRetry
                )
                Button("Cancel", action: onCancel)
                    .font(AppFont.meta)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ZStack {
                    Circle()
                        .fill(AppColor.accent.opacity(0.10))
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                    AnatomyFigureView(side: .front, gender: .male, selectedMuscles: Set(Muscle.allCases), isInteractive: false)
                        .frame(width: 130, height: 260)
                        .opacity(pulse ? 1.0 : 0.6)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }

                Text(messages[messageIndex])
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .contentTransition(.opacity)
                    .task {
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .milliseconds(450))
                            withAnimation(DS.smooth) {
                                messageIndex = min(messageIndex + 1, messages.count - 1)
                            }
                            if messageIndex == messages.count - 1 { break }
                        }
                    }
            }
            Spacer()
        }
        .padding(DS.spacing)
    }
}
