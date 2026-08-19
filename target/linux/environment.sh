### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path_front "${HOME}/.local/bin"
path_back  "${HOME}/.cargo/bin"
path_back  "${HOME}/.platformio/penv/bin"
path_dedup

### --------------------------------
### Variables
### --------------------------------
export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

### --------------------------------
### Commands
### --------------------------------
command -v incus > "/dev/null" 2>&1 && alias incus="LC_ALL=C incus"
