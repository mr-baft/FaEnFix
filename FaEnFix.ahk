#Requires AutoHotkey v2.0
#SingleInstance Force
;@Ahk2Exe-SetName FaEnFix
;@Ahk2Exe-SetDescription FaEnFix - اصلاح متن تایپ‌شده با کیبورد اشتباه
;@Ahk2Exe-SetVersion 1.1.0
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-SetProductName FaEnFix
;@Ahk2Exe-SetCompanyName Alireza Moghaddam
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Alireza Moghaddam
;@Ahk2Exe-SetOrigFilename FaEnFix.exe
; FaEnFix: اصلاح متنی که با کیبورد اشتباه (فارسی/انگلیسی) تایپ شده — در همه برنامه‌ها

; تنظیمات در %AppData%\FaEnFix\settings.ini ذخیره می‌شوند (از منوی کنار ساعت ← تنظیمات)
HELP_URL := "https://github.com/mr-baft/FaEnFix#readme"
DEFAULT_HOTKEYS := Map("auto", "^+vk20", "auto2", "vk13", "to_fa", "+!vk46", "to_en", "+!vk45")
; برنامه‌هایی که Ctrl+C در آن‌ها معنی دیگری دارد (ترمینال‌ها)
DEFAULT_EXCLUDE := "WindowsTerminal.exe,cmd.exe,powershell.exe,pwsh.exe,mintty.exe,conhost.exe,"
                 . "alacritty.exe,wezterm-gui.exe,putty.exe,kitty.exe,Hyper.exe,Tabby.exe,"
                 . "ConEmu.exe,ConEmu64.exe,wsl.exe,bash.exe"

global AppDir := A_AppData "\FaEnFix", IniFile := AppDir "\settings.ini"
global Cfg := LoadConfig()

for exe in StrSplit(Cfg.exclude, ",", " `t")
    if (exe != "")
        GroupAdd "NoFix", "ahk_exe " exe

; ویرایشگرهایی که Ctrl+C بدون انتخاب، کل خط را (با Enter) کپی می‌کنند
for exe in ["Code.exe", "Code - Insiders.exe", "Cursor.exe", "VSCodium.exe", "devenv.exe"
          , "sublime_text.exe", "notepad++.exe", "idea64.exe", "pycharm64.exe", "webstorm64.exe"
          , "rider64.exe", "clion64.exe", "goland64.exe", "phpstorm64.exe", "studio64.exe"]
    GroupAdd "LineCopy", "ahk_exe " exe

global Maps := Map()
global Last := {result: "", source: "", hwnd: 0, srcHkl: 0}
global DictEn := Map(), DictFa := Map()

if FileExist(A_ScriptDir "\icon.ico") && !A_IsCompiled
    TraySetIcon A_ScriptDir "\icon.ico"
LoadDicts()
SetupTray()
RegisterHotkeys()

Arg := A_Args.Length ? A_Args[1] : ""
if (Arg = "/settings")
    SetTimer ShowSettings, -200
else if (Arg = "/welcome" || IniRead(IniFile, "app", "welcomed", "0") = "0") {
    IniWrite "1", IniFile, "app", "welcomed"
    SetTimer ShowWelcome, -500
} else if (Arg != "/silent")
    TrayTip "هر جا اشتباهی تایپ کردی، " HotkeyLabel(Cfg.hk["auto"]) " رو بزن.", "FaEnFix روشنه"

; ================= تنظیمات =================
LoadConfig() {
    DirCreate AppDir
    hk := Map()
    for k, def in DEFAULT_HOTKEYS
        hk[k] := IniRead(IniFile, "hotkeys", k, def)
    c := {hk: hk}
    c.switchLayout := IniRead(IniFile, "options", "switch_layout", "1") = "1"
    c.useDict := IniRead(IniFile, "options", "use_dictionary", "1") = "1"
    c.notify := IniRead(IniFile, "options", "notify", "1") = "1"
    c.exclude := IniRead(IniFile, "apps", "exclude", DEFAULT_EXCLUDE)
    return c
}

