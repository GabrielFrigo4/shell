### ================================
### CONTAINER CONTEXT OPENBSD
### ================================

### --------------------------------
### Sandbox & Chroot Detection
### --------------------------------
if [ ! -f /bsd ]; then
	export CONTAINER_RUNTIME="chroot"
else
	export CONTAINER_RUNTIME="sandbox"
fi

### --------------------------------
### Process Inspector
### --------------------------------
cprocs() {
	command ps aux 2> "/dev/null" || command ps -ef 2> "/dev/null"
}
