### ================================
### SERVER CONTEXT ILLUMOS
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
	command prtconf 2> "/dev/null" | command grep -i "Memory size" ||
	command prstat -c -n 5 -s rss 1 1 2> "/dev/null" ||
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
	command grep -i -E "${*}" /var/adm/messages 2> "/dev/null" ||
	command grep -i -E "${*}" /var/log/messages 2> "/dev/null" ||
	echo "❌ No searchable log source found or pattern not matched." >&2
}
