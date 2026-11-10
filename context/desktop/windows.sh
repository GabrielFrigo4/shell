### ================================
### DESKTOP CONTEXT WINDOWS
### ================================

### --------------------------------
### EMACS
### --------------------------------
_emacs_kill() {
	command -v runemacs > "/dev/null" 2>&1 || command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	pkill emacs
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
_emacs_start() {
	command -v runemacs > "/dev/null" 2>&1 || { _ui_err "runemacs not found."; return 127; }
	runemacs --fg-daemon
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
_emacs_restart() {
	_emacs_kill && _emacs_start
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
_emacs_client() {
	command -v emacsclientw > "/dev/null" 2>&1 || { _ui_err "emacsclientw not found."; return 127; }
	emacsclientw --create-frame --alternate-editor "" "$@"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
_emacs_nw() {
	local _status=0
	if command -v emacs > "/dev/null" 2>&1; then
		command emacs -nw "$@"
		_status=$?
	elif command -v emacs.exe > "/dev/null" 2>&1; then
		command emacs.exe -nw "$@"
		_status=$?
	else
		_ui_err "emacs not found."
		return 127
	fi
	_restore_tty_cursor
	return ${_status}
}
_emacs_open() {
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
_emacs_open_nw() {
	local _status=0
	if [ "$#" -eq 0 ]; then
		_emacs_nw .
		_status=$?
	else
		_emacs_nw "$@"
		_status=$?
	fi
	_restore_tty_cursor
	return ${_status}
}
_emacs_eshell() {
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

alias ek="_emacs_kill"
alias es="_emacs_start"
alias er="_emacs_restart"
alias ec="_emacs_client"
alias en="_emacs_nw"
alias enw="_emacs_nw"
alias oe="_emacs_open"
alias open-emacs="_emacs_open"
alias oen="_emacs_open_nw"
alias oenw="_emacs_open_nw"
alias open-emacs-nw="_emacs_open_nw"
alias open-eshell="_emacs_eshell"
alias oes="_emacs_eshell"
alias esh="_emacs_eshell"

if (eval 'f-f() { :; }') 2> "/dev/null"; then
	eval 'emacs-kill() { _emacs_kill "$@"; }'
	eval 'emacs-start() { _emacs_start "$@"; }'
	eval 'emacs-restart() { _emacs_restart "$@"; }'
	eval 'emacs-client() { _emacs_client "$@"; }'
	eval 'emacs-nw() { _emacs_nw "$@"; }'
	eval 'emacs-open() { _emacs_open "$@"; }'
	eval 'emacs-open-nw() { _emacs_open_nw "$@"; }'
	eval 'emacs-eshell() { _emacs_eshell "$@"; }'
fi
