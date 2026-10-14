@echo off
rem ----------------------------------------------------------------
rem Config: Windows CMD Profile
rem ----------------------------------------------------------------

rem ================================
rem SETUP
rem ================================
if exist "%USERPROFILE%\.local\share\vault\vault.cmd" (
	call "%USERPROFILE%\.local\share\vault\vault.cmd"
) else if exist "%USERPROFILE%\.config\vault\vault.cmd" (
	call "%USERPROFILE%\.config\vault\vault.cmd"
) else if exist "%USERPROFILE%\.vault\vault.cmd" (
	call "%USERPROFILE%\.vault\vault.cmd"
)

rem ================================
rem VARS
rem ================================
set "HOME=%USERPROFILE%"
set "SYSTEM32=C:\Windows\System32"
set "ONEDRIVE=%HOME%\OneDrive"
set "DESKTOP=%ONEDRIVE%\Área de Trabalho"
set "DOCUMENTS=%ONEDRIVE%\Documentos"
set "IMAGES=%ONEDRIVE%\Imagens"
set "WORKSPACE=%ONEDRIVE%\Workspace"
set "DOWNLOADS=%HOME%\Downloads"
set "CLINKPATH=%PROGRAMFILES(x86)%\clink"
set "CMD_PROFILE=%HOME%\profile.cmd"
set "LUA_PROFILE=%CLINKPATH%\profile.lua"
set "PWSH_PROFILE=C:\Program Files\PowerShell\7\profile.ps1"
set "VIRTUAL_STORE=%LOCALAPPDATA%\VirtualStore"
set "FASM_STORE=%VIRTUAL_STORE%\Program Files\FASM"
set "FASM2_STORE=%VIRTUAL_STORE%\Program Files\FASM2"
set "FASMG_STORE=%VIRTUAL_STORE%\Program Files\FASMG"
set "FASMARM_STORE=%VIRTUAL_STORE%\Program Files\FASMARM"

if not defined SHELL_REPO_DIR (
	if exist "%~dp0..\..\..\shell.sh" (
		set "SHELL_REPO_DIR=%~dp0..\..\.."
	) else if exist "%USERPROFILE%\.local\share\shell\shell.sh" (
		set "SHELL_REPO_DIR=%USERPROFILE%\.local\share\shell"
	) else if exist "%USERPROFILE%\.config\shell\shell.sh" (
		set "SHELL_REPO_DIR=%USERPROFILE%\.config\shell"
	) else if exist "%PROGRAMFILES%\Shell\shell.sh" (
		set "SHELL_REPO_DIR=%PROGRAMFILES%\Shell"
	)
)

rem ================================
rem ALIASES & DOSKEY
rem ================================
doskey upget=winget upgrade --all
doskey upscp=scoop update ^&^& scoop update --all
doskey upcho=choco upgrade all -y
doskey upsys=winget upgrade --all ^&^& scoop update ^&^& scoop update --all ^&^& choco upgrade all -y
doskey upwin=powershell -NoProfile -Command "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"
doskey upgit=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Git $* }"
doskey plgit=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Git $* }"
doskey psgit=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Push-Git $* }"
doskey uped=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Editors }"
doskey uprc=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Profile }"
doskey upprofile=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Profile }"
doskey sync-profile=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Sync-Profile $* }"
doskey upvt=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Vault }"
doskey vault-perms=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; vault-perms $* }"
doskey upsh=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-Shell }"
doskey upall=powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . $PROFILE; Update-All }"
