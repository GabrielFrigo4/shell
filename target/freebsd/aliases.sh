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
