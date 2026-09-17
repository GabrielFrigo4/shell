### ================================
### DESKTOP CONTEXT FREEBSD
### ================================

### --------------------------------
### Software
### --------------------------------
code() {
	if command -v vscode > "/dev/null" 2>&1; then
		command vscode "$@"
	elif [ -x "/usr/local/bin/code" ]; then
		/usr/local/bin/code "$@"
	else
		echo "❌ Neither 'vscode' nor 'code' found." >&2
		return 127
	fi
	[ -e "${HOME}/:0" ] && rm -f "${HOME}/:0" 2> "/dev/null"
}

### --------------------------------
### Housekeeping
### --------------------------------
[ -e "${HOME}/:0" ] && rm -f "${HOME}/:0" 2> "/dev/null"
