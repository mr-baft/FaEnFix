#Requires AutoHotkey v2.0
; تست منطق تبدیل، بدون کلیدزدن:  AutoHotkey64.exe /ErrorStdOut tests\unit.ahk
; متن «اشتباه» از روی متن درست و با نقشه‌ی کیبوردهای نصب‌شده‌ی همین سیستم ساخته می‌شود
#Include ..\FaEnFix.ahk

LoadDicts()
if !PickLayouts(&faHkl, &enHkl) {
    FileAppend "no Persian/English layout`n", "*", "UTF-8"
    ExitApp 2
}
; آرگومان اختیاری: کیبورد فارسی مشخص، مثلاً 00000429 (فارسی قدیمی) یا 00050429 (فارسی استاندارد)
if A_Args.Length {
    faHkl := DllCall("LoadKeyboardLayout", "Str", A_Args[1], "UInt", 0x80, "Ptr")
    FileAppend "Persian layout: " A_Args[1] " (" Format("0x{:X}", faHkl) ")`n", "*", "UTF-8"
    if !faHkl
        ExitApp 2
} else {
    FileAppend "Persian layout: " Format("0x{:X}", faHkl) " (default)`n", "*", "UTF-8"
}
M := BuildMaps(faHkl, enHkl)
global Passed := 0, Failed := 0

; فارسی‌ای که با کیبورد انگلیسی تایپ شده و برعکس
OnEn(fa) => Transform(fa, false, M)
OnFa(en) => Transform(en, true, M)
; چند کلمه را (با فاصله) اشتباه تایپ می‌کند
WrongFa(s) => OnEn(s)
WrongEn(s) => OnFa(s)

Check(name, got, want) {
    global Passed, Failed
    if (got == want) {
        Passed++
        FileAppend "PASS | " name "`n", "*", "UTF-8"
    } else {
        Failed++
        FileAppend "FAIL | " name "`n   got: «" got "»`n   exp: «" want "»`n", "*", "UTF-8"
    }
}

; در بعضی کیبوردهای فارسی (مثل «فارسی» قدیمی) نیم‌فاصله کلید ساده ندارد و کسی که با کیبورد انگلیسی
; تایپ کرده فاصله زده؛ پس وقتی کل متن اشتباه است، نیم‌فاصله و فاصله یکی حساب می‌شوند
CheckLoose(name, got, want) => Check(name " (ZWNJ ~ space)", StrReplace(got, Chr(0x200C), " "), StrReplace(want, Chr(0x200C), " "))

; انتخاب (Ctrl+A): همه‌ی کلمه‌های اشتباه، هر جای متن
Sel(text, force := "") {
    out := FixMixed(text, M, force, &fixed, &endsFa)
    return out
}
; بدون انتخاب: از مکان‌نما به عقب
Caret(text, force := "") {
    if !SplitTail(text, &prefix, &seg, &toPersian, force)
        return text
    return prefix . FixSegment(seg, toPersian, M, Cfg.useDict)
}

; ---------- جمله‌ها ----------
faLong := "امروز صبح زود از خواب بیدار شدم و بعد از صبحانه به دفتر رفتم. "
        . "با همکارانم درباره پروژه جدید صحبت کردیم و قرار شد تا آخر هفته گزارش کامل را آماده کنیم. "
        . "بعد از ظهر هم جلسه داشتیم و مدیر گفت که باید همه بخش‌ها را دوباره بررسی کنیم."
enLong := "I woke up early this morning and went to the office after breakfast. "
        . "We talked about the new project with my colleagues and decided to prepare the full report by the end of the week. "
        . "In the afternoon we had a meeting and the manager said we should check every section again."

; جایگزینی کلمه‌ها در متن درست با نسخه‌ی اشتباه‌شان
Spoil(text, words, wrongFn) {
    for w in words
        text := StrReplace(text, w, wrongFn(w), true, , 1)
    return text
}

