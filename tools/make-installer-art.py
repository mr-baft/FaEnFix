# تصویرهای نصب‌کننده (زرشکی) را از روی آیکون می‌سازد:  python tools/make-installer-art.py
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
icon = Image.open(root / "docs" / "icon.png").convert("RGBA")
out = root / "installer"

# تصویر کوچک گوشه‌ی بالای صفحه‌ها (۱۰۰٪ و ۲۰۰٪)
for size in (55, 110):
    bg = Image.new("RGB", (size, size), "white")
    ic = icon.resize((size - size // 8, size - size // 8), Image.LANCZOS)
    bg.paste(ic, ((size - ic.width) // 2, (size - ic.height) // 2), ic)
    bg.save(out / f"wizard-small-{size}.bmp")

# تصویر بلند کنار صفحه‌ی پایان (۱۰۰٪ و ۲۰۰٪)
for w, h in ((164, 314), (328, 628)):
    bg = Image.new("RGB", (w, h), (136, 19, 55))
    top = Image.new("RGB", (w, h // 2), (164, 28, 68))
    bg.paste(top, (0, 0))
    s = int(w * 0.62)
    ic = icon.resize((s, s), Image.LANCZOS)
    bg.paste(ic, ((w - s) // 2, (h - s) // 2), ic)
    bg.save(out / f"wizard-{w}.bmp")
print(out)
