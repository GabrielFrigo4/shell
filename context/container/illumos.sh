### ================================
### CONTAINER CONTEXT ILLUMOS
### ================================

### --------------------------------
### Zone Detection
### --------------------------------
if command -v zonename > "/dev/null" 2>&1; then
	_zone_name="$(command zonename 2> "/dev/null")"
	if [ -n "${_zone_name}" ] && [ "${_zone_name}" != "global" ]; then
		export CONTAINER_RUNTIME="zone"
	fi
	unset _zone_name
fi

### --------------------------------
### Zone Identity
### --------------------------------
zid() {
	command zonename 2> "/dev/null" || echo "unknown"
}

### --------------------------------
### Process Inspector
### --------------------------------
cprocs() {
	command ps -ef 2> "/dev/null" || command ps aux 2> "/dev/null"
}
