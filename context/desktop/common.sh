### ================================
### DESKTOP CONTEXT COMMON
### ================================

### --------------------------------
### Terminal Editors
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

open-neovim() {
	if [ "$#" -eq 0 ]; then
		nvim .
	else
		nvim "$@"
	fi
}
alias open-nvim="open-neovim"
alias on="open-neovim"

open-vim() {
	command -v vim > "/dev/null" 2>&1 || { _ui_err "vim not found."; return 127; }
	if [ "$#" -eq 0 ]; then
		command vim .
	else
		command vim "$@"
	fi
	local _status=$?
	_restore_tty_cursor
	return ${_status}
}
alias ov="open-vim"

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

open-micro() {
	if [ "$#" -eq 0 ]; then
		micro .
	else
		micro "$@"
	fi
}
alias om="open-micro"

### --------------------------------
### GUI Editors
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
### Emacs Daemon & Client
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
### GUI Integration
### --------------------------------
if [ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ]; then
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

	_default_cursor_paths="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
	case ":${XCURSOR_PATH:-}:" in
		*":/usr/local/share/icons:"*) ;;
		*) export XCURSOR_PATH="${XCURSOR_PATH:+${XCURSOR_PATH}:}${_default_cursor_paths}" ;;
	esac
	unset _default_cursor_paths

	if [ -z "${XCURSOR_THEME:-}" ] || [ -z "${XCURSOR_SIZE:-}" ]; then
		if [ -n "${_DETECTED_XCURSOR_THEME+x}" ] && [ -n "${_DETECTED_XCURSOR_SIZE+x}" ]; then
			[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_DETECTED_XCURSOR_THEME}"
			[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_DETECTED_XCURSOR_SIZE}"
		else
			_cursor_theme=""
			_cursor_size=""

			if [ -z "${_cursor_theme}" ] && [ -f "${HOME}/.icons/default/index.theme" ]; then
				_cursor_theme=$(awk -F= '/^[[:space:]]*Inherits[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.icons/default/index.theme" 2> "/dev/null")
			fi
			if [ -z "${_cursor_theme}" ] && [ -f "${HOME}/.config/kcminputrc" ]; then
				_cursor_theme=$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")
				[ -z "${_cursor_size}" ] && _cursor_size=$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")
			fi
			if [ -z "${_cursor_theme}" ] && [ -f "${HOME}/.config/kdedefaults/kcminputrc" ]; then
				_cursor_theme=$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kdedefaults/kcminputrc" 2> "/dev/null")
			fi
			if [ -z "${_cursor_theme}" ] && [ -f "${HOME}/.config/gtk-4.0/settings.ini" ]; then
				_cursor_theme=$(awk -F= '/^[[:space:]]*gtk-cursor-theme-name[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/gtk-4.0/settings.ini" 2> "/dev/null")
				[ -z "${_cursor_size}" ] && _cursor_size=$(awk -F= '/^[[:space:]]*gtk-cursor-theme-size[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/gtk-4.0/settings.ini" 2> "/dev/null")
			fi
			if [ -z "${_cursor_theme}" ] && command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")
				[ -z "${_cursor_size}" ] && _cursor_size=$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")
			fi
			if [ -z "${_cursor_theme}" ]; then
				case "${XDG_CURRENT_DESKTOP:-}" in
					*KDE*)   _cursor_theme="breeze_cursors" ;;
					*GNOME*) _cursor_theme="Adwaita" ;;
					*)       _cursor_theme="default" ;;
				esac
			fi

			[ -z "${_cursor_size}" ] && _cursor_size="24"
			[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_cursor_theme}"
			[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_cursor_size}"
			if command -v _cache_write > "/dev/null" 2>&1; then
				_cache_write "xcursor_theme" "${_cursor_theme}"
				_cache_write "xcursor_size" "${_cursor_size}"
			fi
			unset _cursor_theme _cursor_size
		fi
	fi
fi

### --------------------------------
### Python Zero-Cruft Policy
### --------------------------------
export PYTHONDONTWRITEBYTECODE=1
unset PYTHONPYCACHEPREFIX
