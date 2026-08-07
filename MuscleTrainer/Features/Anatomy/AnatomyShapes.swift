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
/// The figure is a stylized capsule-anatomy: a soft skeleton silhouette
/// (head, torso, limbs) with each muscle drawn as a rounded shape on top.
/// Everything is authored in a fixed 200×420 design space, mirrored around
/// x = 100 for symmetric muscles, with male/female torso and chest variants.
enum AnatomyShapeStore {

    static let designSize = CGSize(width: 200, height: 420)

    // MARK: - Public API

    /// Skeleton layers, drawn first: (path, isLimb). Head/torso use the base
    /// body color; neck/limbs use the slightly darker limb color.
    static func skeleton(gender: AnatomyGender) -> (base: Path, limbs: Path) {
        if let cached = skeletonCache[gender] { return cached }

        var base = Path()
        base.addEllipse(in: rect(cx: 100, cy: 30, rx: 17, ry: 21))
        base.addPath(torso(gender: gender))

        var limbs = Path()
        limbs.addRoundedRect(in: CGRect(x: 90, y: 44, width: 20, height: 16), cornerSize: CGSize(width: 7, height: 7))
        for p in limbPaths() {
            limbs.addPath(p)
            limbs.addPath(mirror(p))
        }

        let result = (base, limbs)
        skeletonCache[gender] = result
        return result
    }

    static func regions(side: BodySide, gender: AnatomyGender) -> [MuscleRegionShape] {
        let key = CacheKey(side: side, gender: gender)
        if let cached = regionCache[key] { return cached }
        let specs = side == .front ? frontSpecs(gender: gender) : backSpecs()
        let built = specs.map { (muscle, path) in
            var full = path
            full.addPath(mirror(path))
            return MuscleRegionShape(
                id: "\(side.rawValue)-\(muscle.rawValue)",
                muscle: muscle,
                side: side,
                path: full
            )
        }
        regionCache[key] = built
        return built
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
    nonisolated(unsafe) private static var skeletonCache: [AnatomyGender: (base: Path, limbs: Path)] = [:]

    // MARK: - Shape helpers

    private static func rect(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> CGRect {
        CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
    }

    private static func rotation(_ degrees: CGFloat, around p: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: p.x, y: p.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -p.x, y: -p.y)
    }

    private static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, rotate degrees: CGFloat = 0) -> Path {
        let p = Path(ellipseIn: rect(cx: cx, cy: cy, rx: rx, ry: ry))
        guard degrees != 0 else { return p }
        return p.applying(rotation(degrees, around: CGPoint(x: cx, y: cy)))
    }

