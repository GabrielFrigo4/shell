### ================================
### DESKTOP CONTEXT COMMON
### ================================

### --------------------------------
### TERMINAL EDITORS
### --------------------------------
_restore_tty_cursor() {
	if [ -t 0 ]; then
		command -v stty > "/dev/null" 2>&1 && stty sane 2> "/dev/null" || true
	fi
	if [ -t 1 ]; then
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
		local _tty_cfg="${XDG_CONFIG_HOME:-${HOME}/.config}/helix/config-tty.toml"
		if [ -f "${_tty_cfg}" ]; then
			command hx -c "${_tty_cfg}" "$@"
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
			open -a Safari
		else
			open -a Safari "$@"
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
	(SAL_USE_VCLPLUGIN=gtk3 GTK_THEME="${GTK_THEME:-adw-gtk3-dark}" GTK_APPLICATION_PREFER_DARK_THEME=1 command nohup "${_bin}" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
}
alias ol="open-libreoffice"

open-terminal() {
	local _term=""
	for _t in konsole kgx gnome-terminal xfce4-terminal foot alacritty kitty wezterm xterm; do
		if command -v "${_t}" > "/dev/null" 2>&1; then
			_term="${_t}"
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
			_ui_warn "Uso: o <arquivo|diretorio|url>"
		else
			echo "Uso: o <arquivo|diretorio|url>" >&2
		fi
		return 1
	fi

	for _target in "$@"; do
		local _ext_match=0
		case "${_target}" in
			*.pdf|*.PDF|*.epub|*.EPUB|*.djvu|*.DJVU|\
			*.sqlite|*.sqlite3|*.db|\
			*.org|*.md|*.txt|*.tex|\
			*.el|*.sh|*.py|*.c|*.h|*.rs|*.go|*.js|*.ts|\
			*.json|*.yaml|*.yml|*.toml|*.xml|*.csv|*.log|\
			*.diff|*.patch|\
			*.zip|*.tar|*.gz|*.xz|*.zst|*.7z)
				_ext_match=1
				;;
		esac

		if { [ -n "${INSIDE_EMACS:-}" ] || [ "${_ext_match}" -eq 1 ]; } && \
		   command -v emacsclient > "/dev/null" 2>&1 && \
		   emacsclient -e t > "/dev/null" 2>&1; then
			emacsclient -n "${_target}"
			continue
		fi

		if [ "${_ext_match}" -eq 1 ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && command -v emacs > "/dev/null" 2>&1; then
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
export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

emacs-kill() {
	command -v emacs > "/dev/null" 2>&1 || command -v emacsclient > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	command pkill emacs
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
emacs-start() {
	command -v emacs > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
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
	command -v emacsclient > "/dev/null" 2>&1 || { _ui_err "emacsclient not found."; return 127; }

	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		_raw_de="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}"
		_is_kde=0
		case "$(printf '%s\n' "${_raw_de}" | tr '[:upper:]' '[:lower:]')" in
			*kde*|*plasma*) _is_kde=1 ;;
		esac
		if [ "${_is_kde}" -eq 0 ] && command -v pgrep > "/dev/null" 2>&1; then
			if pgrep -x plasmashell > "/dev/null" 2>&1 || pgrep -x kwin_wayland > "/dev/null" 2>&1 || pgrep -x kwin_x11 > "/dev/null" 2>&1; then
				_is_kde=1
			fi
		fi
		if [ "${_is_kde}" -eq 1 ]; then
			export GTK_THEME="Breeze-Dark"
			export GTK_APPLICATION_PREFER_DARK_THEME=1
			export QT_QPA_PLATFORMTHEME="kde"
			export QT_STYLE_OVERRIDE="Breeze-Dark"
		else
			export GTK_APPLICATION_PREFER_DARK_THEME=1
			if [ -z "${GTK_THEME:-}" ]; then
				if [ -r "${HOME}/.config/gtk-3.0/settings.ini" ]; then
					_ini_theme="$(awk -F= '/^[[:space:]]*gtk-theme-name[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/gtk-3.0/settings.ini" 2> "/dev/null" | head -n 1)"
					[ -n "${_ini_theme}" ] && export GTK_THEME="${_ini_theme}"
				fi
				[ -z "${GTK_THEME:-}" ] && export GTK_THEME="adw-gtk3-dark"
			fi
		fi
		export SAL_USE_VCLPLUGIN="gtk3"
		unset _raw_de _is_kde
	fi

	if command -v pgrep > "/dev/null" 2>&1 && pgrep -x emacs > "/dev/null" 2>&1; then
		_probe_ok=0
		if command -v timeout > "/dev/null" 2>&1; then
			timeout 2 emacsclient -e '(+ 1 1)' > "/dev/null" 2>&1 && _probe_ok=1 || _probe_ok=0
		else
			(
				command emacsclient -e '(+ 1 1)' > "/dev/null" 2>&1 &
				_probe_pid=$!
				(
					sleep 2 2> "/dev/null" || true
					kill -0 "${_probe_pid}" 2> "/dev/null" && kill -9 "${_probe_pid}" 2> "/dev/null" || true
				) &
				_wd_pid=$!
				wait "${_probe_pid}" 2> "/dev/null"
				_probe_ret=$?
				kill -9 "${_wd_pid}" 2> "/dev/null" || true
				wait "${_wd_pid}" 2> "/dev/null" || true
				exit "${_probe_ret}"
			) && _probe_ok=1 || _probe_ok=0
		fi
		if [ "${_probe_ok}" -eq 0 ]; then
			_ui_warn "Emacs daemon unresponsive (deadlock detected). Terminating hung process..."
			command pkill -9 -x emacs > "/dev/null" 2>&1 || true
			sleep 0.5 2> "/dev/null" || sleep 1 2> "/dev/null" || true
			[ -n "${EMACS_SOCKET_NAME:-}" ] && rm -f "${EMACS_SOCKET_NAME}" 2> "/dev/null" || true
		fi
		unset _probe_ok
	fi

	local _status=0
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if [ "$#" -eq 0 ]; then
			command emacsclient --create-frame --alternate-editor "" -n
			_status=$?
		else
			command emacsclient --create-frame --alternate-editor "" "$@"
			_status=$?
		fi
	else
		command emacsclient -t --alternate-editor "" "$@"
		_status=$?
	fi
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
	command -v emacsclient > "/dev/null" 2>&1 || { _ui_err "emacsclient not found."; return 127; }
	local _status=0
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if [ "$#" -eq 0 ]; then
			(command nohup emacsclient --create-frame --alternate-editor "" . < "/dev/null" > "/dev/null" 2>&1 &)
			_status=$?
		else
			(command nohup emacsclient --create-frame --alternate-editor "" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
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
	command -v emacsclient > "/dev/null" 2>&1 || command -v emacs > "/dev/null" 2>&1 || {
		_ui_err "emacs não encontrado no PATH."
		return 127
	}

	local _dir="${1:-.}"
	if [ -d "${_dir}" ]; then
		_dir="$(cd "${_dir}" && pwd)"
	else
		_dir="${PWD}"
	fi

	local _status=0
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if command -v emacsclient > "/dev/null" 2>&1; then
			(command nohup emacsclient --create-frame --alternate-editor "" \
				--eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
			_status=$?
		else
			(command nohup emacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
			_status=$?
		fi
	else
		if command -v emacsclient > "/dev/null" 2>&1; then
			command emacsclient -t --alternate-editor "" \
				--eval "(progn (cd \"${_dir}/\") (aweshell/new))"
			_status=$?
		else
			command emacs -nw --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
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

### --------------------------------
### GUI INTEGRATION
### --------------------------------
[ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/target/common/session.sh" ] && . "${SHELL_REPO_DIR}/target/common/session.sh"

if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
	if [ -z "${GTK_THEME:-}" ]; then
		if [ -n "${_DETECTED_GTK_THEME:-}" ]; then
			export GTK_THEME="${_DETECTED_GTK_THEME}"
		elif [ -z "${_DETECTED_GTK_THEME+x}" ]; then
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
	export GTK_APPLICATION_PREFER_DARK_THEME=1

	if command -v _propagate_session_theme_env > "/dev/null" 2>&1; then
		_propagate_session_theme_env
	fi

	_default_cursor_paths="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
	case ":${XCURSOR_PATH:-}:" in
		*":/usr/local/share/icons:"*) ;;
		*) export XCURSOR_PATH="${XCURSOR_PATH:+${XCURSOR_PATH}:}${_default_cursor_paths}" ;;
	esac
	unset _default_cursor_paths

	if [ -z "${XCURSOR_THEME:-}" ] || [ -z "${XCURSOR_SIZE:-}" ]; then
		_cursor_theme=""
		_cursor_size="${XCURSOR_SIZE:-24}"

		_uid="$(id -u 2> "/dev/null" || echo 1000)"
		if pgrep -u "${_uid}" -x plasmashell > "/dev/null" 2>&1 || pgrep -u "${_uid}" -x kwin_wayland > "/dev/null" 2>&1 || pgrep -u "${_uid}" -x kwin_x11 > "/dev/null" 2>&1; then
			if [ -f "${HOME}/.config/kcminputrc" ]; then
				_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
				_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
		elif pgrep -u "${_uid}" -x gnome-shell > "/dev/null" 2>&1; then
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x mate-session > "/dev/null" 2>&1; then
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.mate.peripherals-mouse cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x cinnamon > "/dev/null" 2>&1; then
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.cinnamon.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x xfce4-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x lxqt-session > "/dev/null" 2>&1; then
			_cursor_theme="breeze_cursors"
		elif pgrep -u "${_uid}" -x lxsession > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x budgie-wm > "/dev/null" 2>&1 || pgrep -u "${_uid}" -x budgie-panel > "/dev/null" 2>&1; then
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x gala > "/dev/null" 2>&1 || pgrep -u "${_uid}" -x wingpanel > "/dev/null" 2>&1; then
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x dde-desktop > "/dev/null" 2>&1 || pgrep -u "${_uid}" -x deepin-wm > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif pgrep -u "${_uid}" -x cosmic-comp > "/dev/null" 2>&1 || pgrep -u "${_uid}" -x cosmic-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif [ -n "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}" ]; then
			case "$(printf '%s\n' "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION}}" | tr '[:upper:]' '[:lower:]')" in
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
			for _cand in Adwaita breeze_cursors Bibata-Modern-Classic DMZ-White default; do
				for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
					if [ -d "${_p}/${_cand}/cursors" ]; then
						_cursor_theme="${_cand}"
						break 2
					fi
				done
			done
		fi

		[ -z "${_cursor_theme}" ] && _cursor_theme="default"
		[ -z "${_cursor_size}" ] && _cursor_size="24"
		[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_cursor_theme}"
		[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_cursor_size}"
		unset _cursor_theme _cursor_size _cand _p _uid
	fi
fi

### --------------------------------
### PYTHON ZERO-CRUFT POLICY
### --------------------------------
export PYTHONDONTWRITEBYTECODE=1
unset PYTHONPYCACHEPREFIX
