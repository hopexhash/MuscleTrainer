import SwiftUI

/// The interactive anatomy figure.
///
/// Renders the capsule-anatomy skeleton and every muscle region in a single
/// `Canvas` pass (paths are cached per side/gender and only transformed per
/// frame). Supports tap hit-testing on real vector shapes, primary/secondary
/// highlight levels, and a tiered heatmap mode.
struct AnatomyFigureView: View {
    let side: BodySide
    let gender: AnatomyGender
    var selectedMuscles: Set<Muscle> = []
    /// Secondary-worked muscles, drawn in the mid blue (#17558C).
    var secondaryMuscles: Set<Muscle> = []
    var heatmap: [Muscle: Double]? = nil
    var isInteractive: Bool = true
    var onTap: ((Muscle) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let transform = AnatomyShapeStore.fittingTransform(in: size)
            let regions = AnatomyShapeStore.regions(side: side, gender: gender)

            Canvas { context, _ in
                let scale = min(size.width / AnatomyShapeStore.designSize.width,
                                size.height / AnatomyShapeStore.designSize.height)
                let lineWidth = max(0.5, 1.8 * scale)

                let outline = AnatomyShapeStore.outline(side: side, gender: gender).applying(transform)
                context.fill(outline, with: .color(AppColor.bodyFill))
                context.stroke(outline, with: .color(AppColor.anatomyLine), lineWidth: lineWidth)

                let hasSelection = !selectedMuscles.isEmpty

                for region in regions {
                    let path = region.path.applying(transform)

                    if let heatmap {
                        let value = foldedIntensity(for: region.muscle, in: heatmap)
                        if value >= 0.7 {
                            var glow = context
                            glow.addFilter(.blur(radius: 5))
                            glow.fill(path, with: .color(AppColor.accent.opacity(0.5)))
                            context.fill(path, with: .color(AppColor.accent))
                        } else if value >= 0.4 {
                            context.fill(path, with: .color(AppColor.heatMid))
                        } else if value >= 0.15 {
                            context.fill(path, with: .color(AppColor.heatLow))
                        } else {
                            context.fill(path, with: .color(AppColor.muscleIdle))
                        }
                    } else if selectedMuscles.contains(region.muscle) {
                        var glow = context
                        glow.addFilter(.blur(radius: 7))
                        glow.fill(path, with: .color(AppColor.accent.opacity(0.55)))
                        context.fill(path, with: .color(AppColor.accent))
                    } else if secondaryMuscles.contains(region.muscle) {
                        context.fill(path, with: .color(AppColor.muscleSecondary))
                    } else {
                        context.fill(path, with: .color(AppColor.muscleIdle.opacity(hasSelection ? 0.4 : 1)))
                    }

                    context.stroke(path, with: .color(AppColor.anatomyLine), lineWidth: lineWidth)
                }

                let details = AnatomyShapeStore.details(side: side, gender: gender).applying(transform)
                context.stroke(details, with: .color(AppColor.anatomyLine.opacity(0.8)), lineWidth: lineWidth * 0.85)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard isInteractive, let onTap else { return }
                // Hit-test in design space to reuse cached, untransformed paths.
                let designPoint = location.applying(transform.inverted())
                if let hit = regions.last(where: { $0.path.contains(designPoint) }) {
                    Haptics.light()
                    onTap(hit.muscle)
                }
            }
            .animation(reduceMotion ? nil : DS.smooth, value: selectedMuscles)
        }
        .accessibilityElement(children: .contain)
        .accessibilityChildren {
            ForEach(AnatomyShapeStore.regions(side: side, gender: gender)) { region in
                Button("Select \(region.displayName.lowercased()) muscles") {
                    onTap?(region.muscle)
                }
            }
        }
    }

    /// Folds sub-muscles without their own region into their parent region.
    private func foldedIntensity(for muscle: Muscle, in heatmap: [Muscle: Double]) -> Double {
        var value = heatmap[muscle] ?? 0
        if muscle == .chest { value = max(value, heatmap[.upperChest] ?? 0) }
        if muscle == .traps { value = max(value, heatmap[.neck] ?? 0) }
        if muscle == .quads { value = max(value, heatmap[.hipFlexors] ?? 0) }
        return value
    }
}

/// Small non-interactive anatomy pair (front + back) used for heatmaps and
/// exercise target visualization.
struct MuscleHeatmapView: View {
    let gender: AnatomyGender
    let heatmap: [Muscle: Double]
    var height: CGFloat = 220

    var body: some View {
        HStack(spacing: DS.spacing) {
            AnatomyFigureView(side: .front, gender: gender, heatmap: heatmap, isInteractive: false)
            AnatomyFigureView(side: .back, gender: gender, heatmap: heatmap, isInteractive: false)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let top = heatmap.sorted { $0.value > $1.value }.prefix(3).map { $0.key.displayName }
        return top.isEmpty ? "Muscle heatmap" : "Muscle heatmap. Most trained: \(top.joined(separator: ", "))"
    }
}

/// Tiny figure with an exercise's muscles lit — used as a thumbnail.
struct ExerciseFigureThumb: View {
    let exercise: Exercise
    var gender: AnatomyGender = .male

    var body: some View {
        let primary = Set(exercise.primaryMuscles)
        let side: BodySide = exercise.primaryMuscle.isBackFacing ? .back : .front
        AnatomyFigureView(
            side: side,
            gender: gender,
            selectedMuscles: primary,
            secondaryMuscles: Set(exercise.secondaryMuscles),
            isInteractive: false
        )
        .accessibilityHidden(true)
    }
}

extension Muscle {
    /// Whether this muscle is best shown on the back view of the figure.
    var isBackFacing: Bool {
        switch self {
        case .traps, .rearDelts, .upperBack, .lats, .lowerBack, .glutes, .hamstrings, .triceps, .calves:
            return true
        default:
            return false
        }
    }
}
