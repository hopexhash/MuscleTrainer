import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    private var weightUnit: String { profiles.first?.weightUnit ?? "kg" }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No training data yet",
                        message: "Finish your first workout and your progress will show up here."
                    )
                    .padding(.top, DS.spacingXXL)
                } else {
                    VStack(alignment: .leading, spacing: DS.spacingL) {
                        statsGrid
                        volumeSection
                        heatmapSection
                        muscleRanking
                        historySection
                    }
                    .padding(.horizontal, DS.spacing)
                    .padding(.bottom, DS.spacingXL)
                }
            }
            .background(AppColor.background)
            .navigationTitle("Progress")
        }
    }

    // MARK: - Aggregates

    private var weeklyCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.startedAt >= weekAgo }.count
    }

    private var streakDays: Int {
        let calendar = Calendar.current
        let trainedDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        // Today counts if trained; otherwise start from yesterday.
        if !trainedDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while trainedDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var aggregatedIntensity: [Muscle: Double] {
        var counts: [Muscle: Double] = [:]
        for session in sessions.prefix(30) {
            for (muscle, value) in session.muscleIntensity {
                counts[muscle, default: 0] += value
            }
        }
        guard let maxValue = counts.values.max(), maxValue > 0 else { return [:] }
        return counts.mapValues { $0 / maxValue }
    }

    private var muscleTotals: [(Muscle, Double)] {
        aggregatedIntensity.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    // MARK: - Sections

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.spacingM) {
            MetricCard(value: "\(weeklyCount)", label: "Workouts this week", icon: "calendar")
            MetricCard(value: streakDays == 1 ? "1 day" : "\(streakDays) days", label: "Training streak", icon: "flame.fill")
            MetricCard(value: "\(sessions.count)", label: "Total workouts", icon: "checkmark.seal.fill")
            MetricCard(value: totalMinutes < 60 ? "\(totalMinutes) min" : "\(totalMinutes / 60) h", label: "Total time", icon: "clock.fill")
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "Volume trend", subtitle: "Last 8 sessions")
            VolumeBars(sessions: Array(sessions.prefix(8).reversed()), weightUnit: weightUnit)
                .cardStyle()
        }
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "Muscle activity", subtitle: "Recent training focus")
            MuscleHeatmapView(
                gender: profiles.first?.anatomyGender ?? .male,
                heatmap: aggregatedIntensity,
                height: 260
            )
            .cardStyle()
        }
    }

    private var muscleRanking: some View {
        VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "Most trained")
            VStack(spacing: DS.spacingS) {
                ForEach(muscleTotals.prefix(5), id: \.0) { muscle, value in
                    rankRow(muscle: muscle, value: value)
                }
            }
            .cardStyle()

            if muscleTotals.count > 5 {
                SectionHeader(title: "Least trained")
                VStack(spacing: DS.spacingS) {
                    ForEach(muscleTotals.suffix(3).reversed(), id: \.0) { muscle, value in
                        rankRow(muscle: muscle, value: value)
                    }
                }
                .cardStyle()
            }
        }
    }

    private func rankRow(muscle: Muscle, value: Double) -> some View {
        HStack(spacing: DS.spacingM) {
            Text(muscle.displayName)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 110, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.surface)
                    Capsule()
                        .fill(AppColor.accent.opacity(0.35 + 0.65 * value))
                        .frame(width: max(8, proxy.size.width * value))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(muscle.displayName): \(Int(value * 100)) percent of your most trained muscle")
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: DS.spacingM) {
            SectionHeader(title: "History", subtitle: "\(sessions.count) sessions")
            ForEach(sessions.prefix(10)) { session in
                SessionRow(session: session, weightUnit: weightUnit)
            }
        }
    }
}

// MARK: - Simple volume bar chart

private struct VolumeBars: View {
    let sessions: [WorkoutSession]
    let weightUnit: String

    var body: some View {
        let maxVolume = max(sessions.map(\.totalVolume).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: DS.spacingS) {
            ForEach(sessions) { session in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppColor.accent.opacity(0.85))
                        .frame(height: max(6, 110 * session.totalVolume / maxVolume))
                    Text(session.startedAt.formatted(.dateTime.day()))
                        .font(AppFont.metaSmall)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(session.startedAt.formatted(date: .abbreviated, time: .omitted)): \(Int(session.totalVolume)) \(weightUnit)")
            }
        }
        .frame(height: 140, alignment: .bottom)
    }
}
