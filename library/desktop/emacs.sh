# ----------------------------------------------------------------
# Library: GNU Emacs Daemon & Client Management
# ----------------------------------------------------------------

### --------------------------------
### EMACS DAEMON & CLIENT
### --------------------------------
if [ -n "${XDG_RUNTIME_DIR+x}" ] && [ -z "${XDG_RUNTIME_DIR}" ]; then
	unset XDG_RUNTIME_DIR
fi
export EMACS_SOCKET_NAME="${EMACS_SOCKET_NAME:-${HOME}/.emacs.d/var/server/auth/server}"

_emacs_current_user() {
	case "$(uname -s 2> "/dev/null")" in
		MINGW*|MSYS*|CYGWIN*) id -un 2> "/dev/null" || printf '%s\n' "${USER:-}" ;;
		*) id -u 2> "/dev/null" || id -un 2> "/dev/null" || printf '%s\n' "${USER:-}" ;;
	esac
}

_emacs_is_raw_vt() {
	case "${FORCE_RAW_TTY:-}" in
		1|true|yes) return 0 ;;
	esac
	if command -v _is_raw_tty > "/dev/null" 2>&1; then
		_is_raw_tty
		return "$?"
	fi
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*0*|*false*|*no*) return 1 ;;
	esac
	local _tty=""
	if [ -t 0 ]; then
		_tty="$(command tty 2> "/dev/null" || true)"
	fi
	if [ -z "${_tty}" ] && [ -t 1 ]; then
		_tty="$(command tty <&1 2> "/dev/null" || true)"
	fi
	case "${_tty}" in
		/dev/pts/*|/dev/ttyp*|/dev/ttys*|/dev/pty*) return 1 ;;
		/dev/tty[0-9]*|/dev/ttyv*|/dev/ttyC*|/dev/ttyE*|/dev/console) return 0 ;;
	esac
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${TERM_PROGRAM:-}" ] || [ -n "${KONSOLE_VERSION:-}" ] || [ -n "${WT_SESSION:-}" ]; then
		return 1
	fi
	case "${TERM:-}" in
		linux|cons25*|wvt25*) return 0 ;;
	esac
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) return 0 ;;
	esac
	return 1
}

_emacs_with_gui_env() {
	command env \
		-u RAW_TTY \
		-u LC_RAW_TTY \
		-u UNIVERSAL_RAW_TTY \
		-u FORCE_RAW_TTY \
		-u NVIM_NOTTYFAST \
		COLORTERM="truecolor" \
		MICRO_TRUECOLOR="1" \
		"$@"
}

_emacs_with_tty_env() {
	if _emacs_is_raw_vt; then
		command env \
			-u DISPLAY \
			-u WAYLAND_DISPLAY \
			-u COLORTERM \
			-u MICRO_TRUECOLOR \
			-u TERM_PROGRAM \
			-u KONSOLE_VERSION \
			-u WT_SESSION \
			RAW_TTY="1" \
			LC_RAW_TTY="1" \
			UNIVERSAL_RAW_TTY="1" \
			FORCE_RAW_TTY="1" \
			"$@"
	else
		command env \
			-u RAW_TTY \
			-u LC_RAW_TTY \
			-u UNIVERSAL_RAW_TTY \
			-u FORCE_RAW_TTY \
			-u NVIM_NOTTYFAST \
			COLORTERM="truecolor" \
			MICRO_TRUECOLOR="1" \
			"$@"
	fi
}

_emacs_std_socket_dir() {
	local _uid=""
	local _tmp_dir="${TMPDIR:-/tmp}"
	local _xdg_dir=""
	_uid="$(id -u 2> "/dev/null" || printf '1000')"
	_tmp_dir="${_tmp_dir%/}"
	[ -n "${_tmp_dir}" ] || _tmp_dir="/tmp"
	if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
		_xdg_dir="${XDG_RUNTIME_DIR%/}"
		[ -n "${_xdg_dir}" ] || _xdg_dir="/"
		printf '%s\n' "${_xdg_dir}/emacs"
	else
		printf '%s\n' "${_tmp_dir}/emacs${_uid}"
	fi
}

_emacs_socket_path() {
	local _socket_name="${1:-${EMACS_SOCKET_NAME:-${HOME}/.emacs.d/var/server/auth/server}}"
	case "${_socket_name}" in
		*/*) printf '%s\n' "${_socket_name}" ;;
		*) printf '%s\n' "$(_emacs_std_socket_dir)/${_socket_name}" ;;
	esac
}

