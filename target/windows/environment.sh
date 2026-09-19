### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### Path
### --------------------------------
path-front "/usr/bin"
[ -n "${MINGW_PREFIX}" ] && path-front "${MINGW_PREFIX}/bin"
path-front "${HOME}/.local/bin"
path-back "$(cygpath -u "${LOCALAPPDATA}")/Coursier/data/bin"
path-dedup

### --------------------------------
### Variables
### --------------------------------
export CYG_SYS_BASHRC="1"
export C_INCLUDE_PATH="$(cygpath -m /usr/local/include)"
export CPLUS_INCLUDE_PATH="$(cygpath -m /usr/local/include)"
export LIBRARY_PATH="$(cygpath -m /usr/local/lib)"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig"
