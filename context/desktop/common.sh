### ================================
### DESKTOP CONTEXT COMMON
### ================================

### --------------------------------
### TERMINAL EDITORS
### --------------------------------
_restore_tty_cursor() {
	[ -n "${INSIDE_EMACS:-}" ] && return 0
	if [ -t 0 ]; then
		command -v stty > "/dev/null" 2>&1 && stty sane 2> "/dev/null" || true
	fi
	if [ -t 1 ]; then
		case "${TERM:-}" in
			""|dumb|unknown) return 0 ;;
		esac
		if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
			if [ "${TERM:-}" = "linux" ] && [ "${_DETECTED_OS-$(_detect_os)}" = "linux" ]; then
				echo -n $'\e%G\e[?16;238;0c'
			fi
		else
			echo -n $'\e[1 q\e]112\a\e]112\e\\'
		fi
	fi
}

nvim() {
	command -v nvim > "/dev/null" 2>&1 || { _ui_err "nvim not found."; return 127; }
	command nvim "$@"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}

hx() {
	command -v hx > "/dev/null" 2>&1 || { _ui_err "hx not found."; return 127; }
	local _status=0
	if [ -t 0 ] && [ -t 1 ] && command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		local _tty_config="${XDG_CONFIG_HOME:-${HOME}/.config}/helix/config-tty.toml"
		if [ -f "${_tty_config}" ]; then
			command hx -c "${_tty_config}" "$@"
			_status=$?
		else
			command hx "$@"
			_status=$?
		fi
	else
		command hx "$@"
		_status=$?
	fi
	_restore_tty_cursor
	return ${_status}
}

open-helix() {
	if [ "$#" -eq 0 ]; then
		hx .
	else
		hx "$@"
	fi
}
alias open-hx="open-helix"
alias oh="open-helix"
alias h="open-helix"

micro() {
	command -v micro > "/dev/null" 2>&1 || { _ui_err "micro not found."; return 127; }
	command micro "$@"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}

