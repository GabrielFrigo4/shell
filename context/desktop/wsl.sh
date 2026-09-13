### ================================
### DESKTOP CONTEXT WSL
### ================================

### --------------------------------
### Windows Integration
### --------------------------------
explorer() {
	command -v explorer.exe > "/dev/null" 2>&1 || { echo "❌ explorer.exe not found." >&2; return 127; }
	command explorer.exe "$@"
}

powershell() {
	command -v powershell.exe > "/dev/null" 2>&1 || { echo "❌ powershell.exe not found." >&2; return 127; }
	command powershell.exe "$@"
}

pwsh() {
	command -v pwsh.exe > "/dev/null" 2>&1 || { echo "❌ pwsh.exe not found." >&2; return 127; }
	command pwsh.exe "$@"
}

cmd() {
	command -v cmd.exe > "/dev/null" 2>&1 || { echo "❌ cmd.exe not found." >&2; return 127; }
	command cmd.exe "$@"
}

### --------------------------------
### Windows Clipboard
### --------------------------------
clip() {
	if command -v win32yank.exe > "/dev/null" 2>&1; then
		command win32yank.exe "$@"
	elif command -v clip.exe > "/dev/null" 2>&1; then
		command clip.exe "$@"
	else
		echo "❌ No Windows clipboard tool found (win32yank.exe/clip.exe)." >&2
		return 127
	fi
}

paste() {
	if command -v win32yank.exe > "/dev/null" 2>&1; then
		command win32yank.exe -o "$@"
	elif command -v powershell.exe > "/dev/null" 2>&1; then
		command powershell.exe -NoProfile -Command Get-Clipboard
	else
		echo "❌ No Windows clipboard tool found (win32yank.exe/powershell.exe)." >&2
		return 127
	fi
}

### --------------------------------
### Path Converters
### --------------------------------
win-path() {
	command -v wslpath > "/dev/null" 2>&1 || { echo "❌ wslpath not found." >&2; return 127; }
	command wslpath -w "${1:-.}"
}

wsl-path() {
	command -v wslpath > "/dev/null" 2>&1 || { echo "❌ wslpath not found." >&2; return 127; }
	command wslpath -u "${1}"
}

### --------------------------------
### Windows Navigation
### --------------------------------
cd-win() {
	local _win_user="${USER}"
	[ -n "${WSL_USER:-}" ] && _win_user="${WSL_USER}"
	if [ -d "/mnt/c/Users/${_win_user}" ]; then
		cd "/mnt/c/Users/${_win_user}/${1:-}"
	elif [ -d "/mnt/c/Users" ]; then
		cd "/mnt/c/Users/${1:-}"
	else
		echo "❌ Windows Users directory not found at /mnt/c/Users." >&2
		return 1
	fi
}

### --------------------------------
### Windows File Launcher
### --------------------------------
open-win() {
	if command -v wslpath > "/dev/null" 2>&1 && command -v explorer.exe > "/dev/null" 2>&1; then
		command explorer.exe "$(command wslpath -w "${1:-.}")" > "/dev/null" 2>&1
	elif command -v explorer.exe > "/dev/null" 2>&1; then
		command explorer.exe "${1:-.}" > "/dev/null" 2>&1
	else
		echo "❌ Neither wslpath nor explorer.exe was found." >&2
		return 127
	fi
}
