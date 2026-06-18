### ================================
### FreeBSD sh - Entry Point
### ================================

SHELL_REPO_DIR="/usr/local/share/shell"

. "${SHELL_REPO_DIR}/target/freebsd/sh/terminal.sh"

### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

. "${SHELL_REPO_DIR}/core/functions.sh"
. "${SHELL_REPO_DIR}/core/environment.sh"
. "${SHELL_REPO_DIR}/core/vault.sh"
. "${SHELL_REPO_DIR}/target/freebsd/sh/triggers.sh"
. "${SHELL_REPO_DIR}/target/freebsd/sh/appearance.sh"
. "${SHELL_REPO_DIR}/target/freebsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================
