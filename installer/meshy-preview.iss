#define AppName "Overkill Meshy Preview"
[Setup]
AppId={{EDD577A6-95C2-476D-8136-BB1E314507B8}
AppName={#AppName}
AppVersion=0.49.0
DefaultDirName={localappdata}\Overkill Meshy Preview
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\build\installer
OutputBaseFilename=Overkill-Meshy-Preview-0.49.0
Compression=lzma2/fast
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
[Files]
Source: "..\build\windows\Overkill.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\Overkill.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "GODOT-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
[Icons]
Name: "{autodesktop}\Overkill Meshy Preview"; Filename: "{app}\Overkill.exe"
[Run]
Filename: "{app}\Overkill.exe"; Description: "Open the Meshy battle preview"; Flags: nowait postinstall skipifsilent

