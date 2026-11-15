### ================================
### DESKTOP CONTEXT OPENBSD
### ================================

### --------------------------------
### WINDOW MANAGEMENT & DISPLAY
### --------------------------------
cwm-reload() {
	if ! command pkill -HUP cwm 2> "/dev/null"; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "cwm is not running."
		else
			echo "❌ cwm is not running." >&2
		fi
		return 1
	fi
}

### --------------------------------
### OPENBSD SOFTWARE
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