_emacs_canonical_socket() {
	local _target="${1:-}"
	local _resolved=""
	[ -n "${_target}" ] || return 1
	if command -v readlink > "/dev/null" 2>&1; then
		_resolved="$(command readlink -f "${_target}" 2> "/dev/null" || true)"
		if [ -n "${_resolved}" ]; then
			printf '%s\n' "${_resolved}"
			return 0
		fi
	fi
	if command -v realpath > "/dev/null" 2>&1; then
		_resolved="$(command realpath "${_target}" 2> "/dev/null" || true)"
		if [ -n "${_resolved}" ]; then
			printf '%s\n' "${_resolved}"
			return 0
		fi
	fi
	printf '%s\n' "${_target}"
}

_emacs_is_default_socket() {
	local _target=""
	local _uid=""
	local _tmp_dir="${TMPDIR:-/tmp}"
	local _std_sock=""
	local _auth_sock=""
	local _var_sock=""
	local _tmp_sock=""
	_target="$(_emacs_socket_path "${1:-}")"
	_uid="$(id -u 2> "/dev/null" || printf '1000')"
	_tmp_dir="${_tmp_dir%/}"
	[ -n "${_tmp_dir}" ] || _tmp_dir="/tmp"
	_std_sock="$(_emacs_std_socket_dir)/server"
	_auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
	_var_sock="${HOME%/}/.emacs.d/var/server/server"
	_tmp_sock="${_tmp_dir}/emacs${_uid}/server"
	case "${_target}" in
		"${_std_sock}"|"${_auth_sock}"|"${_var_sock}"|"${_tmp_sock}"|"/tmp/emacs${_uid}/server") return 0 ;;
	esac
	return 1
}

_emacs_sanitize_path() {
	local _target="${1:-}"
	local _parent=""
	local _rem=""
	local _cur=""
	local _part=""
	[ -n "${_target}" ] || return 0
	case "${_target}" in
		*/*) _parent="${_target%/*}" ;;
		*) return 0 ;;
	esac
	[ -n "${_parent}" ] || _parent="/"

	_rem="${_parent#/}"
	while [ -n "${_rem}" ]; do
		_part="${_rem%%/*}"
		if [ "${_rem}" = "${_part}" ]; then
			_rem=""
		else
			_rem="${_rem#*/}"
		fi
		[ -n "${_part}" ] || continue
		_cur="${_cur}/${_part}"
		if [ -L "${_cur}" ] && [ ! -e "${_cur}" ]; then
			command rm -f "${_cur}" 2> "/dev/null" || true
		elif [ -e "${_cur}" ] && [ ! -d "${_cur}" ]; then
			command rm -f "${_cur}" 2> "/dev/null" || true
		fi
	done

	if [ -L "${_target}" ] && [ ! -e "${_target}" ]; then
		command rm -f "${_target}" 2> "/dev/null" || true
	elif [ -e "${_target}" ] && [ ! -S "${_target}" ]; then
		command rm -rf "${_target}" 2> "/dev/null" || true
	fi
	return 0
}

