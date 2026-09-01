### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "${HOME}/.local/bin"
path-front "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### Variables
### --------------------------------
export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

### --------------------------------
### Commands
### --------------------------------
alias clear="echo -n $'\e[2J\e[3J\e[H'"
