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
### System Completions (Lazy Load)
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
