#!/usr/bin/env python3
"""
MuscleTrainer anatomy generator v2 — detailed line-art figure from the user's
reference: light body, dark outlines, flared arms with hands, segmented abs,
sartorius/patella/gastroc details. Front = left of reference, back = right.

Design space: 440 x 780. Centerline x = 220.
Emits preview PNGs, anatomy.json (prototype) and AnatomyArt.swift (app).
"""
import json, sys
from PIL import Image, ImageDraw

CX = 220.0
W, H = 440, 780

def cr_cubics(pts, closed=True):
    n = len(pts); segs = []
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if closed else pts[max(i - 1, 0)]
        p1 = pts[i]; p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if closed else pts[min(i + 2, n - 1)]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        segs.append((p1, c1, c2, p2))
    return segs

def mirror_pt(p): return (2 * CX - p[0], p[1])
def mirror_pts(pts): return [mirror_pt(p) for p in pts]

def segs_to_path(segs, close=True):
    d = f"M{segs[0][0][0]:.1f},{segs[0][0][1]:.1f}"
    for (_, c1, c2, p2) in segs:
        d += f"C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}"
    return d + ("Z" if close else "")

def flatten(segs, n=22):
    out = []
    for (p1, c1, c2, p2) in segs:
        for i in range(n):
            t = i / n; mt = 1 - t
            out.append((mt**3*p1[0] + 3*mt*mt*t*c1[0] + 3*mt*t*t*c2[0] + t**3*p2[0],
                        mt**3*p1[1] + 3*mt*mt*t*c1[1] + 3*mt*t*t*c2[1] + t**3*p2[1]))
    out.append(segs[-1][3])
    return out

def warp_female(pts):
    ctrl = [(0,0.95),(100,0.93),(140,0.87),(210,0.86),(260,0.84),(320,0.80),(370,0.94),(420,1.05),(470,1.02),(560,0.98),(660,0.94),(780,0.95)]
    out = []
    for x, y in pts:
        f = ctrl[-1][1]
        for i in range(1, len(ctrl)):
            if y <= ctrl[i][0]:
                y0, f0 = ctrl[i-1]; y1, f1 = ctrl[i]
                t = (y - y0) / (y1 - y0) if y1 > y0 else 0
                f = f0 + (f1 - f0) * t
                break
        out.append((CX + (x - CX) * f, y))
    return out

def blobs(spec):
    """Muscle spec points may be one point-list or a list of point-lists."""
    return spec if isinstance(spec[0], list) else [spec]

# ───────────────────────── FRONT ─────────────────────────
# Right half of outline, crown → crotch. Arms flared, open hands.

FRONT_OUTLINE_R = [
    (220,14),(242,18),(252,36),(253,58),          # crown → temple
    (250,80),(242,94),(232,100),                  # cheek → jaw
    (230,112),(232,124),(240,131),                # neck side
    (256,137),(278,144),(294,152),                # trap slope → shoulder
    (308,162),(316,180),(318,202),                # delt cap
    (324,236),(334,268),(344,296),                # upper arm outer → elbow
    (356,326),(366,360),(374,394),                # forearm outer
    (380,412),(392,434),(400,458),(396,478),(384,486), # palm edge + fingertips
    (372,482),(362,466),                          # finger mass inner
    (352,452),(346,432),(346,416),                # thumb / wrist inner
    (336,382),(326,346),(316,308),                # forearm inner
    (306,268),(296,236),(284,214),                # upper arm inner → armpit
    (281,212),                                    # armpit crease
    (276,232),(266,278),(258,320),                # chest side → waist
    (264,352),(272,378),(278,400),(280,416),      # hip flare
    (277,452),(271,500),(264,534),(260,560),      # outer thigh → knee
    (266,590),(268,620),(260,658),(256,688),(254,706), # calf outer → ankle
    (262,720),(264,742),(252,755),(234,756),(228,738),(228,714), # foot + toes
    (232,676),(236,634),(234,596),(232,566),      # inner lower leg
    (230,524),(228,478),(222,446),                # inner thigh → crotch
    (220,438),
]

FRONT_MUSCLES = [
    ("traps", True, [(234,128),(258,138),(282,148),(274,154),(248,152),(234,140)]),
    ("frontDelts", True, [(288,154),(300,158),(308,170),(310,186),(304,200),(292,198),(284,180),(283,164)]),
    ("sideDelts", True, [(306,164),(314,176),(317,196),(314,214),(304,222),(296,208),(298,186),(300,172)]),
    ("chest", True, [(224,164),(248,160),(268,166),(279,182),(280,206),(271,228),(252,240),(230,242),(224,236),(223,200)]),
    ("biceps", True, [(288,224),(301,232),(310,258),(315,288),(309,304),(296,300),(287,272),(284,246)]),
    ("forearms", True, [(319,314),(333,322),(345,350),(357,384),(364,406),(354,412),(341,388),(329,352),(317,326)]),
    # segmented rectus — 4 block rows per side (mirrored automatically)
    ("abs", True, [
        [(226,258),(246,254),(250,262),(248,286),(226,290),(223,266)],
        [(225,296),(247,292),(249,300),(247,324),(225,328),(222,304)],
        [(224,334),(246,330),(248,338),(246,362),(224,366),(221,342)],
        [(223,372),(245,368),(247,378),(243,416),(230,432),(221,404),(220,382)],
    ]),
    ("obliques", True, [(254,270),(268,290),(274,322),(272,356),(263,392),(252,406),(246,372),(248,320),(250,290)]),
    ("quads", True, [(236,446),(262,438),(275,470),(273,514),(264,552),(248,562),(236,548),(230,504),(231,470)]),
    ("adductors", True, [(226,452),(236,464),(240,502),(234,528),(226,506),(223,472)]),
]

