### ================================
### SHELL APPEARANCE
### ================================

unset PROMPT_OS_ICON PROMPT_OS_COLOR PROMPT_OS_NAME
PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="cyan"
PROMPT_OS_NAME="${_DETECTED_DISTRO_VERSION:-$(command sw_vers -productVersion 2> "/dev/null" || command uname -r)}"

[ -f "${SHELL_REPO_DIR:-}/theme/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/theme/zsh.sh"
[ -f "${SHELL_REPO_DIR:-}/target/macos/environment.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/macos/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/macos.sh" ] && \
	. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/macos.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh"