RegisterHotkeys() {
    HotIf((*) => !WinActive("ahk_group NoFix"))
    bad := ""
    for k, force in Map("auto", "", "auto2", "", "to_fa", "fa", "to_en", "en") {
        if (Cfg.hk[k] = "")
            continue
        try Hotkey Cfg.hk[k], FixLayout.Bind(force)
        catch
            bad .= " " Cfg.hk[k]
    }
    HotIf()
    if (bad != "")
        TrayTip "این کلیدها رو یه برنامه‌ی دیگه گرفته:" bad "`nاز تنظیمات یه ترکیب دیگه انتخاب کن.", "FaEnFix", "Iconx"
}

; ================= اصلی =================
; force: "" = تشخیص خودکار، "fa" = به فارسی، "en" = به انگلیسی
FixLayout(force, *) {
    global Last
    KeyWait "Control"
    KeyWait "Shift"
    KeyWait "Alt"

    if !PickLayouts(&fa, &en) {
        Tip("کیبورد فارسی یا انگلیسی روی ویندوز پیدا نشد")
        return
    }
    m := BuildMaps(fa, en)
    hwnd := WinExist("A")
    saved := ClipboardAll()
    try {
        ; ۱) اگر متنی انتخاب شده، همان را اصلاح کن
        text := CopyText()
        fromSel := true
        ; (VS Code و مشابه‌ها بدون انتخاب، کل خط را با Enter کپی می‌کنند)
        if (text = "" || (WinActive("ahk_group LineCopy") && RegExMatch(text, "\R$"))) {
            ; ۲) وگرنه از ابتدای خط تا مکان‌نما
            Send "+{Home}"
            text := CopyText()
            fromSel := false
            if (text = "")
                return
        }

        ; زدن دوباره‌ی شورتکات خودکار = برگرداندن آخرین تغییر
        if (force = "" && Last.result != "" && text == Last.result && Last.hwnd = hwnd) {
            Paste(Last.source)
            if Cfg.switchLayout
                SwitchTo(Last.srcHkl)
            Last.result := ""
            if Cfg.notify
                Tip("↩ برگشت")
            return
        }

        if !SplitTail(text, &prefix, &seg, &toPersian, force) {
            Paste(text)
            if (force != "")
                Tip(force = "fa" ? "متن انگلیسی‌ای برای تبدیل نیست" : "متن فارسی‌ای برای تبدیل نیست")
            return
        }
        newText := prefix . FixSegment(seg, toPersian, m, Cfg.useDict && !fromSel)
        Paste(newText)
        Last := {result: newText, source: text, hwnd: hwnd, srcHkl: toPersian ? en : fa}
        if Cfg.switchLayout
            SwitchTo(toPersian ? fa : en)
        if Cfg.notify
            Tip(toPersian ? "فارسی ✓" : "English ✓")
    } finally {
        Sleep 400                      ; برنامه‌های کند (تلگرام، Slack، Teams) فرصت خواندن داشته باشند
        A_Clipboard := saved
    }
}

; ============ تشخیص کیبوردهای نصب‌شده ============
GetLayouts() {
    n := DllCall("GetKeyboardLayoutList", "Int", 0, "Ptr", 0, "Int")
    buf := Buffer(n * A_PtrSize, 0)
    DllCall("GetKeyboardLayoutList", "Int", n, "Ptr", buf, "Int")
    list := []
    Loop n
        list.Push(NumGet(buf, (A_Index - 1) * A_PtrSize, "Ptr"))
    return list
}
IsPersianHkl(h) => (h & 0xFFFF) = 0x0429
IsEnglishHkl(h) => (h & 0x3FF) = 0x09

ActiveHkl() {
    tid := DllCall("GetWindowThreadProcessId", "Ptr", WinExist("A"), "Ptr", 0, "UInt")
    return DllCall("GetKeyboardLayout", "UInt", tid, "Ptr")
}