FRONT_DETAILS = [
    # sternocleidomastoid V
    (True, [(226,106),(230,122),(236,134)], False),
    # clavicles
    (True, [(226,158),(254,152),(284,158)], False),
    # chest centerline
    (False, [(220,164),(220,244)], False),
    # linea alba
    (False, [(220,252),(220,434)], False),
    # inguinal V
    (True, [(262,410),(232,446)], False),
    # sartorius diagonal
    (True, [(266,444),(242,532)], False),
    # rectus femoris seam
    (True, [(254,450),(251,542)], False),
    # patella
    (True, [(246,568),(254,574),(252,588),(242,590),(238,578)], True),
    # shin line
    (True, [(244,600),(248,640),(240,690)], False),
    # finger lines
    (True, [(378,436),(390,462)], False),
    (True, [(370,442),(380,470)], False),
]

# ───────────────────────── BACK ─────────────────────────

BACK_OUTLINE_R = FRONT_OUTLINE_R

BACK_MUSCLES = [
    ("traps", True, [(222,118),(244,130),(274,144),(290,152),(272,166),(246,194),(230,220),(222,230)]),
    ("rearDelts", True, [(292,152),(306,160),(314,176),(316,198),(308,216),(296,210),(288,188),(286,164)]),
    ("upperBack", True, [(230,206),(258,198),(280,210),(276,236),(254,248),(234,242)]),
    ("lats", True, [(278,244),(283,274),(274,310),(256,342),(238,354),(226,348),(228,304),(240,272),(260,254)]),
    ("lowerBack", False, [(206,318),(220,314),(234,318),(238,354),(231,396),(220,406),(209,396),(202,354)]),
    ("triceps", True, [(288,222),(302,230),(312,258),(318,290),(311,308),(297,304),(288,276),(285,248)]),
    ("forearms", True, [(319,314),(333,322),(345,350),(357,384),(364,406),(354,412),(341,388),(329,352),(317,326)]),
    ("glutes", True, [(226,412),(254,404),(276,414),(284,442),(277,472),(255,486),(231,480),(222,452)]),
    ("hamstrings", True, [(234,494),(262,490),(277,500),(279,530),(270,560),(252,572),(237,562),(229,528)]),
    # gastrocnemius: outer + inner heads
    ("calves", True, [
        [(256,594),(266,608),(263,648),(252,670),(248,636),(250,610)],
        [(232,592),(242,602),(240,646),(232,662),(226,630),(228,606)],
    ]),
]

BACK_DETAILS = [
    # spine + sacrum
    (False, [(220,116),(220,408)], False),
    (True, [(232,408),(221,432)], False),
    # scapula line
    (True, [(238,208),(266,226)], False),
    # triceps horseshoe seam
    (True, [(300,240),(304,278)], False),
    # glute split
    (False, [(220,412),(220,486)], False),
    # hamstring split
    (True, [(256,494),(258,530),(252,564)], False),
    # achilles
    (True, [(244,674),(242,706)], False),
    # finger lines
    (True, [(378,436),(390,462)], False),
    (True, [(370,442),(380,470)], False),
]


# Female-specific shapes (final coordinates, not warped)
FEMALE_CHEST = [(223,166),(242,162),(258,170),(266,186),(265,206),(256,222),(240,230),(226,228),(222,214),(221,188)]
FEMALE_GLUTES = [(224,406),(252,396),(276,410),(285,442),(277,478),(254,494),(228,488),(219,450)]
FEMALE_QUADS = [(233,446),(256,438),(268,470),(266,514),(258,552),(243,562),(232,548),(227,504),(228,470)]

# ───────────────────────── build/emit ─────────────────────────

def build_view(outline_r, muscles, details, female=False, overrides=None):
    wf = warp_female if female else (lambda p: p)
    overrides = overrides or {}
    full = outline_r + mirror_pts(list(reversed(outline_r))[1:-1])
    view = {"outline": segs_to_path(cr_cubics(wf(full), True)), "muscles": [], "details": []}
    for mid, mirrored, spec in muscles:
        paths = []
        use_wf = wf
        if mid in overrides:
            spec = overrides[mid]
            use_wf = lambda p: p  # override points are already in final coordinates
        for pts in blobs(spec):
            paths.append(segs_to_path(cr_cubics(use_wf(pts), True)))
            if mirrored:
                paths.append(segs_to_path(cr_cubics(use_wf(mirror_pts(pts)), True)))
        view["muscles"].append({"id": mid, "paths": paths})
    for mirrored, pts, closed in details:
        view["details"].append(segs_to_path(cr_cubics(wf(pts), closed), closed))
        if mirrored:
            view["details"].append(segs_to_path(cr_cubics(wf(mirror_pts(pts)), closed), closed))
    return view

