### ================================
### SHELL APPEARANCE
### ================================

unset PROMPT_OS_ICON PROMPT_OS_COLOR PROMPT_OS_NAME
PROMPT_OS_ICON="${_DETECTED_DISTRO_ICON:-$(command -v _detect_distro_icon > "/dev/null" 2>&1 && _detect_distro_icon)}"
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="${_DETECTED_DISTRO_VERSION:-$(command -v _detect_distro_version > "/dev/null" 2>&1 && _detect_distro_version)}"

[ -f "${SHELL_REPO_DIR:-}/theme/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/theme/zsh.sh"
[ -f "${SHELL_REPO_DIR:-}/target/linux/environment.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/linux/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/linux.sh" ] && \
	. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/linux.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh"
