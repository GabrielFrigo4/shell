### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="yellow"
PROMPT_OS_NAME="${_DETECTED_KERNEL_RELEASE:-$(command uname -r 2> "/dev/null" || echo "NetBSD")}"

. "${SHELL_REPO_DIR}/theme/bash.sh"
if [ -z "${_SHELL_TARGET_ENV_LOADED:-}" ] && [ -f "${SHELL_REPO_DIR}/target/netbsd/environment.sh" ]; then
	. "${SHELL_REPO_DIR}/target/netbsd/environment.sh"
fi

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
if [ -z "${_SHELL_CONTEXT_LOADED:-}" ]; then
	[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
		. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
	[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/netbsd.sh" ] && \
		. "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/netbsd.sh"
	_SHELL_CONTEXT_LOADED=1
fi

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR}/target/common/bash/bash.sh" ] && \
	. "${SHELL_REPO_DIR}/target/common/bash/bash.sh"
