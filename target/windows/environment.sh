### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### PATH
### --------------------------------
path-front "/usr/bin"
[ -n "${MINGW_PREFIX}" ] && path-front "${MINGW_PREFIX}/bin"
path-front "${HOME}/.local/bin"
path-back "$(cygpath -u "${LOCALAPPDATA}")/Coursier/data/bin"
path-dedup

### --------------------------------
### VARIABLES
### --------------------------------
export CYG_SYS_BASHRC="1"
_win_inc="$(cygpath -m /usr/local/include)"
export C_INCLUDE_PATH="${_win_inc}"
export CPLUS_INCLUDE_PATH="${_win_inc}"
unset -v _win_inc
export LIBRARY_PATH="$(cygpath -m /usr/local/lib)"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig"
_SHELL_TARGET_ENV_LOADED=1
