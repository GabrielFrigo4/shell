### ================================
### TERMINAL INITIALIZATION
### ================================

. "${SHELL_REPO_DIR}/target/freebsd/sh/terminal.sh"

### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1

[ -f "${SHELL_REPO_DIR}/target/common/sh/sh.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/sh/sh.sh"

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="red"
_os_ver="${_DETECTED_KERNEL_RELEASE:-$(command uname -r 2> "/dev/null" || command freebsd-version 2> "/dev/null" || echo "FreeBSD")}"
PROMPT_OS_NAME="${_os_ver%%-*}"
unset -v _os_ver

case "${PROMPT_OS_NAME}" in
	[0-9].*|1[0-3].*) PROMPT_BUFFER_LIMIT=128 ;;
	*)                PROMPT_BUFFER_LIMIT=192 ;;
esac
export PROMPT_BUFFER_LIMIT

. "${SHELL_REPO_DIR}/theme/sh.sh"
. "${SHELL_REPO_DIR}/target/freebsd/sh/behavior.sh"
if [ -z "${_SHELL_TARGET_ENV_LOADED:-}" ] && [ -f "${SHELL_REPO_DIR}/target/freebsd/environment.sh" ]; then
	. "${SHELL_REPO_DIR}/target/freebsd/environment.sh"
fi

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
if [ -z "${_SHELL_CONTEXT_LOADED:-}" ]; then
	[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
		. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
	[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh" ] && \
		. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/freebsd.sh"
	_SHELL_CONTEXT_LOADED=1
fi
