### ================================
### CONTAINER CONTEXT NETBSD
### ================================

### --------------------------------
### Process Inspector
### --------------------------------
cprocs() {
	command ps aux 2> "/dev/null" || command ps -ef 2> "/dev/null"
}
