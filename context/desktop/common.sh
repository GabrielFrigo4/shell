### ================================
### DESKTOP CONTEXT COMMON
### ================================

### --------------------------------
### Terminal Editors
### --------------------------------
_restore_tty_cursor() {
	if [ -t 1 ]; then
		if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
			if [ "${TERM:-}" = "linux" ] && [ "${_DETECTED_OS-$(_detect_os)}" = "linux" ]; then
				echo -n $'\e%G\e[?16;238;0c'
			else
				echo -n $'\e]112\7'
			fi
		else
			echo -n $'\e[1 q\e]112\7'
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
}
emacs-start() {
	command -v emacs > "/dev/null" 2>&1 || { _ui_err "emacs not found."; return 127; }
	command emacs --daemon="${EMACS_SOCKET_NAME}"
}
emacs-restart() {
	emacs-kill && emacs-start
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
		_restore_tty_cursor
	fi
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
	if [ "$#" -eq 0 ]; then
		emacs-client
	else
		command emacsclient "$@"
		local _status=$?
		_restore_tty_cursor
		return ${_status}
	fi
}
emacs() {
	local _status=0
	case "${1:-}" in
		client)
			shift 1
			emacs-client "$@"
			_status=$?
			;;
		-nw | --no-window-system | -t | --tty)
			shift 1
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
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if [ "$#" -eq 0 ]; then
			(command nohup emacsclient --create-frame --alternate-editor "" . < "/dev/null" > "/dev/null" 2>&1 &)
		else
			(command nohup emacsclient --create-frame --alternate-editor "" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
		fi
	else
		emacs-open-nw "$@"
	fi
}
emacs-open-nw() {
	if [ "$#" -eq 0 ]; then
		emacs-nw .
	else
		emacs-nw "$@"
	fi
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

	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if command -v emacsclient > "/dev/null" 2>&1; then
			(command nohup emacsclient --create-frame --alternate-editor "" \
				--eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
		else
			(command nohup emacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))" < "/dev/null" > "/dev/null" 2>&1 &)
		fi
	else
		if command -v emacsclient > "/dev/null" 2>&1; then
			command emacsclient -t --alternate-editor "" \
				--eval "(progn (cd \"${_dir}/\") (aweshell/new))"
		else
			command emacs -nw --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
		fi
		local _status=$?
		_restore_tty_cursor
		return ${_status}
	fi
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
### Remote Servers
### --------------------------------
_resolve_vault_ssh_key() {
	_explicit_key="${1:-}"
	_key_name="${2:-}"

	if [ -n "${_explicit_key}" ] && [ -f "${_explicit_key}" ]; then
		chmod 0600 "${_explicit_key}" 2> "/dev/null" || true
		echo "${_explicit_key}"
		return 0
	fi

	for _candidate in \
		"${VAULT_DIR:-}/keys/${_key_name}" \
		"${XDG_DATA_HOME:-${HOME}/.local/share}/vault/keys/${_key_name}" \
		"${XDG_CONFIG_HOME:-${HOME}/.config}/vault/keys/${_key_name}" \
		"${HOME}/.vault/keys/${_key_name}" \
		"/usr/local/share/vault/keys/${_key_name}"; do
		if [ -n "${_candidate}" ] && [ -f "${_candidate}" ]; then
			chmod 0600 "${_candidate}" 2> "/dev/null" || true
			echo "${_candidate}"
			return 0
		fi
	done

	return 1
}

personal-server() {
	_ip="${PERSONAL_SERVER_IP:-144.22.210.65}"
	_user="${PERSONAL_SERVER_USER:-ubuntu}"
	_key="$(_resolve_vault_ssh_key "${PERSONAL_SERVER_KEY:-}" "ssh-key-personal-server.key")"

	_ssh_opts=""
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		_ssh_opts="-o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	if [ -n "${_key}" ]; then
		export PERSONAL_SERVER_KEY="${_key}"
		ssh ${_ssh_opts} -i "${_key}" "${_user}@${_ip}" "$@"
	else
		ssh ${_ssh_opts} "${_user}@${_ip}" "$@"
	fi
}

venture-server() {
	_ip="${VENTURE_SERVER_IP:-137.131.238.161}"
	_user="${VENTURE_SERVER_USER:-ubuntu}"
	_key="$(_resolve_vault_ssh_key "${VENTURE_SERVER_KEY:-}" "ssh-key-venture-server.key")"

	_ssh_opts=""
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		_ssh_opts="-o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	if [ -n "${_key}" ]; then
		export VENTURE_SERVER_KEY="${_key}"
		ssh ${_ssh_opts} -i "${_key}" "${_user}@${_ip}" "$@"
	else
		ssh ${_ssh_opts} "${_user}@${_ip}" "$@"
	fi
}

### --------------------------------
### Mobile Device Management
### --------------------------------
_find_desktop_device() {
	local _rt _found

	for _rt in "${XDG_RUNTIME_DIR}/gvfs" "/var/run/user/$(id -u)/gvfs" "/run/user/$(id -u)/gvfs" "${HOME}/.gvfs"; do
		[ -d "${_rt}" ] || continue
		_found=$(command find "${_rt}" -maxdepth 1 \( -name "mtp:*" -o -name "*mtp*" -o -name "sftp:*" \) 2> "/dev/null" | command head -n 1)
		[ -n "${_found}" ] && [ -d "${_found}" ] && echo "${_found}" && return 0
	done

	for _rt in "${XDG_RUNTIME_DIR}" "/var/run/user/$(id -u)" "/run/user/$(id -u)" "/tmp"; do
		[ -d "${_rt}" ] || continue
		_found=$(command find "${_rt}" -maxdepth 4 -path "*kio-fuse*/*" \( -name "*mtp*" -o -name "*kdeconnect*" \) 2> "/dev/null" | command head -n 1)
		[ -n "${_found}" ] && [ -d "${_found}" ] && echo "${_found}" && return 0
	done

	return 0
}

_find_kdeconnect_device() {
	command -v kdeconnect-cli > "/dev/null" 2>&1 || return 0
	local _dev _mount_dir _rt _found

	_dev="$(command kdeconnect-cli -a --id-only 2> "/dev/null" | command head -n 1)"
	[ -z "${_dev}" ] && _dev="$(command kdeconnect-cli --list-available --id-only 2> "/dev/null" | command head -n 1)"
	[ -z "${_dev}" ] && _dev="$(command kdeconnect-cli -a 2> "/dev/null" | command grep -oE '[a-zA-Z0-9_-]{8,}' | command head -n 1)"
	[ -z "${_dev}" ] && return 0

	command kdeconnect-cli -d "${_dev}" --mount > "/dev/null" 2>&1 || true

	_mount_dir=$(command mount 2> "/dev/null" | command grep -iE 'kdeconnect|sshfs' | command awk '{for(i=1;i<=NF;i++) if($i=="on") print $(i+1)}' | command head -n 1)
	[ -n "${_mount_dir}" ] && [ -d "${_mount_dir}" ] && echo "${_mount_dir}" && return 0

	for _rt in "${XDG_RUNTIME_DIR}" "/var/run/user/$(id -u)" "/run/user/$(id -u)" "/tmp"; do
		[ -d "${_rt}" ] || continue
		_found=$(command find "${_rt}" -maxdepth 4 \( -path "*kio-fuse*/*" -o -path "*kdeconnect*/*" -o -name "*${_dev}*" \) 2> "/dev/null" | command head -n 1)
		[ -n "${_found}" ] && [ -d "${_found}" ] && echo "${_found}" && return 0
	done

	return 0
}

_open_file_manager() {
	[ -z "${1}" ] && return 0
	[ -z "${DISPLAY}" ] && [ -z "${WAYLAND_DISPLAY}" ] && return 0
	local _opener

	echo "📂 Abrindo gerenciador de arquivos..."
	if [ -n "${FILEMANAGER}" ] && command -v "${FILEMANAGER}" > "/dev/null" 2>&1; then
		(nohup "${FILEMANAGER}" "${1}" < "/dev/null" > "/dev/null" 2>&1 &)
		return 0
	fi

	for _opener in xdg-open gio nautilus dolphin thunar nemo caja pcmanfm-qt pcmanfm; do
		if command -v "${_opener}" > "/dev/null" 2>&1; then
			(nohup "${_opener}" "${1}" < "/dev/null" > "/dev/null" 2>&1 &)
			return 0
		fi
	done
}

mount-device() {
	local _target="${HOME}/Device"
	local _desktop_dir

	if [ -L "${_target}" ]; then
		echo "📱 Dispositivo já está acessível em ~/Device (vinculado a $(readlink "${_target}"))."
		_open_file_manager "${_target}"
		return 0
	elif command mount 2> "/dev/null" | command grep -qF " ${_target} "; then
		echo "📱 Dispositivo já está montado em ~/Device."
		_open_file_manager "${_target}"
		return 0
	fi

	_desktop_dir="$(_find_desktop_device)"
	[ -z "${_desktop_dir}" ] && _desktop_dir="$(_find_kdeconnect_device)"

	if [ -n "${_desktop_dir}" ]; then
		if [ -d "${_desktop_dir}/storage/emulated/0" ]; then
			_desktop_dir="${_desktop_dir}/storage/emulated/0"
		elif [ -d "${_desktop_dir}/sdcard" ]; then
			_desktop_dir="${_desktop_dir}/sdcard"
		fi
		[ -d "${_target}" ] && [ ! -L "${_target}" ] && command rmdir "${_target}" 2> "/dev/null"
		command ln -sfn "${_desktop_dir}" "${_target}"
		echo "✅ Dispositivo conectado via KDE/GNOME e vinculado a ~/Device!"
		_open_file_manager "${_target}"
		return 0
	fi

	if command -v "adbfs" > "/dev/null" 2>&1 && command adb devices 2> "/dev/null" | command grep -qE '\bdevice\b'; then
		command mkdir -p "${_target}"
		echo "📱 Montando dispositivo Android via ADB em ~/Device..."
		if adbfs "${_target}" > "/dev/null" 2>&1 || _as_root adbfs -o "allow_other,uid=$(id -u),gid=$(id -g)" "${_target}" > "/dev/null" 2>&1; then
			echo "✅ Dispositivo Android montado com sucesso em ~/Device via ADB!"
			_open_file_manager "${_target}"
			return 0
		fi
	fi

	[ -d "${_target}" ] && [ ! -L "${_target}" ] && command rmdir "${_target}" 2> "/dev/null"
	echo "❌ Nenhum dispositivo encontrado via KDE/GNOME (MTP/GSConnect), KDE Connect ou ADB."
	echo ""
	echo "💡 Formas de conexão recomendadas:"
	echo "   1. Cabo USB: Conecte via GNOME/KDE (MTP nativo) ou ative a 'Depuração USB' (ADB)."
	echo "   2. Sem fio: Conecte via KDE Connect (KDE) ou GSConnect (GNOME)."
	return 1
}

_unmount_target() {
	if [ "$(_detect_os)" = "freebsd" ]; then
		command umount "${1}" 2> "/dev/null" || _as_root umount "${1}" 2> "/dev/null" || true
	else
		command fusermount3 -u "${1}" 2> "/dev/null" || \
		command fusermount -u "${1}" 2> "/dev/null" || \
		command umount "${1}" 2> "/dev/null" || \
		_as_root umount "${1}" 2> "/dev/null" || true
	fi
}

umount-device() {
	local _target="${HOME}/Device"
	local _kde_dev

	if [ -L "${_target}" ]; then
		command rm -f "${_target}"
		echo "✅ Vínculo ~/Device removido com sucesso."
		echo "🔒 Dispositivo desvinculado do shell."
		return 0
	fi

	if ! command mount 2> "/dev/null" | command grep -qF " ${_target} "; then
		if [ -d "${_target}" ]; then
			command rmdir "${_target}" 2> "/dev/null" && echo "🧹 Diretório não utilizado ~/Device foi removido."
		fi
		echo "ℹ️ O diretório ~/Device não está montado."
		return 0
	fi

	echo "🔌 Desmontando ~/Device com segurança..."

	if command -v kdeconnect-cli > "/dev/null" 2>&1; then
		_kde_dev="$(command kdeconnect-cli -a --id-only 2> "/dev/null" | command head -n 1)"
		[ -n "${_kde_dev}" ] && command kdeconnect-cli -d "${_kde_dev}" --unmount > "/dev/null" 2>&1 || true
	fi

	_unmount_target "${_target}"

	if ! command mount 2> "/dev/null" | command grep -qF " ${_target} "; then
		[ -d "${_target}" ] && command rmdir "${_target}" 2> "/dev/null" || true
		echo "✅ Dispositivo desmontado e pasta ~/Device removida com sucesso."
		echo "🔒 É seguro desconectar o cabo USB."
		return 0
	fi

	echo "❌ Não foi possível desmontar ~/Device."
	echo "💡 Verifique se existem programas, terminais ou gerenciadores de arquivos abertos dentro de ~/Device."
	return 1
}

### --------------------------------
### Device Aliases
### --------------------------------
alias mntdev="mount-device"
alias mdev="mount-device"
alias umntdev="umount-device"
alias umdev="umount-device"
alias unmount-device="umount-device"

if ! command -v udev > "/dev/null" 2>&1; then
	alias udev="umount-device"
fi

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
		elif [ -z "${_DETECTED_QT_THEME+x}" ]; then
			_qt_style="$(_detect_qt_theme)"
			[ -n "${_qt_style}" ] && export QT_STYLE_OVERRIDE="${_qt_style}"
			unset _qt_style
		fi
	fi

	if [ -z "${QT_QPA_PLATFORMTHEME:-}" ]; then
		if [ -n "${_DETECTED_QT_PLATFORM_THEME:-}" ]; then
			export QT_QPA_PLATFORMTHEME="${_DETECTED_QT_PLATFORM_THEME}"
		elif [ -z "${_DETECTED_QT_PLATFORM_THEME+x}" ]; then
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
### Graphical Session Launchers
### --------------------------------
_exec_wayland() {
	if [ "$(_detect_os)" = "freebsd" ]; then
		if command -v ck-launch-session > "/dev/null" 2>&1; then
			if command -v dbus-launch > "/dev/null" 2>&1; then
				exec ck-launch-session dbus-launch --exit-with-session "$@"
			fi
			exec ck-launch-session "$@"
		fi
		if command -v dbus-run-session > "/dev/null" 2>&1; then
			exec dbus-run-session "$@"
		fi
		exec "$@"
	fi

	if [ -S "/run/user/$(id -u)/bus" ]; then
		DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
		export DBUS_SESSION_BUS_ADDRESS
		exec "$@"
	fi

	if command -v dbus-run-session > "/dev/null" 2>&1; then
		exec dbus-run-session "$@"
	elif command -v dbus-launch > "/dev/null" 2>&1; then
		exec dbus-launch --exit-with-session "$@"
	fi

	exec "$@"
}

_resolve_vt_arg() {
	local _cur_tty="${1:-$(tty 2> "/dev/null" || true)}"
	case "${_cur_tty}" in
		/dev/ttyv[0-9a-fA-F]*)
			local _hex="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/ttyv\([0-9a-fA-F]\{1,2\}\)$#\1#p')"
			[ -n "${_hex}" ] && echo "vt$(( 0x${_hex} + 1 ))"
			;;
		/dev/ttyC[0-9a-fA-F]*)
			local _hex="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/ttyC\([0-9a-fA-F]\{1,2\}\)$#\1#p')"
			[ -n "${_hex}" ] && echo "vt$(( 0x${_hex} + 1 ))"
			;;
		/dev/tty[0-9]*)
			local _num="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/tty\([0-9]\{1,3\}\)$#\1#p')"
			[ -n "${_num}" ] && echo "vt${_num}"
			;;
	esac
}

