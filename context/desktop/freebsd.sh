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
	elif command -v code-oss > "/dev/null" 2>&1; then
		command code-oss "$@"
	else
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Neither 'vscode', 'code' nor 'code-oss' found."
		else
			echo "Neither 'vscode', 'code' nor 'code-oss' found." >&2
		fi
		return 127
	fi
	for _sock in 0 1 2 3 4 5 6 7 8 9; do
		[ -e "${HOME}/:${_sock}" ] && rm -f "${HOME}/:${_sock}" 2> "/dev/null"
	done
	unset -v _sock
}
