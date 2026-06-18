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

### ================================
### WINDOWS FUNCTIONS
### ================================

### --------------------------------
### Manual
### --------------------------------
win-man() {
	start "https://learn.microsoft.com/en-us/search/?terms=${1}"
}

### ================================
### UNIX FUNCTIONS
### ================================

### --------------------------------
### Manual
### --------------------------------
unix-man() {
	section="${1}"
	command="${2}"
	number="$section"

	if [[ ! "$section" =~ [0-9]$ ]]; then
		number="${section%?}"
	fi

	w3m "https://www.man7.org/linux/man-pages/man$number/$command.$section.html"
}
