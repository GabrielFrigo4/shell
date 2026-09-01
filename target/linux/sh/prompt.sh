### ================================
### SHELL INITIALIZATION
### ================================

. "${SHELL_REPO_DIR}/theme/sh.sh"
. "${SHELL_REPO_DIR}/target/linux/sh/behavior.sh"
. "${SHELL_REPO_DIR}/target/linux/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/linux.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/linux.sh"

### ================================
### SHELL CONFIGURATION
### ================================
