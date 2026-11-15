### ================================
### SERVER CONTEXT FREEBSD
### ================================

### --------------------------------
### DISK USAGE
### --------------------------------
duse() {
	command df -h "$@"
}

### --------------------------------
### MEMORY USAGE
### --------------------------------
muse() {
	command sysctl -h hw.physmem hw.usermem 2> "/dev/null" ||
	command top -d1 "$@" | command head -5
}

### --------------------------------
### LOG SEARCH
### --------------------------------
logsearch() {
	if [ -z "${1:-}" ]; then
		echo "Usage: logsearch <pattern>" >&2
		return 1
	fi
	if [ ! -e "/var/log/messages" ]; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Log file '/var/log/messages' not found."
		else
			echo "❌ Log file '/var/log/messages' not found." >&2
		fi
		return 1
	fi
	if [ ! -r "/var/log/messages" ]; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Permission denied reading '/var/log/messages'."
		else
			echo "❌ Permission denied reading '/var/log/messages'." >&2
		fi
		return 1
	fi
	command grep -i -E -- "${*}" "/var/log/messages"
	local _exit_code=$?
	if [ "${_exit_code}" -eq 1 ]; then
		if command -v _ui_info > "/dev/null" 2>&1; then
			_ui_info "No matches found in '/var/log/messages'."
		else
			echo "No matches found in '/var/log/messages'." >&2
		fi
	elif [ "${_exit_code}" -gt 1 ]; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Failed to search '/var/log/messages' (exit ${_exit_code})."
		else
			echo "❌ Failed to search '/var/log/messages' (exit ${_exit_code})." >&2
		fi
	fi
	return "${_exit_code}"
}
