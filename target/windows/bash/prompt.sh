### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="MSYS2-$MSYSTEM"

SHELL_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${SHELL_REPO_DIR}/theme/bash.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

command_not_found_handle() {
	local cmd="${1}"
	shift
	for ext in .bat .cmd .exe; do
		if command -v "${cmd}${ext}" &> "/dev/null"; then
			"${cmd}${ext}" "$@"
			return $?
		fi
	done
	echo "bash: ${cmd}: command not found" >&2
	return 127
}

source "${SHELL_REPO_DIR}/target/windows/aliases.sh"

### ================================
### SHELL CONFIGURATION
### ================================
