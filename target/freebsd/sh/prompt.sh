### ================================
### TERMINAL INITIALIZATION
### ================================

. "${SHELL_REPO_DIR}/target/freebsd/sh/terminal.sh"

### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

. "${SHELL_REPO_DIR}/target/freebsd/sh/appearance.sh"
. "${SHELL_REPO_DIR}/target/freebsd/sh/triggers.sh"
. "${SHELL_REPO_DIR}/target/freebsd/sh/behavior.sh"
. "${SHELL_REPO_DIR}/target/freebsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================
