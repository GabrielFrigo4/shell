### ================================
### DESKTOP CONTEXT WINDOWS
### ================================

### --------------------------------
### Emacs
### --------------------------------
emacs-kill() {
	command -v runemacs > "/dev/null" 2>&1 || command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	pkill emacs
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-start() {
	command -v runemacs > "/dev/null" 2>&1 || { _ui_err "runemacs not found."; return 127; }
	runemacs --fg-daemon
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-restart() {
	emacs-kill && emacs-start
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-client() {
	command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacsclientw not found."; return 127; }
	emacsclientw --create-frame --alternate-editor "" "$@"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-nw() {
	local _status=0
	if command -v emacsclient > "/dev/null" 2>&1; then
		command emacsclient -t --alternate-editor "" "$@"
		_status=$?
	elif command -v emacs > "/dev/null" 2>&1; then
		command emacs -nw "$@"
		_status=$?
	else
		_ui_err "emacs not found."
		return 127
	fi
	_restore_tty_cursor
	return ${_status}
}
emacs-open() {
	command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacsclientw not found."; return 127; }
	local _status=0
	if [ "$#" -eq 0 ]; then
		emacsclientw --create-frame --alternate-editor "" .
		_status=$?
	else
		emacsclientw --create-frame --alternate-editor "" "$@"
		_status=$?
	fi
	_restore_tty_cursor
	return ${_status}
}
emacs-open-nw() {
	local _status=0
	if [ "$#" -eq 0 ]; then
		emacs-nw .
		_status=$?
	else
		emacs-nw "$@"
		_status=$?
	fi
	_restore_tty_cursor
	return ${_status}
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

	local _status=0
	if command -v emacsclientw > "/dev/null" 2>&1; then
		emacsclientw --create-frame --alternate-editor "" --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
		_status=$?
	else
		runemacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
		_status=$?
	fi
	_restore_tty_cursor
	return ${_status}
}
alias ek="emacs-kill"
alias es="emacs-start"
alias er="emacs-restart"
alias ec="emacs-client"
alias en="emacs-nw"
alias enw="emacs-nw"
alias oe="emacs-open"
alias open-emacs="emacs-open"
alias oen="emacs-open-nw"
alias oenw="emacs-open-nw"
alias open-emacs-nw="emacs-open-nw"
alias open-eshell="emacs-eshell"
alias oes="emacs-eshell"
alias esh="emacs-eshell"
