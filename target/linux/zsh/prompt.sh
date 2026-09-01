### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="$(uname -r)"

. "${SHELL_REPO_DIR}/theme/zsh.sh"
. "${SHELL_REPO_DIR}/target/linux/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/linux.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/linux.sh"

### ================================
### SHELL CONFIGURATION
### ================================
