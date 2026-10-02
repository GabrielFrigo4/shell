### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "${HOME}/.local/bin"
path-front "${HOME}/.cargo/bin"
path-back  "${HOME}/.platformio/penv/bin"
path-dedup


### --------------------------------
### Commands
### --------------------------------
command -v incus > "/dev/null" 2>&1 && alias incus="LC_ALL=C incus"