PickLayouts(&fa, &en) {
    fa := 0, en := 0, other := 0
    cur := ActiveHkl()
    if IsPersianHkl(cur)          ; اگر کیبورد فعلی فارسی است، دقیقاً همان نسخه
        fa := cur
    else if IsEnglishHkl(cur)
        en := cur
    for h in GetLayouts() {
        if (!fa && IsPersianHkl(h))
            fa := h
        else if (!en && IsEnglishHkl(h))
            en := h
        else if (!other && !IsPersianHkl(h))
            other := h
    }
    if !en
        en := other ? other : DllCall("LoadKeyboardLayout", "Str", "00000409", "UInt", 0x80, "Ptr")
    if !fa
        fa := DllCall("LoadKeyboardLayout", "Str", "00000429", "UInt", 0x80, "Ptr")
    return fa && en
}

; نگاشت را مستقیم از خود ویندوز می‌خواند، پس با هر نسخه‌ی کیبورد درست است
BuildMaps(fa, en) {
    key := fa "|" en
    if Maps.Has(key)
        return Maps[key]
    toFa := Map(), toEn := Map()
    state := Buffer(256, 0)
    scs := []
    Loop 0x34
        scs.Push(0x01 + A_Index)      ; ردیف‌های اصلی کیبورد
    scs.Push(0x56)                    ; کلید اضافه‌ی کیبوردهای ISO
    for sc in scs {
        for shift in [0, 0x80] {
            NumPut("UChar", shift, state, 0x10)
            NumPut("UChar", shift, state, 0xA0)
            e := KeyChar(sc, en, state)
            f := KeyChar(sc, fa, state)
            if (e = "" || f = "" || e == f)
                continue
            if (StrLen(e) = 1 && !toFa.Has(e))
                toFa[e] := f
            if (StrLen(f) = 1 && !toEn.Has(f))
                toEn[f] := e
        }
    }
    if !toEn.Has(Chr(0x200C))
        toEn[Chr(0x200C)] := " "       ; نیم‌فاصله (Shift+Space در فارسی استاندارد)
    return Maps[key] := {toFa: toFa, toEn: toEn}
}

KeyChar(sc, hkl, state) {
    vk := DllCall("MapVirtualKeyEx", "UInt", sc, "UInt", 1, "Ptr", hkl, "UInt")
    if !vk
        return ""
    out := Buffer(32, 0)
    n := DllCall("ToUnicodeEx", "UInt", vk, "UInt", sc, "Ptr", state, "Ptr", out, "Int", 15, "UInt", 4, "Ptr", hkl, "Int")
    if (n < 0)   ; dead key
        DllCall("ToUnicodeEx", "UInt", vk, "UInt", sc, "Ptr", state, "Ptr", out, "Int", 15, "UInt", 4, "Ptr", hkl, "Int")
    if (n < 1)
        return ""
    s := StrGet(out, n, "UTF-16")
    return Ord(s) < 0x20 ? "" : s
}

; ============ تشخیص محدوده‌ی اشتباه ============
IsFaChar(c) {
    o := Ord(c)
    return (o >= 0x0600 && o <= 0x06FF) || (o >= 0xFB50 && o <= 0xFDFF) || (o >= 0xFE70 && o <= 0xFEFF)
}
IsEnChar(c) => RegExMatch(c, "^[A-Za-z]$")

; از انتها به عقب می‌رود تا به اولین حرفِ خط دیگر برسد
SplitTail(text, &prefix, &seg, &toPersian, force := "") {
    chars := StrSplit(text)
    i := chars.Length, script := ""
    while (i >= 1) {
        if IsFaChar(chars[i]) {
            script := "fa"
            break
        }
        if IsEnChar(chars[i]) {
            script := "en"
            break
        }
        i--
    }
    ; اجبار جهت: «به فارسی» یعنی متن آخر باید انگلیسی باشد و برعکس
    if (script = "" || (force = "fa" && script != "en") || (force = "en" && script != "fa"))
        return false
    j := i
    while (j >= 1 && !(script = "fa" ? IsEnChar(chars[j]) : IsFaChar(chars[j])))
        j--
    s := j + 1
    while (s <= chars.Length && (chars[s] = " " || chars[s] = "`t" || chars[s] = "`n" || chars[s] = "`r"))
        s++
    prefix := SubStr(text, 1, s - 1)
    seg := SubStr(text, s)
    toPersian := (script = "en")
    return seg != ""
}

