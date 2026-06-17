### ================================
### SHELL ENVIRONMENT
### ================================

path_front "${HOME}/.local/bin"
path_back "$(cygpath -u "$LOCALAPPDATA")/Coursier/data/bin"
export PATH=$(printf "%s" "${PATH}" | awk -v RS=: -v ORS=: '!a[$(0)]++' | sed 's/:$//')

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

### ================================
### SHELL ALIAS
### ================================

### --------------------------------
### Software
### --------------------------------
alias wh="which"
alias brw="lynx -use_mouse=on -nobrowse=on -nopause=on -show_cursor=off"
### --------------------------------
### Manual
### --------------------------------
alias wman="win-man"
alias uman="unix-man"
alias mandoc="unix-man"
### --------------------------------
### Management
### --------------------------------
alias upsys="pacman --noconfirm -Syu"
alias upall="upsys"
alias pac="pacman"
alias pacs="pacman -Ss"
alias paci="pacman -S"
alias pacr="pacman -Rcns"
alias pacu="pacman -Syu"
### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="runemacs --fg-daemon"
alias er="ek && es"
alias ec="emacsclientw --create-frame --alternate-editor \"\""
alias oe="emacsclientw --create-frame --alternate-editor \"\" ."
### --------------------------------
### Code Editors
### --------------------------------
alias on="nvim ."
alias ov="vim ."