; ۱) یک کلمه‌ی اشتباه وسط پاراگراف فارسی
Check("fa paragraph, 1 wrong word in middle", Sel(Spoil(faLong, ["همکارانم"], WrongFa)), faLong)
; ۲) چند کلمه‌ی جدا از هم
Check("fa paragraph, 4 scattered wrong words", Sel(Spoil(faLong, ["صبح", "پروژه", "گزارش", "مدیر"], WrongFa)), faLong)
; ۳) چند کلمه‌ی پشت سر هم
Check("fa paragraph, 5 consecutive wrong words", Sel(Spoil(faLong, ["درباره پروژه جدید صحبت کردیم"], WrongFa)), faLong)
; ۴) چند تکه‌ی چندکلمه‌ای
Check("fa paragraph, 2 multi-word wrong runs", Sel(Spoil(faLong, ["از خواب بیدار شدم", "جلسه داشتیم و مدیر گفت"], WrongFa)), faLong)
; ۵) یک جمله‌ی کامل اشتباه وسط متن
Check("fa paragraph, whole middle sentence wrong", Sel(Spoil(faLong, ["با همکارانم درباره پروژه جدید صحبت کردیم و قرار شد تا آخر هفته گزارش کامل را آماده کنیم"], WrongFa)), faLong)
; ۶) کل پاراگراف اشتباه
CheckLoose("fa paragraph, everything wrong", Sel(WrongFa(faLong)), faLong)

; ۷ تا ۱۰) همین‌ها برای انگلیسی
Check("en paragraph, 1 wrong word in middle", Sel(Spoil(enLong, ["colleagues"], WrongEn)), enLong)
Check("en paragraph, 4 scattered wrong words", Sel(Spoil(enLong, ["morning", "project", "report", "manager"], WrongEn)), enLong)
Check("en paragraph, 6 consecutive wrong words", Sel(Spoil(enLong, ["decided to prepare the full report"], WrongEn)), enLong)
Check("en paragraph, everything wrong", Sel(WrongEn(enLong)), enLong)

; ۱۱) متن دوزبانه: اسم و اصطلاح انگلیسی درست، چند کلمه‌ی فارسی اشتباه
mixed := "دیروز با Ali رفتیم coffee shop و درباره GitHub و پروژه جدید حرف زدیم"
Check("bilingual, correct English kept, wrong Persian fixed", Sel(Spoil(mixed, ["رفتیم", "درباره", "حرف زدیم"], WrongFa)), mixed)
; ۱۲) متن دوزبانه: کلمه‌ی انگلیسی اشتباه وسط فارسی
mixed2 := "این report رو تا فردا برای manager بفرست"
Check("bilingual, wrong English word inside Persian", Sel(Spoil(mixed2, ["report", "manager"], WrongEn)), mixed2)
; ۱۳) هر دو جهت با هم
both := "من امروز meeting دارم و بعدش report رو می‌فرستم"
Check("both directions wrong in one text", Sel(Spoil(both, ["امروز", "meeting", "دارم", "report"], (w) => RegExMatch(w, "[a-z]") ? WrongEn(w) : WrongFa(w))), both)

; دوزبانه‌ی کاملاً برعکس: فارسی‌ها با کیبورد انگلیسی، انگلیسی‌ها با کیبورد فارسی
Swap(text) {
    out := "", pos := 1
    while RegExMatch(text, "\S+", &mt, pos) {
        w := mt[0]
        out .= SubStr(text, pos, mt.Pos - pos) . (RegExMatch(w, "[A-Za-z]") ? WrongEn(w) : RegExMatch(w, "[\x{0600}-\x{06FF}]") ? WrongFa(w) : w)
        pos := mt.Pos + mt.Len
    }
    return out . SubStr(text, pos)
}
biLong := "امروز جلسه weekly review داشتیم و درباره release plan و deadline پروژه صحبت کردیم. "
        . "قرار شد feedback مشتری‌ها رو تا آخر هفته جمع کنیم و یه report کامل برای manager بفرستیم. "
        . "بعدش هم با team درباره design جدید و performance سایت حرف زدیم."
CheckLoose("bilingual paragraph, every word swapped", Sel(Swap(biLong)), biLong)
biShort := "سلام، meeting فردا ساعت ده هست و لطفا laptop رو هم بیار"
Check("bilingual sentence, every word swapped", Sel(Swap(biShort)), biShort)

