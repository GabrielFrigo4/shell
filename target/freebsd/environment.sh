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
[ -e "${HOME}/:0" ] && rm -f "${HOME}/:0" 2> "/dev/null"

### --------------------------------
### FreeBSD Compat Layer
### --------------------------------
[ -f "${SHELL_REPO_DIR}/target/freebsd/compat.sh" ] && . "${SHELL_REPO_DIR}/target/freebsd/compat.sh"

### --------------------------------
### Bhyve Linux Runtime
### --------------------------------
[ -f "${SHELL_REPO_DIR}/target/freebsd/bhyve.sh" ] && . "${SHELL_REPO_DIR}/target/freebsd/bhyve.sh"
