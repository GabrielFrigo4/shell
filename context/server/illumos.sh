### ================================
### SERVER CONTEXT ILLUMOS
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
	command prtconf 2> "/dev/null" | command grep -i "Memory size" ||
	command prstat -c -n 5 -s rss 1 1 2> "/dev/null" ||
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
	local _log_file="" _unreadable_file="" _candidate _exit_code
	for _candidate in /var/adm/messages /var/log/messages; do
		if [ -r "${_candidate}" ]; then
			_log_file="${_candidate}"
			break
		elif [ -e "${_candidate}" ] && [ -z "${_unreadable_file}" ]; then
			_unreadable_file="${_candidate}"
		fi
	done
	if [ -z "${_log_file}" ]; then
		if [ -n "${_unreadable_file}" ]; then
			if command -v _ui_err > "/dev/null" 2>&1; then
				_ui_err "Permission denied reading '${_unreadable_file}'."
			else
				echo "❌ Permission denied reading '${_unreadable_file}'." >&2
			fi
		else
			if command -v _ui_err > "/dev/null" 2>&1; then
				_ui_err "No log file found (/var/adm/messages or /var/log/messages)."
			else
				echo "❌ No log file found (/var/adm/messages or /var/log/messages)." >&2
			fi
		fi
		return 1
	fi
	command grep -i -E -- "${*}" "${_log_file}"
	_exit_code=$?
	if [ "${_exit_code}" -eq 1 ]; then
		if command -v _ui_info > "/dev/null" 2>&1; then
			_ui_info "No matches found in '${_log_file}'."
		else
			echo "No matches found in '${_log_file}'." >&2
		fi
	elif [ "${_exit_code}" -gt 1 ]; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Failed to search '${_log_file}' (exit ${_exit_code})."
		else
			echo "❌ Failed to search '${_log_file}' (exit ${_exit_code})." >&2
		fi
	fi
	return "${_exit_code}"
}
