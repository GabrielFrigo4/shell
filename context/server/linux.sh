### ================================
### SERVER CONTEXT LINUX
### ================================

### --------------------------------
### Disk Usage
### --------------------------------
duse() {
	command df -h --output=source,fstype,size,used,avail,pcent,target \
		-x tmpfs -x devtmpfs 2> "/dev/null" || command df -h
}

### --------------------------------
### Memory Usage
### --------------------------------
muse() {
	if command -v free > "/dev/null" 2>&1; then
		command free -h "$@"
	else
		command cat /proc/meminfo
	fi
}

### --------------------------------
### Log Search
### --------------------------------
logsearch() {
	if [ -z "${1:-}" ]; then
		echo "Usage: logsearch <pattern>" >&2
		return 1
	fi
	if command -v journalctl > "/dev/null" 2>&1; then
		command journalctl --no-pager -n 200 --grep "${*}"
	else
		command grep -i -E "${*}" /var/log/messages 2> "/dev/null" ||
		command grep -i -E "${*}" /var/log/syslog 2> "/dev/null" ||
		echo "❌ No searchable log source found or pattern not matched." >&2
	fi
}

### --------------------------------
### WSL Subsystem Extensions
### --------------------------------
if _is_wsl; then
	[ -f "${SHELL_REPO_DIR}/context/server/wsl.sh" ] && \
		. "${SHELL_REPO_DIR}/context/server/wsl.sh"
fi
