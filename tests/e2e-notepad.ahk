#Requires AutoHotkey v2.0
; تست با کلیدزدن واقعی در Notepad. قبلش FaEnFix (exe یا FaEnFix.ahk) باید در حال اجرا باشد.
;   AutoHotkey64.exe /ErrorStdOut tests\e2e-notepad.ahk
#Include ..\FaEnFix.ahk

SetKeyDelay 20
SendLevel 1          ; وگرنه FaEnFix کلیدهای فرستاده‌شده از یک اسکریپت AutoHotkey دیگر را نادیده می‌گیرد
PickLayouts(&faHkl, &enHkl)
M := BuildMaps(faHkl, enHkl)
WrongFa(s) => Transform(s, false, M)
WrongEn(s) => Transform(s, true, M)

faLong := "امروز صبح زود از خواب بیدار شدم و بعد از صبحانه به دفتر رفتم. "
        . "با همکارانم درباره پروژه جدید صحبت کردیم و قرار شد تا آخر هفته گزارش کامل را آماده کنیم."
bi := "امروز جلسه weekly review داشتیم و درباره release plan و deadline پروژه صحبت کردیم"
Swap(text) {
    out := "", pos := 1
    while RegExMatch(text, "\S+", &mt, pos) {
        w := mt[0]
        out .= SubStr(text, pos, mt.Pos - pos) . (RegExMatch(w, "[A-Za-z]") ? WrongEn(w) : WrongFa(w))
        pos := mt.Pos + mt.Len
    }
    return out . SubStr(text, pos)
}
Spoil(text, words) {
    for w in words
        text := StrReplace(text, w, WrongFa(w), true, , 1)
    return text
}

cases := [
    ; [متن تایپ‌شده, کلیدها, انتظار, توضیح]
    [Spoil(faLong, ["صبح زود", "پروژه جدید صحبت کردیم", "گزارش"]), "^a|^+{Space}", faLong, "Ctrl+A on long paragraph, 3 wrong runs in middle"],
    [Swap(bi), "^a|^+{Space}", bi, "Ctrl+A on fully swapped bilingual text"],
    [WrongFa(faLong), "^a|^+{Space}", faLong, "Ctrl+A on whole wrong paragraph"],
    ["سلام علی`nفردا " WrongFa("جلسه داریم") "`nلطفا " WrongFa("گزارش") " را بیاور", "^a|^+{Space}", "سلام علی`r`nفردا جلسه داریم`r`nلطفا گزارش را بیاور", "Ctrl+A on multi-line text"],
    [Spoil(faLong, ["پروژه"]), "^a|^+{Space}|^+{Space}", Spoil(faLong, ["پروژه"]), "Ctrl+A fix, then press again = undo"],
    [Spoil(faLong, ["پروژه"]), "^a|+!f", faLong, "Ctrl+A then Shift+Alt+F"],
    ["سلام " WrongFa("امروز کجا بودی"), "^+{Space}", "سلام امروز کجا بودی", "no selection: wrong tail after Persian"],
    ["hello " WrongFa("سلام خبری"), "{Pause}", "hello سلام خبری", "no selection: Pause key"],
]

A_Clipboard := "CLIP-SENTINEL"
pass := 0
global pid
Run "notepad.exe", , , &pid
if !WinWait("ahk_pid " pid, , 5)
    ExitApp 3
; هیچ کلیدی جز به همین Notepad فرستاده نشود؛ اگر پنجره‌ی دیگری فعال شد، تست متوقف شود
SafeSend(keys) {
    global pid
    WinActivate "ahk_pid " pid
    if !WinWaitActive("ahk_pid " pid, , 2) {
        FileAppend "ABORT: Notepad is not the active window, nothing more sent`n", "*", "UTF-8"
        ExitApp 3
    }
    Send keys
}
for c in cases {
    A_Clipboard := "CLIP-SENTINEL"     ; کلیپ‌بورد بعد از هر اصلاح باید همین بماند
    ; متن مستقیم در Notepad گذاشته می‌شود (تایپ نمی‌شود) و مکان‌نما به آخرش می‌رود
    ControlSetText StrReplace(StrReplace(c[1], "`r`n", "`n"), "`n", "`r`n"), "Edit1", "ahk_pid " pid
    Sleep 200
    SafeSend "^{End}"
    Sleep 200
    for k in StrSplit(c[2], "|") {
        SafeSend k
        Sleep(k = "^a" ? 300 : 1400)
    }
    got := ControlGetText("Edit1", "ahk_pid " pid)
    ok := got == c[3] && A_Clipboard == "CLIP-SENTINEL"
    pass += ok
    FileAppend (ok ? "PASS" : "FAIL") " | " c[4] (ok ? "" : "`n   got: «" got "»`n   exp: «" c[3] "»`n   clipboard: «" SubStr(A_Clipboard, 1, 60) "»") "`n", "*", "UTF-8"
}
Sleep 600
FileAppend "clipboard restored: " (A_Clipboard == "CLIP-SENTINEL" ? "yes" : "NO") "`n", "*", "UTF-8"
FileAppend pass "/" cases.Length " passed`n", "*", "UTF-8"
ControlSetText "", "Edit1", "ahk_pid " pid
ProcessClose pid
ExitApp pass = cases.Length ? 0 : 1
