; نصب‌کننده‌ی FaEnFix (Inno Setup 6)
; ساخت:  iscc /DAppVersion=1.2.0 installer\FaEnFix.iss   ← فایل dist\FaEnFix.exe باید از قبل ساخته شده باشد
; نصب برای کاربر فعلی، بدون نیاز به دسترسی ادمین؛ بعد از نصب برنامه اجرا و به اجرای خودکار ویندوز اضافه می‌شود

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{6F3B2C1E-8A4D-4F2B-9C7E-FAE0F1C0DE01}
AppName=FaEnFix
AppVersion={#AppVersion}
AppVerName=FaEnFix {#AppVersion}
AppPublisher=Alireza Moghaddam
AppPublisherURL=https://github.com/mr-baft/FaEnFix
AppSupportURL=https://github.com/mr-baft/FaEnFix/issues
DefaultDirName={localappdata}\Programs\FaEnFix
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
DisableWelcomePage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=FaEnFix-Setup
SetupIconFile=..\icon.ico
UninstallDisplayIcon={app}\FaEnFix.exe
UninstallDisplayName=FaEnFix
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
RestartApplications=no

[Files]
Source: "..\dist\FaEnFix.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\FaEnFix"; Filename: "{app}\FaEnFix.exe"

[Registry]
; اجرای خودکار با روشن شدن ویندوز (از منوی برنامه قابل خاموش کردن است)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "FaEnFix"; ValueData: """{app}\FaEnFix.exe"" /silent"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\FaEnFix.exe"; Description: "Launch FaEnFix"; Flags: nowait postinstall

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM FaEnFix.exe"; Flags: runhidden; RunOnceId: "KillApp"

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\FaEnFix"

[Code]
// اگر برنامه در حال اجراست، قبل از نصب نسخه‌ی جدید بسته شود
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Code: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM FaEnFix.exe', '', SW_HIDE, ewWaitUntilTerminated, Code);
  Result := '';
end;
