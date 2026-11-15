### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### PATH
### --------------------------------
path-front "/usr/X11R6/bin"
path-front "/usr/local/bin"
path-front "/usr/local/sbin"
path-front "${HOME}/.local/bin"
path-back "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### HOUSEKEEPING
### --------------------------------
for _sock in 0 1 2 3 4 5 6 7 8 9; do
	[ -e "${HOME}/:${_sock}" ] && rm -f "${HOME}/:${_sock}" 2> "/dev/null"
done
unset -v _sock

### --------------------------------
### OPENBSD VARIABLES
### --------------------------------
if [ ! -s "/etc/installurl" ] && [ -z "${PKG_PATH:-}" ]; then
	export PKG_PATH="https://cdn.openbsd.org/pub/OpenBSD/$(uname -r 2> "/dev/null")/packages/$(uname -m 2> "/dev/null")/"
fi
