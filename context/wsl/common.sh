### ================================
### WSL CONTEXT COMMON
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
