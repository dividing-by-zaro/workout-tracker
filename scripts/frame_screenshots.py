"""Add iPhone device frames to screenshots."""

from PIL import Image, ImageDraw
from pathlib import Path

# Frame geometry
BEZEL = 44
OUTER_RADIUS = 140
INNER_RADIUS = 105
FRAME_COLOR = (28, 28, 30)  # #1C1C1E

# Side buttons — protrude from phone edge
BTN_PROTRUSION = 10
BTN_THICKNESS = 10
BTN_RADIUS = BTN_THICKNESS // 2
BTN_COLOR = (22, 22, 24)  # slightly darker than frame

# Left side buttons (y offsets from phone body top, heights)
ACTION_BTN = {"y": 460, "h": 70}  # action/silent switch
VOL_UP_BTN = {"y": 600, "h": 170}
VOL_DN_BTN = {"y": 790, "h": 170}

# Right side button
POWER_BTN = {"y": 640, "h": 220}

SCREENSHOTS_DIR = Path(__file__).resolve().parent.parent / "screenshots"


def frame_screenshot(path: Path, output: Path) -> None:
    img = Image.open(path).convert("RGBA")
    sw, sh = img.size

    # Phone body dimensions
    pw, ph = sw + BEZEL * 2, sh + BEZEL * 2

    # Canvas adds room for button protrusion on left and right
    cw = pw + BTN_PROTRUSION * 2
    ch = ph
    phone_x = BTN_PROTRUSION  # phone body x offset on canvas

    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    # Side buttons (drawn behind the phone body)
    for btn in [ACTION_BTN, VOL_UP_BTN, VOL_DN_BTN]:
        x = phone_x - BTN_PROTRUSION
        y = btn["y"]
        draw.rounded_rectangle(
            [x, y, x + BTN_THICKNESS + BTN_PROTRUSION, y + btn["h"]],
            radius=BTN_RADIUS,
            fill=BTN_COLOR,
        )

    # Power button (right side)
    rx = phone_x + pw - BTN_PROTRUSION
    draw.rounded_rectangle(
        [rx, POWER_BTN["y"], rx + BTN_THICKNESS + BTN_PROTRUSION, POWER_BTN["y"] + POWER_BTN["h"]],
        radius=BTN_RADIUS,
        fill=BTN_COLOR,
    )

    # Phone body
    draw.rounded_rectangle(
        [phone_x, 0, phone_x + pw - 1, ph - 1],
        radius=OUTER_RADIUS,
        fill=FRAME_COLOR,
    )

    # Screen mask (rounded inner corners)
    screen_mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(screen_mask).rounded_rectangle(
        [0, 0, sw - 1, sh - 1], radius=INNER_RADIUS, fill=255
    )
    canvas.paste(img, (phone_x + BEZEL, BEZEL), screen_mask)

    canvas.save(output, "PNG")
    print(f"Framed {path.name} -> {output.name} ({cw}x{ch})")


if __name__ == "__main__":
    SCREENSHOTS_DIR.mkdir(exist_ok=True)

    root = Path(__file__).resolve().parent.parent
    # Frame any PNGs in repo root that start with "Simulator Screenshot" or "create-"
    for pattern in ["Simulator Screenshot*.png", "create-*.png", "screenshot-*.png"]:
        for png in sorted(root.glob(pattern)):
            output = SCREENSHOTS_DIR / (png.stem + "-framed.png")
            frame_screenshot(png, output)
