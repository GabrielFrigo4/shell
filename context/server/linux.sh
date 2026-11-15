### ================================
### SERVER CONTEXT LINUX
### ================================

### --------------------------------
### DISK USAGE
### --------------------------------
duse() {
	command df -h --output=source,fstype,size,used,avail,pcent,target \
		-x tmpfs -x devtmpfs 2> "/dev/null" || command df -h
}

### --------------------------------
### MEMORY USAGE
### --------------------------------
muse() {
	if command -v free > "/dev/null" 2>&1; then
		command free -h "$@"
	else
		command cat "/proc/meminfo"
	fi
}

### --------------------------------
### LOG SEARCH
### --------------------------------
logsearch() {
	if [ -z "${1:-}" ]; then
		_ui_err "Usage: logsearch <pattern>"
		return 1
	fi
	if command -v journalctl > "/dev/null" 2>&1; then
		command journalctl --no-pager -n 200 --grep "${*}"
	elif [ -f "/var/log/messages" ] || [ -f "/var/log/syslog" ]; then
		command grep -i -E "${*}" "/var/log/messages" 2> "/dev/null" ||
			command grep -i -E "${*}" "/var/log/syslog" 2> "/dev/null" ||
			return 1
	else
		_ui_err "No searchable log source found or pattern not matched."
		return 1
	fi
}

### --------------------------------
### WSL SUBSYSTEM EXTENSIONS
### --------------------------------
if command -v _is_wsl > "/dev/null" 2>&1 && _is_wsl; then
	[ -f "${SHELL_REPO_DIR:-}/context/server/wsl.sh" ] && \
		. "${SHELL_REPO_DIR:-}/context/server/wsl.sh"
fi
