"""Generate a README banner with the Kiln app icon, grain texture, and title."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Dimensions — wide banner, not too tall
WIDTH = 1280
HEIGHT = 320

# Colors from DesignSystem
BG_COLOR = (245, 240, 235)        # Warm cream #F5F0EB
PRIMARY = (191, 51, 38)           # Fire red #BF3326
TEXT_SECONDARY = (107, 91, 79)    # Warm gray-brown #6B5B4F

# Paths
ICON_PATH = ROOT / "Kiln" / "Assets.xcassets" / "AppIcon.appiconset" / "kiln_icon.png"
NOISE_PATH = ROOT / "Kiln" / "Assets.xcassets" / "noise_tile.imageset" / "noise_tile.png"
OUTPUT_PATH = ROOT / "screenshots" / "banner.png"


def tile_noise(width, height, tile_path):
    """Tile the noise texture across the given dimensions."""
    tile = Image.open(tile_path).convert("L")
    tw, th = tile.size
    tiled = Image.new("L", (width, height))
    for x in range(0, width, tw):
        for y in range(0, height, th):
            tiled.paste(tile, (x, y))
    return tiled


def make_rounded_icon(icon, size, radius):
    """Resize icon and apply rounded corners."""
    icon = icon.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rounded.paste(icon, (0, 0), mask)
    return rounded


def main():
    # Base canvas
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), BG_COLOR + (255,))

    # Apply grain texture (multiply blend, subtle)
    noise = tile_noise(WIDTH, HEIGHT, NOISE_PATH)
    noise_rgba = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    for x in range(WIDTH):
        for y in range(HEIGHT):
            v = noise.getpixel((x, y))
            # Multiply blend: darken the background slightly based on noise
            noise_rgba.putpixel((x, y), (v, v, v, 30))
    canvas = Image.alpha_composite(canvas, noise_rgba)

    # This pixel-by-pixel approach is slow, use numpy instead
    pass  # we'll do it differently below

    # Actually, let's redo with a faster approach
    import numpy as np

    canvas = Image.new("RGBA", (WIDTH, HEIGHT), BG_COLOR + (255,))
    canvas_arr = np.array(canvas, dtype=np.float32)

    noise = tile_noise(WIDTH, HEIGHT, NOISE_PATH)
    noise_arr = np.array(noise, dtype=np.float32) / 255.0

    # Multiply blend at 12% opacity (matching the app's 0.12)
    opacity = 0.12
    for c in range(3):
        canvas_arr[:, :, c] = canvas_arr[:, :, c] * (1.0 - opacity + opacity * noise_arr)

    canvas = Image.fromarray(canvas_arr.clip(0, 255).astype(np.uint8), "RGBA")

    # Add app icon
    icon = Image.open(ICON_PATH).convert("RGBA")
    icon_size = 180
    icon_radius = 40
    rounded_icon = make_rounded_icon(icon, icon_size, icon_radius)

    # Add a subtle shadow behind the icon
    shadow = Image.new("RGBA", (icon_size + 20, icon_size + 20), (0, 0, 0, 0))
    shadow_mask = Image.new("L", (icon_size, icon_size), 0)
    ImageDraw.Draw(shadow_mask).rounded_rectangle([0, 0, icon_size - 1, icon_size - 1], radius=icon_radius, fill=60)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(radius=8))
    shadow_layer = Image.new("RGBA", (icon_size, icon_size), (80, 50, 30, 0))
    for x in range(icon_size):
        for y in range(icon_size):
            a = shadow_mask.getpixel((x, y))
            shadow_layer.putpixel((x, y), (80, 50, 30, a))

    # Position: icon left-of-center, text right of icon
    total_content_width = icon_size + 30 + 400  # icon + gap + ~text width
    start_x = (WIDTH - total_content_width) // 2
    icon_y = (HEIGHT - icon_size) // 2

    # Paste shadow then icon
    canvas.paste(Image.alpha_composite(
        Image.new("RGBA", shadow_layer.size, (0, 0, 0, 0)), shadow_layer
    ), (start_x + 4, icon_y + 6), shadow_layer)
    canvas.paste(rounded_icon, (start_x, icon_y), rounded_icon)

    # Draw text
    draw = ImageDraw.Draw(canvas)

    # Try to find a nice serif/display font, fall back to default
    title_size = 96
    subtitle_size = 28
    title_font = None
    subtitle_font = None

    font_candidates = [
        "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
        "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "/Library/Fonts/Georgia Bold.ttf",
    ]
    for f in font_candidates:
        if Path(f).exists():
            title_font = ImageFont.truetype(f, title_size)
            break

    subtitle_candidates = [
        "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "/Library/Fonts/Georgia.ttf",
    ]
    for f in subtitle_candidates:
        if Path(f).exists():
            subtitle_font = ImageFont.truetype(f, subtitle_size)
            break

    if title_font is None:
        title_font = ImageFont.load_default()
    if subtitle_font is None:
        subtitle_font = ImageFont.load_default()

    text_x = start_x + icon_size + 36
    title_y = icon_y + 20
    draw.text((text_x, title_y), "Kiln", fill=PRIMARY, font=title_font)

    subtitle_y = title_y + title_size + 4
    draw.text((text_x, subtitle_y), "A personal workout tracker", fill=TEXT_SECONDARY, font=subtitle_font)

    OUTPUT_PATH.parent.mkdir(exist_ok=True)
    canvas.save(OUTPUT_PATH, "PNG")
    print(f"Banner saved to {OUTPUT_PATH} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
