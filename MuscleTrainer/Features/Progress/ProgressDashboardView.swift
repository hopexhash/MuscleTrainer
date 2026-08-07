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
                    VStack(alignment: .leading, spacing: 0) {
                        weekCard
                        statsGrid
                            .padding(.top, DS.spacingM)

                        Text("Muscle activity")
                            .font(AppFont.sectionTitle)
                            .kerning(-0.5)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.top, DS.spacingXL)
                        heatmapCard
                            .padding(.top, DS.spacingM)

                        Text("Training balance")
                            .font(AppFont.sectionTitle)
                            .kerning(-0.5)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.top, DS.spacingXL)
                        balanceCard
                            .padding(.top, DS.spacingM)

                        Text("History")
                            .font(AppFont.sectionTitle)
                            .kerning(-0.5)
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.top, DS.spacingXL)
                        VStack(spacing: DS.spacingS) {
                            ForEach(sessions.prefix(10)) { session in
                                SessionRow(session: session, weightUnit: weightUnit)
                            }
                        }
                        .padding(.top, DS.spacingM)
                    }
                    .padding(.horizontal, DS.spacingL)
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

    private var previousWeekCount: Int {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: .now) else { return 0 }
        return sessions.filter { $0.startedAt >= twoWeeksAgo && $0.startedAt < weekAgo }.count
    }

    private var streakDays: Int {
        let calendar = Calendar.current
        let trainedDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        var streak = 0
        var day = calendar.startOfDay(for: .now)
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

    /// Sets per broad region over recent sessions, normalized to the busiest region.
    private var regionBalance: [(BodyRegion, Double)] {
        var counts: [BodyRegion: Double] = [:]
        for session in sessions.prefix(30) {
            for set in session.completedSets {
                guard let exercise = ExerciseDatabase.exercise(id: set.exerciseID) else { continue }
                counts[exercise.primaryMuscle.region, default: 0] += 1
            }
        }
        guard let maxValue = counts.values.max(), maxValue > 0 else { return [] }
        return counts
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value / maxValue) }
    }

    /// Sessions per day for the last 7 days, oldest first.
    private var weekBars: [(label: String, count: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) ?? .now
            let count = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }.count
            return (formatter.string(from: day), count)
        }
    }

    // MARK: - Sections

    private var weekCard: some View {
        let delta = weeklyCount - previousWeekCount
        let bars = weekBars
        let maxCount = max(bars.map(\.count).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weeklyCount) workout\(weeklyCount == 1 ? "" : "s")")
                        .font(.system(size: 32, weight: .bold))
                        .kerning(-1.2)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("This week")
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                if delta != 0 {
                    Text(delta > 0 ? "+\(delta) vs last" : "\(delta) vs last")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(delta > 0 ? AppColor.accentBright : AppColor.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(delta > 0 ? AppColor.accent.opacity(0.12) : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }

            HStack(alignment: .bottom, spacing: DS.spacingS) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    VStack(spacing: 8) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(bar.count > 0 ? AppColor.accent : AppColor.surface)
                            .frame(height: bar.count > 0 ? max(14, 64 * Double(bar.count) / Double(maxCount)) : 8)
                        Text(bar.label)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(AppColor.textFaint)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(bar.label): \(bar.count) workouts")
                }
            }
            .frame(height: 96)
            .padding(.top, DS.spacingL)
        }
        .padding(DS.spacingL)
        .background(
            LinearGradient(
                colors: [AppColor.segmentOn.opacity(0.6), AppColor.card],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.spacingM) {
            MetricCard(value: streakDays == 1 ? "1 day" : "\(streakDays) days", label: "Training streak")
            MetricCard(value: "\(sessions.count)", label: "Total workouts")
            MetricCard(value: totalMinutes < 60 ? "\(totalMinutes) min" : "\(totalMinutes / 60) h", label: "Total time")
            MetricCard(
                value: "\(Int(sessions.prefix(30).reduce(0.0) { $0 + $1.totalVolume })) \(weightUnit)",
                label: "Recent volume"
            )
        }
    }

    private var heatmapCard: some View {
        VStack(spacing: DS.spacing) {
            MuscleHeatmapView(
                gender: profiles.first?.anatomyGender ?? .male,
                heatmap: aggregatedIntensity,
                height: 250
            )
            HStack(spacing: 9) {
                Text("Less")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.textTertiary)
                HStack(spacing: 4) {
                    scaleStep(AppColor.muscleIdle)
                    scaleStep(AppColor.heatLow)
                    scaleStep(AppColor.heatMid)
                    scaleStep(AppColor.accent)
                }
                Text("More")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle(radius: DS.radiusL)
    }

    private func scaleStep(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 22, height: 8)
    }

    private var balanceCard: some View {
        let balance = regionBalance
        return VStack(alignment: .leading, spacing: DS.spacing) {
            ForEach(balance, id: \.0) { region, value in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(region.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text("\(Int(value * 100))%")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColor.textTertiary)
                            .monospacedDigit()
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppColor.control)
                            Capsule()
                                .fill(AppColor.accent.opacity(0.35 + 0.65 * value))
                                .frame(width: max(8, proxy.size.width * value))
                        }
                    }
                    .frame(height: 5)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(region.displayName): \(Int(value * 100)) percent of your most trained region")
            }
        }
        .cardStyle(padding: DS.spacingL, radius: DS.radiusL)
    }
}