_resolve_free_display() {
	if [ -n "${DISPLAY:-}" ]; then
		local _num="${DISPLAY#:}"
		_num="${_num%%.*}"
		if [ -e "/tmp/.X${_num}-lock" ] || [ -S "/tmp/.X11-unix/X${_num}" ]; then
			echo "${DISPLAY}"
			return 0
		fi
	fi

	local _d=0
	while true; do
		if [ ! -e "/tmp/.X${_d}-lock" ] && [ ! -S "/tmp/.X11-unix/X${_d}" ]; then
			if [ -r "/proc/net/unix" ] && command grep -q "/tmp/.X11-unix/X${_d}" "/proc/net/unix" 2> "/dev/null"; then
				:
			else
				echo ":${_d}"
				return 0
			fi
		fi
		_d=$((_d + 1))
	done
}

_exec_x11() {
	command -v startx > "/dev/null" 2>&1 || command -v xinit > "/dev/null" 2>&1 || return 1

	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0
	local _display=""
	if [ "${_had_display}" -eq 1 ]; then
		_display="${DISPLAY}"
	else
		_display="$(_resolve_free_display)"
	fi
	export DISPLAY="${_display}"
	export XORG_RUN_AS_USER_OK=1
	_setup_cursor_env

	local _theme_flavor="$(_detect_desktop_theme)"
	case "${_theme_flavor}" in
		gnome|adwaita)
			export GTK_THEME="Adwaita:dark"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			;;
		kde)
			export GTK_THEME="Breeze-Dark"
			export QT_STYLE_OVERRIDE="Breeze"
			;;
		xfce)
			export GTK_THEME="Greybird-dark"
			;;
	esac

	if [ -f "${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
		xrdb -merge "${HOME}/.Xresources" 2> "/dev/null" || true
	fi

	local _vt_arg="$(_resolve_vt_arg)"

	if command -v startx > "/dev/null" 2>&1; then
		startx "$@" -- "${_display}" ${_vt_arg} > "/dev/null" 2>&1
	elif command -v xinit > "/dev/null" 2>&1; then
		xinit "$@" -- "${_display}" ${_vt_arg} > "/dev/null" 2>&1
	fi

	if [ "${_had_display}" -eq 0 ]; then
		unset DISPLAY
	fi
}

