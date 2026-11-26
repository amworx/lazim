"""Generate Lazim launcher icons.

Brand: warm clay (#C2553A) with a white checklist glyph, matching the in-app
logo on the sign-in screen. Produces legacy square icons plus Android adaptive
icon layers (foreground/background) so the icon masks correctly on every
launcher shape.

Run: python tool/make_icons.py
"""
import os
from PIL import Image, ImageDraw

CLAY = (194, 85, 58, 255)
WHITE = (255, 255, 255, 255)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

# Legacy icon sizes (48dp baseline).
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# Adaptive foreground is 108dp with the glyph inside the inner 66dp safe zone.
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

SS = 4  # supersample factor for smooth edges


def draw_glyph(size, glyph_scale, color):
    """Draw the checklist glyph centred on a transparent canvas."""
    canvas = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    S = size * SS

    # Glyph occupies glyph_scale of the canvas, centred.
    gw = S * glyph_scale
    ox = (S - gw) / 2
    oy = (S - gw) / 2

    stroke = max(1, int(gw * 0.085))
    r = stroke / 2

    def line(x1, y1, x2, y2):
        d.line(
            [(ox + x1 * gw, oy + y1 * gw), (ox + x2 * gw, oy + y2 * gw)],
            fill=color,
            width=stroke,
            joint="curve",
        )
        for (px, py) in ((x1, y1), (x2, y2)):
            d.ellipse(
                [ox + px * gw - r, oy + py * gw - r,
                 ox + px * gw + r, oy + py * gw + r],
                fill=color,
            )

    # Two rows: a check mark then a rule, stacked.
    # Row 1
    line(0.06, 0.30, 0.17, 0.41)
    line(0.17, 0.41, 0.34, 0.19)
    line(0.45, 0.30, 0.94, 0.30)
    # Row 2
    line(0.06, 0.68, 0.17, 0.79)
    line(0.17, 0.79, 0.34, 0.57)
    line(0.45, 0.68, 0.94, 0.68)

    return canvas.resize((size, size), Image.LANCZOS)


def rounded_rect(size, radius_ratio, fill):
    canvas = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    S = size * SS
    rad = int(S * radius_ratio)
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=rad, fill=fill)
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    for density, px in LEGACY.items():
        out_dir = os.path.join(RES, f"mipmap-{density}")
        os.makedirs(out_dir, exist_ok=True)

        # Legacy: clay rounded square + white glyph baked in.
        base = rounded_rect(px, 0.22, CLAY)
        glyph = draw_glyph(px, 0.62, WHITE)
        base.alpha_composite(glyph)
        base.save(os.path.join(out_dir, "ic_launcher.png"))

        # Adaptive foreground: transparent, glyph only, inside the safe zone.
        fg = draw_glyph(ADAPTIVE[density], 0.42, WHITE)
        fg.save(os.path.join(out_dir, "ic_launcher_foreground.png"))

        print(f"{density}: legacy {px}px, adaptive {ADAPTIVE[density]}px")

    # Adaptive icon descriptor.
    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n'
    )
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(xml)

    # Background colour resource.
    values = os.path.join(RES, "values")
    os.makedirs(values, exist_ok=True)
    colors_path = os.path.join(values, "colors.xml")
    with open(colors_path, "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<resources>\n"
            '    <color name="ic_launcher_background">#C2553A</color>\n'
            "</resources>\n"
        )

    print("adaptive icon xml + colors.xml written")


if __name__ == "__main__":
    main()
