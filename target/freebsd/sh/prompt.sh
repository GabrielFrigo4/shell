### ================================
### TERMINAL INITIALIZATION
### ================================

. "${SHELL_REPO_DIR}/target/freebsd/sh/terminal.sh"

### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

[ -f "${SHELL_REPO_DIR}/target/common/sh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/sh.sh"

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="red"
PROMPT_OS_NAME="$(command freebsd-version 2> "/dev/null" | command cut -d- -f1)"
[ -z "${PROMPT_OS_NAME}" ] && PROMPT_OS_NAME="15.1"

. "${SHELL_REPO_DIR}/theme/sh.sh"
. "${SHELL_REPO_DIR}/target/freebsd/sh/behavior.sh"
. "${SHELL_REPO_DIR}/target/freebsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"