_has_wayland() {
	[ -n "${WAYLAND_DISPLAY:-}" ] && return 0

	local _session_dir
	for _session_dir in /usr/share/wayland-sessions /usr/local/share/wayland-sessions "${XDG_DATA_HOME:-${HOME}/.local/share}/wayland-sessions"; do
		if [ -d "${_session_dir}" ] && [ -n "$(command ls -A "${_session_dir}" 2> "/dev/null")" ]; then
			return 0
		fi
	done

	if [ -f "${HOME}/.local/lib/libewm_core.so" ] || [ -f "${HOME}/.local/lib/libewm.so" ]; then
		return 0
	fi

	local _compositor _micro _desktops _tilings _emacs _compositors
	_micro="cage river labwc sway"
	_desktops="gnome-shell startplasma-wayland cosmic-session"
	_tilings="Hyprland hyprland niri wayfire dwl hikari weston"
	_emacs="ewm"
	_compositors="${_micro} ${_desktops} ${_tilings} ${_emacs}"

	for _compositor in ${_compositors}; do
		if command -v "${_compositor}" > "/dev/null" 2>&1; then
			return 0
		fi
	done

	return 1
}

_has_x11() {
	[ -n "${DISPLAY:-}" ] && return 0

	command -v Xorg > "/dev/null" 2>&1 && return 0
	command -v X > "/dev/null" 2>&1 && return 0
	command -v xinit > "/dev/null" 2>&1 && return 0
	command -v startx > "/dev/null" 2>&1 && return 0

	local _session_dir
	for _session_dir in /usr/share/xsessions /usr/local/share/xsessions /usr/X11R6/share/xsessions "${XDG_DATA_HOME:-${HOME}/.local/share}/xsessions"; do
		if [ -d "${_session_dir}" ] && [ -n "$(command ls -A "${_session_dir}" 2> "/dev/null")" ]; then
			return 0
		fi
	done

	return 1
}

