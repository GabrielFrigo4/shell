### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="MSYS2-$MSYSTEM"

source "${SHELL_REPO_DIR}/theme/bash.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

command_not_found_handle() {
	local cmd="${1}"
	shift
	for ext in .bat .cmd .exe; do
		if command -v "${cmd}${ext}" > "/dev/null" 2>&1; then
			"${cmd}${ext}" "$@"
			return $?
		fi
	done
	echo "bash: ${cmd}: command not found" >&2
	return 127
}

source "${SHELL_REPO_DIR}/target/windows/environment.sh"

SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh" ] && \
    source "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/common.sh"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh" ] && \
    source "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh"

### ================================
### SHELL CONFIGURATION
### ================================
