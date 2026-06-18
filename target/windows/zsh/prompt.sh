### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="MSYS2-$MSYSTEM"

SHELL_REPO_DIR="${${(%):-%x}:A:h:h:h:h}"
source "${SHELL_REPO_DIR}/theme/zsh.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

command_not_found_handler() {
	local cmd="${1}"
	shift
	for ext in .bat .cmd .exe; do
		if (( $+commands[${cmd}${ext}] )); then
			"${cmd}${ext}" "$@"
			return $?
		fi
	done
	echo "zsh: ${cmd}: command not found" >&2
	return 127
}

source "${SHELL_REPO_DIR}/target/windows/aliases.sh"

### Context (desktop/server)
SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
[ -f "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh" ] && \
    source "${SHELL_REPO_DIR}/context/${SHELL_CONTEXT}/windows.sh"

### ================================
### SHELL CONFIGURATION
### ================================
