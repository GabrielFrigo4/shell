### ================================
### SHELL ENVIRONMENT
### ================================

path_front "${HOME}/.local/bin"
path_front "${HOME}/.cargo/bin"
path_dedup

export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

### ================================
### SHELL ALIAS
### ================================

### --------------------------------
### Commands
### --------------------------------
alias clear="printf \"\e[H\e[2J\e[3J\""