_dispatch_display_server() {
	local _base_target="${1:-}"
	[ "$#" -ge 1 ] && shift

	if _has_wayland && command -v "${_base_target}-wayland" > "/dev/null" 2>&1; then
		"${_base_target}-wayland" "$@"
	elif _has_x11 && command -v "${_base_target}-x11" > "/dev/null" 2>&1; then
		"${_base_target}-x11" "$@"
	else
		_ui_err "Nenhum backend gráfico suportado (Wayland ou X11) disponível para '${_base_target}'."
		return 127
	fi
}

_try_wayland() {
	local _bin
	for _bin in "$@"; do
		if command -v "${_bin}" > "/dev/null" 2>&1; then
			if [ "${_bin}" = "gnome-session" ]; then
				export XDG_SESSION_TYPE="wayland"
				_exec_wayland gnome-session --session=gnome
			elif [ "${_bin}" = "gnome-shell" ]; then
				export XDG_SESSION_TYPE="wayland"
				_exec_wayland gnome-shell --wayland
			else
				_exec_wayland "${_bin}"
			fi
		fi
	done
	return 1
}

_try_xorg() {
	local _bin
	for _bin in "$@"; do
		if command -v "${_bin}" > "/dev/null" 2>&1; then
			if [ "${_bin}" = "gnome-session" ]; then
				_exec_x11 "$(command -v gnome-session)" --session=gnome-xorg
			elif [ "${_bin}" = "qtile" ]; then
				_exec_x11 "$(command -v qtile)" start
			else
				_exec_x11 "$(command -v "${_bin}")"
			fi
		fi
	done
	return 1
}

_start_wayland() {
	case "${1}" in
		kde|plasma)    _try_wayland startplasma-wayland plasma-wayland-session ;;
		gnome)         _try_wayland gnome-session gnome-shell ;;
		hyprland|hypr) _try_wayland Hyprland hyprland ;;
		sway)          _try_wayland sway ;;
		cosmic)        _try_wayland cosmic-session start-cosmic ;;
		niri)          _try_wayland niri-session niri ;;
		river)         _try_wayland river ;;
		wayfire)       _try_wayland wayfire ;;
		labwc)         _try_wayland labwc ;;
		dwl)           _try_wayland dwl ;;
		hikari)        _try_wayland hikari ;;
		weston)        _try_wayland weston ;;
		"")            _try_wayland startplasma-wayland plasma-wayland-session gnome-session Hyprland hyprland sway cosmic-session start-cosmic niri-session niri river wayfire labwc dwl hikari weston ;;
		*)             _try_wayland "${1}" ;;
	esac
}

_start_xorg() {
	command -v startx > "/dev/null" 2>&1 || command -v xinit > "/dev/null" 2>&1 || return 1

	case "${1}" in
		kde|plasma) _try_xorg startplasma-x11 startkde ;;
		gnome)      _try_xorg gnome-session ;;
		xfce|xfce4) _try_xorg startxfce4 ;;
		mate)       _try_xorg mate-session ;;
		cinnamon)   _try_xorg cinnamon-session ;;
		lxqt)       _try_xorg startlxqt ;;
		lxde)       _try_xorg startlxde ;;
		i3)         _try_xorg i3 ;;
		bspwm)      _try_xorg bspwm ;;
		awesome)    _try_xorg awesome ;;
		openbox)    _try_xorg openbox-session openbox ;;
		dwm)        _try_xorg dwm ;;
		xmonad)     _try_xorg xmonad ;;
		qtile)      _try_xorg qtile ;;
		fluxbox)    _try_xorg startfluxbox fluxbox ;;
		"")
			if [ -f "${HOME}/.xinitrc" ] || [ -f "${HOME}/.xsession" ] || [ -f "${HOME}/.Xclients" ]; then
				_exec_x11
			fi
			_try_xorg startplasma-x11 startxfce4 gnome-session mate-session cinnamon-session startlxqt startlxde i3 bspwm awesome openbox-session dwm xmonad qtile startfluxbox
			_exec_x11
			;;
		*)
			_try_xorg "${1}"
			;;
	esac
}

start-session() {
	if [ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ]; then
		echo "⚠️ Uma sessão gráfica já está ativa (${WAYLAND_DISPLAY:-${DISPLAY}})."
	fi

	local _type="${1}"
	local _env="${2}"

	case "${_type}" in
		way|wayland)
			_start_wayland "${_env}" || {
				echo "❌ Nenhum compositor ou ambiente Wayland '${_env:-detectado}' foi encontrado."
				return 1
			}
			;;
		xorg|x11)
			_start_xorg "${_env}" || {
				echo "❌ Nenhum ambiente ou gerenciador Xorg '${_env:-detectado}' foi encontrado."
				return 1
			}
			;;
		"")
			_start_wayland "" || _start_xorg "" || {
				echo "❌ Nenhum ambiente gráfico (Wayland ou Xorg) foi encontrado no sistema."
				return 1
			}
			;;
		*)
			_start_wayland "${_type}" || _start_xorg "${_type}" || {
				echo "❌ Ambiente '${_type}' não encontrado para Wayland ou Xorg."
				return 1
			}
			;;
	esac
}

### --------------------------------
### Desktop Window Managers
### --------------------------------
window-manager-wayland() {
	start-session way "$@"
}
alias wwm="window-manager-wayland"
alias way="window-manager-wayland"
alias wayland="window-manager-wayland"
alias start-way="window-manager-wayland"
alias start-wayland="window-manager-wayland"

window-manager-x11() {
	start-session xorg "$@"
}
alias xwm="window-manager-x11"
alias xorg="window-manager-x11"
alias x11="window-manager-x11"
alias start-xorg="window-manager-x11"
alias start-x11="window-manager-x11"

window-manager() {
	_dispatch_display_server "window-manager" "$@"
}
alias wm="window-manager"
alias win="window-manager"
alias win-man="window-manager"
alias window="window-manager"

