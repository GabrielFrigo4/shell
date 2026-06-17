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

### ================================
### SHELL ENVIRONMENT
### ================================

path_front "${HOME}/.local/bin"
path_front "${HOME}/.cargo/bin"
export PATH=$(printf "%s" "${PATH}" | awk -v RS=: -v ORS=: '!a[$(0)]++' | sed 's/:$//')

export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

### ================================
### SHELL ALIAS
### ================================

### --------------------------------
### Commands
### --------------------------------
alias clear="printf \"\e[H\e[2J\e[3J\""
### --------------------------------
### Software
### --------------------------------
alias code="vscode"
### --------------------------------
### Packages
### --------------------------------
alias uppkg="sudo pkg update && sudo pkg upgrade --yes"
alias upall="uppkg"
### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="emacs --daemon"
alias er="ek && es"
alias ec="emacsclient --create-frame --alternate-editor \"\""
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . &> \"/dev/null\" &"
### --------------------------------
### Editors
### --------------------------------
alias ok="nohup kate . &> \"/dev/null\" &"
alias oc="code ."
alias on="nvim ."
alias ov="vim ."

### ================================
### SHELL CONFIGURATION
### ================================