### --------------------------------
### GUI EDITORS
### --------------------------------
open-kate() {
	command -v kate > "/dev/null" 2>&1 || { _ui_err "kate not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		(command nohup kate . < "/dev/null" > "/dev/null" 2>&1 &)
	else
		(command nohup kate "$@" < "/dev/null" > "/dev/null" 2>&1 &)
	fi
}
alias ok="open-kate"

open-geany() {
	command -v geany > "/dev/null" 2>&1 || { _ui_err "geany not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		(command nohup geany . < "/dev/null" > "/dev/null" 2>&1 &)
	else
		(command nohup geany "$@" < "/dev/null" > "/dev/null" 2>&1 &)
	fi
}
alias og="open-geany"

open-code() {
	local _bin=""
	if command -v vscode > "/dev/null" 2>&1; then
		_bin="vscode"
	elif command -v code > "/dev/null" 2>&1; then
		_bin="code"
	fi
	[ -z "${_bin}" ] && { _ui_err "Neither 'vscode' nor 'code' found."; return 127; }
	if [ "$#" -eq 0 ]; then
		"${_bin}" .
	else
		"${_bin}" "$@"
	fi
}
alias oc="open-code"

open-codium() {
	command -v codium > "/dev/null" 2>&1 || { _ui_err "codium not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		command codium .
	else
		command codium "$@"
	fi
}
alias ocm="open-codium"

open-antigravity() {
	command -v antigravity-ide > "/dev/null" 2>&1 || { _ui_err "antigravity-ide not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		command antigravity-ide .
	else
		command antigravity-ide "$@"
	fi
}
alias open-ant="open-antigravity"
alias oa="open-antigravity"
alias ant="antigravity-ide"

open-zed() {
	command -v zed > "/dev/null" 2>&1 || { _ui_err "zed not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		command zed .
	else
		command zed "$@"
	fi
}
alias oz="open-zed"

### --------------------------------
### DESKTOP APPLICATIONS
### --------------------------------
open-vlc() {
	command -v vlc > "/dev/null" 2>&1 || { _ui_err "vlc not found."; return 127; }
	if [ -t 0 ] && [ -t 1 ] && command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
		if command -v graphical-launcher > "/dev/null" 2>&1; then
			graphical-launcher vlc "$@"
			return $?
		fi
	fi
	(command nohup vlc "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias ov="open-vlc"

open-mpv() {
	command -v mpv > "/dev/null" 2>&1 || { _ui_err "mpv not found."; return 127; }
	if [ -t 0 ] && [ -t 1 ] && command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
		if command -v graphical-launcher > "/dev/null" 2>&1; then
			graphical-launcher mpv "$@"
			return $?
		fi
	fi
	command mpv "$@"
}
alias om="open-mpv"

open-wireshark() {
	command -v wireshark > "/dev/null" 2>&1 || { _ui_err "wireshark not found."; return 127; }
	(command nohup wireshark "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias open-shark="open-wireshark"
alias os="open-wireshark"

open-firefox() {
	command -v firefox > "/dev/null" 2>&1 || { _ui_err "firefox not found."; return 127; }
	(command nohup firefox "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias of="open-firefox"

open-browser() {
	local _browser=""
	if command -v google-chrome > "/dev/null" 2>&1; then
		_browser="google-chrome"
	elif command -v google-chrome-stable > "/dev/null" 2>&1; then
		_browser="google-chrome-stable"
	elif command -v brave-browser > "/dev/null" 2>&1; then
		_browser="brave-browser"
	elif command -v brave > "/dev/null" 2>&1; then
		_browser="brave"
	elif command -v chromium > "/dev/null" 2>&1; then
		_browser="chromium"
	elif command -v chromium-browser > "/dev/null" 2>&1; then
		_browser="chromium-browser"
	elif [ "$(uname -s 2> "/dev/null")" = "FreeBSD" ] && command -v chrome > "/dev/null" 2>&1; then
		_browser="chrome"
	elif command -v microsoft-edge > "/dev/null" 2>&1; then
		_browser="microsoft-edge"
	elif command -v firefox > "/dev/null" 2>&1; then
		_browser="firefox"
	elif [ "$(uname -s 2> "/dev/null")" = "Darwin" ]; then
		if [ "$#" -eq 0 ]; then
			command open -a Safari
		else
			command open -a Safari "$@"
		fi
		return $?
	fi
	[ -z "${_browser}" ] && { _ui_err "No supported web browser found."; return 127; }
	(command nohup "${_browser}" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias open-web="open-browser"
alias ow="open-browser"

open-onlyoffice() {
	local _bin=""
	if command -v onlyoffice-desktopeditors > "/dev/null" 2>&1; then
		_bin="onlyoffice-desktopeditors"
	elif command -v desktopeditors > "/dev/null" 2>&1; then
		_bin="desktopeditors"
	fi
	[ -z "${_bin}" ] && { _ui_err "OnlyOffice not found."; return 127; }
	(command nohup "${_bin}" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias oo="open-onlyoffice"

open-libreoffice() {
	local _bin=""
	if command -v libreoffice > "/dev/null" 2>&1; then
		_bin="libreoffice"
	elif command -v soffice > "/dev/null" 2>&1; then
		_bin="soffice"
	fi
	[ -z "${_bin}" ] && { _ui_err "LibreOffice not found."; return 127; }
	(SAL_USE_VCLPLUGIN=gtk3 command nohup "${_bin}" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias ol="open-libreoffice"

open-terminal() {
	local _term=""
	local _candidate=""
	for _candidate in konsole kgx gnome-terminal xfce4-terminal foot alacritty kitty wezterm xterm; do
		if command -v "${_candidate}" > "/dev/null" 2>&1; then
			_term="${_candidate}"
			break
		fi
	done
	[ -z "${_term}" ] && { _ui_err "No supported terminal found."; return 127; }
	(command nohup "${_term}" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias ot="open-terminal"

open-thunderbird() {
	command -v thunderbird > "/dev/null" 2>&1 || { _ui_err "thunderbird not found."; return 127; }
	(command nohup thunderbird "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias open-mail="open-thunderbird"
alias omail="open-thunderbird"
alias oth="open-thunderbird"

### --------------------------------
### FILE OPENER
### --------------------------------
unalias open o > "/dev/null" 2>&1 || true

open-smart() {
	if [ "$#" -eq 0 ]; then
		if command -v _ui_warn > "/dev/null" 2>&1; then
			_ui_warn "Usage: o <file|dir|url>"
		else
			echo "Usage: o <file|dir|url>" >&2
		fi
		return 1
	fi

	local _target=""
	local _extension_match=0
	local _live_sock=""
	for _target in "$@"; do
		_extension_match=0
		case "${_target}" in
			*.pdf|*.PDF|*.epub|*.EPUB|*.djvu|*.DJVU|\
			*.sqlite|*.sqlite3|*.db|\
			*.org|*.md|*.txt|*.tex|\
			*.el|*.sh|*.py|*.c|*.h|*.rs|*.go|*.js|*.ts|\
			*.json|*.yaml|*.yml|*.toml|*.xml|*.csv|*.log|\
			*.diff|*.patch|\
			*.zip|*.tar|*.gz|*.xz|*.zst|*.7z)
				_extension_match=1
				;;
		esac

		if { [ -n "${INSIDE_EMACS:-}" ] || [ "${_extension_match}" -eq 1 ]; } && \
		   command -v emacsclient > "/dev/null" 2>&1; then
			_live_sock="$(_emacs_live_socket)"
			if [ -n "${_live_sock}" ]; then
				command emacsclient -s "${_live_sock}" -n "${_target}"
				continue
			fi
		fi

		if [ "${_extension_match}" -eq 1 ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && command -v emacs > "/dev/null" 2>&1; then
			(command nohup emacs "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
			continue
		fi

		if [ "$(uname -s 2> "/dev/null")" = "Darwin" ]; then
			(command nohup open "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
		elif command -v cygstart > "/dev/null" 2>&1; then
			(command nohup cygstart "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
		elif command -v wslview > "/dev/null" 2>&1; then
			(command nohup wslview "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
		elif command -v explorer.exe > "/dev/null" 2>&1; then
			if command -v wslpath > "/dev/null" 2>&1; then
				(command nohup explorer.exe "$(command wslpath -w "${_target}")" < "/dev/null" > "/dev/null" 2>&1 &)
			else
				(command nohup explorer.exe "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
			fi
		elif command -v xdg-open > "/dev/null" 2>&1; then
			(command nohup xdg-open "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
		elif command -v gio > "/dev/null" 2>&1; then
			(command nohup gio open "${_target}" < "/dev/null" > "/dev/null" 2>&1 &)
		fi
	done
}

open() {
	open-smart "$@"
}

o() {
	open-smart "$@"
}

### --------------------------------
### MODERN RUST CLI TOOLS
### --------------------------------
if command -v rg > "/dev/null" 2>&1 && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
	alias r="rg --smart-case"
else
	alias r="grep -Ei"
fi

if ! command -v delta > "/dev/null" 2>&1 && command -v git-delta > "/dev/null" 2>&1; then
	alias delta="git-delta"
fi

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
	local _tty=""
	if [ -t 0 ]; then
		_tty="$(command tty 2> "/dev/null" || true)"
	fi
	if [ -z "${_tty}" ] && [ -t 1 ]; then
		_tty="$(command tty <&1 2> "/dev/null" || true)"
	fi
	case "${_tty}" in
		/dev/tty[0-9]*|/dev/ttyv*|/dev/ttyC*|/dev/ttyE*|/dev/console) return 0 ;;
	esac
	return 1
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
	local _tmp_sock=""
	_target="$(_emacs_socket_path "${1:-}")"
	_uid="$(id -u 2> "/dev/null" || printf '1000')"
	_tmp_dir="${_tmp_dir%/}"
	[ -n "${_tmp_dir}" ] || _tmp_dir="/tmp"
	_std_sock="$(_emacs_std_socket_dir)/server"
	_auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
	_tmp_sock="${_tmp_dir}/emacs${_uid}/server"
	case "${_target}" in
		"${_std_sock}"|"${_auth_sock}"|"${_tmp_sock}"|"/tmp/emacs${_uid}/server") return 0 ;;
	esac
	return 1
}

_emacs_ensure_socket_dir() {
	local _sock_path="${1:-}"
	local _parent=""
	case "${_sock_path}" in
		*/*) _parent="${_sock_path%/*}" ;;
		*) return 0 ;;
	esac
	[ -n "${_parent}" ] || _parent="/"
	if [ ! -d "${_parent}" ]; then
		command mkdir -p "${_parent}" 2> "/dev/null" || true
	fi
	if [ -d "${_parent}" ] && [ -O "${_parent}" ]; then
		command chmod 0700 "${_parent}" 2> "/dev/null" || true
	fi
	return 0
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
	command -v emacsclient > "/dev/null" 2>&1 || return 127
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
	local _tmp_sock=""
	local _cand=""
	command -v emacsclient > "/dev/null" 2>&1 || return 1
	_target="$(_emacs_socket_path "${1:-}")"
	_emacs_try_live_socket "${_target}" && return 0
	_emacs_is_default_socket "${_target}" || return 1
	_uid="$(id -u 2> "/dev/null" || printf '1000')"
	_tmp_dir="${_tmp_dir%/}"
	[ -n "${_tmp_dir}" ] || _tmp_dir="/tmp"
	_std_sock="$(_emacs_std_socket_dir)/server"
	_auth_sock="${HOME%/}/.emacs.d/var/server/auth/server"
	_tmp_sock="${_tmp_dir}/emacs${_uid}/server"
	for _cand in "${_std_sock}" "${_auth_sock}" "${_tmp_sock}" "/tmp/emacs${_uid}/server"; do
		[ "${_cand}" != "${_target}" ] || continue
		_emacs_try_live_socket "${_cand}" && return 0
	done
	return 1
}

_emacs_remove_one_socket() {
	local _sock="${1:-}"
	local _parent=""
	[ -n "${_sock}" ] || return 0
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
		_tmp_sock="${_tmp_dir}/emacs${_uid}/server"
		for _cand in "${_std_sock}" "${_auth_sock}" "${_tmp_sock}" "/tmp/emacs${_uid}/server"; do
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

	if { [ -n "${_live_sock}" ] || [ -e "${_socket_path}" ] || [ -S "${_socket_path}" ] || [ -n "${_pids}" ]; } && command -v emacsclient > "/dev/null" 2>&1; then
		if _emacs_timeout_eval 2 "(kill-emacs)" "${_live_sock:-${_socket_path}}"; then
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

_emacs_ensure_healthy_daemon() {
	local _socket_path=""
	local _live_sock=""
	local _unit_state=""
	local _attempt=0
	_socket_path="$(_emacs_socket_path)"
	_live_sock="$(_emacs_live_socket "${_socket_path}" || true)"
	[ -n "${_live_sock}" ] && return 0

	if _emacs_is_default_socket "${_socket_path}" && command -v systemctl > "/dev/null" 2>&1; then
		_unit_state="$(command systemctl --user show -p ActiveState --value emacs.service 2> "/dev/null" || true)"
		if [ "${_unit_state}" = "activating" ]; then
			while [ "${_attempt}" -lt 8 ]; do
				_live_sock="$(_emacs_live_socket "${_socket_path}" || true)"
				[ -n "${_live_sock}" ] && return 0
				if sleep 0.5 2> "/dev/null"; then
					_attempt=$((_attempt + 1))
				else
					sleep 1 2> "/dev/null" || break
					_attempt=$((_attempt + 2))
				fi
			done
		fi
	fi

	if [ -e "${_socket_path}" ] || [ -S "${_socket_path}" ] || [ -L "${_socket_path}" ] || [ -n "$(_emacs_list_pids "daemon")" ]; then
		if ! _emacs_timeout_eval 2 "(+ 1 1)" "${_socket_path}"; then
			_ui_warn "Emacs daemon unresponsive (deadlock or stale socket detected). Recovering..."
			_emacs_stop_daemon "daemon"
		fi
	fi
}

_emacs_run_nw() {
	command -v emacs > "/dev/null" 2>&1 || return 127
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
	command emacs -nw "$@"
}

emacs-kill() {
	command -v emacs > "/dev/null" 2>&1 || command -v emacsclient > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	_emacs_stop_daemon "all"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-start() {
	command -v emacs > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	_emacs_ensure_healthy_daemon
	_emacs_ensure_socket_dir "$(_emacs_socket_path)"
	command emacs --daemon="${EMACS_SOCKET_NAME}"
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
	command -v emacsclient > "/dev/null" 2>&1 || { _ui_err "emacsclient not found."; return 127; }
	_emacs_ensure_healthy_daemon
	_live_sock="$(_emacs_live_socket || true)"
	if [ -n "${_live_sock}" ]; then
		if [ "$#" -eq 0 ]; then
			command emacsclient -s "${_live_sock}" --create-frame --alternate-editor="" -n
			_status=$?
		else
			command emacsclient -s "${_live_sock}" --create-frame --alternate-editor="" "$@"
			_status=$?
		fi
	else
		_emacs_ensure_socket_dir "$(_emacs_socket_path)"
		if [ "$#" -eq 0 ]; then
			command emacsclient --create-frame --alternate-editor="" -n
			_status=$?
		else
			command emacsclient --create-frame --alternate-editor="" "$@"
			_status=$?
		fi
	fi
	_restore_tty_cursor
	return ${_status}
}
emacs-nw() {
	local _status=0
	local _live_sock=""
	if _emacs_is_raw_vt; then
		if command -v emacs > "/dev/null" 2>&1; then
			_emacs_run_nw "$@"
			_status=$?
		else
			_ui_err "emacs not found."
			return 127
		fi
	else
		if command -v emacsclient > "/dev/null" 2>&1; then
			_live_sock="$(_emacs_live_socket || true)"
			if [ -n "${_live_sock}" ]; then
				command emacsclient -t -s "${_live_sock}" "$@" 2> "/dev/null"
				_status=$?
				if [ "${_status}" -eq 0 ]; then
					_restore_tty_cursor
					return 0
				fi
			fi
		fi
		if command -v emacs > "/dev/null" 2>&1; then
			_emacs_run_nw "$@"
			_status=$?
		elif command -v emacsclient > "/dev/null" 2>&1; then
			command emacsclient -t --alternate-editor="" "$@"
			_status=$?
		else
			_ui_err "emacs not found."
			return 127
		fi
	fi
	_restore_tty_cursor
	return ${_status}
}
emacsclient() {
	local _status=0
	if [ "$#" -eq 0 ]; then
		emacs-client
		_status=$?
	else
		command emacsclient "$@"
		_status=$?
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
		command -v emacsclient > "/dev/null" 2>&1 || { _ui_err "emacsclient not found."; return 127; }
		_emacs_ensure_healthy_daemon
		_live_sock="$(_emacs_live_socket || true)"
		if [ -n "${_live_sock}" ]; then
			if [ "$#" -eq 0 ]; then
				(command nohup emacsclient -s "${_live_sock}" --create-frame --alternate-editor="" . < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			else
				(command nohup emacsclient -s "${_live_sock}" --create-frame --alternate-editor="" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			fi
		else
			_emacs_ensure_socket_dir "$(_emacs_socket_path)"
			if [ "$#" -eq 0 ]; then
				(command nohup emacsclient --create-frame --alternate-editor="" . < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			else
				(command nohup emacsclient --create-frame --alternate-editor="" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			fi
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
	command -v emacsclient > "/dev/null" 2>&1 || command -v emacs > "/dev/null" 2>&1 || {
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
		if command -v emacsclient > "/dev/null" 2>&1; then
			_live_sock="$(_emacs_live_socket || true)"
			if [ -n "${_live_sock}" ]; then
				(command nohup emacsclient -s "${_live_sock}" --create-frame --alternate-editor="" \
					--eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			else
				_emacs_ensure_socket_dir "$(_emacs_socket_path)"
				(command nohup emacsclient --create-frame --alternate-editor="" \
					--eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
				_status=$?
			fi
		else
			(command nohup emacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
			_status=$?
		fi
	else
		if _emacs_is_raw_vt; then
			command emacs -nw --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
			_status=$?
		else
			_live_sock="$(_emacs_live_socket || true)"
			if [ -n "${_live_sock}" ] && command -v emacsclient > "/dev/null" 2>&1; then
				command emacsclient -t -s "${_live_sock}" \
					--eval "(progn (cd \"${_dir}/\") (aweshell/new))" 2> "/dev/null"
				_status=$?
			else
				_status=1
			fi
			if [ "${_status}" -ne 0 ]; then
				if command -v emacs > "/dev/null" 2>&1; then
					if [ -t 0 ]; then
						command -v stty > "/dev/null" 2>&1 && stty sane 2> "/dev/null" || true
					fi
					command emacs -nw --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
					_status=$?
				elif command -v emacsclient > "/dev/null" 2>&1; then
					command emacsclient -t --alternate-editor="" \
						--eval "(progn (cd \"${_dir}/\") (aweshell/new))"
					_status=$?
				fi
			fi
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

### --------------------------------
### GUI INTEGRATION
### --------------------------------
[ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/target/common/session.sh" ] && . "${SHELL_REPO_DIR}/target/common/session.sh"

if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
	_gui_raw_de="${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}}"
	_gui_is_full_de=0
	if [ "${KDE_FULL_SESSION:-}" = "true" ]; then
		_gui_is_full_de=1
	elif [ -n "${_gui_raw_de}" ]; then
		case "$(printf '%s' "${_gui_raw_de}" | tr '[:upper:]' '[:lower:]')" in
			*kde*|*plasma*|*gnome*|*ubuntu*|*unity*|*zorin*|*xfce*|*mate*|*cinnamon*|*cosmic*|*budgie*|*pantheon*|*lxqt*|*lxde*|*deepin*|*dde*)
				_gui_is_full_de=1
				;;
		esac
	elif command -v pgrep > "/dev/null" 2>&1; then
		_gui_uid="$(_emacs_current_user)"
		for _gui_proc in plasmashell kwin_wayland kwin_x11 gnome-shell xfce4-session mate-session cinnamon cosmic-comp cosmic-session budgie-wm budgie-panel gala wingpanel lxqt-session lxsession dde-desktop deepin-wm; do
			if [ -n "${_gui_uid}" ] && pgrep -u "${_gui_uid}" -x "${_gui_proc}" > "/dev/null" 2>&1; then
				_gui_is_full_de=1
				break
			fi
		done
		unset _gui_uid _gui_proc
	fi

	if [ "${_gui_is_full_de}" -eq 0 ]; then
		if [ -z "${GTK_THEME:-}" ]; then
			if [ -n "${_DETECTED_GTK_THEME:-}" ]; then
				export GTK_THEME="${_DETECTED_GTK_THEME}"
			elif [ -z "${_DETECTED_GTK_THEME+x}" ] && command -v _detect_gtk_theme > "/dev/null" 2>&1; then
				_gtk_theme="$(_detect_gtk_theme)"
				[ -n "${_gtk_theme}" ] && export GTK_THEME="${_gtk_theme}"
				unset _gtk_theme
			fi
		fi

		if [ -z "${QT_STYLE_OVERRIDE:-}" ]; then
			if [ -n "${_DETECTED_QT_THEME:-}" ]; then
				export QT_STYLE_OVERRIDE="${_DETECTED_QT_THEME}"
			elif [ -z "${_DETECTED_QT_THEME+x}" ] && command -v _detect_qt_theme > "/dev/null" 2>&1; then
				_qt_style="$(_detect_qt_theme)"
				[ -n "${_qt_style}" ] && export QT_STYLE_OVERRIDE="${_qt_style}"
				unset _qt_style
			fi
		fi
	fi

	if [ -z "${QT_QPA_PLATFORMTHEME:-}" ]; then
		if [ -n "${_DETECTED_QT_PLATFORM_THEME:-}" ]; then
			export QT_QPA_PLATFORMTHEME="${_DETECTED_QT_PLATFORM_THEME}"
		elif [ -z "${_DETECTED_QT_PLATFORM_THEME+x}" ] && command -v _detect_qt_platform_theme > "/dev/null" 2>&1; then
			_qt_platform="$(_detect_qt_platform_theme)"
			[ -n "${_qt_platform}" ] && export QT_QPA_PLATFORMTHEME="${_qt_platform}"
			unset _qt_platform
		fi
	fi

	export ELECTRON_OZONE_PLATFORM_HINT="auto"
	export _JAVA_AWT_WM_NONREPARENTING=1
	export SAL_USE_VCLPLUGIN="gtk3"
	unset _gui_raw_de _gui_is_full_de

	_theme_env_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d"
	_theme_stamp="${_SHELL_CACHE_DIR:-}/session_theme_propagated_${_DETECTED_DESKTOP_ENV:-default}"
	if { [ -z "${_SHELL_CACHE_DIR:-}" ] || [ ! -f "${_theme_stamp}" ] || [ ! -f "${_theme_env_dir}/10-theme.conf" ]; } && command -v _propagate_session_theme_env > "/dev/null" 2>&1; then
		_propagate_session_theme_env
		if [ -n "${_SHELL_CACHE_DIR:-}" ]; then
			[ -d "${_SHELL_CACHE_DIR}" ] || command mkdir -p "${_SHELL_CACHE_DIR}" 2> "/dev/null" || true
			: >| "${_theme_stamp}" 2> "/dev/null" || true
		fi
	fi
	unset _theme_env_dir _theme_stamp

	_default_cursor_paths="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
	case ":${XCURSOR_PATH:-}:" in
		*":/usr/local/share/icons:"*) ;;
		*) export XCURSOR_PATH="${XCURSOR_PATH:+${XCURSOR_PATH}:}${_default_cursor_paths}" ;;
	esac
	unset _default_cursor_paths

	if [ -z "${XCURSOR_THEME:-}" ] || [ -z "${XCURSOR_SIZE:-}" ]; then
		if [ -n "${_DETECTED_CURSOR_THEME:-}" ] && [ -n "${_DETECTED_CURSOR_SIZE:-}" ]; then
			[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_DETECTED_CURSOR_THEME}"
			[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_DETECTED_CURSOR_SIZE}"
		else
			_cursor_theme=""
			_cursor_size="${XCURSOR_SIZE:-24}"

			_user_id=""
			if [ -z "${_DETECTED_DESKTOP_ENV:-}" ] && [ -z "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}" ] && command -v pgrep > "/dev/null" 2>&1; then
				case "$(uname -s 2> "/dev/null")" in
					MINGW*|MSYS*|CYGWIN*) _user_id="$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")" ;;
					*) _user_id="$(id -u 2> "/dev/null" || printf '1000')" ;;
				esac
			fi
			if [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x plasmashell > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x kwin_wayland > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x kwin_x11 > "/dev/null" 2>&1; }; then
				if [ -f "${HOME}/.config/kcminputrc" ]; then
					_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
					_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
			elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x gnome-shell > "/dev/null" 2>&1; then
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
					_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x mate-session > "/dev/null" 2>&1; then
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.mate.peripherals-mouse cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x cinnamon > "/dev/null" 2>&1; then
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.cinnamon.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x xfce4-session > "/dev/null" 2>&1; then
				_cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x lxqt-session > "/dev/null" 2>&1; then
				_cursor_theme="breeze_cursors"
			elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x lxsession > "/dev/null" 2>&1; then
				_cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x budgie-wm > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x budgie-panel > "/dev/null" 2>&1; }; then
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
					_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x gala > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x wingpanel > "/dev/null" 2>&1; }; then
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
					_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x dde-desktop > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x deepin-wm > "/dev/null" 2>&1; }; then
				_cursor_theme="Adwaita"
			elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x cosmic-comp > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x cosmic-session > "/dev/null" 2>&1; }; then
				_cursor_theme="Adwaita"
			elif [ -n "${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}" ]; then
				case "$(printf '%s\n' "${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}" | tr '[:upper:]' '[:lower:]')" in
					*kde*|*plasma*)
						if [ -f "${HOME}/.config/kcminputrc" ]; then
							_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
							_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
						fi
						[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
						;;
					*gnome*)
						if command -v gsettings > "/dev/null" 2>&1; then
							_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
							_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
						fi
						[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
						;;
					*mate*)         _cursor_theme="Adwaita" ;;
					*cinnamon*)     _cursor_theme="Adwaita" ;;
					*xfce*)         _cursor_theme="Adwaita" ;;
					*lxqt*)         _cursor_theme="breeze_cursors" ;;
					*lxde*)         _cursor_theme="Adwaita" ;;
					*budgie*)       _cursor_theme="Adwaita" ;;
					*pantheon*)     _cursor_theme="Adwaita" ;;
					*deepin*|*dde*) _cursor_theme="Adwaita" ;;
					*cosmic*)       _cursor_theme="Adwaita" ;;
				esac
			fi

			if [ -z "${_cursor_theme}" ]; then
				if command -v plasmashell > "/dev/null" 2>&1 || command -v startplasma-wayland > "/dev/null" 2>&1 || command -v startplasma-x11 > "/dev/null" 2>&1 || [ -d "/usr/share/plasma" ] || [ -d "/usr/local/share/plasma" ]; then
					if [ -f "${HOME}/.config/kcminputrc" ]; then
						_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
						_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
				elif command -v gnome-shell > "/dev/null" 2>&1 || command -v gnome-session > "/dev/null" 2>&1 || [ -d "/usr/share/gnome-shell" ] || [ -d "/usr/local/share/gnome-shell" ]; then
					if command -v gsettings > "/dev/null" 2>&1; then
						_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
						_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				elif command -v mate-session > "/dev/null" 2>&1 || [ -d "/usr/share/mate" ] || [ -d "/usr/local/share/mate" ]; then
					_cursor_theme="Adwaita"
				elif command -v cinnamon > "/dev/null" 2>&1 || command -v cinnamon-session > "/dev/null" 2>&1 || [ -d "/usr/share/cinnamon" ] || [ -d "/usr/local/share/cinnamon" ]; then
					_cursor_theme="Adwaita"
				elif command -v xfce4-session > "/dev/null" 2>&1 || [ -d "/usr/share/xfce4" ] || [ -d "/usr/local/share/xfce4" ]; then
					_cursor_theme="Adwaita"
				elif command -v lxqt-session > "/dev/null" 2>&1 || [ -d "/usr/share/lxqt" ] || [ -d "/usr/local/share/lxqt" ]; then
					_cursor_theme="breeze_cursors"
				elif command -v lxsession > "/dev/null" 2>&1 || command -v startlxde > "/dev/null" 2>&1 || [ -d "/usr/share/lxde" ] || [ -d "/usr/local/share/lxde" ]; then
					_cursor_theme="Adwaita"
				elif command -v budgie-desktop > "/dev/null" 2>&1 || command -v budgie-wm > "/dev/null" 2>&1 || [ -d "/usr/share/budgie-desktop" ] || [ -d "/usr/local/share/budgie-desktop" ]; then
					_cursor_theme="Adwaita"
				elif command -v gala > "/dev/null" 2>&1 || command -v wingpanel > "/dev/null" 2>&1 || [ -d "/usr/share/pantheon" ] || [ -d "/usr/local/share/pantheon" ]; then
					_cursor_theme="Adwaita"
				elif command -v dde-desktop > "/dev/null" 2>&1 || command -v dde-session > "/dev/null" 2>&1 || [ -d "/usr/share/dde" ] || [ -d "/usr/local/share/dde" ]; then
					_cursor_theme="Adwaita"
				elif command -v cosmic-session > "/dev/null" 2>&1 || command -v cosmic-comp > "/dev/null" 2>&1 || [ -d "/usr/share/cosmic" ] || [ -d "/usr/local/share/cosmic" ]; then
					_cursor_theme="Adwaita"
				fi
			fi

			if [ -z "${_cursor_theme}" ]; then
				for _cursor_candidate in Adwaita breeze_cursors Bibata-Modern-Classic DMZ-White default; do
					for _icon_dir in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
						if [ -d "${_icon_dir}/${_cursor_candidate}/cursors" ]; then
							_cursor_theme="${_cursor_candidate}"
							break 2
						fi
					done
				done
			fi

			[ -z "${_cursor_theme}" ] && _cursor_theme="default"
			[ -z "${_cursor_size}" ] && _cursor_size="24"
			if command -v _cache_write > "/dev/null" 2>&1; then
				_cache_write "cursor_theme" "${_cursor_theme}"
				_cache_write "cursor_size" "${_cursor_size}"
			fi
			[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_cursor_theme}"
			[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_cursor_size}"
			unset _cursor_theme _cursor_size _cursor_candidate _icon_dir _user_id
		fi
	fi
fi

### --------------------------------
### PYTHON ZERO-CRUFT POLICY
### --------------------------------
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"