_emacs_ensure_socket_dir() {
	local _sock_path="${1:-}"
	local _parent=""
	case "${_sock_path}" in
		*/*) _parent="${_sock_path%/*}" ;;
		*) return 0 ;;
	esac
	[ -n "${_parent}" ] || _parent="/"
	_emacs_sanitize_path "${_sock_path}"
	if [ ! -d "${_parent}" ]; then
		command mkdir -p "${_parent}" 2> "/dev/null" || true
	fi
	if [ -d "${_parent}" ] && [ -O "${_parent}" ]; then
		command chmod 0700 "${_parent}" 2> "/dev/null" || true
	fi
	return 0
}

_emacs_sync_auth_symlink() {
	local _live_sock="${1:-}"
	local _auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
	[ -n "${_live_sock}" ] && [ -S "${_live_sock}" ] || return 0
	_live_sock="$(_emacs_canonical_socket "${_live_sock}" || printf '%s\n' "${_live_sock}")"
	[ "${_live_sock}" != "${_auth_sock}" ] || return 0
	_emacs_ensure_socket_dir "${_auth_sock}"
	command ln -sfn "${_live_sock}" "${_auth_sock}" 2> "/dev/null" || true
}

_emacs_pgrep() {
	command -v pgrep > "/dev/null" 2>&1 || return 1
	local _target_user=""
	_target_user="$(_emacs_current_user)"
	if [ -n "${_target_user}" ]; then
		command pgrep -u "${_target_user}" "$@"
	else
		command pgrep "$@"
	fi
}

_emacs_list_pids() {
	local _mode="${1:-all}"
	local _exact_pids=""
	local _daemon_pids=""
	if [ "${_mode}" = "all" ]; then
		_exact_pids="$(_emacs_pgrep -x emacs 2> "/dev/null" || true)"
	fi
	_daemon_pids="$(_emacs_pgrep -f '(^|/)emacs[^/[:space:]]*[[:space:]].*--(fg-|bg-)?daemon' 2> "/dev/null" || true)"
	printf '%s\n%s\n' "${_exact_pids}" "${_daemon_pids}" | \
		command awk -v self_pid="$$" 'NF && $1 ~ /^[0-9]+$/ && $1 != self_pid && !seen[$1]++ { print $1 }'
}

_emacs_wait_exit() {
	local _checks="${1:-10}"
	local _mode="${2:-daemon}"
	local _attempt=0
	while [ "${_attempt}" -lt "${_checks}" ]; do
		[ -z "$(_emacs_list_pids "${_mode}")" ] && return 0
		if sleep 0.2 2> "/dev/null"; then
			_attempt=$((_attempt + 1))
		else
			sleep 1 2> "/dev/null" || break
			_attempt=$((_attempt + 5))
		fi
	done
	[ -z "$(_emacs_list_pids "${_mode}")" ]
}

_emacs_send_signal() {
	local _signal="${1:-TERM}"
	local _mode="${2:-all}"
	local _target_user=""
	local _pids=""
	local _pid=""
	_target_user="$(_emacs_current_user)"
	if [ "${_mode}" = "all" ] && command -v pkill > "/dev/null" 2>&1 && [ -n "${_target_user}" ]; then
		command pkill "-${_signal}" -u "${_target_user}" -x emacs > "/dev/null" 2>&1 || true
	fi
	_pids="$(_emacs_list_pids "${_mode}")"
	if [ -n "${_pids}" ]; then
		printf '%s\n' "${_pids}" | while IFS= read -r _pid; do
			[ -n "${_pid}" ] || continue
			kill -0 "${_pid}" 2> "/dev/null" && kill "-${_signal}" "${_pid}" 2> "/dev/null" || true
		done
	fi
}

_emacs_timeout_eval() {
	local _timeout_seconds="${1:-2}"
	local _lisp_expr="${2:-t}"
	local _socket_path="${3:-$(_emacs_socket_path)}"
	_has_bin "emacsclient" || return 127
	if command -v timeout > "/dev/null" 2>&1; then
		command timeout "${_timeout_seconds}" emacsclient -s "${_socket_path}" -e "${_lisp_expr}" < "/dev/null" > "/dev/null" 2>&1
		return "$?"
	fi
	(
		command emacsclient -s "${_socket_path}" -e "${_lisp_expr}" < "/dev/null" > "/dev/null" 2>&1 &
		_probe_pid=$!
		(
			sleep "${_timeout_seconds}" 2> "/dev/null" || true
			if kill -0 "${_probe_pid}" 2> "/dev/null"; then
				kill -TERM "${_probe_pid}" 2> "/dev/null" || true
				sleep 1 2> "/dev/null" || true
				kill -0 "${_probe_pid}" 2> "/dev/null" && kill -KILL "${_probe_pid}" 2> "/dev/null" || true
			fi
		) &
		_watchdog_pid=$!
		wait "${_probe_pid}" 2> "/dev/null"
		_probe_status=$?
		kill -TERM "${_watchdog_pid}" 2> "/dev/null" || true
		wait "${_watchdog_pid}" 2> "/dev/null" || true
		exit "${_probe_status}"
	)
}

_emacs_try_live_socket() {
	local _cand="${1:-}"
	[ -n "${_cand}" ] || return 1
	if [ -S "${_cand}" ] && _emacs_timeout_eval 2 "(+ 1 1)" "${_cand}"; then
		_emacs_canonical_socket "${_cand}"
		return 0
	fi
	return 1
}

_emacs_live_socket() {
	local _target=""
	local _uid=""
	local _tmp_dir="${TMPDIR:-/tmp}"
	local _std_sock=""
	local _auth_sock=""
	local _var_sock=""
	local _tmp_sock=""
	local _cand=""
	_has_bin "emacsclient" || return 1
	_target="$(_emacs_socket_path "${1:-}")"
	_emacs_try_live_socket "${_target}" && return 0
	_emacs_is_default_socket "${_target}" || return 1
	_uid="$(id -u 2> "/dev/null" || printf '1000')"
	_tmp_dir="${_tmp_dir%/}"
	[ -n "${_tmp_dir}" ] || _tmp_dir="/tmp"
	_std_sock="$(_emacs_std_socket_dir)/server"
	_auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
	_var_sock="${HOME%/}/.emacs.d/var/server/server"
	_tmp_sock="${_tmp_dir}/emacs${_uid}/server"
	for _cand in "${_std_sock}" "${_auth_sock}" "${_var_sock}" "${_tmp_sock}" "/tmp/emacs${_uid}/server"; do
		[ "${_cand}" != "${_target}" ] || continue
		_emacs_try_live_socket "${_cand}" && return 0
	done
	return 1
}

_emacs_remove_one_socket() {
	local _sock="${1:-}"
	local _parent=""
	[ -n "${_sock}" ] || return 0
	_emacs_sanitize_path "${_sock}"
	if [ -e "${_sock}" ] || [ -S "${_sock}" ] || [ -L "${_sock}" ]; then
		_parent="${_sock%/*}"
		[ -n "${_parent}" ] || _parent="/"
		if [ -O "${_sock}" ] 2> "/dev/null" || { [ -L "${_sock}" ] && [ -O "${_parent}" ] 2> "/dev/null"; }; then
			command rm -f "${_sock}" 2> "/dev/null" || true
		else
			_ui_warn "Refusing to remove Emacs socket not owned by current user: ${_sock}"
			return 1
		fi
	fi
	return 0
}

_emacs_cleanup_socket() {
	local _target=""
	local _uid=""
	local _tmp_dir="${TMPDIR:-/tmp}"
	local _std_sock=""
	local _auth_sock=""
	local _var_sock=""
	local _tmp_sock=""
	local _cand=""
	local _rc=0
	_target="$(_emacs_socket_path "${1:-}")"
	_emacs_remove_one_socket "${_target}" || _rc=1
	if _emacs_is_default_socket "${_target}"; then
		_uid="$(id -u 2> "/dev/null" || printf '1000')"
		_tmp_dir="${_tmp_dir%/}"
		[ -n "${_tmp_dir}" ] || _tmp_dir="/tmp"
		_std_sock="$(_emacs_std_socket_dir)/server"
		_auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
		_var_sock="${HOME%/}/.emacs.d/var/server/server"
		_tmp_sock="${_tmp_dir}/emacs${_uid}/server"
		for _cand in "${_std_sock}" "${_auth_sock}" "${_var_sock}" "${_tmp_sock}" "/tmp/emacs${_uid}/server"; do
			[ "${_cand}" != "${_target}" ] || continue
			_emacs_remove_one_socket "${_cand}" || _rc=1
		done
	fi
	return "${_rc}"
}

_emacs_stop_daemon() {
	local _mode="${1:-all}"
	local _socket_path=""
	local _live_sock=""
	local _pids=""
	_socket_path="$(_emacs_socket_path)"
	_live_sock="$(_emacs_live_socket "${_socket_path}" || true)"
	_pids="$(_emacs_list_pids "${_mode}")"

	if { [ -n "${_live_sock}" ] || [ -S "${_socket_path}" ] || [ -n "${_pids}" ]; } && _has_bin "emacsclient"; then
		if [ -n "${_live_sock}" ] && _emacs_timeout_eval 2 "(kill-emacs)" "${_live_sock}"; then
			_emacs_wait_exit 10 "${_mode}" && { _emacs_cleanup_socket; return 0; }
		fi
	fi

	_pids="$(_emacs_list_pids "${_mode}")"
	if [ -n "${_pids}" ]; then
		_emacs_send_signal TERM "${_mode}"
		_emacs_wait_exit 10 "${_mode}"
	fi

	_pids="$(_emacs_list_pids "${_mode}")"
	if [ -n "${_pids}" ]; then
		_ui_warn "Emacs daemon unresponsive after SIGTERM. Sending SIGKILL..."
		_emacs_send_signal KILL "${_mode}"
		_emacs_wait_exit 5 "${_mode}"
	fi

	if [ -n "$(_emacs_list_pids "${_mode}")" ]; then
		_ui_err "Failed to terminate unresponsive Emacs process."
		return 1
	fi

	_emacs_cleanup_socket
}

_emacs_start_daemon() {
	_has_bin "emacs" || { _ui_err "emacs not found."; return 127; }
	local _std_sock=""
	local _auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
	local _target_sock=""
	local _daemon_sock=""
	local _live_sock=""
	local _attempt=0

	_std_sock="$(_emacs_std_socket_dir)/server"
	_target_sock="$(_emacs_socket_path)"

	_emacs_ensure_socket_dir "${_std_sock}"
	_emacs_ensure_socket_dir "${_auth_sock}"
	if _emacs_is_default_socket "${_target_sock}"; then
		_daemon_sock="${_std_sock}"
	else
		_emacs_ensure_socket_dir "${_target_sock}"
		_daemon_sock="${_target_sock}"
	fi

	command env \
		-u EMACS_SOCKET_NAME \
		-u RAW_TTY \
		-u LC_RAW_TTY \
		-u UNIVERSAL_RAW_TTY \
		-u FORCE_RAW_TTY \
		-u NVIM_NOTTYFAST \
		-u TERM_PROGRAM \
		-u KONSOLE_VERSION \
		-u WT_SESSION \
		emacs --daemon="${_daemon_sock}" || return $?

	while [ "${_attempt}" -lt 25 ]; do
		_live_sock="$(_emacs_live_socket "${_target_sock}" || true)"
		if [ -n "${_live_sock}" ]; then
			_emacs_sync_auth_symlink "${_live_sock}"
			return 0
		fi
		if sleep 0.2 2> "/dev/null"; then
			_attempt=$((_attempt + 1))
		else
			sleep 1 2> "/dev/null" || break
			_attempt=$((_attempt + 5))
		fi
	done

	return 1
}

_emacs_ensure_healthy_daemon() {
	local _socket_path=""
	local _live_sock=""
	local _unit_state=""
	local _attempt=0
	_socket_path="$(_emacs_socket_path)"
	_live_sock="$(_emacs_live_socket "${_socket_path}" || true)"
	if [ -n "${_live_sock}" ]; then
		_emacs_sync_auth_symlink "${_live_sock}"
		return 0
	fi

	if _emacs_is_default_socket "${_socket_path}" && command -v systemctl > "/dev/null" 2>&1; then
		_unit_state="$(command systemctl --user show -p ActiveState --value emacs.service 2> "/dev/null" || true)"
		if [ "${_unit_state}" = "activating" ]; then
			while [ "${_attempt}" -lt 8 ]; do
				_live_sock="$(_emacs_live_socket "${_socket_path}" || true)"
				if [ -n "${_live_sock}" ]; then
					_emacs_sync_auth_symlink "${_live_sock}"
					return 0
				fi
				if sleep 0.5 2> "/dev/null"; then
					_attempt=$((_attempt + 1))
				else
					sleep 1 2> "/dev/null" || break
					_attempt=$((_attempt + 2))
				fi
			done
		fi
	fi

	if [ -n "$(_emacs_list_pids "daemon")" ]; then
		_ui_warn "Emacs daemon unresponsive (deadlock or stale socket detected). Recovering..."
		_emacs_stop_daemon "daemon"
	else
		_emacs_cleanup_socket "${_socket_path}"
	fi

	_emacs_start_daemon
}

_emacs_run_nw() {
	_has_bin "emacs" || return 127
	if [ -t 0 ]; then
		command -v stty > "/dev/null" 2>&1 && stty sane 2> "/dev/null" || true
	fi
	local _argc=$#
	local _arg=""
	while [ "${_argc}" -gt 0 ]; do
		_arg="$1"
		[ "$#" -ge 1 ] && shift 1
		case "${_arg}" in
			-t|--tty|-nw|--no-window-system) ;;
			*) set -- "$@" "${_arg}" ;;
		esac
		_argc=$((_argc - 1))
	done
	_emacs_with_tty_env emacs -nw "$@"
}

emacs-kill() {
	_has_bin "emacs" || _has_bin "emacsclient" || { _ui_err "emacs not found."; return 127; }
	_emacs_stop_daemon "all"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-start() {
	_has_bin "emacs" || { _ui_err "emacs not found."; return 127; }
	_emacs_ensure_healthy_daemon
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
	local _status=0
	local _live_sock=""
	local _arg=""
	if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
		emacs-nw "$@"
		return $?
	fi
	for _arg in "$@"; do
		case "${_arg}" in
			-t|--tty|-nw|--no-window-system)
				emacs-nw "$@"
				return $?
				;;
		esac
	done
	_has_bin "emacsclient" || { _ui_err "emacsclient not found."; return 127; }
	_emacs_ensure_healthy_daemon
	_live_sock="$(_emacs_live_socket || true)"
	if [ -n "${_live_sock}" ]; then
		if [ "$#" -eq 0 ]; then
			_emacs_with_gui_env emacsclient -s "${_live_sock}" --create-frame -n
			_status=$?
		else
			_emacs_with_gui_env emacsclient -s "${_live_sock}" --create-frame "$@"
			_status=$?
		fi
	else
		_emacs_with_gui_env emacs "$@"
		_status=$?
	fi
	_restore_tty_cursor
	return ${_status}
}
emacs-nw() {
	local _status=0
	local _live_sock=""
	if _has_bin "emacsclient"; then
		_emacs_ensure_healthy_daemon > "/dev/null" 2>&1 || true
		_live_sock="$(_emacs_live_socket || true)"
		if [ -n "${_live_sock}" ]; then
			_emacs_with_tty_env emacsclient -t -s "${_live_sock}" "$@" 2> "/dev/null"
			_status=$?
			if [ "${_status}" -eq 0 ]; then
				_restore_tty_cursor
				return 0
			fi
		fi
	fi
	if _has_bin "emacs"; then
		_emacs_run_nw "$@"
		_status=$?
	else
		_ui_err "emacs not found."
		return 127
	fi
	_restore_tty_cursor
	return ${_status}
}
emacsclient() {
	local _status=0
	local _arg=""
	local _mode="auto"
	if [ "$#" -eq 0 ]; then
		emacs-client
		_status=$?
	else
		_has_bin "emacsclient" || { _ui_err "emacsclient not found."; return 127; }
		for _arg in "$@"; do
			case "${_arg}" in
				-e|--eval|-h|-H|--help|-V|--version)
					_mode="raw"
					break
					;;
				-t|--tty|-nw|--no-window-system)
					_mode="tty"
					;;
				-c|--create-frame|-r|--reuse-frame)
					[ "${_mode}" = "auto" ] && _mode="frame"
					;;
			esac
		done
		case "${_mode}" in
			raw)
				command emacsclient "$@"
				_status=$?
				;;
			tty)
				_emacs_with_tty_env emacsclient "$@"
				_status=$?
				;;
			*)
				if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
					_emacs_with_gui_env emacsclient "$@"
				else
					_emacs_with_tty_env emacsclient "$@"
				fi
				_status=$?
				;;
		esac
	fi
	_restore_tty_cursor
	return ${_status}
}
emacs() {
	local _status=0
	case "${1:-}" in
		client)
			[ "$#" -ge 1 ] && shift 1
			emacs-client "$@"
			_status=$?
			;;
		-nw | --no-window-system | -t | --tty)
			[ "$#" -ge 1 ] && shift 1
			emacs-nw "$@"
			_status=$?
			;;
		-*)
			_has_bin "emacs" || { _ui_err "emacs not found."; return 127; }
			command emacs "$@"
			_status=$?
			;;
		*)
			emacs-client "$@"
			_status=$?
			;;
	esac
	_restore_tty_cursor
	return ${_status}
}
emacs-open() {
	local _status=0
	local _live_sock=""
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		_has_bin "emacsclient" || { _ui_err "emacsclient not found."; return 127; }
		_emacs_ensure_healthy_daemon
		_live_sock="$(_emacs_live_socket || true)"
		if [ -n "${_live_sock}" ]; then
			if [ "$#" -eq 0 ]; then
				(_emacs_with_gui_env nohup emacsclient -s "${_live_sock}" --create-frame . < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			else
				(_emacs_with_gui_env nohup emacsclient -s "${_live_sock}" --create-frame "$@" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			fi
		else
			(_emacs_with_gui_env nohup emacs "$@" < "/dev/null" > "/dev/null" 2>&1 &)
			_status=$?
		fi
	else
		emacs-open-nw "$@"
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
	_has_bin "emacsclient" || _has_bin "emacs" || {
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
	local _live_sock=""
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if _has_bin "emacsclient"; then
			_emacs_ensure_healthy_daemon
			_live_sock="$(_emacs_live_socket || true)"
			if [ -n "${_live_sock}" ]; then
				(_emacs_with_gui_env nohup emacsclient -s "${_live_sock}" --create-frame \
					--eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			else
				(_emacs_with_gui_env nohup emacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			fi
		else
			(_emacs_with_gui_env nohup emacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
			_status=$?
		fi
	else
		if _has_bin "emacsclient"; then
			_emacs_ensure_healthy_daemon > "/dev/null" 2>&1 || true
			_live_sock="$(_emacs_live_socket || true)"
			if [ -n "${_live_sock}" ]; then
				_emacs_with_tty_env emacsclient -t -s "${_live_sock}" \
					--eval "(progn (cd \"${_dir}/\") (aweshell/new))" 2> "/dev/null"
				_status=$?
			else
				_status=1
			fi
		else
			_status=1
		fi
		if [ "${_status}" -ne 0 ] && _has_bin "emacs"; then
			_emacs_run_nw --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
			_status=$?
		fi
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
