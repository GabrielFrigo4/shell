### ================================
### SHELL APPEARANCE
### ================================

unset PROMPT_OS_ICON PROMPT_OS_COLOR PROMPT_OS_NAME
PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="${MSYSTEM:-MSYS2}"

[ -f "${SHELL_REPO_DIR:-}/theme/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/theme/zsh.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

command_not_found_handler() {
	local _command_name="${1:-}"
	local _extension=""
	[ -n "${_command_name}" ] || return 127
	[ "$#" -ge 1 ] && shift 1
	for _extension in .bat .cmd .exe; do
		if (( $+commands[${_command_name}${_extension}] )); then
			"${_command_name}${_extension}" "$@"
			return "$?"
		fi
	done
	echo "zsh: ${_command_name}: command not found" >&2
	return 127
}

[ -f "${SHELL_REPO_DIR:-}/target/windows/environment.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/windows/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh" ] && \
	. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/windows.sh" ] && \
	. "${SHELL_REPO_DIR:-}/context/${SHELL_CONTEXT}/windows.sh"

### ================================
### SHELL CONFIGURATION
### ================================

[ -f "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh" ] && \
	. "${SHELL_REPO_DIR:-}/target/common/zsh/zsh.sh"
