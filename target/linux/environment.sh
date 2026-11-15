### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### PATH
### --------------------------------
path-front "${HOME}/.cargo/bin"
path-front "${HOME}/.local/bin"
path-back  "${HOME}/.platformio/penv/bin"
path-dedup


### --------------------------------
### COMMANDS
### --------------------------------
command -v incus > "/dev/null" 2>&1 && alias incus="LC_ALL=C incus"
_SHELL_TARGET_ENV_LOADED=1
