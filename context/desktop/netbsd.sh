### ================================
### DESKTOP CONTEXT NETBSD
### ================================

### --------------------------------
### Window Management & WSCONS
### --------------------------------
ctwm-reload() {
	command pkill -HUP ctwm 2> "/dev/null" || echo "❌ ctwm is not running." >&2
}

### --------------------------------
### NetBSD Software
### --------------------------------
code() {
	if command -v code > "/dev/null" 2>&1; then
		command code "$@"
	elif command -v vscode > "/dev/null" 2>&1; then
		command vscode "$@"
	else
		echo "❌ Neither 'code' nor 'vscode' found." >&2
		return 127
	fi
}
