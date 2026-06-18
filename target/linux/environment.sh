### ================================
### SHELL ENVIRONMENT
### ================================

path_front "${HOME}/.local/bin"
path_back  "${HOME}/.cargo/bin"
path_back  "${HOME}/.platformio/penv/bin"
path_dedup

export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"
