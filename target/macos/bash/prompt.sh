### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="cyan"
PROMPT_OS_NAME="$(sw_vers -productVersion 2> "/dev/null" || uname -r)"

. "${SHELL_REPO_DIR}/theme/bash.sh"
. "${SHELL_REPO_DIR}/target/macos/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/macos.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/macos.sh"

### ================================
### SHELL CONFIGURATION
### ================================
