; نصب‌کننده‌ی FaEnFix (Inno Setup 6)
; ساخت:  iscc /DAppVersion=1.2.0 installer\FaEnFix.iss   ← فایل dist\FaEnFix.exe باید از قبل ساخته شده باشد
; نصب برای کاربر فعلی، بدون نیاز به دسترسی ادمین؛ اجرای خودکار با ویندوز یک تیک (پیش‌فرض روشن) در نصب است

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
WizardImageFile=wizard-164.bmp,wizard-328.bmp
WizardSmallImageFile=wizard-small-55.bmp,wizard-small-110.bmp
VersionInfoDescription=FaEnFix Setup
VersionInfoCopyright=Copyright (c) 2026 Alireza Moghaddam
CloseApplications=force
RestartApplications=no

[Tasks]
Name: "autostart"; Description: "Start FaEnFix automatically when Windows starts (runs quietly in the background)"

[Files]
Source: "..\dist\FaEnFix.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\FaEnFix"; Filename: "{app}\FaEnFix.exe"

[Registry]
; اجرای خودکار با روشن شدن ویندوز، فقط اگر کاربر تیکش را زده باشد (از منوی برنامه هم قابل خاموش کردن است)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "FaEnFix"; ValueData: """{app}\FaEnFix.exe"" /silent"; Flags: uninsdeletevalue; Tasks: autostart
; به برنامه می‌گوید با نصب‌کننده نصب شده (انتخاب اجرای خودکار را دوباره نپرسد)
Root: HKCU; Subkey: "Software\FaEnFix"; ValueType: string; ValueName: "InstalledBy"; ValueData: "setup"; Flags: uninsdeletekey

[Run]
Filename: "{app}\FaEnFix.exe"; Description: "Launch FaEnFix"; Flags: nowait postinstall

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM FaEnFix.exe"; Flags: runhidden; RunOnceId: "KillApp"

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\FaEnFix"

[Code]
// «حالت ادمین» برنامه یک Scheduled Task به اسم FaEnFix می‌سازد و برنامه با دسترسی بالا اجرا می‌شود
function AdminTaskExists(): Boolean;
var
  Code: Integer;
begin
  Result := Exec(ExpandConstant('{sys}\schtasks.exe'), '/Query /TN "FaEnFix"', '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0);
end;

// بستن برنامه؛ نسخه‌ی ادمین فقط با تأیید ویندوز بسته می‌شود (و در حذف، Task هم پاک می‌شود)
procedure StopApp(DeleteTask: Boolean);
var
  Code: Integer;
  Cmd: String;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM FaEnFix.exe', '', SW_HIDE, ewWaitUntilTerminated, Code);
  if AdminTaskExists() then
  begin
    Cmd := '/c taskkill /F /IM FaEnFix.exe';
    if DeleteTask then
      Cmd := Cmd + ' & schtasks /Delete /F /TN FaEnFix';
    ShellExec('runas', ExpandConstant('{cmd}'), Cmd, '', SW_HIDE, ewWaitUntilTerminated, Code);
  end;
end;

// اگر در به‌روزرسانی تیک اجرای خودکار برداشته شد، مقدار قبلی هم پاک شود
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and not WizardIsTaskSelected('autostart') then
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'FaEnFix');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopApp(False);
  Result := '';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    StopApp(True);
end;
