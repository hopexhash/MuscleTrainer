import SwiftUI

/// A selectable muscle region: identity + vector shape in design space.
struct MuscleRegionShape: Identifiable {
    let id: String
    let muscle: Muscle
    let side: BodySide
    let path: Path

    var displayName: String { muscle.displayName }
    var anatomicalName: String { muscle.anatomicalName }
}

/// Builds and caches anatomy geometry.
///
/// All shapes are authored as point clouds in a fixed 300×640 design space and
/// smoothed into closed curves. Gender differences are applied as a parametric
/// warp of x-coordinates around the centerline, so professional SVG artwork can
/// later replace this without touching any selection or exercise logic.
enum AnatomyShapeStore {

    static let designSize = CGSize(width: 300, height: 640)
    private static let centerX: CGFloat = 150

    // MARK: - Public API

    static func regions(side: BodySide, gender: AnatomyGender) -> [MuscleRegionShape] {
        let key = CacheKey(side: side, gender: gender)
        if let cached = regionCache[key] { return cached }
        let built = buildRegions(side: side, gender: gender)
        regionCache[key] = built
        return built
    }

    static func silhouette(gender: AnatomyGender) -> Path {
        if let cached = silhouetteCache[gender] { return cached }
        let path = smoothClosedPath(points: silhouettePoints.map { warp($0, gender: gender) })
        silhouetteCache[gender] = path
        return path
    }

