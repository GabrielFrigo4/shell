### ================================
### DESKTOP CONTEXT FREEBSD
### ================================

### --------------------------------
### SOFTWARE
### --------------------------------
code() {
	local _exit_code=0
	if command -v vscode > "/dev/null" 2>&1; then
		command vscode "$@"
		_exit_code=$?
	elif [ -x "/usr/local/bin/code" ]; then
		/usr/local/bin/code "$@"
		_exit_code=$?
	elif command -v code-oss > "/dev/null" 2>&1; then
		command code-oss "$@"
		_exit_code=$?
	else
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Neither 'vscode', 'code' nor 'code-oss' found."
		else
			echo "❌ Neither 'vscode', 'code' nor 'code-oss' found." >&2
		fi
		return 127
	fi
	local _sock
	for _sock in 0 1 2 3 4 5 6 7 8 9; do
		[ -e "${HOME}/:${_sock}" ] && rm -f "${HOME}/:${_sock}" 2> "/dev/null"
	done
	return "${_exit_code}"
}