; ۱۴) چندخطی، تب و خط خالی حفظ شوند
multi := "سلام علی`r`n`r`nفردا جلسه داریم`tساعت ده`r`nلطفا گزارش را بیاور"
Check("multi-line, tabs and blank lines kept", Sel(Spoil(multi, ["جلسه داریم", "گزارش"], WrongFa)), multi)
; ۱۵) لینک، ایمیل، عدد و علائم دست نخورند
misc := "لینک https://github.com/mr-baft/FaEnFix و ایمیل test@example.com رو ببین، شماره ۱۲۳ و 456 هم هست."
Check("URL, email, numbers untouched", Sel(Spoil(misc, ["ببین"], WrongFa)), misc)
; ۱۶) کلمه‌ی اشتباه کنار علامت
; («?» با کیبورد فارسی «؟» است)
Check("wrong word next to ! and ?", Sel("hello " WrongFa("سلام") "! " WrongFa("خوبی") "?"), "hello سلام! خوبی؟")
; ویرگول انگلیسی واقعی در متن انگلیسی درست، «و» نشود
Check("real comma in correct English kept", Sel("first , second and third"), "first , second and third")
; ۱۷) هیچ کلمه‌ای اشتباه نیست → تغییری نکند
FixMixed(faLong, M, "", &fx, &ef)
Check("nothing wrong in fa paragraph → 0 fixes", fx, 0)
FixMixed(enLong, M, "", &fx, &ef)
Check("nothing wrong in en paragraph → 0 fixes", fx, 0)
; ۱۸) «فقط به فارسی» به کلمه‌های فارسی‌نمای اشتباه دست نزند
f := Spoil(both, ["امروز", "meeting"], (w) => RegExMatch(w, "[a-z]") ? WrongEn(w) : WrongFa(w))
Check("force fa: only English-looking words converted", Sel(f, "fa"), StrReplace(f, WrongFa("امروز"), "امروز"))
; ۱۹) نیم‌فاصله‌ی کلمه‌های درست حفظ شود
zw := "می‌خواهم این بخش‌ها را " WrongFa("دوباره") " بنویسم"
Check("ZWNJ in correct words kept", Sel(zw), "می‌خواهم این بخش‌ها را دوباره بنویسم")

; ---------- محاوره‌ای ----------
chat1 := "سلام خوبی؟ چه خبرا؟ داری چیکار میکنی؟ بیا بریم بیرون یه چیزی بخوریم"
Check("colloquial chat, everything wrong", Sel(WrongFa(chat1)), chat1)
chat2 := "اینو بهش بگو که فردا نمیام، خیلی کار دارم"
Check("colloquial, 3 wrong words in middle", Sel(Spoil(chat2, ["اینو", "بهش", "نمیام"], WrongFa)), chat2)
chat3 := "دارم میرم gym بعدش بهت زنگ میزنم باشه؟"
Check("colloquial + English word, every word swapped", Sel(Swap(chat3)), chat3)
chat4 := "آره دیگه، منم همینو میگم ولی کسی گوش نمیده"
Check("colloquial, caret mode whole line wrong", Caret(WrongFa(chat4)), chat4)
; «می‌خوام» با کیبورد انگلیسی: Shift+Space فاصله است → نیم‌فاصله برگردد
Check("ZWNJ restored in می‌ (selection)", Sel(WrongFa("من می‌خوام برم خونه")), "من می‌خوام برم خونه")
Check("ZWNJ restored in نمی‌ (caret)", Caret("ok " WrongFa("نمی‌دونم چی بگم")), "ok نمی‌دونم چی بگم")

; ---------- بدون انتخاب (از مکان‌نما به عقب) ----------
Check("caret: wrong tail after correct Persian", Caret("سلام دوست من، " WrongFa("امروز کجا بودی")), "سلام دوست من، امروز کجا بودی")
Check("caret: long correct line + 6 wrong words", Caret(faLong " " WrongFa("فردا هم باید زودتر بیایم")), faLong " فردا هم باید زودتر بیایم")
Check("caret: English then wrong Persian words", Caret("hello " WrongFa("سلام خبری")), "hello سلام خبری")
Check("caret: wrong English at end of Persian", Caret("این متن " WrongEn("good morning")), "این متن good morning")

; ---------- سرعت ----------
big := ""
Loop 40
    big .= Spoil(faLong, ["پروژه", "گزارش کامل"], WrongFa) "`n"
t0 := A_TickCount
out := Sel(big)
ms := A_TickCount - t0
want := ""
Loop 40
    want .= faLong "`n"
Check("very long text (" StrLen(big) " chars, 120 wrong words) correct", out, want)
Check("very long text under 2s (" ms " ms)", ms < 2000, true)

FileAppend "`n" Passed " passed, " Failed " failed`n", "*", "UTF-8"
ExitApp Failed ? 1 : 0
