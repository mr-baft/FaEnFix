# icon.ico را می‌سازد:  python tools/make-icon.py
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

S = 256
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle((8, 8, S - 8, S - 8), radius=56, fill=(37, 99, 235))
d.rounded_rectangle((8, 8, S - 8, S // 2), radius=56, fill=(59, 130, 246))
d.rectangle((8, S // 2 - 56, S - 8, S // 2), fill=(59, 130, 246))

font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 112)
d.text((S * 0.27, S * 0.50), "A", font=font, fill="white", anchor="mm")
d.text((S * 0.74, S * 0.47), "ف", font=font, fill="white", anchor="mm")
d.line((S * 0.5, S * 0.28, S * 0.5, S * 0.72), fill=(255, 255, 255, 140), width=6)

out = Path(__file__).resolve().parent.parent / "icon.ico"
img.save(out, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
img.save(out.with_suffix(".png"))
print(out)
