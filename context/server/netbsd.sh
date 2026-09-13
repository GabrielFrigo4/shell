### ================================
### SERVER CONTEXT NETBSD
### ================================

### --------------------------------
### Disk Usage
### --------------------------------
duse() {
	command df -h "$@"
}

### --------------------------------
### Memory Usage
### --------------------------------
muse() {
	command sysctl -h hw.physmem64 hw.usermem64 2> "/dev/null" ||
	command sysctl -h hw.physmem hw.usermem 2> "/dev/null" ||
	command top -d1 "$@" | command head -5
}

### --------------------------------
### Log Search
### --------------------------------
logsearch() {
	if [ -z "${1:-}" ]; then
		echo "Usage: logsearch <pattern>" >&2
		return 1
	fi
	command grep -i -E "${*}" /var/log/messages 2> "/dev/null" ||
	echo "❌ No searchable log source found or pattern not matched." >&2
}
