import SwiftUI

/// The interactive anatomy figure.
///
/// Renders the silhouette and every muscle region with a single `Canvas` pass
/// (paths are cached per side/gender and only transformed per frame), supports
/// tap hit-testing on real vector shapes, single or multi selection, and an
/// optional heatmap mode driven by per-muscle intensity.
struct AnatomyFigureView: View {
    let side: BodySide
    let gender: AnatomyGender
    var selectedMuscles: Set<Muscle> = []
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
                let silhouette = AnatomyShapeStore.silhouette(gender: gender)
                    .applying(transform)
                context.fill(silhouette, with: .color(AppColor.bodyFill))
                context.stroke(silhouette, with: .color(AppColor.border), lineWidth: 1)

                let hasSelection = !selectedMuscles.isEmpty

                for region in regions {
                    let path = region.path.applying(transform)

                    if let heatmap {
                        let intensity = foldedIntensity(for: region.muscle, in: heatmap)
                        let fill = intensity > 0.01
                            ? AppColor.accent.opacity(0.15 + 0.75 * intensity)
                            : AppColor.muscleIdle.opacity(0.55)
                        context.fill(path, with: .color(fill))
                    } else if selectedMuscles.contains(region.muscle) {
                        // Soft glow behind the selected muscle.
                        var glow = context
                        glow.addFilter(.blur(radius: 6))
                        glow.fill(path, with: .color(AppColor.accentBright.opacity(0.55)))
                        context.fill(path, with: .color(AppColor.accent))
                    } else {
                        let idleOpacity = hasSelection ? 0.45 : 0.9
                        context.fill(path, with: .color(AppColor.muscleIdle.opacity(idleOpacity)))
                    }

                    context.stroke(path, with: .color(AppColor.background.opacity(0.8)), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard isInteractive, let onTap else { return }
                // Hit-test in design space to reuse cached, untransformed paths.
                let inverse = transform.inverted()
                let designPoint = location.applying(inverse)
                // Later specs draw on top, so test in reverse order.
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
