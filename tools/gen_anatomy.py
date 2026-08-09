#!/usr/bin/env python3
"""
MuscleTrainer anatomy generator — original line-art figure.

Authors the figure once (right-half point lists, Catmull-Rom smoothed into
cubics), then emits:
  - preview PNGs (front/back) for visual iteration
  - anatomy.json (path strings for the HTML prototype)
  - AnatomyArt.swift (same path strings for the app)

Design space: 360 x 780. Centerline x = 180.
"""
import json, math, sys
from PIL import Image, ImageDraw

CX = 180.0
W, H = 360, 780

# ───────────────────────── helpers ─────────────────────────

def cr_cubics(pts, closed=True):
    """Catmull-Rom -> cubic segments [(p1,c1,c2,p2)...]. Duplicate a point to sharpen."""
    n = len(pts)
    segs = []
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if closed else pts[max(i - 1, 0)]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
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
            x = mt**3*p1[0] + 3*mt*mt*t*c1[0] + 3*mt*t*t*c2[0] + t**3*p2[0]
            y = mt**3*p1[1] + 3*mt*mt*t*c1[1] + 3*mt*t*t*c2[1] + t**3*p2[1]
            out.append((x, y))
    out.append(segs[-1][3])
    return out

def warp_female(pts):
    """Y-dependent x-scale around the centerline: narrower shoulders, wider hips."""
    ctrl = [(0,0.97),(120,0.96),(165,0.90),(240,0.90),(330,0.85),(392,1.00),(430,1.06),(560,1.00),(780,0.97)]
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

# ───────────────────────── FRONT ─────────────────────────
# Right half of the body outline, crown → crotch (mirrored automatically).

FRONT_OUTLINE_R = [
    (180,18),(200,22),(212,40),(214,62),          # crown → temple (narrower head)
    (211,84),(202,100),(192,108),                 # cheek → jaw
    (190,122),(194,134),                          # neck side
    (222,144),(252,154),(274,164),                # trap slope → shoulder pt
    (290,176),(298,196),(298,218),                # delt outer
    (303,256),(310,294),(316,328),                # upper-arm outer → elbow
    (323,360),(330,392),(334,422),                # forearm outer → wrist
    (345,450),(350,466),(348,484),(340,492),      # hand outer edge
    (329,492),(325,478),                          # fingertips
    (317,484),(308,476),(306,458),                # finger/thumb mass
    (304,436),                                    # wrist inner
    (296,398),(289,364),(283,332),                # forearm inner → elbow inner
    (276,298),(268,264),(258,236),                # upper-arm inner → armpit
    (255,234),                                    # armpit crease (tight)
    (249,262),(244,298),(240,330),                # chest side → waist
    (245,356),(252,378),(258,398),(261,416),      # hip flare
    (259,452),(254,492),(247,528),(240,558),      # outer thigh → knee
    (243,582),(244,608),(238,644),(228,678),(220,706),  # calf outer → ankle
    (226,722),(230,742),(222,756),(202,760),(190,748),(188,726),(190,708), # foot + toes
    (193,676),(196,644),(194,610),(196,576),(198,556),  # inner calf → knee inner
    (194,528),(190,494),(186,466),(182,446),      # inner thigh → crotch
    (180,440),
]

FRONT_MUSCLES = [
    ("traps", True, [(196,130),(226,140),(252,152),(246,158),(214,156),(197,144)]),
    ("frontDelts", True, [(234,160),(256,158),(270,168),(276,184),(272,202),(260,206),(246,188),(234,170)]),
    ("sideDelts", True, [(272,168),(288,178),(294,198),(293,220),(284,230),(273,212),(270,190)]),
    ("chest", True, [(183,172),(210,168),(236,172),(247,188),(248,210),(240,232),(222,244),(200,246),(186,240),(183,208)]),
    ("biceps", True, [(262,238),(276,244),(284,270),(289,304),(284,322),(272,320),(262,294),(258,262)]),
    ("forearms", True, [(287,336),(299,342),(309,370),(319,402),(325,428),(315,434),(303,410),(293,378),(286,350)]),
    ("abs", False, [(162,258),(180,254),(198,258),(206,284),(204,326),(198,372),(192,406),(180,424),(168,406),(162,372),(156,326),(154,284)]),
    ("obliques", True, [(210,300),(224,314),(232,338),(234,362),(226,390),(214,406),(206,384),(208,344),(208,318)]),
    ("quads", True, [(200,444),(224,426),(246,432),(256,468),(254,506),(246,538),(232,554),(216,548),(204,516),(198,480)]),
    ("adductors", True, [(184,448),(196,456),(202,492),(200,524),(190,536),(184,500),(181,468)]),
    ("tibialis", True, [(206,568),(220,572),(226,606),(224,648),(214,690),(206,664),(202,616)]),
    ("calves", True, [(230,574),(240,588),(240,624),(232,656),(226,624),(226,594)]),
]

# stroke-only interior lines (both sides where mirrored=True)
FRONT_DETAILS = [
    # face hint: none (clean). chest centerline:
    (False, [(180,168),(180,258)], False),
    # linea alba + ab rows
    (False, [(180,264),(180,430)], False),
    (False, [(157,300),(203,300)], False),
    (False, [(158,332),(202,332)], False),
    (False, [(162,366),(198,366)], False),
    # quad seam (rectus femoris)
    (True, [(228,436),(232,480),(228,530)], False),
    # collarbone hint
    (True, [(186,164),(216,160),(244,166)], False),
]

