### ================================
### DESKTOP CONTEXT WINDOWS
### ================================

### --------------------------------
### EMACS
### --------------------------------
export EMACS_SOCKET_NAME="${EMACS_SOCKET_NAME:-${HOME}/.emacs.d/var/server/auth/server}"

_emacs_win_user() {
	printf '%s\n' "${USERNAME:-$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")}"
}

_emacs_win_socket_path() {
	local _socket_name="${EMACS_SOCKET_NAME:-${HOME}/.emacs.d/var/server/auth/server}"
	case "${_socket_name}" in
		*/*|*\\*) printf '%s\n' "${_socket_name}" ;;
		*) printf '%s\n' "${XDG_RUNTIME_DIR:-/tmp}/emacs$(id -u 2> "/dev/null" || printf '0')/${_socket_name}" ;;
	esac
}

_emacs_win_posix_pids() {
	local _mode="${1:-all}"
	command -v pgrep > "/dev/null" 2>&1 || return 0
	local _msys_user=""
	local _exact_pids=""
	local _daemon_pids=""
	_msys_user="$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")"
	if [ -n "${_msys_user}" ]; then
		[ "${_mode}" = "all" ] && _exact_pids="$(command pgrep -u "${_msys_user}" -x emacs 2> "/dev/null" || true)"
		_daemon_pids="$(command pgrep -u "${_msys_user}" -f '(^|/)emacs[^/[:space:]]*[[:space:]].*--(fg-|bg-)?daemon' 2> "/dev/null" || true)"
	else
		[ "${_mode}" = "all" ] && _exact_pids="$(command pgrep -x emacs 2> "/dev/null" || true)"
		_daemon_pids="$(command pgrep -f '(^|/)emacs[^/[:space:]]*[[:space:]].*--(fg-|bg-)?daemon' 2> "/dev/null" || true)"
	fi
	printf '%s\n%s\n' "${_exact_pids}" "${_daemon_pids}" | \
		command awk -v self_pid="$$" 'NF && $1 ~ /^[0-9]+$/ && $1 != self_pid && !seen[$1]++ { print $1 }'
}

_emacs_win_native_running() {
	command -v tasklist.exe > "/dev/null" 2>&1 || return 1
	local _win_user=""
	local _image=""
	_win_user="$(_emacs_win_user)"
	for _image in emacs.exe runemacs.exe; do
		if [ -n "${_win_user}" ]; then
			if MSYS2_ARG_CONV_EXCL="*" command tasklist.exe /FI "USERNAME eq ${_win_user}" /FI "IMAGENAME eq ${_image}" /FO CSV /NH 2> "/dev/null" | \
			   command grep -qiE "^\"(emacs|runemacs)\.exe\","; then
				return 0
			fi
		elif MSYS2_ARG_CONV_EXCL="*" command tasklist.exe /FI "IMAGENAME eq ${_image}" /FO CSV /NH 2> "/dev/null" | \
		     command grep -qiE "^\"(emacs|runemacs)\.exe\","; then
			return 0
		fi
	done
	return 1
}

_emacs_win_is_running() {
	local _mode="${1:-all}"
	[ -n "$(_emacs_win_posix_pids "${_mode}")" ] && return 0
	[ "${_mode}" = "all" ] && _emacs_win_native_running && return 0
	return 1
}

_emacs_win_wait_exit() {
	local _checks="${1:-10}"
	local _mode="${2:-all}"
	local _attempt=0
	while [ "${_attempt}" -lt "${_checks}" ]; do
		_emacs_win_is_running "${_mode}" || return 0
		if sleep 0.2 2> "/dev/null"; then
			_attempt=$((_attempt + 1))
		else
			sleep 1 2> "/dev/null" || break
			_attempt=$((_attempt + 5))
		fi
	done
	! _emacs_win_is_running "${_mode}"
}

_emacs_win_signal_posix() {
	local _signal="${1:-TERM}"
	local _mode="${2:-all}"
	local _msys_user=""
	local _pids=""
	local _pid=""
	_msys_user="$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")"
	if [ "${_mode}" = "all" ] && command -v pkill > "/dev/null" 2>&1 && [ -n "${_msys_user}" ]; then
		command pkill "-${_signal}" -u "${_msys_user}" -x emacs > "/dev/null" 2>&1 || true
	fi
	_pids="$(_emacs_win_posix_pids "${_mode}")"
	if [ -n "${_pids}" ]; then
		printf '%s\n' "${_pids}" | while IFS= read -r _pid; do
			[ -n "${_pid}" ] || continue
			kill -0 "${_pid}" 2> "/dev/null" && kill "-${_signal}" "${_pid}" 2> "/dev/null" || true
		done
	fi
}

_emacs_win_signal_native() {
	local _force="${1:-0}"
	command -v taskkill.exe > "/dev/null" 2>&1 || return 0
	local _win_user=""
	local _image=""
	_win_user="$(_emacs_win_user)"
	for _image in emacs.exe runemacs.exe; do
		if [ "${_force}" -eq 1 ]; then
			if [ -n "${_win_user}" ]; then
				MSYS2_ARG_CONV_EXCL="*" command taskkill.exe /F /FI "USERNAME eq ${_win_user}" /IM "${_image}" > "/dev/null" 2>&1 || true
			else
				MSYS2_ARG_CONV_EXCL="*" command taskkill.exe /F /IM "${_image}" > "/dev/null" 2>&1 || true
			fi
		else
			if [ -n "${_win_user}" ]; then
				MSYS2_ARG_CONV_EXCL="*" command taskkill.exe /FI "USERNAME eq ${_win_user}" /IM "${_image}" > "/dev/null" 2>&1 || true
			else
				MSYS2_ARG_CONV_EXCL="*" command taskkill.exe /IM "${_image}" > "/dev/null" 2>&1 || true
			fi
		fi
	done
}

_emacs_win_timeout_eval() {
	local _timeout_seconds="${1:-2}"
	local _lisp_expr="${2:-t}"
	local _client_bin=""
	local _socket_path=""
	_socket_path="$(_emacs_win_socket_path)"
	if command -v emacsclient > "/dev/null" 2>&1; then
		_client_bin="emacsclient"
	elif command -v emacsclientw > "/dev/null" 2>&1; then
		_client_bin="emacsclientw"
	else
		return 127
	fi
	if command -v timeout > "/dev/null" 2>&1; then
		command timeout "${_timeout_seconds}" "${_client_bin}" -s "${_socket_path}" --eval "${_lisp_expr}" > "/dev/null" 2>&1
		return "$?"
	fi
	command "${_client_bin}" -s "${_socket_path}" --eval "${_lisp_expr}" > "/dev/null" 2>&1
}

_emacs_win_cleanup_socket() {
	local _socket_path=""
	_socket_path="$(_emacs_win_socket_path)"
	[ -n "${_socket_path}" ] || return 0
	if [ -e "${_socket_path}" ] || [ -S "${_socket_path}" ]; then
		if [ -O "${_socket_path}" ] 2> "/dev/null"; then
			command rm -f "${_socket_path}" 2> "/dev/null" || true
		else
			_ui_warn "Refusing to remove Emacs socket not owned by current user: ${_socket_path}"
			return 1
		fi
	fi
	return 0
}

_emacs_win_stop_daemon() {
	local _mode="${1:-all}"
	local _socket_path=""
	_socket_path="$(_emacs_win_socket_path)"

	if [ -e "${_socket_path}" ] || [ -S "${_socket_path}" ] || _emacs_win_is_running "${_mode}"; then
		if _emacs_win_timeout_eval 2 "(kill-emacs)"; then
			_emacs_win_wait_exit 10 "${_mode}" && { _emacs_win_cleanup_socket; return 0; }
		fi
	fi

	if _emacs_win_is_running "${_mode}"; then
		_emacs_win_signal_posix TERM "${_mode}"
		[ "${_mode}" = "all" ] && _emacs_win_signal_native 0
		_emacs_win_wait_exit 10 "${_mode}"
	fi

	if _emacs_win_is_running "${_mode}"; then
		_ui_warn "Emacs unresponsive after graceful stop. Forcing termination..."
		_emacs_win_signal_posix KILL "${_mode}"
		[ "${_mode}" = "all" ] && _emacs_win_signal_native 1
		_emacs_win_wait_exit 5 "${_mode}"
	fi

	if _emacs_win_is_running "${_mode}"; then
		_ui_err "Failed to terminate unresponsive Emacs process."
		return 1
	fi

	_emacs_win_cleanup_socket
}

_emacs_win_ensure_healthy_socket() {
	local _socket_path=""
	_socket_path="$(_emacs_win_socket_path)"
	if [ -e "${_socket_path}" ] || [ -S "${_socket_path}" ] || [ -n "$(_emacs_win_posix_pids "daemon")" ]; then
		if ! _emacs_win_timeout_eval 2 "(+ 1 1)"; then
			_ui_warn "Emacs server socket unresponsive. Cleaning stale state..."
			_emacs_win_stop_daemon "daemon"
		fi
	fi
}

_emacs_kill() {
	command -v runemacs > "/dev/null" 2>&1 || command -v emacsclientw > "/dev/null" 2>&1 || \
		command -v emacsclient > "/dev/null" 2>&1 || command -v emacs > "/dev/null" 2>&1 || \
		command -v emacs.exe > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	_emacs_win_stop_daemon "all"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
_emacs_start() {
	command -v runemacs > "/dev/null" 2>&1 || { _ui_err "runemacs not found."; return 127; }
	command runemacs --fg-daemon
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
	_emacs_win_ensure_healthy_socket
	command emacsclientw --create-frame --alternate-editor "" "$@"
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
	_emacs_win_ensure_healthy_socket
	local _status=0
	if [ "$#" -eq 0 ]; then
		command emacsclientw --create-frame --alternate-editor "" .
		_status=$?
	else
		command emacsclientw --create-frame --alternate-editor "" "$@"
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
		_emacs_win_ensure_healthy_socket
		command emacsclientw --create-frame --alternate-editor "" --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
		_status=$?
	else
		command runemacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
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
