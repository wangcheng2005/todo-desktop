"""Generate a todo-themed app icon in teal color."""
from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    sizes = [16, 32, 48, 64, 128, 256]
    images = []

    for size in sizes:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Teal colors matching AppTheme
        teal = (13, 148, 136, 255)       # 0xFF0D9488
        teal_dark = (15, 118, 110, 255)  # 0xFF0F766E
        white = (255, 255, 255, 255)

        margin = max(1, size // 16)
        rect = [margin, margin, size - margin - 1, size - margin - 1]
        corner = max(2, size // 6)

        # Background: rounded rectangle
        draw.rounded_rectangle(rect, radius=corner, fill=teal)

        # Draw a checkmark
        cx, cy = size / 2, size / 2
        s = size * 0.28  # checkmark scale
        stroke_w = max(1, int(size * 0.08))

        # Checkmark points: down-left to bottom-center, then up to upper-right
        p1 = (cx - s * 0.7, cy - s * 0.05)
        p2 = (cx - s * 0.15, cy + s * 0.55)
        p3 = (cx + s * 0.8, cy - s * 0.55)

        draw.line([p1, p2], fill=white, width=stroke_w)
        draw.line([p2, p3], fill=white, width=stroke_w)

        images.append(img)

    # Save as .ico
    out_paths = [
        os.path.join(os.path.dirname(__file__), '..', 'windows', 'runner', 'resources', 'app_icon.ico'),
        os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons', 'app_icon.ico'),
    ]
    for p in out_paths:
        p = os.path.normpath(p)
        images[0].save(p, format='ICO', sizes=[(s, s) for s in [16, 32, 48, 64, 128, 256]],
                       append_images=images[1:])
        print(f'Saved: {p}')

if __name__ == '__main__':
    create_icon()
