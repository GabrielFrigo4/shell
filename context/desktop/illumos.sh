### ================================
### DESKTOP CONTEXT ILLUMOS
### ================================

### --------------------------------
### illumos Software
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
