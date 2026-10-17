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
if not defined PWSH_EXE (
	where pwsh >nul 2>&1 && (
		set "PWSH_EXE=pwsh"
	) || (
		set "PWSH_EXE=powershell"
	)
)

set "PWSH_BOOT=& { if (Test-Path $PROFILE) { . $PROFILE } elseif (Test-Path '%SHELL_REPO_DIR%\target\windows\powershell\profile.ps1') { . '%SHELL_REPO_DIR%\target\windows\powershell\profile.ps1' }"

rem ================================
rem ALIASES & DOSKEY
rem ================================
doskey upget=winget upgrade --all
doskey upscp=scoop update ^&^& scoop update --all
doskey upcho=choco upgrade all -y
doskey upsys=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-System }"
doskey upwin=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Windows }"
doskey upgit=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Git $* }"
doskey plgit=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Git $* }"
doskey psgit=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Push-Git $* }"
doskey uped=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Editors }"
doskey uprc=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Profile }"
doskey upprofile=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Profile }"
doskey sync-profile=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Sync-Profile $* }"
doskey upvt=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Vault }"
doskey vault-perms=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; vault-perms $* }"
doskey upsh=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Shell }"
doskey upall=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-All }"
doskey cleansys=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System }"
doskey sysclean=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System }"
doskey syscls=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System }"
doskey clean-system=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System }"
