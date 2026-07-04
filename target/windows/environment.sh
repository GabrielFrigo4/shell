### ================================
### SHELL ENVIRONMENT
### ================================

path_front "${HOME}/.local/bin"
path_back "$(cygpath -u "$LOCALAPPDATA")/Coursier/data/bin"
path_dedup

export C_INCLUDE_PATH="$(cygpath -m /usr/local/include)"
export CPLUS_INCLUDE_PATH="$(cygpath -m /usr/local/include)"
export LIBRARY_PATH="$(cygpath -m /usr/local/lib)"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig"