# ───────────────────────── BACK ─────────────────────────

BACK_OUTLINE_R = FRONT_OUTLINE_R  # same silhouette from behind

BACK_MUSCLES = [
    ("traps", True, [(181,124),(204,134),(238,150),(258,160),(242,176),(214,204),(196,226),(182,236)]),
    ("rearDelts", True, [(254,160),(272,166),(286,180),(292,200),(288,220),(276,228),(264,206),(256,180)]),
    ("upperBack", True, [(200,216),(228,210),(248,222),(244,246),(224,256),(204,252)]),
    ("lats", True, [(250,236),(254,264),(246,300),(230,332),(208,342),(196,336),(198,296),(210,266),(230,248)]),
    ("lowerBack", False, [(168,314),(180,310),(192,314),(196,350),(190,392),(180,402),(170,392),(164,350)]),
    ("triceps", True, [(262,236),(276,246),(284,276),(288,308),(282,326),(268,322),(260,292),(258,260)]),
    ("forearms", True, [(287,336),(299,342),(309,370),(319,402),(325,428),(315,434),(303,410),(293,378),(286,350)]),
    ("glutes", True, [(186,402),(214,394),(240,402),(250,430),(244,458),(224,472),(198,468),(186,448)]),
    ("hamstrings", True, [(200,482),(226,478),(244,484),(248,514),(240,546),(226,562),(208,554),(198,522)]),
    ("calves", True, [(202,572),(224,568),(238,580),(242,614),(234,652),(220,668),(206,650),(198,610)]),
]

BACK_DETAILS = [
    # spine
    (False, [(180,130),(180,404)], False),
    # glute seam
    (False, [(180,408),(180,476)], False),
    # hamstring seam
    (True, [(224,484),(226,520),(222,556)], False),
    # calf seam
    (True, [(220,572),(222,608),(218,650)], False),
]

# ───────────────────────── build ─────────────────────────

def build_outline(right_pts):
    full = right_pts + mirror_pts(list(reversed(right_pts))[1:-1])
    return cr_cubics(full, closed=True)

def build_view(outline_r, muscles, details, female=False):
    wf = warp_female if female else (lambda p: p)
    view = {"outline": segs_to_path(cr_cubics(wf(outline_r + mirror_pts(list(reversed(outline_r))[1:-1])), True)),
            "muscles": [], "details": []}
    for mid, mirrored, pts in muscles:
        paths = [segs_to_path(cr_cubics(wf(pts), True))]
        if mirrored:
            paths.append(segs_to_path(cr_cubics(wf(mirror_pts(pts)), True)))
        view["muscles"].append({"id": mid, "paths": paths})
    for mirrored, pts, closed in details:
        view["details"].append(segs_to_path(cr_cubics(wf(pts), closed), closed))
        if mirrored:
            view["details"].append(segs_to_path(cr_cubics(wf(mirror_pts(pts)), closed), closed))
    return view

# ───────────────────────── preview ─────────────────────────

def preview(view_name, outline_r, muscles, details, out_png):
    SC = 2
    img = Image.new("RGB", (W*SC, H*SC), (5, 7, 10))
    dr = ImageDraw.Draw(img)
    LINE = (94, 116, 142)
    BODYF = (14, 20, 28)
    MUSF = (26, 36, 48)

    def poly(segs): return [(x*SC, y*SC) for x, y in flatten(segs)]

    full = outline_r + mirror_pts(list(reversed(outline_r))[1:-1])
    dr.polygon(poly(cr_cubics(full, True)), fill=BODYF, outline=LINE, width=2)

    for mid, mirrored, pts in muscles:
        for P in ([pts, mirror_pts(pts)] if mirrored else [pts]):
            fill = (22, 135, 255) if mid == "chest" and view_name == "front" else MUSF
            dr.polygon(poly(cr_cubics(P, True)), fill=fill, outline=LINE, width=2)

    for mirrored, pts, closed in details:
        for P in ([pts, mirror_pts(pts)] if mirrored else [pts]):
            fp = poly(cr_cubics(P, closed)) if len(P) > 2 else [(x*SC, y*SC) for x, y in P]
            dr.line(fp, fill=LINE, width=2)

    img.save(out_png)
    print("wrote", out_png)


def emit_swift(data, path):
    lines = [
        "import SwiftUI",
        "",
        "/// Generated line-art anatomy: path data authored in a 360x780 design space.",
        "/// Regenerate with scratchpad/gen_anatomy.py --emit (edits there, not here).",
        "enum AnatomyArt {",
        "    static let designSize = CGSize(width: 360, height: 780)",
        "",
        "    struct ViewArt {",
        "        let outline: String",
        "        let muscles: [(Muscle, [String])]",
        "        let details: [String]",
        "    }",
        "",
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
    if "--emit" in sys.argv:
        data = {
            "front":  build_view(FRONT_OUTLINE_R, FRONT_MUSCLES, FRONT_DETAILS),
            "back":   build_view(BACK_OUTLINE_R, BACK_MUSCLES, BACK_DETAILS),
            "frontF": build_view(FRONT_OUTLINE_R, FRONT_MUSCLES, FRONT_DETAILS, female=True),
            "backF":  build_view(BACK_OUTLINE_R, BACK_MUSCLES, BACK_DETAILS, female=True),
        }
        json.dump(data, open("anatomy.json", "w"))
        print("wrote anatomy.json")
        emit_swift(data, "/home/user/MuscleTrainer/MuscleTrainer/Features/Anatomy/AnatomyArt.swift")
