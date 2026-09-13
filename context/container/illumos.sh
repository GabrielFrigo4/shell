### ================================
### CONTAINER CONTEXT ILLUMOS
### ================================

### --------------------------------
### Zone Detection
### --------------------------------
if command -v zonename > "/dev/null" 2>&1; then
	_z="$(command zonename 2> "/dev/null")"
	if [ -n "${_z}" ] && [ "${_z}" != "global" ]; then
		export CONTAINER_RUNTIME="zone"
	fi
	unset _z
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
