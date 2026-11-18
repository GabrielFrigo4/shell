# ----------------------------------------------------------------
# Library: Desktop Editors, Applications & Smart File Opener
# ----------------------------------------------------------------

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
		local _app_esc=$'\e'
		[ "${#_app_esc}" -ne 1 ] && _app_esc="$(printf '\x1b')"
		if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
			if [ "${TERM:-}" = "linux" ] && [ "${_DETECTED_OS-$(_detect_os)}" = "linux" ]; then
				printf '%s%%G%s[?16;238;0c' "${_app_esc}" "${_app_esc}"
			fi
		else
			printf '%s[1 q%s]112\a%s]112%s\\' "${_app_esc}" "${_app_esc}" "${_app_esc}" "${_app_esc}"
		fi
	fi
}

nvim() {
	_has_bin "nvim" || { _ui_err "nvim not found."; return 127; }
	command nvim "$@"
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}

hx() {
	_has_bin "hx" || { _ui_err "hx not found."; return 127; }
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
	_has_bin "micro" || { _ui_err "micro not found."; return 127; }
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
		   _has_bin "emacsclient"; then
			if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${INSIDE_EMACS:-}" ]; then
				_emacs_ensure_healthy_daemon > "/dev/null" 2>&1 || true
			fi
			_live_sock="$(_emacs_live_socket || true)"
			if [ -n "${_live_sock}" ]; then
				if [ -n "${INSIDE_EMACS:-}" ]; then
					command emacsclient -s "${_live_sock}" -n "${_target}"
				else
					command emacsclient -s "${_live_sock}" --create-frame -n "${_target}"
				fi
				continue
			fi
		fi

		if [ "${_extension_match}" -eq 1 ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && _has_bin "emacs"; then
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
