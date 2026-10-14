@echo off
rem ----------------------------------------------------------------
rem Windows CMD AutoRun Bootstrap
rem ----------------------------------------------------------------

if exist "%~dp0profile.cmd" (
	call "%~dp0profile.cmd"
) else if exist "%USERPROFILE%\profile.cmd" (
	call "%USERPROFILE%\profile.cmd"
)
