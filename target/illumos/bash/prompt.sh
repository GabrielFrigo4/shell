### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON="󰖨 "
PROMPT_OS_COLOR="yellow"
PROMPT_OS_NAME="$(command uname -v 2> "/dev/null" || command uname -r 2> "/dev/null" || echo "illumos")"
PROMPT_OS_NAME="${PROMPT_OS_NAME%%_*}"

. "${SHELL_REPO_DIR}/theme/bash.sh"
. "${SHELL_REPO_DIR}/target/illumos/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/illumos.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/illumos.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/bash.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/bash.sh"
