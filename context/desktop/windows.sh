### ================================
### DESKTOP CONTEXT WINDOWS
### ================================

### --------------------------------
### Emacs
### --------------------------------
emacs-kill() {
	command -v runemacs > "/dev/null" 2>&1 || command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	pkill emacs
}
emacs-start() {
	command -v runemacs > "/dev/null" 2>&1 || { _ui_err "runemacs not found."; return 127; }
	runemacs --fg-daemon
}
emacs-restart() {
	emacs-kill && emacs-start
}
emacs-client() {
	command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacsclientw not found."; return 127; }
	emacsclientw --create-frame --alternate-editor "" "$@"
}
emacs-nw() {
	if command -v emacsclient > "/dev/null" 2>&1; then
		if [ "$#" -eq 0 ]; then
			command emacsclient -t --alternate-editor "" .
		else
			command emacsclient -t --alternate-editor "" "$@"
		fi
	elif command -v emacs > "/dev/null" 2>&1; then
		if [ "$#" -eq 0 ]; then
			command emacs -nw .
		else
			command emacs -nw "$@"
		fi
	else
		_ui_err "emacs not found."
		return 127
	fi
}
emacs-open() {
	command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacsclientw not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		emacsclientw --create-frame --alternate-editor "" .
	else
		emacsclientw --create-frame --alternate-editor "" "$@"
	fi
}
emacs-eshell() {
	command -v emacsclientw > "/dev/null" 2>&1 || command -v runemacs > "/dev/null" 2>&1 || {
		_ui_err "emacs not found."
		return 127
	}

	local _dir="${1:-.}"
	if [ -d "${_dir}" ]; then
		_dir="$(cd "${_dir}" && pwd)"
	else
		_dir="${PWD}"
	fi

	if command -v emacsclientw > "/dev/null" 2>&1; then
		emacsclientw --create-frame --alternate-editor "" --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
	else
		runemacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
	fi
}
alias ek="emacs-kill"
alias es="emacs-start"
alias er="emacs-restart"
alias ec="emacs-client"
alias en="emacs-nw"
alias enw="emacs-nw"
alias oen="emacs-nw"
alias oenw="emacs-nw"
alias open-emacs-nw="emacs-nw"
alias oe="emacs-open"
alias open-emacs="emacs-open"
alias open-eshell="emacs-eshell"
alias oes="emacs-eshell"
alias esh="emacs-eshell"
