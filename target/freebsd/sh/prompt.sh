### ================================
### FreeBSD sh - Entry Point
### ================================

SHELL_REPO_DIR="/usr/local/share/shell"

### Terminal Environment (tty detection, exec to zsh)
. "${SHELL_REPO_DIR}/target/freebsd/sh/terminal.sh"

### Shell Initialization
export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

### Core Functions (path_front, path_back, path_dedup)
. "${SHELL_REPO_DIR}/core/functions.sh"

### Core Environment
. "${SHELL_REPO_DIR}/core/environment.sh"

### Core Vault
. "${SHELL_REPO_DIR}/core/vault.sh"

### Triggers (auto-refresh prompt)
. "${SHELL_REPO_DIR}/target/freebsd/sh/triggers.sh"

### Appearance (prompt, git_branch, colors)
. "${SHELL_REPO_DIR}/target/freebsd/sh/appearance.sh"

### OS Aliases (common)
. "${SHELL_REPO_DIR}/target/freebsd/aliases.sh"

### Context (desktop/server)
SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================
