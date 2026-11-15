### ================================
### CONTAINER CONTEXT COMMON
### ================================

### --------------------------------
### CONTAINER IDENTITY
### --------------------------------
cid() {
	command hostname 2> "/dev/null" || command cat "/etc/hostname" 2> "/dev/null" || echo "unknown"
}

cip() {
	local _ip_address=""
	if command -v hostname > "/dev/null" 2>&1; then
		_ip_address="$(command hostname -I 2> "/dev/null" | command awk 'NF {print $1; exit}')"
		[ -z "${_ip_address}" ] && _ip_address="$(command hostname -i 2> "/dev/null" | command awk 'NF {print $1; exit}')"
	fi
	if [ -z "${_ip_address}" ] && command -v ip > "/dev/null" 2>&1; then
		_ip_address="$(command ip -4 -o addr show scope global 2> "/dev/null" | command awk '{sub(/\/.*/, "", $4); print $4; exit}')"
	fi
	if [ -z "${_ip_address}" ] && command -v ifconfig > "/dev/null" 2>&1; then
		_ip_address="$(command ifconfig 2> "/dev/null" | command awk '/inet / && !/127\.0\.0\.1/ {sub(/^addr:/, "", $2); print $2; exit}')"
	fi
	printf '%s\n' "${_ip_address:-unknown}"
}

cuptime() {
	command uptime 2> "/dev/null" || echo "uptime unavailable"
}

cenv() {
	env | command sort
}

### --------------------------------
### CONTAINER RUNTIME DETECTION
### --------------------------------
chost() {
	if [ -f "/run/host/container-manager" ]; then
		command cat "/run/host/container-manager"
	elif [ -f "/.dockerenv" ]; then
		echo "docker"
	elif command grep -qsF 'kubepods' "/proc/1/cgroup" 2> "/dev/null"; then
		echo "kubernetes"
	elif command grep -qsF 'docker' "/proc/1/cgroup" 2> "/dev/null"; then
		echo "docker"
	elif [ -n "${CONTAINER_RUNTIME:-}" ]; then
		echo "${CONTAINER_RUNTIME}"
	elif command -v zonename > "/dev/null" 2>&1 && [ "$(command zonename 2> "/dev/null")" != "global" ]; then
		echo "zone"
	elif [ "$(command sysctl -n security.jail.jailed 2> "/dev/null")" = "1" ]; then
		echo "jail"
	elif [ -n "${container:-}" ]; then
		echo "${container}"
	else
		echo "unknown"
	fi
}

### --------------------------------
### PYTHON EPHEMERAL POLICY
### --------------------------------
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"
