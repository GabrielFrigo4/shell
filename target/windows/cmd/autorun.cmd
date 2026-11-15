@echo off
rem ----------------------------------------------------------------
rem Windows CMD AutoRun Bootstrap
rem ----------------------------------------------------------------

if defined _SHELL_CMD_AUTORUN_ACTIVE exit /b 0
set "_SHELL_CMD_AUTORUN_ACTIVE=1"

setlocal EnableDelayedExpansion
set "_cmd_line=!CMDCMDLINE!"
set "_cmd_clean= !_cmd_line:"= ! "
if not "!_cmd_clean: /c =!"=="!_cmd_clean!" (
	endlocal
	set "_SHELL_CMD_AUTORUN_ACTIVE="
	exit /b 0
)
endlocal

set "_clink_bat="
if defined CLINK_DIR if exist "%CLINK_DIR%\clink.bat" set "_clink_bat=%CLINK_DIR%\clink.bat"
if not defined _clink_bat if exist "%ProgramFiles%\clink\clink.bat" set "_clink_bat=%ProgramFiles%\clink\clink.bat"
if not defined _clink_bat if exist "%ProgramFiles(x86)%\clink\clink.bat" set "_clink_bat=%ProgramFiles(x86)%\clink\clink.bat"
if not defined _clink_bat if exist "%LOCALAPPDATA%\Programs\clink\clink.bat" set "_clink_bat=%LOCALAPPDATA%\Programs\clink\clink.bat"
if not defined _clink_bat if exist "%LOCALAPPDATA%\clink\clink.bat" set "_clink_bat=%LOCALAPPDATA%\clink\clink.bat"
if not defined _clink_bat if exist "%USERPROFILE%\scoop\apps\clink\current\clink.bat" set "_clink_bat=%USERPROFILE%\scoop\apps\clink\current\clink.bat"

if defined _clink_bat (
	if defined CLINK_NOAUTORUN (
		set "CLINK_ACTIVE="
		set "CLINK_DIR="
	) else (
		call "%_clink_bat%" inject --autorun --quiet
		if not errorlevel 2 set "CLINK_ACTIVE=1"
	)
)
set "_clink_bat="

if exist "%~dp0profile.cmd" (
	call "%~dp0profile.cmd"
) else if exist "%USERPROFILE%\profile.cmd" (
	call "%USERPROFILE%\profile.cmd"
)

set "_SHELL_CMD_AUTORUN_ACTIVE="
