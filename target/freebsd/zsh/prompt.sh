### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="red"
_os_ver="${_DETECTED_KERNEL_RELEASE:-$(command uname -r 2> "/dev/null" || command freebsd-version 2> "/dev/null" || echo "FreeBSD")}"
PROMPT_OS_NAME="${_os_ver%%-*}"
unset -v _os_ver

. "${SHELL_REPO_DIR}/theme/zsh.sh"
. "${SHELL_REPO_DIR}/target/freebsd/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
	. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/zsh/zsh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/zsh/zsh.sh"
