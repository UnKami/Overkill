; Inno Setup script for OVERKILL.
; Builds a Windows installer from the Godot export in build/windows/.
; Version is passed in from the build script via /DAppVersion=x.y.z so it
; stays driven by the repo-root VERSION file rather than duplicated here.

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif

#define AppName "Overkill"
#define AppPublisher "Overkill"
#define AppExeName "Overkill.exe"
#define SourceDir "..\build\windows"
#define OutputDir "..\build\installer"

[Setup]
AppId={{B7F2E7E4-6C1A-4C1E-9C2E-0C7C0E6F5A21}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=OverkillSetup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#AppExeName}
DisableWelcomePage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "{#SourceDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\Overkill.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\GODOT-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\DELIVERY.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\Play Sentinel.cmd"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Play Sentinel encounter"; Filename: "{app}\Play Sentinel.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\{#AppExeName}"; Flags: runminimized
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
