"""Draws the dialog and menu bar icons for the Mac menu (pure Python, no extra libraries).

Usage:  python3 generate.py [output folder]     (default: this folder)
Style:  dark tile (fits Dark Mode), muted coloured glyph, glyph automatically centred.

Output:
  power-on.icns/.png   power-off.icns/.png   sleep.icns/.png      512x512 dialog icons
  menubar-on.png       menubar-off.png       menubar-sleep.png    36x36 @2x menu bar icons
"""
import math, os, struct, sys, zlib

N = 512
C = N / 2
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)

TILE_TOP = (52, 52, 56)      # dark grey, slightly lighter at the top
TILE_BOTTOM = (24, 24, 27)
BORDER = (82, 82, 88)        # thin light border so the tile stands out on a dark window

# muted colours so nothing jumps out
GREEN = (126, 196, 142)
RED = (214, 128, 122)
YELLOW = (230, 206, 132)


def clamp(x, a=0.0, b=1.0):
    return a if x < a else b if x > b else x


# --- signed distance functions: < 0 inside the shape, > 0 outside (gives smooth anti-aliasing) ---

def sd_roundbox(px, py, cx, cy, hw, hh, r):
    qx = abs(px - cx) - (hw - r)
    qy = abs(py - cy) - (hh - r)
    return math.hypot(max(qx, 0.0), max(qy, 0.0)) + min(max(qx, qy), 0.0) - r


def sd_segment(px, py, ax, ay, bx, by, w):
    pax, pay, bax, bay = px - ax, py - ay, bx - ax, by - ay
    h = clamp((pax * bax + pay * bay) / (bax * bax + bay * bay))
    return math.hypot(pax - bax * h, pay - bay * h) - w


def sd_power(px, py, R=100, w=17, gap_deg=42):
    """Power symbol around (0,0): open ring (gap at the top) + vertical bar, rounded ends."""
    ang = math.degrees(math.atan2(px, -py))  # 0 degrees = up
    if abs(ang) > gap_deg:
        ring = abs(math.hypot(px, py) - R) - w
    else:
        ring = min(math.hypot(px - s * R * math.sin(math.radians(gap_deg)),
                              py + R * math.cos(math.radians(gap_deg))) - w for s in (-1, 1))
    return min(ring, sd_segment(px, py, 0, -R - w * 0.6, 0, -R * 0.15, w))


def sd_star(px, py, cx, cy, r):
    """Four-pointed sparkle with radius r."""
    dx, dy = abs(px - cx), abs(py - cy)
    return (math.sqrt(dx) + math.sqrt(dy) - math.sqrt(r)) * 2 * math.sqrt(r)


def sd_crescent(px, py, R=110):
    return max(math.hypot(px, py) - R, -(math.hypot(px - R * 0.55, py + R * 0.45) - R * 0.85))


def sd_moon(px, py, R=110):
    """Crescent with two sparkles in the cut-out, around (0,0)."""
    return min(sd_crescent(px, py, R), sd_star(px, py, R * 0.68, -R * 0.40, 30), sd_star(px, py, R * 1.08, R * 0.20, 17))


def centred(glyph):
    """Shift a glyph so its visible area sits exactly in the middle of the tile."""
    xs, ys = [], []
    for y in range(-200, 201, 2):
        for x in range(-200, 201, 2):
            if glyph(x, y) <= 0:
                xs.append(x); ys.append(y)
    mx, my = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    return lambda x, y: glyph(x - C + mx, y - C + my)


def png_bytes(w, h, rows, dpi=72):
    def chunk(typ, data):
        return struct.pack(">I", len(data)) + typ + data + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)
    ppm = round(dpi / 0.0254)  # pixels per metre; 144 dpi = Retina (@2x)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"pHYs", struct.pack(">IIB", ppm, ppm, 1))
            + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b""))


def render_tile(colour, glyph):
    """512x512 dialog icon: dark rounded tile with coloured glyph."""
    glyph = centred(glyph)
    rows = []
    for y in range(N):
        t = y / (N - 1)
        bg = [TILE_TOP[i] + (TILE_BOTTOM[i] - TILE_TOP[i]) * t for i in range(3)]
        row = bytearray([0])  # PNG filter "None"
        for x in range(N):
            px, py = x + 0.5, y + 0.5
            d_box = sd_roundbox(px, py, C, C, 206, 206, 92)
            a_box = clamp(0.5 - d_box)
            a_border = clamp(0.5 - abs(d_box + 2.0) + 1.0)   # ~2 px border along the inner edge
            a_glyph = clamp(0.5 - glyph(px, py))
            col = [bg[i] + (BORDER[i] - bg[i]) * a_border for i in range(3)]
            col = [col[i] + (colour[i] - col[i]) * a_glyph for i in range(3)]
            row += bytes((int(col[0]), int(col[1]), int(col[2]), int(255 * a_box)))
        rows.append(bytes(row))
    return png_bytes(N, N, rows)


def render_menubar(colour, glyph, size=36):
    """Small menu bar icon: glyph only, transparent background, @2x (144 dpi)."""
    glyph = centred(glyph)
    s = 264 / (size - 2)   # glyph (about 260 units wide) fills the icon with a 1 px margin
    rows = []
    for y in range(size):
        row = bytearray([0])
        for x in range(size):
            gx = C + (x + 0.5 - size / 2) * s
            gy = C + (y + 0.5 - size / 2) * s
            a = clamp(0.5 - glyph(gx, gy) / s)
            row += bytes((colour[0], colour[1], colour[2], int(255 * a)))
        rows.append(bytes(row))
    return png_bytes(size, size, rows, dpi=144)


def icns(png):
    entry = b"ic09" + struct.pack(">I", 8 + len(png)) + png  # ic09 = 512x512 PNG
    return b"icns" + struct.pack(">I", 8 + len(entry)) + entry


# menu bar variant with thicker strokes so it stays readable when small
power_bold = lambda x, y: sd_power(x, y, R=100, w=24)

ICONS = {
    # dialog name, menu bar name: (colour, dialog glyph, menu bar glyph)
    ("power-on", "menubar-on"): (GREEN, sd_power, power_bold),
    ("power-off", "menubar-off"): (RED, sd_power, power_bold),
    ("sleep", "menubar-sleep"): (YELLOW, sd_moon, sd_crescent),  # stars would be too tiny in the menu bar
}
for (dialog, bar), (colour, glyph, glyph_small) in ICONS.items():
    png = render_tile(colour, glyph)
    open(os.path.join(OUT, dialog + ".png"), "wb").write(png)
    open(os.path.join(OUT, dialog + ".icns"), "wb").write(icns(png))
    open(os.path.join(OUT, bar + ".png"), "wb").write(render_menubar(colour, glyph_small))
    print("created", dialog, "+", bar)