    private static func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat,
                              rotate degrees: CGFloat = 0, pivot: CGPoint? = nil) -> Path {
        let p = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
        guard degrees != 0 else { return p }
        let center = pivot ?? CGPoint(x: x + w / 2, y: y + h / 2)
        return p.applying(rotation(degrees, around: center))
    }

    private static func mirror(_ p: Path) -> Path {
        p.applying(CGAffineTransform(translationX: 200, y: 0).scaledBy(x: -1, y: 1))
    }

    // MARK: - Skeleton geometry

    private static func torso(gender: AnatomyGender) -> Path {
        var p = Path()
        if gender == .female {
            p.move(to: CGPoint(x: 66, y: 78))
            p.addCurve(to: CGPoint(x: 73, y: 152), control1: CGPoint(x: 61, y: 94), control2: CGPoint(x: 67, y: 126))
            p.addLine(to: CGPoint(x: 71, y: 192))
            p.addCurve(to: CGPoint(x: 100, y: 215), control1: CGPoint(x: 73, y: 207), control2: CGPoint(x: 83, y: 215))
            p.addCurve(to: CGPoint(x: 129, y: 192), control1: CGPoint(x: 117, y: 215), control2: CGPoint(x: 127, y: 207))
            p.addLine(to: CGPoint(x: 127, y: 152))
            p.addCurve(to: CGPoint(x: 134, y: 78), control1: CGPoint(x: 133, y: 126), control2: CGPoint(x: 139, y: 94))
            p.addCurve(to: CGPoint(x: 100, y: 65), control1: CGPoint(x: 126, y: 69), control2: CGPoint(x: 116, y: 65))
            p.addCurve(to: CGPoint(x: 66, y: 78), control1: CGPoint(x: 84, y: 65), control2: CGPoint(x: 74, y: 69))
        } else {
            p.move(to: CGPoint(x: 62, y: 76))
            p.addCurve(to: CGPoint(x: 67, y: 150), control1: CGPoint(x: 57, y: 92), control2: CGPoint(x: 61, y: 122))
            p.addLine(to: CGPoint(x: 73, y: 192))
            p.addCurve(to: CGPoint(x: 100, y: 213), control1: CGPoint(x: 75, y: 206), control2: CGPoint(x: 83, y: 213))
            p.addCurve(to: CGPoint(x: 127, y: 192), control1: CGPoint(x: 117, y: 213), control2: CGPoint(x: 125, y: 206))
            p.addLine(to: CGPoint(x: 133, y: 150))
            p.addCurve(to: CGPoint(x: 138, y: 76), control1: CGPoint(x: 139, y: 122), control2: CGPoint(x: 143, y: 92))
            p.addCurve(to: CGPoint(x: 100, y: 63), control1: CGPoint(x: 130, y: 67), control2: CGPoint(x: 118, y: 63))
            p.addCurve(to: CGPoint(x: 62, y: 76), control1: CGPoint(x: 82, y: 63), control2: CGPoint(x: 70, y: 67))
        }
        p.closeSubpath()
        return p
    }

    /// Left-side limbs; callers mirror for the right side.
    private static func limbPaths() -> [Path] {
        [
            rrect(43, 80, 22, 66, 11, rotate: 5, pivot: CGPoint(x: 54, y: 113)),   // upper arm
            rrect(36, 142, 19, 64, 9.5, rotate: 6, pivot: CGPoint(x: 45, y: 174)), // forearm
            ellipse(42, 216, 8.5, 12),                                             // hand
            rrect(66, 198, 32, 102, 16),                                           // thigh
            rrect(70, 294, 24, 96, 12),                                            // shin
            ellipse(80, 398, 11, 9),                                               // foot
        ]
    }

    // MARK: - Muscle geometry (left side; mirrored automatically)

    private static func frontSpecs(gender: AnatomyGender) -> [(Muscle, Path)] {
        let chest: Path = gender == .female
            ? rrect(79, 79, 19, 27, 12, rotate: -4, pivot: CGPoint(x: 88, y: 91))
            : rrect(78, 76, 20.5, 31, 9, rotate: -4, pivot: CGPoint(x: 88, y: 91))

        var abs = Path()
        abs.addPath(rrect(89, 113, 9.5, 11, 3))
        abs.addPath(rrect(89, 127, 9.5, 11, 3))
        abs.addPath(rrect(89, 141, 9.5, 11, 3))
        abs.addPath(rrect(89, 155, 9.5, 10, 3))

        return [
            (.sideDelts, ellipse(63, 86, 12.5, 14, rotate: -8)),
            (.frontDelts, ellipse(77, 82, 10, 11.5)),
            (.chest, chest),
            (.biceps, ellipse(57, 118, 9.5, 19, rotate: 6)),
            (.forearms, ellipse(47, 170, 8.5, 24, rotate: 6)),
            (.abs, abs),
            (.obliques, ellipse(81, 138, 6.5, 21, rotate: -5)),
            (.quads, ellipse(82, 244, 14.5, 42)),
            (.adductors, ellipse(95, 238, 6, 30)),
            (.tibialis, ellipse(85, 336, 6, 31)),
            (.calves, ellipse(73, 332, 6, 25)),
        ]
    }

    private static func backSpecs() -> [(Muscle, Path)] {
        var traps = Path()
        traps.move(to: CGPoint(x: 99, y: 58))
        traps.addLine(to: CGPoint(x: 99, y: 104))
        traps.addLine(to: CGPoint(x: 72, y: 86))
        traps.addCurve(to: CGPoint(x: 99, y: 58), control1: CGPoint(x: 75, y: 70), control2: CGPoint(x: 86, y: 60))
        traps.closeSubpath()

        var lats = Path()
        lats.move(to: CGPoint(x: 79, y: 100))
        lats.addCurve(to: CGPoint(x: 85, y: 160), control1: CGPoint(x: 68, y: 116), control2: CGPoint(x: 71, y: 144))
        lats.addLine(to: CGPoint(x: 98, y: 152))
        lats.addLine(to: CGPoint(x: 98, y: 104))
        lats.closeSubpath()

        return [
            (.traps, traps),
            (.rearDelts, ellipse(64, 86, 12.5, 14, rotate: -8)),
            (.upperBack, rrect(80, 96, 18, 26, 6)),
            (.lats, lats),
            (.lowerBack, rrect(84, 160, 14, 28, 5)),
            (.triceps, ellipse(55, 118, 9.5, 19, rotate: 6)),
            (.forearms, ellipse(47, 170, 8.5, 24, rotate: 6)),
            (.glutes, ellipse(85, 206, 16, 16)),
            (.hamstrings, ellipse(83, 258, 13.5, 38)),
            (.calves, ellipse(82, 332, 8.5, 30)),
        ]
    }
}
