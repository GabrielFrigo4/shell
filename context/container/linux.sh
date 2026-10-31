### ================================
### CONTAINER CONTEXT LINUX
### ================================

### --------------------------------
### Runtime Detection
### --------------------------------
if [ -f /.dockerenv ] || command grep -qsF 'docker' /proc/1/cgroup 2> "/dev/null"; then
	export CONTAINER_RUNTIME="docker"
elif command grep -qsF 'kubepods' /proc/1/cgroup 2> "/dev/null"; then
	export CONTAINER_RUNTIME="kubernetes"
elif [ -n "${container:-}" ]; then
	export CONTAINER_RUNTIME="${container}"
fi

### --------------------------------
### PROCESS INSPECTOR
### --------------------------------
cprocs() {
	if command -v ps > "/dev/null" 2>&1; then
		command ps aux 2> "/dev/null" || command ps -ef 2> "/dev/null"
	else
		_count="$(command ls /proc/ 2> "/dev/null" | command grep -E '^[0-9]+$' | command wc -l | command tr -d ' ')"
		echo "${_count} processes (ps unavailable)"
	fi
}