### --------------------------------
### Ephemeral Session Helpers
### --------------------------------
_setup_cursor_env() {
	export XCURSOR_PATH="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
	export WLR_NO_HARDWARE_CURSORS=1

	local _candidate=""
	local _found_theme=""
	for _candidate in "${XCURSOR_THEME:-}" "Adwaita" "breeze_cursors" "Bibata-Modern-Classic" "default"; do
		[ -z "${_candidate}" ] && continue
		for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
			if [ -d "${_p}/${_candidate}/cursors" ]; then
				_found_theme="${_candidate}"
				break 2
			fi
		done
	done

	[ -z "${_found_theme}" ] && _found_theme="default"

	local _target_size="${XCURSOR_SIZE:-24}"

	export XCURSOR_THEME="${_found_theme}"
	export XCURSOR_SIZE="${_target_size}"

	if [ ! -f "${HOME}/.icons/default/index.theme" ]; then
		mkdir -p "${HOME}/.icons/default"
		printf '[Icon Theme]\nInherits=%s\n' "${_found_theme}" > "${HOME}/.icons/default/index.theme" 2> "/dev/null" || true
	fi

	if command -v xrdb > "/dev/null" 2>&1; then
		printf "Xcursor.theme: %s\nXcursor.size: %s\n" "${_found_theme}" "${_target_size}" | xrdb -merge - 2> "/dev/null" || true
	fi
}

_detect_desktop_theme() {
	if [ -n "${1:-}" ]; then
		case "$1" in
			gnome|kde|xfce|mate|cinnamon|adwaita) echo "$1"; return 0 ;;
		esac
	fi

	if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
		case "$(printf '%s\n' "${XDG_CURRENT_DESKTOP}" | tr '[:upper:]' '[:lower:]')" in
			*gnome*) echo "gnome"; return 0 ;;
			*kde*|*plasma*) echo "kde"; return 0 ;;
			*cinnamon*) echo "cinnamon"; return 0 ;;
			*mate*) echo "mate"; return 0 ;;
			*xfce*) echo "xfce"; return 0 ;;
		esac
	fi

	if command -v gnome-shell > "/dev/null" 2>&1 || [ -d "/usr/share/gnome" ]; then
		echo "gnome"
	elif command -v startplasma-wayland > "/dev/null" 2>&1 || command -v plasmashell > "/dev/null" 2>&1 || [ -d "/usr/share/plasma" ]; then
		echo "kde"
	elif command -v cinnamon > "/dev/null" 2>&1 || [ -d "/usr/share/cinnamon" ]; then
		echo "cinnamon"
	elif command -v mate-session > "/dev/null" 2>&1 || [ -d "/usr/share/mate" ]; then
		echo "mate"
	elif command -v xfce4-session > "/dev/null" 2>&1 || [ -d "/usr/share/xfce4" ]; then
		echo "xfce"
	else
		echo "adwaita"
	fi
}

_wayland_session_env() {
	local _target_flavor="${1:-}"

	export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
	if [ ! -d "${XDG_RUNTIME_DIR}" ]; then
		mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"
	fi

	export XKB_DEFAULT_LAYOUT="br"
	export XKB_DEFAULT_MODEL="abnt2"
	export WLR_KEYBOARD_REPEAT_DELAY=200
	export WLR_KEYBOARD_REPEAT_RATE=50

	export GDK_BACKEND="wayland,x11,*"
	export CLUTTER_BACKEND="wayland"
	export SDL_VIDEODRIVER="wayland"
	export MOZ_ENABLE_WAYLAND=1
	export ELECTRON_OZONE_PLATFORM_HINT="wayland"

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	case "${_theme_flavor}" in
		gnome|adwaita)
			export XDG_CURRENT_DESKTOP="GNOME"
			export GTK_THEME="Adwaita:dark"
			export QT_QPA_PLATFORM="wayland;xcb"
			export QT_QPA_PLATFORMTHEME="gnome"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
		kde)
			export XDG_CURRENT_DESKTOP="KDE"
			export GTK_THEME="Breeze-Dark"
			export QT_QPA_PLATFORM="wayland"
			export QT_QPA_PLATFORMTHEME="kde"
			export QT_STYLE_OVERRIDE="Breeze"
			export XCURSOR_THEME="breeze_cursors"
			;;
		cinnamon)
			export XDG_CURRENT_DESKTOP="X-Cinnamon"
			export GTK_THEME="Mint-Y-Dark"
			export QT_QPA_PLATFORM="wayland;xcb"
			export QT_QPA_PLATFORMTHEME="gtk3"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
		mate)
			export XDG_CURRENT_DESKTOP="MATE"
			export GTK_THEME="Yaru-MATE-dark"
			export QT_QPA_PLATFORM="wayland;xcb"
			export QT_QPA_PLATFORMTHEME="gtk3"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
		xfce)
			export XDG_CURRENT_DESKTOP="XFCE"
			export GTK_THEME="Greybird-dark"
			export QT_QPA_PLATFORM="wayland;xcb"
			export QT_QPA_PLATFORMTHEME="gtk3"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
	esac

	_setup_cursor_env
}

_freebsd_vt_bounce() {
	if [ "$(_detect_os)" = "freebsd" ]; then
		local _cur_tty="$(tty 2> "/dev/null" || true)"
		case "${_cur_tty}" in
			/dev/ttyv[0-9a-fA-F]*)
				local _hex="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/ttyv\([0-9a-fA-F]\{1,2\}\)$#\1#p')"
				if [ -n "${_hex}" ]; then
					local _vt_idx=$(( 0x${_hex} + 1 ))
					local _target_vt=1
					[ "${_vt_idx}" -eq 1 ] && _target_vt=2
					command vidcontrol -s "${_target_vt}" < "${_cur_tty}" 2> "/dev/null" || true
					command vidcontrol -s "${_vt_idx}" < "${_cur_tty}" 2> "/dev/null" || printf '\x1bc'
				fi
				;;
		esac
	fi
}

