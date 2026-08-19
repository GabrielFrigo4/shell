### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="red"
PROMPT_OS_NAME="$(freebsd-version)"

source "${SHELL_REPO_DIR}/theme/bash.sh"
source "${SHELL_REPO_DIR}/target/freebsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    source "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
    source "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================
