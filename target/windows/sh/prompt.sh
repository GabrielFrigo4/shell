### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="MSYS2-${MSYSTEM:-UCRT64}"

. "${SHELL_REPO_DIR}/theme/sh.sh"
. "${SHELL_REPO_DIR}/target/windows/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/sh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/sh.sh"
