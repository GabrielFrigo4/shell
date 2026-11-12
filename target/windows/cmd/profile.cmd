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

if defined XDG_CACHE_HOME (
	set "PYTHONPYCACHEPREFIX=%XDG_CACHE_HOME%\pycache"
) else (
	set "PYTHONPYCACHEPREFIX=%USERPROFILE%\.cache\pycache"
)

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

set "PWSH_BOOT=if ($PROFILE.CurrentUserAllHosts -and (Test-Path $PROFILE.CurrentUserAllHosts)) { . $PROFILE.CurrentUserAllHosts }; if (Test-Path $PROFILE) { . $PROFILE }; if (-not (Get-Command Update-All -ErrorAction SilentlyContinue) -and (Test-Path '%SHELL_REPO_DIR%\target\windows\powershell\profile.ps1')) { . '%SHELL_REPO_DIR%\target\windows\powershell\profile.ps1' }"

rem ================================
rem ALIASES & DOSKEY
rem ================================
doskey upget=winget upgrade --all
doskey upscp=scoop update ^&^& scoop update --all
doskey upcho=choco upgrade all -y
doskey upsys=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-System"
doskey upwin=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Windows"
doskey upgit=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Git $*"
doskey plgit=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Git $*"
doskey psgit=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Push-Git $*"
doskey uped=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Editors"
doskey upmodes=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-EmacsModes"
doskey update-emacs-modes=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-EmacsModes"
doskey uprc=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Profile"
doskey upprofile=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Profile"
doskey sync-profile=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Sync-Profile $*"
doskey upvt=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Vault"
doskey vault-perms=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; vault-perms $*"
doskey upsh=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Shell"
doskey upall=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-All"
doskey u=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-All"
doskey cleansys=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System"
doskey clearsys=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System"
doskey sysclean=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System"
doskey syscls=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System"
doskey clean-system=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System"
doskey clear-system=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-System"
doskey reinstall-shell=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Reinstall-Shell"
doskey resh=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Reinstall-Shell"
doskey bench-shell=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Bench-Shell"
doskey bsh=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Bench-Shell"
doskey shell-bench=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Bench-Shell"
doskey clean-cache=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-Cache"
doskey ccache=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-Cache"
doskey cleancache=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Clean-Cache"
doskey update-wifi=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Wifi"
doskey upwf=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Wifi"
doskey update-network=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Network"
doskey upnet=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Update-Network"

doskey ek=taskkill /IM emacs.exe /F
doskey es=runemacs --fg-daemon
doskey er=taskkill /IM emacs.exe /F ^&^& runemacs --fg-daemon
doskey ec=emacsclientw.exe --create-frame --alternate-editor ""
doskey oe=emacsclientw.exe --create-frame --alternate-editor "" .
doskey open-emacs=emacsclientw.exe --create-frame --alternate-editor "" .
doskey en=emacs.exe -nw $*
doskey enw=emacs.exe -nw $*
doskey emacs-nw=emacs.exe -nw $*
doskey oen=emacs.exe -nw .
doskey oenw=emacs.exe -nw .
doskey open-emacs-nw=emacs.exe -nw .
doskey emacs-eshell=emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"
doskey open-eshell=emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"
doskey oes=emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"
doskey esh=emacsclientw.exe --create-frame --alternate-editor "" --eval "(progn (cd \".\") (aweshell/new))"

doskey editor=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-UniversalEditor $*"
doskey e=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-UniversalEditor $*"
doskey open-helix=hx $*
doskey open-hx=hx $*
doskey oh=hx $*
doskey h=hx $*
doskey open-kate=start "" kate $*
doskey ok=start "" kate $*
doskey open-geany=start "" geany $*
doskey og=start "" geany $*
doskey open-code=start "" code $*
doskey oc=start "" code $*
doskey open-codium=start "" codium $*
doskey ocm=start "" codium $*
doskey open-zed=start "" zed $*
doskey oz=start "" zed $*
doskey open-antigravity=start "" antigravity-ide $*
doskey open-ant=start "" antigravity-ide $*
doskey oa=start "" antigravity-ide $*
doskey ant=start "" antigravity-ide $*

doskey open-smart=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-OpenSmart $*"
doskey o=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-OpenSmart $*"
doskey open=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-OpenSmart $*"
doskey take=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-TakeDir $*"
doskey take-dir=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-TakeDir $*"
doskey mkcd=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-TakeDir $*"
doskey cdb=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-CdGitRoot"
doskey cd-git-root=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-CdGitRoot"
doskey hist=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-HistSearch $*"
doskey hg=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-HistSearch $*"
doskey extract=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-ExtractArchive $*"
doskey x=%PWSH_EXE% -NoProfile -ExecutionPolicy Bypass -Command "%PWSH_BOOT%; Invoke-ExtractArchive $*"
doskey z=zoxide $*

doskey gs=git status -sb $*
doskey gd=git diff $*
doskey gst=git status $*
doskey gco=git checkout $*
doskey gcb=git checkout -b $*
doskey gsw=git switch $*
doskey gswc=git switch -c $*
doskey gcm=git commit -m $*
doskey gaa=git add --all $*
doskey gl=git pull $*
doskey gp=git push $*
doskey glog=git log --oneline --decorate --graph -n 20 $*

doskey a=agy $*
doskey aa=agy --dangerously-skip-permissions $*
doskey ad=agy --dangerously-skip-permissions $*
doskey agy-continue=agy -c $*
doskey agyc=agy -c $*
doskey agyr=agy -c $*
doskey agy-return=agy -c $*
doskey agy-auto=agy --dangerously-skip-permissions $*
doskey agy-danger=agy --dangerously-skip-permissions $*
doskey agya=agy --dangerously-skip-permissions $*
doskey agyd=agy --dangerously-skip-permissions $*
doskey agy-continue-auto=agy -c --dangerously-skip-permissions $*
doskey agy-continue-danger=agy -c --dangerously-skip-permissions $*
doskey agyca=agy -c --dangerously-skip-permissions $*
doskey agycd=agy -c --dangerously-skip-permissions $*
doskey agyra=agy -c --dangerously-skip-permissions $*
doskey agyrd=agy -c --dangerously-skip-permissions $*
doskey agy-return-auto=agy -c --dangerously-skip-permissions $*
doskey agy-return-danger=agy -c --dangerously-skip-permissions $*
