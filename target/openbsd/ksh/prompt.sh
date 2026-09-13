### ================================
### TERMINAL INITIALIZATION
### ================================

. "${SHELL_REPO_DIR}/target/openbsd/ksh/terminal.sh"

### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
for _trash in "${HOME}"/:\*; do
	[ -e "${_trash}" ] && rm -f "${_trash}"
done

[ -f "${SHELL_REPO_DIR}/target/common/ksh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/ksh.sh"

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON="🐡 "
PROMPT_OS_COLOR="yellow"
PROMPT_OS_NAME="OpenBSD"

. "${SHELL_REPO_DIR}/theme/ksh.sh"
. "${SHELL_REPO_DIR}/target/openbsd/ksh/behavior.sh"
. "${SHELL_REPO_DIR}/target/openbsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/openbsd.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/openbsd.sh"
