### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "/usr/local/bin"
path-front "/usr/local/sbin"
path-front "/usr/X11R6/bin"
path-front "${HOME}/.local/bin"
path-back "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### OpenBSD Variables
### --------------------------------
export PKG_PATH="${PKG_PATH:-https://cdn.openbsd.org/pub/OpenBSD/$(uname -r 2> "/dev/null")/packages/$(uname -m 2> "/dev/null")/}"
