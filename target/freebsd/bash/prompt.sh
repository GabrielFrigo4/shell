### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="red"
PROMPT_OS_NAME="$(freebsd-version)"

SHELL_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${SHELL_REPO_DIR}/theme/bash.sh"
source "${SHELL_REPO_DIR}/target/freebsd/aliases.sh"

### ================================
### SHELL CONFIGURATION
### ================================
