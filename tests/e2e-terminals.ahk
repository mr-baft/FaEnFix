#Requires AutoHotkey v2.0
; در هر ترمینال یک ping طولانی اجرا می‌کند، کلیدهای FaEnFix را می‌زند و چک می‌کند ping متوقف نشده باشد.
; قبلش FaEnFix باید در حال اجرا باشد.   AutoHotkey64.exe /ErrorStdOut tests\e2e-terminals.ahk
; هیچ کلیدی جز به پنجره‌ای که خود تست باز کرده فرستاده نمی‌شود.
SendLevel 1
SetTitleMatchMode 2
scratch := A_Temp "\faenfix-e2e"
DirCreate scratch
pass := 0
Log(s) => FileAppend(s "`n", "*", "UTF-8")

PingAlive(marker) {
    for p in ComObjGet("winmgmts:").ExecQuery("SELECT CommandLine FROM Win32_Process WHERE Name='PING.EXE'")
        if InStr(p.CommandLine, "-n " marker)
            return true
    return false
}
KillPing(marker) {
    for p in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='PING.EXE'")
        if InStr(p.CommandLine, "-n " marker)
            ProcessClose p.ProcessId
}
; پنجره‌ی تازه‌ای که بعد از اجرا ظاهر می‌شود (نه پنجره‌های قبلی کاربر)
NewWindow(winTitle, before, timeout := 15000) {
    t0 := A_TickCount
    while (A_TickCount - t0 < timeout) {
        for h in WinGetList(winTitle)
            if !HasVal(before, h)
                return h
        Sleep 250
    }
    return 0
}
HasVal(arr, v) {
    for x in arr
        if (x = v)
            return true
    return false
}
SafeSend(hwnd, keys, text := false) {
    Loop 3 {
        WinActivate hwnd
        if WinWaitActive(hwnd, , 1)
            break
    }
    if !WinActive(hwnd) {
        FileAppend "ABORT: test window " WinGetTitle(hwnd) " is not active (active: " WinGetProcessName("A") " / " WinGetTitle("A") "), nothing more sent`n", "*", "UTF-8"
        ExitApp 3
    }
    text ? SendText(keys) : Send(keys)
}

; هر ترمینال: [اسم, شناسه‌ی پنجره, دستور اجرا, شماره‌ی ping, آماده‌سازی بعد از باز شدن]
code := EnvGet("LOCALAPPDATA") "\Programs\Microsoft VS Code\Code.exe"
vsData := scratch "\vscode-data"
DirCreate vsData "\User"
DirCreate scratch "\vscode-folder"
try FileDelete vsData "\User\settings.json"
FileAppend '{"workbench.startupEditor": "none", "security.workspace.trust.enabled": false, '
    . '"terminal.integrated.defaultProfile.windows": "Command Prompt", "window.restoreWindows": "none"}', vsData "\User\settings.json"

terms := [
    ["cmd", "ahk_exe cmd.exe", 'cmd.exe /k ping -n 301 127.0.0.1', 301, ""],
    ["PowerShell", "ahk_exe powershell.exe", 'powershell.exe -NoExit -Command ping -n 302 127.0.0.1', 302, ""],
    ["Windows Terminal", "ahk_exe WindowsTerminal.exe", 'wt.exe -w new cmd /k ping -n 303 127.0.0.1', 303, ""],
    ; VS Code جدا با پروفایل موقت (به VS Code خود کاربر دست نمی‌زند)؛ اگر VS Code در حال به‌روزرسانی باشد باز نمی‌شود
    ["VS Code terminal", "ahk_exe Code.exe", '"' code '" --user-data-dir "' vsData '" --extensions-dir "' scratch '\vscode-ext" --new-window "' scratch '\vscode-folder"', 304, "vscode"],
]

for t in terms {
    name := t[1], marker := t[4]
    before := WinGetList(t[2])
    try Run t[3]
    catch {
        Log("SKIP | " name " (not installed)")
        continue
    }
    hwnd := NewWindow(t[2], before)
    if !hwnd {
        Log("SKIP | " name " (window did not appear)")
        continue
    }
    if (t[5] = "vscode") {
        Sleep 6000                               ; بالا آمدن VS Code
        SafeSend(hwnd, "^{vkC0}")                ; Ctrl+` : باز کردن ترمینال
        Sleep 4000
        SafeSend(hwnd, "ping -n 304 127.0.0.1", true)
        SafeSend(hwnd, "{Enter}")
    }
    ; ping باید راه افتاده باشد
    t0 := A_TickCount
    while (!PingAlive(marker) && A_TickCount - t0 < 10000)
        Sleep 300
    if !PingAlive(marker) {
        Log("SKIP | " name " (ping did not start)")
        WinClose hwnd
        continue
    }
    Sleep 1000
    ; کلیدهای FaEnFix، هر کدام جدا
    for k in ["^+{Space}", "+!f", "+!e"] {
        SafeSend(hwnd, k)
        Sleep 1500
    }
    ok := PingAlive(marker)
    pass += ok
    Log((ok ? "PASS" : "FAIL") " | " name ": running command " (ok ? "kept running" : "WAS STOPPED") " after Ctrl+Shift+Space, Shift+Alt+F, Shift+Alt+E")
    KillPing(marker)
    Sleep 500
    try WinClose hwnd
    Sleep 1500
    if WinExist(hwnd)
        try WinKill hwnd
}
FileAppend pass " passed`n", "*", "UTF-8"