; فقط کلمه‌هایی را تبدیل می‌کند که با کیبورد اشتباه تایپ شده‌اند (مثلاً «hello sghl» → «hello سلام»)
FixSegment(seg, toPersian, m, useDict) {
    if (!useDict || !DictEn.Count || !DictFa.Count)
        return Transform(seg, toPersian, m)
    toks := [], pos := 1
    while RegExMatch(seg, "\S+", &mt, pos) {
        toks.Push({s: mt.Pos, len: mt.Len, c: Classify(mt[0], toPersian, m)})
        pos := mt.Pos + mt.Len
    }
    ; کلمه‌ی ناشناخته (اسم، غلط تایپی) تابع کلمه‌ی شناخته‌شده‌ی بعدی است، وگرنه قبلی
    nxt := 0
    Loop toks.Length {
        t := toks[toks.Length - A_Index + 1]
        if t.c
            nxt := t.c
        else
            t.c := nxt
    }
    prv := 0, anyWrong := false
    for t in toks {
        if t.c
            prv := t.c
        else
            t.c := prv
        anyWrong := anyWrong || t.c = 1
    }
    if !anyWrong                       ; هیچ کلمه‌ای غلط تشخیص داده نشد: کاربر خواسته، پس همه تبدیل شود
        return Transform(seg, toPersian, m)
    out := "", pos := 1
    for t in toks {
        w := SubStr(seg, t.s, t.len)
        out .= SubStr(seg, pos, t.s - pos) . (t.c = 1 ? Transform(w, toPersian, m) : w)
        pos := t.s + t.len
    }
    return out . SubStr(seg, pos)
}

; ۱ = با کیبورد اشتباه تایپ شده، ‎-۱ = درست است، ۰ = نامعلوم
Classify(w, toPersian, m) {
    static INF := 0x7FFFFFFF
    t := Trim2(w)
    if toPersian {
        own := Min(Rank(DictEn, StrLower(w)), Rank(DictEn, StrLower(t)))
        oth := Min(Rank(DictFa, NormFa(Transform(w, true, m))), Rank(DictFa, NormFa(Transform(t, true, m))))
    } else {
        own := Min(Rank(DictFa, NormFa(w)), Rank(DictFa, NormFa(t)))
        c := Transform(w, false, m)
        oth := Min(Rank(DictEn, StrLower(c)), Rank(DictEn, StrLower(Trim2(c))))
    }
    if (own = INF && oth = INF)
        return 0
    return oth < own ? 1 : -1
}

Trim2(s) => RegExReplace(s, "^[^\pL]+|[^\pL]+$")
Rank(d, w) => (w != "" && d.Has(w)) ? d[w] : 0x7FFFFFFF
NormFa(s) {
    s := StrReplace(StrReplace(StrReplace(s, "ي", "ی"), "ى", "ی"), "ك", "ک")
    return RegExReplace(s, "[\x{064B}-\x{065F}\x{0640}\x{200C}]")
}

Transform(s, toPersian, m) {
    if (toPersian && GetKeyState("CapsLock", "T"))
        s := SwapCase(s)               ; تایپ با CapsLock روشن
    out := "", mp := toPersian ? m.toFa : m.toEn
    Loop Parse s
        out .= mp.Has(A_LoopField) ? mp[A_LoopField] : A_LoopField
    return out
}

SwapCase(s) {
    out := ""
    Loop Parse s
        out .= IsUpper(A_LoopField) ? StrLower(A_LoopField) : StrUpper(A_LoopField)
    return out
}

