### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="$(uname -r)"

SHELL_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${SHELL_REPO_DIR}/theme/bash.sh"
source "${SHELL_REPO_DIR}/target/linux/aliases.sh"

### ================================
### SHELL CONFIGURATION
### ================================