def preview(view_name, outline_r, muscles, details, out_png):
    SC = 2
    img = Image.new("RGB", (W*SC, H*SC), (5, 9, 11))
    dr = ImageDraw.Draw(img)
    LINE = (207, 227, 235); BODYF = (11, 17, 21); MUSF = (15, 23, 28)
    def poly(segs): return [(x*SC, y*SC) for x, y in flatten(segs)]
    full = outline_r + mirror_pts(list(reversed(outline_r))[1:-1])
    dr.polygon(poly(cr_cubics(full, True)), fill=BODYF, outline=LINE, width=3)
    for mid, mirrored, spec in muscles:
        for pts in blobs(spec):
            for Pts in ([pts, mirror_pts(pts)] if mirrored else [pts]):
                fill = (43, 212, 238) if mid == "chest" and view_name == "front" else MUSF
                dr.polygon(poly(cr_cubics(Pts, True)), fill=fill, outline=LINE, width=3)
    for mirrored, pts, closed in details:
        for Pts in ([pts, mirror_pts(pts)] if mirrored else [pts]):
            dr.line(poly(cr_cubics(Pts, closed)), fill=LINE, width=3)
    img.save(out_png)
    print("wrote", out_png)

def emit_swift(data, path):
    lines = [
        "import SwiftUI", "",
        "/// Generated line-art anatomy: path data authored in a 440x780 design space.",
        "/// Regenerate with tools/gen_anatomy.py --emit (edit there, not here).",
        "enum AnatomyArt {",
        f"    static let designSize = CGSize(width: {W}, height: {H})", "",
        "    struct ViewArt {",
        "        let outline: String",
        "        let muscles: [(Muscle, [String])]",
        "        let details: [String]",
        "    }", "",
    ]
    names = {"front": "maleFront", "back": "maleBack", "frontF": "femaleFront", "backF": "femaleBack"}
    for key, name in names.items():
        v = data[key]
        lines.append(f"    static let {name} = ViewArt(")
        lines.append(f'        outline: "{v["outline"]}",')
        lines.append("        muscles: [")
        for m in v["muscles"]:
            paths = ", ".join(f'"{p}"' for p in m["paths"])
            lines.append(f'            (.{m["id"]}, [{paths}]),')
        lines.append("        ],")
        lines.append("        details: [")
        for d in v["details"]:
            lines.append(f'            "{d}",')
        lines.append("        ]")
        lines.append("    )")
        lines.append("")
    lines.append("}")
    open(path, "w").write("\n".join(lines))
    print("wrote", path)

if __name__ == "__main__":
    preview("front", FRONT_OUTLINE_R, FRONT_MUSCLES, FRONT_DETAILS, "preview_front.png")
    preview("back", BACK_OUTLINE_R, BACK_MUSCLES, BACK_DETAILS, "preview_back.png")
    def fem_preview(view_name, outline_r, muscles, details, overrides, out):
        wm = []
        for mid, mirrored, spec in muscles:
            if mid in overrides:
                wm.append((mid, mirrored, overrides[mid]))
            else:
                fspec = [warp_female(b) for b in blobs(spec)]
                wm.append((mid, mirrored, fspec if len(fspec) > 1 else fspec[0]))
        wd = [(m, warp_female(p), c) for m, p, c in details]
        preview(view_name, warp_female(outline_r), wm, wd, out)
    fem_preview("frontF", FRONT_OUTLINE_R, FRONT_MUSCLES, FRONT_DETAILS,
                {"chest": FEMALE_CHEST, "quads": FEMALE_QUADS}, "preview_front_f.png")
    fem_preview("backF", BACK_OUTLINE_R, BACK_MUSCLES, BACK_DETAILS,
                {"glutes": FEMALE_GLUTES}, "preview_back_f.png")
    if "--emit" in sys.argv:
        data = {
            "front":  build_view(FRONT_OUTLINE_R, FRONT_MUSCLES, FRONT_DETAILS),
            "back":   build_view(BACK_OUTLINE_R, BACK_MUSCLES, BACK_DETAILS),
            "frontF": build_view(FRONT_OUTLINE_R, FRONT_MUSCLES, FRONT_DETAILS, female=True,
                                 overrides={"chest": FEMALE_CHEST, "quads": FEMALE_QUADS}),
            "backF":  build_view(BACK_OUTLINE_R, BACK_MUSCLES, BACK_DETAILS, female=True,
                                 overrides={"glutes": FEMALE_GLUTES}),
        }
        json.dump(data, open("anatomy.json", "w"))
        print("wrote anatomy.json")
        emit_swift(data, "/home/user/MuscleTrainer/MuscleTrainer/Features/Anatomy/AnatomyArt.swift")
