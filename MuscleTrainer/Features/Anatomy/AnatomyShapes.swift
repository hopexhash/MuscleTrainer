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

/// Builds and caches anatomy geometry from the generated line-art path data
/// in `AnatomyArt` (360×780 design space, male/female × front/back).
enum AnatomyShapeStore {

    static let designSize = AnatomyArt.designSize

    // MARK: - Public API

    static func art(side: BodySide, gender: AnatomyGender) -> AnatomyArt.ViewArt {
        switch (side, gender) {
        case (.front, .male): return AnatomyArt.maleFront
        case (.back, .male): return AnatomyArt.maleBack
        case (.front, .female): return AnatomyArt.femaleFront
        case (.back, .female): return AnatomyArt.femaleBack
        }
    }

    /// Full-body outline (fill + stroke).
    static func outline(side: BodySide, gender: AnatomyGender) -> Path {
        cached(&outlineCache, side, gender) { path(from: art(side: side, gender: gender).outline) }
    }

    /// Interior detail lines (ab rows, seams, spine) — stroke only.
    static func details(side: BodySide, gender: AnatomyGender) -> Path {
        cached(&detailCache, side, gender) {
            var p = Path()
            for d in art(side: side, gender: gender).details { p.addPath(path(from: d)) }
            return p
        }
    }

    static func regions(side: BodySide, gender: AnatomyGender) -> [MuscleRegionShape] {
        let key = CacheKey(side: side, gender: gender)
        if let hit = regionCache[key] { return hit }
        let built = art(side: side, gender: gender).muscles.map { muscle, paths in
            var combined = Path()
            for d in paths { combined.addPath(path(from: d)) }
            return MuscleRegionShape(
                id: "\(side.rawValue)-\(muscle.rawValue)",
                muscle: muscle,
                side: side,
                path: combined
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
    nonisolated(unsafe) private static var outlineCache: [CacheKey: Path] = [:]
    nonisolated(unsafe) private static var detailCache: [CacheKey: Path] = [:]

    private static func cached(_ cache: inout [CacheKey: Path], _ side: BodySide, _ gender: AnatomyGender, build: () -> Path) -> Path {
        let key = CacheKey(side: side, gender: gender)
        if let hit = cache[key] { return hit }
        let built = build()
        cache[key] = built
        return built
    }

    // MARK: - Minimal SVG path-data parser (M / C / Z, absolute)

    static func path(from d: String) -> Path {
        var p = Path()
        let chars = Array(d)
        var i = 0

        func number() -> CGFloat {
            while i < chars.count, chars[i] == "," || chars[i] == " " { i += 1 }
            var s = ""
            while i < chars.count, chars[i].isNumber || chars[i] == "." || chars[i] == "-" {
                s.append(chars[i]); i += 1
            }
            return CGFloat(Double(s) ?? 0)
        }
        func point() -> CGPoint { CGPoint(x: number(), y: number()) }

        while i < chars.count {
            let c = chars[i]; i += 1
            switch c {
            case "M":
                p.move(to: point())
            case "C":
                let c1 = point(), c2 = point(), to = point()
                p.addCurve(to: to, control1: c1, control2: c2)
            case "L":
                p.addLine(to: point())
            case "Z":
                p.closeSubpath()
            default:
                break
            }
        }
        return p
    }
}
