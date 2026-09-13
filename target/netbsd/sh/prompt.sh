### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON="󰈺 "
PROMPT_OS_COLOR="yellow"
PROMPT_OS_NAME="$(command uname -r 2> "/dev/null" || echo "NetBSD")"

. "${SHELL_REPO_DIR}/theme/sh.sh"
. "${SHELL_REPO_DIR}/target/netbsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/netbsd.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/netbsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/sh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/sh.sh"
