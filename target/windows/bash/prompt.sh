### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="MSYS2-$MSYSTEM"

. "${SHELL_REPO_DIR}/theme/bash.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

command_not_found_handle() {
	local _cmd="${1}"
	local _ext
	shift
	for _ext in .bat .cmd .exe; do
		if command -v "${_cmd}${_ext}" > "/dev/null" 2>&1; then
			"${_cmd}${_ext}" "$@"
			return $?
		fi
	done
	echo "bash: ${_cmd}: command not found" >&2
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
