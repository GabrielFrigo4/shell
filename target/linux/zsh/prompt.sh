### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="$(uname -r)"

SHELL_REPO_DIR="${${(%):-%x}:A:h:h:h:h}"
source "${SHELL_REPO_DIR}/theme/zsh.sh"
source "${SHELL_REPO_DIR}/target/linux/aliases.sh"

### ================================
### SHELL CONFIGURATION
### ================================