_is_terminal_app() {
	local _target="${1:-}"
	[ -z "${_target}" ] && return 0

	local _base="${_target##*/}"
	local _bin_path=""
	if [ -f "${_target}" ] && [ -x "${_target}" ]; then
		_bin_path="${_target}"
	else
		_bin_path="$(command -v "${_base}" 2> "/dev/null" || true)"
	fi
	[ -z "${_bin_path}" ] && return 0

	# 1. Padrão XDG Desktop Entry (Freedesktop Specification)
	local _xdg_dir _desktop_file
	for _xdg_dir in /usr/share/applications /usr/local/share/applications "${XDG_DATA_HOME:-${HOME}/.local/share}/applications" /var/lib/flatpak/exports/share/applications; do
		[ -d "${_xdg_dir}" ] || continue
		for _desktop_file in "${_xdg_dir}/${_base}.desktop" "${_xdg_dir}/"*".${_base}.desktop"; do
			[ -f "${_desktop_file}" ] || continue
			if command grep -q -E "^Exec=([^ ]*/|)${_base}( |$)" "${_desktop_file}" 2> "/dev/null"; then
				if command grep -q "^Terminal=true" "${_desktop_file}" 2> "/dev/null"; then
					return 0
				elif command grep -q "^Type=Application" "${_desktop_file}" 2> "/dev/null"; then
					return 1
				fi
			fi
		done
	done

	# Resolver links simbólicos para atingir o executável canônico
	if command -v realpath > "/dev/null" 2>&1; then
		_bin_path="$(command realpath "${_bin_path}" 2> "/dev/null" || echo "${_bin_path}")"
	elif command -v readlink > "/dev/null" 2>&1; then
		_bin_path="$(command readlink -f "${_bin_path}" 2> "/dev/null" || echo "${_bin_path}")"
	fi

	# 2. Introspecção de Seção Dinâmica ELF (Zero Falsos Positivos)
	if [ -f "${_bin_path}" ] && command -v readelf > "/dev/null" 2>&1; then
		local _needed_libs
		_needed_libs="$(command readelf -d "${_bin_path}" 2> "/dev/null" | command grep "(NEEDED)" | command sed -n 's/.*\[\(lib[^]]*\)\].*/\1/p' || true)"
		if [ -n "${_needed_libs}" ]; then
			if printf '%s\n' "${_needed_libs}" | command grep -qiE "libwayland-client|libX11|libxcb|libgtk|libgdk|libQt|libfltk|libwx|libFOX|libglfw|libSDL|libraylib|libsfml|liballegro|libGL\.|libEGL\.|libGLES|libvulkan" > "/dev/null" 2>&1; then
				return 1
			fi
			return 0
		fi
	fi

	# 3. Scripts de Texto com Shebang POSIX
	if [ -f "${_bin_path}" ]; then
		local _first_line
		_first_line="$(command head -n 1 "${_bin_path}" 2> "/dev/null" || true)"
		case "${_first_line}" in
			"#!"*sh*)
				return 0
				;;
			"#!"*python*|"#!"*node*|"#!"*ruby*|"#!"*perl*)
				if command grep -q -E "(tkinter|PyQt|PySide|gi\.repository\.Gtk|pygame|wx)" "${_bin_path}" 2> "/dev/null"; then
					return 1
				fi
				return 0
				;;
		esac
	fi

	# 4. Fallback Seguro: sem evidências de GUI nativa, precisa de terminal
	return 0
}

### --------------------------------
### Ephemeral Graphical Launchers
### --------------------------------
graphical-launcher-wayland() {
	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1

	local _flavor=""
	local _had_wayland=1
	[ -z "${WAYLAND_DISPLAY:-}" ] && _had_wayland=0
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)
				_flavor="gnome"
				shift
				;;
			-k|--kde)
				_flavor="kde"
				shift
				;;
			-x|--xfce)
				_flavor="xfce"
				shift
				;;
			-m|--mate)
				_flavor="mate"
				shift
				;;
			-c|--cinnamon)
				_flavor="cinnamon"
				shift
				;;
			--)
				shift
				break
				;;
			-*)
				break
				;;
			*)
				break
				;;
		esac
	done

	local _app="${1:-foot}"
	[ "$#" -ge 1 ] && shift

	_wayland_session_env "${_flavor}"
	_setup_cursor_env

	local _exec_cmd=""
	if _is_terminal_app "${_app}"; then
		local _sh="$(_detect_enabled_shell)"
		[ -z "${_sh}" ] && _sh="$(command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || echo "/bin/sh")"
		_exec_cmd="foot ${_sh} -i -c '${_app} $*'"
	else
		_exec_cmd="${_app} $*"
	fi

	if [ "${_app}" = "foot" ] || _is_terminal_app "${_app}"; then
		local _foot_target="${HOME}/.config/foot/foot.ini"
		local _foot_src=""
		if [ -f "${HOME}/.local/share/profile/terminals/foot/foot.ini" ]; then
			_foot_src="${HOME}/.local/share/profile/terminals/foot/foot.ini"
		elif [ -f "${PROFILE_REPO_DIR:-}/terminals/foot/foot.ini" ]; then
			_foot_src="${PROFILE_REPO_DIR}/terminals/foot/foot.ini"
		fi
		if [ -n "${_foot_src}" ]; then
			mkdir -p "${HOME}/.config/foot"
			if [ ! -f "${_foot_target}" ] || ! cmp -s "${_foot_src}" "${_foot_target}"; then
				cp -f "${_foot_src}" "${_foot_target}" 2> "/dev/null" || true
			fi
		fi
	fi

	local _cur_theme="${XCURSOR_THEME:-default}"
	local _cur_size="${XCURSOR_SIZE:-24}"

	if command -v sway > "/dev/null" 2>&1; then
		local _sway_cfg="${XDG_RUNTIME_DIR}/sway-gui-$$.conf"
		cat << EOF > "${_sway_cfg}"
default_border none
default_floating_border none
titlebar_border_thickness 0
seat * xcursor_theme ${_cur_theme} ${_cur_size}
xwayland enable
for_window [app_id=".*"] fullscreen enable
for_window [class=".*"] fullscreen enable
input type:keyboard {
    xkb_layout br
    xkb_model abnt2
    repeat_delay 200
    repeat_rate 50
}
exec sh -c '${_exec_cmd} ; swaymsg exit'
EOF
		command sway -c "${_sway_cfg}" > "/dev/null" 2>&1
		rm -f "${_sway_cfg}"
	elif command -v river > "/dev/null" 2>&1; then
		local _river_init="${XDG_RUNTIME_DIR:-/tmp}/river-gui-$$.sh"
		cat << EOF > "${_river_init}"
