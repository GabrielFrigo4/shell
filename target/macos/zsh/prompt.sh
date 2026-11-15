### ================================
### SHELL APPEARANCE
### ================================

unset PROMPT_OS_ICON PROMPT_OS_COLOR PROMPT_OS_NAME
PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="cyan"
PROMPT_OS_NAME="${_DETECTED_DISTRO_VERSION:-$(command sw_vers -productVersion 2> "/dev/null" || command uname -r)}"

[ -f "${SHELL_REPO_DIR:-}/theme/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/theme/zsh.sh"
if [ -z "${_SHELL_TARGET_ENV_LOADED:-}" ] && [ -f "${SHELL_REPO_DIR:-}/target/macos/environment.sh" ]; then
	. "${SHELL_REPO_DIR:-}/target/macos/environment.sh"
fi

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
if [ -z "${_SHELL_CONTEXT_LOADED:-}" ]; then
	[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh" ] && \
		. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh"
	[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/macos.sh" ] && \
		. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/macos.sh"
	_SHELL_CONTEXT_LOADED=1
fi

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh"
