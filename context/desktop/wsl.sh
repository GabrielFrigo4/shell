### ================================
### DESKTOP CONTEXT WSL
### ================================

### --------------------------------
### WINDOWS INTEGRATION
### --------------------------------
explorer() {
	command -v explorer.exe > "/dev/null" 2>&1 || { _ui_err "explorer.exe not found."; return 127; }
	command explorer.exe "$@"
}

powershell() {
	command -v powershell.exe > "/dev/null" 2>&1 || { _ui_err "powershell.exe not found."; return 127; }
	command powershell.exe "$@"
}

pwsh() {
	command -v pwsh.exe > "/dev/null" 2>&1 || { _ui_err "pwsh.exe not found."; return 127; }
	command pwsh.exe "$@"
}

cmd() {
	command -v cmd.exe > "/dev/null" 2>&1 || { _ui_err "cmd.exe not found."; return 127; }
	command cmd.exe "$@"
}

### --------------------------------
### WINDOWS CLIPBOARD
### --------------------------------
clip() {
	if command -v win32yank.exe > "/dev/null" 2>&1; then
		command win32yank.exe "$@"
	elif command -v clip.exe > "/dev/null" 2>&1; then
		command clip.exe "$@"
	else
		_ui_err "No Windows clipboard tool found (win32yank.exe/clip.exe)."
		return 127
	fi
}

paste() {
	if command -v win32yank.exe > "/dev/null" 2>&1; then
		command win32yank.exe -o "$@"
	elif command -v powershell.exe > "/dev/null" 2>&1; then
		command powershell.exe -NoProfile -Command Get-Clipboard
	else
		_ui_err "No Windows clipboard tool found (win32yank.exe/powershell.exe)."
		return 127
	fi
}

### --------------------------------
### PATH CONVERTERS
### --------------------------------
win-path() {
	command -v wslpath > "/dev/null" 2>&1 || { _ui_err "wslpath not found."; return 127; }
	command wslpath -w "${1:-.}"
}

wsl-path() {
	command -v wslpath > "/dev/null" 2>&1 || { _ui_err "wslpath not found."; return 127; }
	if [ -z "${1:-}" ]; then
		_ui_err "Usage: wsl-path <windows-path>"
		return 1
	fi
	command wslpath -u "${1}"
}

### --------------------------------
### WINDOWS NAVIGATION
### --------------------------------
cd-win() {
	local _win_user="${WSL_USER:-${USER:-${USERNAME:-}}}"
	local _win_home=""
	if [ -z "${WSL_USER:-}" ] && { [ -z "${_win_user}" ] || [ ! -d "/mnt/c/Users/${_win_user}" ]; }; then
		if command -v cmd.exe > "/dev/null" 2>&1 && command -v wslpath > "/dev/null" 2>&1; then
			_win_home="$(command cmd.exe /C "echo %USERPROFILE%" 2> "/dev/null" | command tr -d '\r')"
			[ -n "${_win_home}" ] && _win_home="$(command wslpath -u "${_win_home}" 2> "/dev/null")"
		fi
	fi
	if [ -n "${_win_home}" ] && [ -d "${_win_home}" ]; then
		cd "${_win_home}/${1:-}"
	elif [ -n "${_win_user}" ] && [ -d "/mnt/c/Users/${_win_user}" ]; then
		cd "/mnt/c/Users/${_win_user}/${1:-}"
	elif [ -d "/mnt/c/Users" ]; then
		cd "/mnt/c/Users/${1:-}"
	else
		_ui_err "Windows Users directory not found at /mnt/c/Users."
		return 1
	fi
}

### --------------------------------
### WINDOWS FILE LAUNCHER
### --------------------------------
open-win() {
	if command -v wslpath > "/dev/null" 2>&1 && command -v explorer.exe > "/dev/null" 2>&1; then
		local _win_target=""
		_win_target="$(command wslpath -w "${1:-.}" 2> "/dev/null")"
		command explorer.exe "${_win_target:-${1:-.}}" > "/dev/null" 2>&1
	elif command -v explorer.exe > "/dev/null" 2>&1; then
		command explorer.exe "${1:-.}" > "/dev/null" 2>&1
	else
		_ui_err "Neither wslpath nor explorer.exe was found."
		return 127
	fi
}