    /// Scale factor + offset to fit the design space in a rect.
    static func fittingTransform(in size: CGSize) -> CGAffineTransform {
        let scale = min(size.width / designSize.width, size.height / designSize.height)
        let dx = (size.width - designSize.width * scale) / 2
        let dy = (size.height - designSize.height * scale) / 2
        return CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)
    }

    // MARK: - Caches

    private struct CacheKey: Hashable {
        let side: BodySide
        let gender: AnatomyGender
    }

    nonisolated(unsafe) private static var regionCache: [CacheKey: [MuscleRegionShape]] = [:]
    nonisolated(unsafe) private static var silhouetteCache: [AnatomyGender: Path] = [:]

    // MARK: - Gender warp

    /// Adjusts silhouette proportions per gender: narrower shoulders and waist,
    /// slightly wider hips for the female figure.
    private static func warp(_ p: CGPoint, gender: AnatomyGender) -> CGPoint {
        guard gender == .female else { return p }
        let factor = femaleWidthFactor(atY: p.y)
        let dx = p.x - centerX
        return CGPoint(x: centerX + dx * factor, y: p.y)
    }

    private static func femaleWidthFactor(atY y: CGFloat) -> CGFloat {
        // Control points: (y, widthFactor) — linearly interpolated.
        let controls: [(CGFloat, CGFloat)] = [
            (0, 0.96), (80, 0.95), (110, 0.90), (170, 0.90),
            (240, 0.84), (290, 0.92), (330, 1.05), (380, 1.02),
            (480, 0.97), (640, 0.95)
        ]
        var previous = controls[0]
        for control in controls {
            if y <= control.0 {
                let span = control.0 - previous.0
                guard span > 0 else { return control.1 }
                let t = (y - previous.0) / span
                return previous.1 + (control.1 - previous.1) * t
            }
            previous = control
        }
        return controls.last?.1 ?? 1
    }

    // MARK: - Region construction

    private static func buildRegions(side: BodySide, gender: AnatomyGender) -> [MuscleRegionShape] {
        let specs = side == .front ? frontSpecs : backSpecs
        return specs.map { spec in
            var path = Path()
            for blob in spec.blobs {
                let warped = blob.map { warp($0, gender: gender) }
                path.addPath(smoothClosedPath(points: warped))
                if spec.mirrored {
                    let mirroredPoints = blob.map {
                        warp(CGPoint(x: 2 * centerX - $0.x, y: $0.y), gender: gender)
                    }
                    path.addPath(smoothClosedPath(points: mirroredPoints))
                }
            }
            return MuscleRegionShape(
                id: "\(side.rawValue)-\(spec.muscle.rawValue)",
                muscle: spec.muscle,
                side: side,
                path: path
            )
        }
    }

    private struct RegionSpec {
        let muscle: Muscle
        let mirrored: Bool
        let blobs: [[CGPoint]]

        init(_ muscle: Muscle, mirrored: Bool = true, _ blobs: [[CGPoint]]) {
            self.muscle = muscle
            self.mirrored = mirrored
            self.blobs = blobs
        }
    }

    private static func pts(_ values: [(CGFloat, CGFloat)]) -> [CGPoint] {
        values.map { CGPoint(x: $0.0, y: $0.1) }
    }

    // MARK: - Silhouette (right half, mirrored automatically)

    private static let silhouettePoints: [CGPoint] = {
        let right: [(CGFloat, CGFloat)] = [
            (150, 10), (168, 16), (177, 36), (172, 56), (163, 68),
            (161, 78), (176, 86), (200, 93), (214, 102),
            (224, 116), (229, 138), (233, 162), (237, 186),
            (241, 212), (246, 240), (250, 264), (252, 284),
            (254, 298), (247, 308), (238, 300), (233, 282),
            (228, 258), (222, 230), (215, 202), (208, 176),
            (204, 156), (201, 170), (194, 200), (188, 232),
            (186, 258), (191, 284), (199, 308), (201, 328),
            (197, 356), (190, 396), (185, 436), (183, 466),
            (187, 500), (183, 540), (175, 578), (173, 592),
            (186, 602), (184, 616), (160, 617), (161, 590),
            (165, 552), (161, 510), (158, 474), (160, 434),
            (157, 392), (152, 358)
        ]
        var all = right.map { CGPoint(x: $0.0, y: $0.1) }
        let mirrored = right.reversed().dropLast().map { CGPoint(x: 300 - $0.0, y: $0.1) }
        all.append(contentsOf: mirrored)
        return all
    }()

    // MARK: - Front muscles

    private static let frontSpecs: [RegionSpec] = [
        RegionSpec(.sideDelts, [pts([
            (212, 100), (226, 112), (230, 134), (222, 148), (212, 140), (214, 118)
        ])]),
        RegionSpec(.frontDelts, [pts([
            (194, 96), (212, 104), (218, 122), (211, 136), (200, 142), (194, 124)
        ])]),
        RegionSpec(.chest, [pts([
            (153, 106), (192, 102), (203, 118), (202, 144), (187, 161), (160, 165), (153, 156)
        ])]),
        RegionSpec(.biceps, [pts([
            (204, 150), (218, 152), (227, 178), (224, 200), (211, 198), (203, 172)
        ])]),
        RegionSpec(.forearms, [pts([
            (221, 206), (235, 210), (243, 240), (247, 266), (238, 270), (226, 244), (217, 222)
        ])]),
        RegionSpec(.abs, mirrored: false, [pts([
            (132, 172), (168, 172), (172, 222), (168, 272), (150, 284), (132, 272), (128, 222)
        ])]),
        RegionSpec(.obliques, [pts([
            (174, 182), (186, 198), (190, 232), (186, 258), (176, 270), (172, 232), (173, 200)
        ])]),
        RegionSpec(.hipFlexors, [pts([
            (156, 290), (176, 283), (186, 297), (172, 312), (158, 306)
        ])]),
        RegionSpec(.adductors, [pts([
            (154, 330), (168, 322), (174, 354), (168, 392), (158, 400), (151, 360)
        ])]),
        RegionSpec(.quads, [pts([
            (170, 330), (192, 323), (198, 362), (196, 412), (188, 452), (176, 458), (166, 420), (164, 372)
        ])]),
        RegionSpec(.tibialis, [pts([
            (172, 480), (182, 478), (185, 520), (178, 566), (170, 560), (168, 516)
        ])]),
        RegionSpec(.calves, [pts([
            (160, 478), (168, 483), (166, 530), (158, 540), (154, 506)
        ])]),
    ]

    // MARK: - Back muscles

    private static let backSpecs: [RegionSpec] = [
        RegionSpec(.traps, [pts([
            (150, 70), (174, 82), (200, 95), (186, 118), (162, 140), (150, 148)
        ])]),
        RegionSpec(.rearDelts, [pts([
            (200, 97), (220, 107), (228, 130), (218, 144), (204, 138), (198, 118)
        ])]),
        RegionSpec(.upperBack, [pts([
            (152, 150), (178, 132), (194, 146), (188, 168), (162, 176), (152, 166)
        ])]),
        RegionSpec(.lats, [pts([
            (156, 178), (190, 160), (201, 178), (195, 214), (178, 248), (158, 262), (153, 216)
        ])]),
        RegionSpec(.lowerBack, mirrored: false, [pts([
            (134, 250), (166, 250), (172, 280), (164, 306), (136, 306), (128, 280)
        ])]),
        RegionSpec(.triceps, [pts([
            (204, 150), (220, 152), (229, 180), (226, 204), (212, 202), (203, 174)
        ])]),
        RegionSpec(.forearms, [pts([
            (221, 208), (235, 212), (243, 242), (247, 266), (238, 270), (226, 246), (217, 224)
        ])]),
        RegionSpec(.glutes, [pts([
            (152, 302), (186, 297), (198, 317), (194, 348), (174, 361), (154, 353)
        ])]),
        RegionSpec(.hamstrings, [pts([
            (158, 368), (190, 362), (194, 402), (188, 448), (174, 460), (162, 432), (157, 396)
        ])]),
        RegionSpec(.calves, [pts([
            (162, 470), (186, 468), (190, 506), (182, 552), (170, 556), (159, 516)
        ])]),
    ]

    // MARK: - Smoothing

    /// Builds a smooth closed path through the given points using Catmull-Rom
    /// splines converted to cubic Béziers.
    private static func smoothClosedPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 2 else {
            if let first = points.first { path.addEllipse(in: CGRect(x: first.x - 2, y: first.y - 2, width: 4, height: 4)) }
            return path
        }
        let n = points.count
        path.move(to: points[0])
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n]
            let p1 = points[i]
            let p2 = points[(i + 1) % n]
            let p3 = points[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }
}
