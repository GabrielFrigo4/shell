### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "/opt/homebrew/bin"
path-front "/opt/homebrew/sbin"
path-front "/usr/local/bin"
path-front "/usr/local/sbin"
path-front "${HOME}/.local/bin"
path-back  "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### Variables
### --------------------------------
export HOMEBREW_NO_ANALYTICS=1
export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"
