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
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=50000
HISTFILESIZE=100000

shopt -s histappend
shopt -s checkwinsize
shopt -s cmdhist

case "${PROMPT_COMMAND:-}" in
	*"history -a"*) ;;
	*) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; }${PROMPT_COMMAND:-}" ;;
esac

### --------------------------------
### Interaction & Safety
### --------------------------------
set -o noclobber

### --------------------------------
### Keybindings & Line Editing
### --------------------------------
if case "$-" in *i*) true;; *) false;; esac; then
	bind 'set show-all-if-ambiguous on' 2> "/dev/null" || true
	bind 'set completion-ignore-case on' 2> "/dev/null" || true
	bind 'set completion-prefix-display-length 2' 2> "/dev/null" || true
	bind 'set colored-stats on' 2> "/dev/null" || true
	bind 'set colored-completion-prefix on' 2> "/dev/null" || true
	bind 'set mark-symlinked-directories on' 2> "/dev/null" || true
	bind '"\e[Z": menu-complete-backward' 2> "/dev/null" || true

	bind '"\e[A": history-search-backward' 2> "/dev/null" || true
	bind '"\e[B": history-search-forward' 2> "/dev/null" || true
	bind '"\eOA": history-search-backward' 2> "/dev/null" || true
	bind '"\eOB": history-search-forward' 2> "/dev/null" || true
	bind '"\e[5~": history-search-backward' 2> "/dev/null" || true
	bind '"\e[6~": history-search-forward' 2> "/dev/null" || true

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
	bind '"\e[1;3C": forward-word' 2> "/dev/null" || true
	bind '"\e[1;3D": backward-word' 2> "/dev/null" || true
	bind '"\e[5C": forward-word' 2> "/dev/null" || true
	bind '"\e[5D": backward-word' 2> "/dev/null" || true
	bind '"\e\e[C": forward-word' 2> "/dev/null" || true
	bind '"\e\e[D": backward-word' 2> "/dev/null" || true

	bind '"\e[3;5~": kill-word' 2> "/dev/null" || true
	bind '"\e\C-?": backward-kill-word' 2> "/dev/null" || true
	bind '"\e\C-h": backward-kill-word' 2> "/dev/null" || true

	bind '"\e[1;2A": history-search-backward' 2> "/dev/null" || true
	bind '"\e[1;2B": history-search-forward' 2> "/dev/null" || true
	bind '"\e[1;2C": forward-word' 2> "/dev/null" || true
	bind '"\e[1;2D": backward-word' 2> "/dev/null" || true
	bind '"\e[a": history-search-backward' 2> "/dev/null" || true
	bind '"\e[b": history-search-forward' 2> "/dev/null" || true
	bind '"\e[c": forward-word' 2> "/dev/null" || true
	bind '"\e[d": backward-word' 2> "/dev/null" || true

	bind '"\e[[A": ""' 2> "/dev/null" || true
	bind '"\e[[B": ""' 2> "/dev/null" || true
	bind '"\e[[C": ""' 2> "/dev/null" || true
	bind '"\e[[D": ""' 2> "/dev/null" || true

	bind '"\eOp": "0"' 2> "/dev/null" || true
	bind '"\eOq": "1"' 2> "/dev/null" || true
	bind '"\eOr": "2"' 2> "/dev/null" || true
	bind '"\eOs": "3"' 2> "/dev/null" || true
	bind '"\eOt": "4"' 2> "/dev/null" || true
	bind '"\eOu": "5"' 2> "/dev/null" || true
	bind '"\eOv": "6"' 2> "/dev/null" || true
	bind '"\eOw": "7"' 2> "/dev/null" || true
	bind '"\eOx": "8"' 2> "/dev/null" || true
	bind '"\eOy": "9"' 2> "/dev/null" || true
	bind '"\eOn": "."' 2> "/dev/null" || true
	bind '"\eOM": accept-line' 2> "/dev/null" || true
	bind '"\eOj": "*"' 2> "/dev/null" || true
	bind '"\eOk": "+"' 2> "/dev/null" || true
	bind '"\eOl": ","' 2> "/dev/null" || true
	bind '"\eOm": "-"' 2> "/dev/null" || true
	bind '"\eOo": "/"' 2> "/dev/null" || true
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
