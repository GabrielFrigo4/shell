### ================================
### DESKTOP CONTEXT NETBSD
### ================================

### --------------------------------
### WINDOW MANAGEMENT & WSCONS
### --------------------------------
ctwm-reload() {
	if ! command pkill -HUP ctwm 2> "/dev/null"; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "ctwm is not running."
		else
			echo "❌ ctwm is not running." >&2
		fi
		return 1
	fi
}

### --------------------------------
### NETBSD SOFTWARE
### --------------------------------
code() {
	if command -v code > "/dev/null" 2>&1; then
		command code "$@"
	elif command -v vscode > "/dev/null" 2>&1; then
		command vscode "$@"
	else
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Neither 'code' nor 'vscode' found."
		else
			echo "❌ Neither 'code' nor 'vscode' found." >&2
		fi
		return 127
	fi
}
