### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="yellow"
PROMPT_OS_NAME="$(command uname -r 2> "/dev/null" || echo "OpenBSD")"

. "${SHELL_REPO_DIR}/theme/zsh.sh"
. "${SHELL_REPO_DIR}/target/openbsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/openbsd.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/openbsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/zsh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/zsh.sh"