#!/bin/sh
riverctl border-width 0
riverctl xcursor-theme "${_cur_theme}" "${_cur_size}"
riverctl keyboard-layout -model abnt2 br
riverctl set-repeat 50 200
riverctl default-attach-mode top
riverctl map normal Super F toggle-fullscreen
sh -c '${_exec_cmd} ; riverctl exit' &
EOF
		chmod 0755 "${_river_init}"
		command river -c "${_river_init}" > "/dev/null" 2>&1
		rm -f "${_river_init}"
	elif command -v labwc > "/dev/null" 2>&1; then
		local _labwc_dir="${XDG_RUNTIME_DIR:-/tmp}/labwc-gui-$$"
		mkdir -p "${_labwc_dir}"
		cat << EOF > "${_labwc_dir}/rc.xml"
<?xml version="1.0"?>
<labwc_config>
  <theme>
    <cornerRadius>0</cornerRadius>
  </theme>
  <windowRules>
    <windowRule identifier="*" serverDecoration="no">
      <action name="Maximize"/>
    </windowRule>
  </windowRules>
</labwc_config>
EOF
		command labwc -C "${_labwc_dir}" -s "sh -c '${_exec_cmd} ; labwc --exit'" > "/dev/null" 2>&1
		rm -rf "${_labwc_dir}"
	elif command -v cage > "/dev/null" 2>&1; then
		if _is_terminal_app "${_app}"; then
			command cage -s -- foot "${_app}" "$@" > "/dev/null" 2>&1
		else
			command cage -s -- "${_app}" "$@" > "/dev/null" 2>&1
		fi
	else
		_ui_err "Nenhum micro-compositor Wayland (sway, river, labwc, cage) foi encontrado."
		return 1
	fi

	if [ "${_had_wayland}" -eq 0 ]; then
		unset WAYLAND_DISPLAY
	fi

	_freebsd_vt_bounce
}
alias wgui="graphical-launcher-wayland"

graphical-launcher-x11() {
	command -v xinit > "/dev/null" 2>&1 || command -v startx > "/dev/null" 2>&1 || {
		_ui_err "xinit ou startx não encontrado para lançador Xorg."
		return 1
	}

	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1

	local _flavor=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)
				_flavor="gnome"
				shift
				;;
			-k|--kde)
				_flavor="kde"
				shift
				;;
			-x|--xfce)
				_flavor="xfce"
				shift
				;;
			-m|--mate)
				_flavor="mate"
				shift
				;;
			-c|--cinnamon)
				_flavor="cinnamon"
				shift
				;;
			--)
				shift
				break
				;;
			-*)
				break
				;;
			*)
				break
				;;
		esac
	done

	local _app="${1:-xterm}"
	[ "$#" -ge 1 ] && shift

	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	local _display=""
	if [ "${_had_display}" -eq 1 ]; then
		_display="${DISPLAY}"
	else
		_display="$(_resolve_free_display)"
	fi
	export DISPLAY="${_display}"
	export XORG_RUN_AS_USER_OK=1

	local _theme_flavor="$(_detect_desktop_theme "${_flavor}")"
	case "${_theme_flavor}" in
		gnome|adwaita)
			export GTK_THEME="Adwaita:dark"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
		kde)
			export GTK_THEME="Breeze-Dark"
			export QT_STYLE_OVERRIDE="Breeze"
			export XCURSOR_THEME="breeze_cursors"
			;;
		cinnamon)
			export GTK_THEME="Mint-Y-Dark"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
		mate)
			export GTK_THEME="Yaru-MATE-dark"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
		xfce)
			export GTK_THEME="Greybird-dark"
			export QT_STYLE_OVERRIDE="adwaita-dark"
			export XCURSOR_THEME="Adwaita"
			;;
	esac

	_setup_cursor_env

	local _xres_target="${HOME}/.Xresources"
	local _xres_src=""
	if [ -f "${HOME}/.local/share/profile/terminals/xterm/Xresources" ]; then
		_xres_src="${HOME}/.local/share/profile/terminals/xterm/Xresources"
	elif [ -f "${PROFILE_REPO_DIR:-}/terminals/xterm/Xresources" ]; then
		_xres_src="${PROFILE_REPO_DIR}/terminals/xterm/Xresources"
	fi
	if [ -n "${_xres_src}" ]; then
		if [ ! -f "${_xres_target}" ] || ! cmp -s "${_xres_src}" "${_xres_target}"; then
			cp -f "${_xres_src}" "${_xres_target}" 2> "/dev/null" || true
		fi
	fi

	local _is_terminal=0
	if _is_terminal_app "${_app}"; then
		_is_terminal=1
	fi

	local _sh="$(_detect_enabled_shell)"
	[ -z "${_sh}" ] && _sh="$(command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || echo "/bin/sh")"

	local _vt_arg="$(_resolve_vt_arg)"
	local _xinit_script="${XDG_RUNTIME_DIR:-/tmp}/xinit-gui-$$.sh"
	cat << EOF > "${_xinit_script}"
