### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="MSYS2-$MSYSTEM"

. "${SHELL_REPO_DIR}/theme/zsh.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

command_not_found_handler() {
	local _cmd="${1}"
	local _ext
	shift
	for _ext in .bat .cmd .exe; do
		if (( $+commands[${_cmd}${_ext}] )); then
			"${_cmd}${_ext}" "$@"
			return $?
		fi
	done
	echo "zsh: ${_cmd}: command not found" >&2
	return 127
}

. "${SHELL_REPO_DIR}/target/windows/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh" ] && \
    . "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh"

### ================================
### SHELL CONFIGURATION
### ================================
