<div align="center">

<img src="docs/icon.png" width="96" alt="FaEnFix">

# FaEnFix

**اصلاح متنی که با زبان اشتباه کیبورد تایپ شده، با یک کلید**

[![Release](https://img.shields.io/github/v/release/mr-baft/FaEnFix?style=flat-square&color=881337)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/mr-baft/FaEnFix/total?style=flat-square&color=881337)](../../releases)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-881337?style=flat-square)](#)
[![License](https://img.shields.io/badge/license-MIT-881337?style=flat-square)](LICENSE)

[فارسی](#) · [English](#english)

</div>

<div dir="rtl">

## FaEnFix چیست؟

ابزاری رایگان و متن‌باز برای ویندوز که متن تایپ‌شده با زبان اشتباه کیبورد را، در هر برنامه‌ای، به فارسی یا انگلیسی درست تبدیل می‌کند.

<div align="center">

| تایپ‌شده | نتیجه |
|---|---|
| `tvnh shuj ni [gsi nhvdl` | فردا ساعت ده جلسه داریم |
| حمثشسث سثدی پث فاث بهدشم قثحخقف | `please send me the final report` |
| `gxth thdg` حقثسثدفشفهخد را تا `tvnh` برای team بفرستید | لطفا فایل presentation را تا فردا برای team بفرستید |

<img src="docs/welcome.png" width="440" alt="FaEnFix">

</div>

## ✨ امکانات

- کار در همه‌ی برنامه‌ها: تلگرام، Word، مرورگر، VS Code و ترمینال
- اصلاح فقط کلمه‌های اشتباه، حتی در متن‌های طولانی و دوزبانه
- پشتیبانی از فارسی محاوره‌ای و نیم‌فاصله
- سازگار با کیبوردهای «فارسی» و «فارسی استاندارد»
- تغییر خودکار زبان کیبورد پس از اصلاح
- آفلاین، بدون نیاز به دسترسی ادمین، اجرا در پس‌زمینه

## 📥 دانلود

<div align="center">

[![Setup](https://img.shields.io/badge/دانلود-FaEnFix--Setup.exe-881337?style=for-the-badge&logo=windows&logoColor=white)](../../releases/latest/download/FaEnFix-Setup.exe)
&nbsp;
[![Portable](https://img.shields.io/badge/نسخه‌ی_قابل‌حمل-FaEnFix.exe-75686C?style=for-the-badge&logo=windows&logoColor=white)](../../releases/latest/download/FaEnFix.exe)

</div>

> [!NOTE]
> اگر ویندوز پیام «Windows protected your PC» نمایش داد، روی **More info** و سپس **Run anyway** کلیک کنید.

## ⌨️ کلیدهای میانبر

| کلید | عملکرد |
|---|---|
| <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Space</kbd> یا <kbd>Pause</kbd> | تبدیل خودکار |
| <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>F</kbd> | تبدیل به فارسی |
| <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd> | تبدیل به انگلیسی |

- برای اصلاح کل متن، ابتدا <kbd>Ctrl</kbd>+<kbd>A</kbd> را بزنید.
- فشردن دوباره‌ی کلید، آخرین تبدیل را لغو می‌کند.

## ⚙️ تنظیمات

با دوبار کلیک روی آیکون FaEnFix در کنار ساعت ویندوز.

<div align="center"><img src="docs/settings.png" width="470" alt="تنظیمات"></div>

<details>
<summary><b>نکته‌ها</b></summary>

<br>

- در VS Code، کلید <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>F</kbd> برای «Format Document» استفاده می‌شود و می‌توان آن را در تنظیمات تغییر داد.
- برای کار در برنامه‌هایی که با دسترسی ادمین اجرا شده‌اند، گزینه‌ی مربوط را در تنظیمات فعال کنید.
- کلمه‌ای که در فرهنگ لغت نیست، مانند برخی نام‌ها، از کلمه‌ی مجاورش پیروی می‌کند. در صورت تبدیل نادرست، فقط همان بخش را انتخاب و تبدیل کنید.

</details>

<details>
<summary><b>توسعه</b></summary>

<br>

نیازمند [AutoHotkey v2](https://www.autohotkey.com):

```powershell
AutoHotkey64.exe FaEnFix.ahk                                    # اجرا
powershell -ExecutionPolicy Bypass -File tools\build.ps1        # ساخت exe
AutoHotkey64.exe /ErrorStdOut tests\unit.ahk                    # تست
```

با هر تگ `v*`، نسخه‌ی جدید توسط GitHub Actions ساخته و منتشر می‌شود.

</details>

## 📄 مجوز

[MIT](LICENSE) · فرهنگ لغت‌ها: [FrequencyWords](https://github.com/hermitdave/FrequencyWords) (CC-BY-SA 4.0) · فونت: [وزیرمتن](https://github.com/rastikerdar/vazirmatn) (OFL)

</div>

---

## English

**FaEnFix** is a free, open-source Windows tool that fixes text typed with the wrong keyboard layout (Persian ⇄ English) in any application.

- <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Space</kbd> or <kbd>Pause</kbd>: convert (auto-detect) · <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>F</kbd>: to Persian · <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd>: to English
- Fixes only the mistyped words, even in long bilingual text; supports colloquial Persian
- Offline, no admin rights required, runs in the background

**Download:** [FaEnFix-Setup.exe](../../releases/latest/download/FaEnFix-Setup.exe) · [portable FaEnFix.exe](../../releases/latest/download/FaEnFix.exe)

### Code signing policy

Free code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org).

- **Committers and reviewers:** [mr-baft](https://github.com/mr-baft)
- **Approvers:** [mr-baft](https://github.com/mr-baft)

Every release is built from this repository's source by [GitHub Actions](.github/workflows/release.yml) and each signing request is approved manually.

### Privacy policy

This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it. It reads the selected text only when its shortcut is pressed, restores the clipboard afterwards, and stores settings in `%AppData%\FaEnFix`.

Bundled components: [AutoHotkey](https://www.autohotkey.com) v2 runtime (GPL-2.0), [Vazirmatn](https://github.com/rastikerdar/vazirmatn) font (OFL-1.1), [FrequencyWords](https://github.com/hermitdave/FrequencyWords) word lists (CC-BY-SA 4.0), [Inno Setup](https://jrsoftware.org/isinfo.php) installer.