#!/bin/sh
if [ -f "\${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "\${HOME}/.Xresources" 2> "/dev/null" || true
fi

# Fallback quiosque de Window Managers para tela cheia estrita
if command -v matchbox-window-manager > "/dev/null" 2>&1; then
	matchbox-window-manager -use_titlebar no > "/dev/null" 2>&1 &
elif command -v openbox > "/dev/null" 2>&1; then
	_ob_cfg="\${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-\$\$.xml"
	cat << 'XOB' > "\${_ob_cfg}"
<?xml version="1.0"?>
<openbox_config>
  <applications>
    <application class="*">
      <maximized>yes</maximized>
      <decorations>no</decorations>
    </application>
  </applications>
</openbox_config>
XOB
	openbox --config-file "\${_ob_cfg}" > "/dev/null" 2>&1 &
elif command -v cwm > "/dev/null" 2>&1; then
	cwm > "/dev/null" 2>&1 &
elif command -v ratpoison > "/dev/null" 2>&1; then
	ratpoison > "/dev/null" 2>&1 &
elif command -v xdotool > "/dev/null" 2>&1; then
	(
		for _i in \$(seq 1 20); do
			sleep 0.1
			for _wid in \$(command xdotool search --onlyvisible --class ".*" 2> "/dev/null"); do
				command xdotool windowsize "\${_wid}" 100% 100% windowmove "\${_wid}" 0 0 2> "/dev/null" || true
			done
		done
	) &
fi

_target_bin="\$1"
shift
if [ "${_is_terminal}" -eq 1 ]; then
	exec xterm -bc -bcf 400 -bcn 500 -xrm 'XTerm*cursorBlink: true' -xrm 'XTerm*cursorBlinkXOR: false' -xrm 'XTerm*vt100.cursorBlink: true' -xrm '*cursorBlink: true' -maximized -e "${_sh}" -i -c "\${_target_bin} \$*"
elif [ "\${_target_bin}" = "xterm" ]; then
	exec xterm -bc -bcf 400 -bcn 500 -xrm 'XTerm*cursorBlink: true' -xrm 'XTerm*cursorBlinkXOR: false' -xrm 'XTerm*vt100.cursorBlink: true' -xrm '*cursorBlink: true' -maximized "\$@"
else
	exec "\${_target_bin}" "\$@"
fi
EOF
	chmod 0755 "${_xinit_script}"

	local _xinit_log="${XDG_RUNTIME_DIR:-/tmp}/xinit-$$.log"
	local _server_auth="${XDG_RUNTIME_DIR:-/tmp}/.serverauth-gui-$$"
	local _xinit_ret=0

	if command -v startx > "/dev/null" 2>&1; then
		command startx "${_xinit_script}" "${_app}" "$@" -- "${_display}" ${_vt_arg} > "${_xinit_log}" 2>&1
		_xinit_ret=$?
	elif command -v xinit > "/dev/null" 2>&1; then
		local _auth_args=""
		if command -v xauth > "/dev/null" 2>&1; then
			local _cookie=""
			if command -v mcookie > "/dev/null" 2>&1; then
				_cookie="$(command mcookie 2> "/dev/null" || true)"
			elif [ -r "/dev/urandom" ]; then
				_cookie="$(command dd if=/dev/urandom bs=16 count=1 2> "/dev/null" | command hexdump -e '16/1 "%02x"' 2> "/dev/null" || true)"
			fi
			if [ -n "${_cookie}" ]; then
				command xauth -q -f "${_server_auth}" add "${_display}" . "${_cookie}" 2> "/dev/null" || true
				command xauth -q add "${_display}" . "${_cookie}" 2> "/dev/null" || true
				_auth_args="-auth ${_server_auth}"
			fi
		fi
		command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" ${_vt_arg} ${_auth_args} > "${_xinit_log}" 2>&1
		_xinit_ret=$?
		rm -f "${_server_auth}" 2> "/dev/null" || true
		command -v xauth > "/dev/null" 2>&1 && command xauth -q remove "${_display}" 2> "/dev/null" || true
	fi

	if [ "${_xinit_ret}" -ne 0 ] && [ -f "${_xinit_log}" ]; then
		_ui_warn "Xorg encerrou com código ${_xinit_ret}."
		command tail -n 10 "${_xinit_log}" 2> "/dev/null" || true
	fi
	rm -f "${_xinit_log}" "${_xinit_script}" "${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-$$.xml" 2> "/dev/null" || true

	if [ "${_had_display}" -eq 0 ]; then
		unset DISPLAY
	fi

	_freebsd_vt_bounce
}
alias xgui="graphical-launcher-x11"

graphical-launcher() {
	_dispatch_display_server "graphical-launcher" "$@"
}
alias gui="graphical-launcher"

### --------------------------------
### Emacs OS Window Managers
### --------------------------------
emacs-window-manager-wayland() {
	_wayland_session_env
	export EMACS_OS_MODE="wayland"

	if ! command -v emacs > "/dev/null" 2>&1; then
		_ui_err "emacs não encontrado."
		return 127
	fi

	if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
		_ui_info "Sessão gráfica ativa detectada. EWM é um compositor soberano DRM/KMS executado via TTY."
		_ui_sub "Encaminhando para instância gráfica padrão do Emacs..."
		command emacs "$@"
		return $?
	fi

	local _ewm_so=""
	if [ -f "${HOME}/.local/lib/libewm_core.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm_core.so"
	elif [ -f "${HOME}/.local/lib/libewm.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm.so"
	fi

	if [ -n "${_ewm_so}" ]; then
		if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -e "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus" ]; then
			export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
		fi
		export EWM_MODULE_PATH="${_ewm_so}"
		export EMACSLOADPATH="${HOME}/.local/share/emacs/site-lisp/ewm:${EMACSLOADPATH:-}:"
		_setup_cursor_env
		rm -f "${XDG_RUNTIME_DIR:-/tmp}/emacs/ewm" 2> "/dev/null" || true

		local _ewm_log="${XDG_RUNTIME_DIR:-/tmp}/ewm-$$.log"
		command emacs --fg-daemon=ewm -L "${HOME}/.local/share/emacs/site-lisp/ewm" -l ewm -f ewm-start-module "$@" 2> "${_ewm_log}"
		local _emacs_ret=$?

		if [ "${_emacs_ret}" -ne 0 ] && [ -f "${_ewm_log}" ]; then
			command grep -v "Due to a limitation in GTK 3" "${_ewm_log}" 2> "/dev/null" | command grep -v "unlikely ever to be able" | command grep -v "display connection is closed" | command grep -v "Failed to connect to user scope bus" | command tail -n 10
		fi
		rm -f "${_ewm_log}" 2> "/dev/null" || true
	else
		graphical-launcher-wayland emacs "$@"
	fi

	_restore_tty_cursor
	_freebsd_vt_bounce
}
alias wewm="emacs-window-manager-wayland"
alias wew="emacs-window-manager-wayland"

emacs-window-manager-x11() {
	export EMACS_OS_MODE="x11"

	if ! command -v emacs > "/dev/null" 2>&1; then
		_ui_err "emacs não encontrado."
		return 127
	fi

	if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
		_ui_info "Sessão gráfica ativa detectada. EXWM é um gerenciador de janelas X11 executado via TTY."
		_ui_sub "Encaminhando para instância gráfica padrão do Emacs..."
		command emacs "$@"
		return $?
	fi

	if [ -f "${HOME}/.emacs.d/etc/apps/exwm.el" ] || [ -f "${HOME}/.emacs.d/var/lib/elpaca/builds/exwm/exwm.el" ]; then
		_exec_x11 "$(command -v emacs)" "$@"
	else
		graphical-launcher-x11 emacs "$@"
	fi

	_freebsd_vt_bounce
}
alias xewm="emacs-window-manager-x11"
alias xew="emacs-window-manager-x11"
alias exwm="emacs-window-manager-x11"
alias exw="emacs-window-manager-x11"

emacs-window-manager() {
	_dispatch_display_server "emacs-window-manager" "$@"
}
alias ewm="emacs-window-manager"
alias ew="emacs-window-manager"

### --------------------------------
### Python Zero-Cruft Policy
### --------------------------------
export PYTHONDONTWRITEBYTECODE=1
unset PYTHONPYCACHEPREFIX
