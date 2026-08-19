### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path_front "${HOME}/.local/bin"
path_front "${HOME}/.cargo/bin"
path_dedup

### --------------------------------
### Variables
### --------------------------------
export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

### --------------------------------
### Commands
### --------------------------------
alias clear="echo -n $'\e[2J\e[3J\e[H'"
