### ================================
### CONTAINER CONTEXT COMMON
### ================================

### --------------------------------
### Container Identity
### --------------------------------
cid() {
	command hostname 2> "/dev/null" || command cat /etc/hostname 2> "/dev/null" || echo "unknown"
}

cip() {
	command hostname -I 2> "/dev/null" | command awk '{print $1}' && return 0
	command hostname -i 2> "/dev/null" | command awk '{print $1}' && return 0
	command ifconfig 2> "/dev/null" | command awk '/inet / && !/127.0.0.1/ {print $2; exit}' && return 0
	echo "unknown"
}

cuptime() {
	command uptime 2> "/dev/null" || echo "uptime unavailable"
}

cenv() {
	env | command sort
}

### --------------------------------
### Container Runtime Detection
### --------------------------------
chost() {
	if [ -f /run/host/container-manager ]; then
		command cat /run/host/container-manager
	elif [ -f /.dockerenv ]; then
		echo "docker"
	elif command grep -qsF 'kubepods' /proc/1/cgroup 2> "/dev/null"; then
		echo "kubernetes"
	elif command grep -qsF 'docker' /proc/1/cgroup 2> "/dev/null"; then
		echo "docker"
	elif [ -n "${CONTAINER_RUNTIME:-}" ]; then
		echo "${CONTAINER_RUNTIME}"
	elif command -v zonename > "/dev/null" 2>&1 && [ "$(command zonename 2> "/dev/null")" != "global" ]; then
		echo "zone"
	elif command sysctl -n security.jail.jailed 2> "/dev/null" | command grep -qF '1'; then
		echo "jail"
	elif [ -n "${container:-}" ]; then
		echo "${container}"
	else
		echo "unknown"
	fi
}