; ============ فرهنگ لغت ============
LoadDicts() {
    if !Cfg.useDict
        return
    if A_IsCompiled {                  ; نسخه‌ی exe: فایل‌ها داخل خود برنامه‌اند
        dir := AppDir
        DirCreate dir
        FileInstall "dict\en.txt", dir "\en.txt", 1
        FileInstall "dict\fa.txt", dir "\fa.txt", 1
    } else {
        SplitPath A_LineFile, , &srcDir
        dir := srcDir "\dict"
    }
    for pair in [[DictEn, "en.txt"], [DictFa, "fa.txt"]] {
        try txt := FileRead(dir "\" pair[2], "UTF-8")
        catch
            continue
        d := pair[1]
        Loop Parse txt, "`n", "`r"
            if (A_LoopField != "" && !d.Has(A_LoopField))
                d[A_LoopField] := A_Index
    }
}

; ============ منوی کنار ساعت و اجرای خودکار ============
RunKey() => "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

; اجرای خودکار با رجیستری (همان جایی که نصب‌کننده هم می‌نویسد)
StartupEnabled() {
    try return RegRead(RunKey(), "FaEnFix") != ""
    catch
        return false
}

SetStartup(on) {
    if on {
        cmd := A_IsCompiled ? '"' A_ScriptFullPath '"' : '"' A_AhkPath '" "' A_ScriptFullPath '"'
        RegWrite cmd " /silent", "REG_SZ", RunKey(), "FaEnFix"
    } else
        try RegDelete RunKey(), "FaEnFix"
}

SetupTray() {
    A_IconTip := "FaEnFix · " HotkeyLabel(Cfg.hk["auto"]) " = اصلاح متن"
    tm := A_TrayMenu
    tm.Delete()
    tm.Add("تنظیمات", ShowSettings)
    tm.Add("راهنمای کوتاه", (*) => ShowWelcome())
    tm.Add("صفحه‌ی برنامه در GitHub", (*) => Run(HELP_URL))
    tm.Add()
    tm.Add("اجرا با روشن شدن ویندوز", ToggleStartup)
    tm.Add("خاموش موقت", ToggleSuspend)
    tm.Add()
    tm.Add("خروج", (*) => ExitApp())
    tm.Default := "تنظیمات"
    ; نسخه‌ی exe قابل‌حمل در اولین اجرا خودش را به اجرای خودکار اضافه می‌کند
    ; (نصب‌کننده این مقدار را از قبل می‌نویسد و انتخاب کاربر را نگه می‌دارد)
    if (A_IsCompiled && IniRead(IniFile, "app", "installed", "0") = "0") {
        IniWrite "1", IniFile, "app", "installed"
        SetStartup(true)
    } else if StartupEnabled()
        SetStartup(true)               ; اگر برنامه جابه‌جا شده، مسیر به‌روز شود
    if FileExist(A_Startup "\FaEnFix.lnk") {   ; نسخه‌ی قدیمی از شورتکات استفاده می‌کرد
        FileDelete A_Startup "\FaEnFix.lnk"
        SetStartup(true)
    }
    if StartupEnabled()
        tm.Check("اجرا با روشن شدن ویندوز")
}

ToggleStartup(name, *) {
    on := !StartupEnabled()
    SetStartup(on)
    if on
        A_TrayMenu.Check(name)
    else
        A_TrayMenu.Uncheck(name)
}

ToggleSuspend(name, *) {
    Suspend -1
    if A_IsSuspended
        A_TrayMenu.Check(name)
    else
        A_TrayMenu.Uncheck(name)
}

; ============ ظاهر ============
global UI := {bg: "FFFFFF", text: "1F1A1C", muted: "75686C", accent: "881337", soft: "FFF1F3"
            , key: "F6F1F2", font: "Vazirmatn"}            ; تم زرشکی

; فونت وزیرمتن فقط برای همین برنامه بارگذاری می‌شود (نصب در ویندوز لازم نیست)
LoadFonts() {
    static done := false
    if done
        return
    done := true
    if A_IsCompiled {
        dir := AppDir "\fonts"
        DirCreate dir
        FileInstall "fonts\Vazirmatn-Regular.ttf", dir "\Vazirmatn-Regular.ttf", 1
        FileInstall "fonts\Vazirmatn-Bold.ttf", dir "\Vazirmatn-Bold.ttf", 1
    } else {
        SplitPath A_LineFile, , &srcDir
        dir := srcDir "\fonts"
    }
    Loop Files dir "\*.ttf"
        DllCall("gdi32\AddFontResourceEx", "Str", A_LoopFileFullPath, "UInt", 0x10, "Ptr", 0)
}

NewWindow(title) {
    LoadFonts()
    g := Gui("-MinimizeBox -MaximizeBox +E0x400000", title)      ; راست‌به‌چپ
    g.BackColor := UI.bg
    g.MarginX := 28, g.MarginY := 22
    g.SetFont("s10 c" UI.text, UI.font)
    return g
}

; سرتیتر: آیکون + عنوان + زیرعنوان
AddHeader(g, title, sub) {
    try g.AddPicture("xm ym w44 h44", A_IsCompiled ? A_ScriptFullPath : A_ScriptDir "\icon.ico")
    g.SetFont("s15 bold")
    g.AddText("x+14 yp-4", title)
    g.SetFont("s10 norm c" UI.muted)
    g.AddText("xp y+0", sub)
    g.SetFont("c" UI.text)
}

AddSection(g, title) {
    g.SetFont("s10 bold c" UI.accent)
    g.AddText("xm y+18", title)
    g.SetFont("norm c" UI.text)
}

; «^+vk20» را به شکل دکمه‌های کیبورد نشان می‌دهد: [Ctrl] + [Shift] + [Space]
AddKeys(g, hk, pos, size := 10) {
    g.SetFont("s" size " bold c" UI.text, "Segoe UI")
    first := true, ctrls := []
    keys := StrSplit(HotkeyLabel(hk), "+")
    Loop keys.Length {                 ; پنجره راست‌به‌چپ است: از آخر اضافه شود تا Ctrl سمت چپ بیاید
        k := keys[keys.Length - A_Index + 1]
        if !first {
            g.SetFont("norm c" UI.muted)
            ctrls.Push(g.AddText("x+4 yp hp 0x200", "+"))
            g.SetFont("bold c" UI.text)
        }
        ctrls.Push(g.AddText((first ? pos : "x+4 yp") " Center 0x200 Border Background" UI.key " h" Round(size * 2.8), " " k " "))
        first := false
    }
    g.SetFont("s10 norm c" UI.text, UI.font)
    return ctrls
}

; دکمه‌ی تخت؛ primary = آبی
AddFlatButton(g, opts, label, fn, primary := true) {
    g.SetFont(primary ? "bold cFFFFFF" : "norm c" UI.text)
    b := g.AddText("h36 " opts " Center 0x200 0x100 Background" (primary ? UI.accent : UI.key), label)
    b.OnEvent("Click", fn)
    g.SetFont("norm c" UI.text)
    return b
}

; اولین اجرا: معرفی کوتاه
ShowWelcome() {
    g := NewWindow("FaEnFix")
    AddHeader(g, "FaEnFix آماده است", "دیگه لازم نیست برای یه کیبورد اشتباه، کل جمله رو پاک کنی.")
    g.AddText("xm y+26 w420", "هر جا یادت رفت زبان کیبورد رو عوض کنی، همین کلیدها رو بزن:")
    AddKeys(g, Cfg.hk["auto"], "xm y+12", 13)

    g.SetFont("s11 c" UI.muted, "Segoe UI")
    g.AddText("xm y+18 w420 h44 0x200 Center Background" UI.soft, "sghl ofvd   ←   سلام خبری")
    g.SetFont("s10 c" UI.text, UI.font)

    rows := [[Cfg.hk["to_fa"], "فقط به فارسی"], [Cfg.hk["to_en"], "فقط به انگلیسی"]]
    g.AddText("xm y+18 c" UI.muted, "اگه خواستی جهت تبدیل رو خودت انتخاب کنی:")
    for r in rows {
        AddKeys(g, r[1], "xm y+8", 9)
        g.AddText("x+12 yp hp 0x200", r[2])
    }
    g.AddText("xm y+14 w420 c" UI.muted, "اشتباه شد؟ همون کلید اول رو دوباره بزن تا برگرده.")
    g.AddText("xm y+4 w420 c" UI.muted, "برای تنظیمات، روی آیکون FaEnFix کنار ساعت دوبار کلیک کن.")
    AddFlatButton(g, "xm y+22 w160", "فهمیدم", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show("AutoSize Center")
}

; ============ پنجره‌ی تنظیمات ============
global SettingsGui := 0
ShowSettings(*) {
    global SettingsGui
    if SettingsGui {
        SettingsGui.Show()
        return
    }
    g := SettingsGui := NewWindow("تنظیمات FaEnFix")
    AddHeader(g, "تنظیمات", "هر طور راحتی، همون‌طور تنظیمش کن.")

    AddSection(g, "کلیدهای میانبر")
    g.SetFont("c" UI.muted)
    g.AddText("xm y+2 w480", "روی «تغییر» بزن و ترکیب جدید رو فشار بده. Backspace خاموشش می‌کنه، Esc لغو.")
    g.SetFont("c" UI.text)
    rows := [["auto", "اصلاح خودکار"], ["auto2", "اصلاح خودکار (کلید دوم)"], ["to_fa", "فقط به فارسی"], ["to_en", "فقط به انگلیسی"]]
    hk := Map()
    for r in rows {
        g.AddText("xm y+8 w190 h32 0x200 Section", r[2])
        g.SetFont("bold", "Segoe UI")
        lbl := g.AddText("ys w200 h32 Center 0x200 Background" UI.key, KeysText(Cfg.hk[r[1]]))
        g.SetFont("norm", UI.font)
        hk[r[1]] := {label: lbl, value: Cfg.hk[r[1]]}
        AddFlatButton(g, "ys w74 h32", "تغییر", RecordHotkey.Bind(hk[r[1]]), false)
    }

    AddSection(g, "رفتار برنامه")
    cbSwitch := g.AddCheckbox("xm y+8 Checked" Cfg.switchLayout, "بعد از اصلاح، زبان کیبورد هم خودش عوض بشه")
    cbDict := g.AddCheckbox("xm y+4 Checked" Cfg.useDict, "فقط کلمه‌های اشتباه عوض بشن (با فرهنگ لغت)")
    cbNotify := g.AddCheckbox("xm y+4 Checked" Cfg.notify, "بعد از هر اصلاح، یه پیام کوچیک نشون بده")
    cbStart := g.AddCheckbox("xm y+4 Checked" StartupEnabled(), "با روشن شدن ویندوز، خودش اجرا بشه")

    AddSection(g, "برنامه‌هایی که FaEnFix توشون کار نکنه")
    g.SetFont("c" UI.muted)
    g.AddText("xm y+2 w480", "اسم فایل exe، هر خط یکی. مثلاً ترمینال‌ها، چون اونجا Ctrl+C یعنی توقف برنامه.")
    g.SetFont("s9 c" UI.text, "Consolas")
    ex := g.AddEdit("xm y+8 w480 r4 -E0x200 Border Background" UI.key, StrReplace(Cfg.exclude, ",", "`n"))
    g.SetFont("s10", UI.font)

    AddFlatButton(g, "xm y+20 w150", "ذخیره", Save)
    AddFlatButton(g, "x+15 w150", "تنظیمات اولیه", Reset, false)
    AddFlatButton(g, "x+15 w150", "راهنما", (*) => Run(HELP_URL), false)
    g.OnEvent("Close", CloseSettings)
    g.OnEvent("Escape", CloseSettings)
    g.Show("AutoSize Center")

    Save(*) {
        for k, h in hk
            IniWrite h.value, IniFile, "hotkeys", k
        IniWrite cbSwitch.Value, IniFile, "options", "switch_layout"
        IniWrite cbDict.Value, IniFile, "options", "use_dictionary"
        IniWrite cbNotify.Value, IniFile, "options", "notify"
        list := ""
        for exe in StrSplit(ex.Value, "`n", " `t`r")
            if (exe != "")
                list .= (list = "" ? "" : ",") exe
        IniWrite list, IniFile, "apps", "exclude"
        if (cbStart.Value != StartupEnabled())
            SetStartup(cbStart.Value)
        Reload
    }
    Reset(*) {
        for sec in ["hotkeys", "options", "apps"]
            try IniDelete IniFile, sec
        Reload
    }
}

CloseSettings(*) {
    global SettingsGui
    SettingsGui.Destroy()
    SettingsGui := 0
}

; کلید بعدی که زده شود را به‌صورت شورتکات (مثل ^+vk20) برمی‌گرداند
RecordHotkey(h, *) {
    h.label.Value := "کلید جدید رو بزن…"
    Suspend true                       ; تا شورتکات‌های فعلی اجرا نشوند
    res := {v: ""}
    ih := InputHook("L0 T8")
    ih.KeyOpt("{All}", "NS")
    ih.KeyOpt("{LCtrl}{RCtrl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-NS")
    ih.OnKeyDown := OnKey
    ih.Start()
    ih.Wait()
    Suspend false
    if (res.v != "" && res.v != "esc")
        h.value := res.v = "bs" ? "" : res.v
    h.label.Value := KeysText(h.value)

    OnKey(ih, vk, sc) {
        if (vk = 0x1B)
            res.v := "esc"
        else if (vk = 0x08)
            res.v := "bs"
        else
            res.v := (GetKeyState("Ctrl", "P") ? "^" : "") . (GetKeyState("Alt", "P") ? "!" : "")
                   . (GetKeyState("Shift", "P") ? "+" : "")
                   . (GetKeyState("LWin", "P") || GetKeyState("RWin", "P") ? "#" : "")
                   . Format("vk{:02X}", vk)
        ih.Stop()
    }
}

KeysText(hk) => hk = "" ? "خاموش" : StrReplace(HotkeyLabel(hk), "+", "  +  ")

; «^+vk20» → «Ctrl+Shift+Space»
HotkeyLabel(hk) {
    if (hk = "")
        return "(خالی)"
    RegExMatch(hk, "^([\^!+#<>*~$]*)(.*)$", &m)
    s := ""
    for p in [["^", "Ctrl+"], ["!", "Alt+"], ["+", "Shift+"], ["#", "Win+"]]
        if InStr(m[1], p[1])
            s .= p[2]
    key := m[2]
    if RegExMatch(key, "i)^vk([0-9a-f]{2})$", &v) {
        vk := Integer("0x" v[1])
        key := (vk >= 0x30 && vk <= 0x5A) ? Chr(vk) : GetKeyName(key)
    }
    return s . (StrLen(key) = 1 ? StrUpper(key) : key)
}

; ============ کلیپ‌بورد و کیبورد ============
CopyText() {
    A_Clipboard := ""
    Send "^{vk43}"                     ; Ctrl+C مستقل از زبان کیبورد
    return ClipWait(0.4) ? A_Clipboard : ""
}

Paste(text) {
    A_Clipboard := text
    ClipWait 0.5
    Send "^{vk56}"                     ; Ctrl+V
    Sleep 100
}

SwitchTo(hkl) {
    try PostMessage 0x50, 0, hkl, , "A"   ; WM_INPUTLANGCHANGEREQUEST
}

Tip(msg) {
    ToolTip msg
    SetTimer () => ToolTip(), -1200
}
