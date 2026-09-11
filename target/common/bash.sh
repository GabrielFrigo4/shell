### ================================
### BASH CONFIGURATION
### ================================

### --------------------------------
### Compatibility & Parsing
### --------------------------------
unset IFS

### --------------------------------
### Shell Options & History
### --------------------------------
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

shopt -s histappend
shopt -s checkwinsize

### --------------------------------
### Interaction & Safety
### --------------------------------
set -o noclobber

### --------------------------------
### Keybindings & Line Editing
### --------------------------------
if case "$-" in *i*) true;; *) false;; esac; then
	bind '"\e[A": history-search-backward' 2> "/dev/null" || true
	bind '"\e[B": history-search-forward' 2> "/dev/null" || true
	bind '"\eOA": history-search-backward' 2> "/dev/null" || true
	bind '"\eOB": history-search-forward' 2> "/dev/null" || true

	bind '"\e[H": beginning-of-line' 2> "/dev/null" || true
	bind '"\eOH": beginning-of-line' 2> "/dev/null" || true
	bind '"\e[1~": beginning-of-line' 2> "/dev/null" || true
	bind '"\e[7~": beginning-of-line' 2> "/dev/null" || true

	bind '"\e[F": end-of-line' 2> "/dev/null" || true
	bind '"\eOF": end-of-line' 2> "/dev/null" || true
	bind '"\e[4~": end-of-line' 2> "/dev/null" || true
	bind '"\e[8~": end-of-line' 2> "/dev/null" || true

	bind '"\e[3~": delete-char' 2> "/dev/null" || true

	bind '"\e[1;5C": forward-word' 2> "/dev/null" || true
	bind '"\e[1;5D": backward-word' 2> "/dev/null" || true
	bind '"\e[5C": forward-word' 2> "/dev/null" || true
	bind '"\e[5D": backward-word' 2> "/dev/null" || true
	bind '"\e\e[C": forward-word' 2> "/dev/null" || true
	bind '"\e\e[D": backward-word' 2> "/dev/null" || true

	bind '"\e[3;5~": kill-word' 2> "/dev/null" || true
fi

### --------------------------------
### Navigation
### --------------------------------
shopt -s autocd 2> "/dev/null" || true
shopt -s cdspell 2> "/dev/null" || true
shopt -s dirspell 2> "/dev/null" || true

### --------------------------------
### Globbing
### --------------------------------
shopt -s globstar 2> "/dev/null" || true
shopt -s extglob  2> "/dev/null" || true

### --------------------------------
### System Completions
### --------------------------------
if ! shopt -oq posix; then
	if ! declare -F _init_completion > "/dev/null" 2>&1; then
		_load_bash_completion() {
			complete -r -D 2> "/dev/null" || true
			if [ -f "/usr/share/bash-completion/bash_completion" ]; then
				. "/usr/share/bash-completion/bash_completion"
			elif [ -f "/etc/bash_completion" ]; then
				. "/etc/bash_completion"
			fi
			return 124
		}
		complete -D -F _load_bash_completion 2> "/dev/null" || true
	fi
fi
