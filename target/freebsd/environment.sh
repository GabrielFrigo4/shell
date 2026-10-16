### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "${HOME}/.local/bin"
path-front "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### Housekeeping
### --------------------------------
for _sock in 0 1 2 3 4 5 6 7 8 9; do
	[ -e "${HOME}/:${_sock}" ] && rm -f "${HOME}/:${_sock}" 2> "/dev/null"
done
unset -v _sock

### --------------------------------
### FreeBSD Compat Layer
### --------------------------------
[ -f "${SHELL_REPO_DIR}/target/freebsd/compat.sh" ] && . "${SHELL_REPO_DIR}/target/freebsd/compat.sh"

### --------------------------------
### Bhyve Linux Runtime
### --------------------------------
[ -f "${SHELL_REPO_DIR}/target/freebsd/bhyve.sh" ] && . "${SHELL_REPO_DIR}/target/freebsd/bhyve.sh"

### --------------------------------
### ZFS Diagnostics
### --------------------------------
alias zarcstat="arcstat"
alias arcstats="arcstat"
