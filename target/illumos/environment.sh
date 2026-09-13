### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "/usr/gnu/bin"
path-front "/opt/local/bin"
path-front "/opt/local/sbin"
path-front "/usr/bin"
path-front "/usr/sbin"
path-front "${HOME}/.local/bin"
path-back "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### illumos Environment
### --------------------------------
export PAGER="${PAGER:-less}"
export MANPATH="/usr/gnu/share/man:/usr/share/man:${MANPATH:-}"
