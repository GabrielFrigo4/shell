### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
for _trash in "${HOME}"/:\*; do
	[ -e "${_trash}" ] && rm -f "${_trash}"
done

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="red"
PROMPT_OS_NAME="${_DETECTED_KERNEL_RELEASE:-$(command freebsd-version 2> "/dev/null" || command uname -r 2> "/dev/null" || echo "FreeBSD")}"

. "${SHELL_REPO_DIR}/theme/bash.sh"
. "${SHELL_REPO_DIR}/target/freebsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/bash.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/bash.sh"
