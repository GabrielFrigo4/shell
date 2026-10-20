### ================================
### DESKTOP CONTEXT COMMON
### ================================

### --------------------------------
### Terminal Editors
### --------------------------------
_restore_tty_cursor() {
	if [ -t 1 ]; then
		if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
			[ "${TERM:-}" = "linux" ] && [ "${_DETECTED_OS-$(_detect_os)}" = "linux" ] && echo -n $'\e%G\e[?16;238;0c'
		else
			echo -n $'\e[1 q'
		fi
	fi
}

nvim() {
	command -v nvim > "/dev/null" 2>&1 || { _ui_err "nvim not found."; return 127; }
	local _status=0
	if [ -t 0 ] && [ -t 1 ] && command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty && [ "${_DETECTED_OS-$(_detect_os)}" = "freebsd" ] && command -v python3 > "/dev/null" 2>&1; then
		command python3 -c '
import os, pty, select, signal, struct, fcntl, termios, sys
pid, master = pty.fork()
if pid == 0:
    os.execvp("nvim", ["nvim"] + sys.argv[1:])
def sync_winsz(*_):
    try:
        s = fcntl.ioctl(0, termios.TIOCGWINSZ, b"\x00" * 8)
        fcntl.ioctl(master, termios.TIOCSWINSZ, s)
    except Exception:
        pass
sync_winsz()
signal.signal(signal.SIGWINCH, sync_winsz)
try:
    old_tty = termios.tcgetattr(0)
    tty_raw = list(old_tty)
    tty_raw[0] &= ~(termios.BRKINT | termios.ICRNL | termios.INPCK | termios.ISTRIP | termios.IXON)
    tty_raw[1] &= ~(termios.OPOST)
    tty_raw[2] &= ~(termios.CSIZE | termios.PARENB)
    tty_raw[2] |= termios.CS8
    tty_raw[3] &= ~(termios.ECHO | termios.ICANON | termios.IEXTEN | termios.ISIG)
    termios.tcsetattr(0, termios.TCSADRAIN, tty_raw)
except Exception:
    old_tty = None
try:
    while True:
        r, _, _ = select.select([0, master], [], [])
        if 0 in r:
            d = os.read(0, 4096)
            if not d:
                break
            os.write(master, d)
        if master in r:
            try:
                d = os.read(master, 4096)
            except OSError:
                break
            if not d:
                break
            if b"\x1b[c" in d or b"\x1b[0c" in d:
                os.write(master, b"\x1b[?1;2c")
            if b"\x1b[5n" in d:
                os.write(master, b"\x1b[0n")
            os.write(1, d)
finally:
    if old_tty is not None:
        try:
            termios.tcsetattr(0, termios.TCSADRAIN, old_tty)
        except Exception:
            pass
    os.close(master)
_, st = os.waitpid(pid, 0)
sys.exit(os.WEXITSTATUS(st) if os.WIFEXITED(st) else 1)
' "$@"
		_status=$?
	else
		command nvim "$@"
		_status=$?
	fi
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
	command hx "$@"
	local _status=$?
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

open-micro() {
	command -v micro > "/dev/null" 2>&1 || { echo "❌ micro not found." >&2; return 127; }
	if [ "$#" -eq 0 ]; then
		command micro .
	else
		command micro "$@"
	fi
}
alias om="open-micro"

### --------------------------------
### GUI Editors
### --------------------------------
open-kate() {
	command -v kate > "/dev/null" 2>&1 || { echo "❌ kate not found." >&2; return 127; }
	if [ "$#" -eq 0 ]; then
		(command nohup kate . < "/dev/null" > "/dev/null" 2>&1 &)
	else
		(command nohup kate "$@" < "/dev/null" > "/dev/null" 2>&1 &)
	fi
}
alias ok="open-kate"

open-geany() {
	command -v geany > "/dev/null" 2>&1 || { echo "❌ geany not found." >&2; return 127; }
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
	[ -z "${_bin}" ] && { echo "❌ Neither 'vscode' nor 'code' found." >&2; return 127; }
	if [ "$#" -eq 0 ]; then
		"${_bin}" .
	else
		"${_bin}" "$@"
	fi
}
alias oc="open-code"

open-codium() {
	command -v codium > "/dev/null" 2>&1 || { echo "❌ codium not found." >&2; return 127; }
	if [ "$#" -eq 0 ]; then
		command codium .
	else
		command codium "$@"
	fi
}
alias ocm="open-codium"

open-antigravity() {
	command -v antigravity-ide > "/dev/null" 2>&1 || { echo "❌ antigravity-ide not found." >&2; return 127; }
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
	command -v zed > "/dev/null" 2>&1 || { echo "❌ zed not found." >&2; return 127; }
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
	command -v emacs > "/dev/null" 2>&1 || command -v emacsclient > "/dev/null" 2>&1 || { echo "❌ emacs not found." >&2; return 127; }
	command pkill emacs
}
emacs-start() {
	command -v emacs > "/dev/null" 2>&1 || { echo "❌ emacs not found." >&2; return 127; }
	command emacs --daemon
}
emacs-restart() {
	emacs-kill && emacs-start
}

emacs-client() {
	command -v emacsclient > "/dev/null" 2>&1 || { echo "❌ emacsclient not found." >&2; return 127; }
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
	if command -v emacsclient > "/dev/null" 2>&1; then
		command emacsclient -t --alternate-editor "" "$@"
	elif command -v emacs > "/dev/null" 2>&1; then
		command emacs -nw "$@"
	else
		echo "❌ emacs not found." >&2
		return 127
	fi
	local _status=$?
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
			[ "$#" -ge 1 ] && shift 1
			emacs-client "$@"
			_status=$?
			;;
		*)
			command emacs "$@"
			_status=$?
			_restore_tty_cursor
			;;
	esac
	return ${_status}
}
emacs-open() {
	command -v emacsclient > "/dev/null" 2>&1 || { echo "❌ emacsclient not found." >&2; return 127; }
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		if [ "$#" -eq 0 ]; then
			(command nohup emacsclient --create-frame --alternate-editor "" . < "/dev/null" > "/dev/null" 2>&1 &)
		else
			(command nohup emacsclient --create-frame --alternate-editor "" "$@" < "/dev/null" > "/dev/null" 2>&1 &)
		fi
	else
		if [ "$#" -eq 0 ]; then
			command emacsclient -t --alternate-editor "" .
		else
			command emacsclient -t --alternate-editor "" "$@"
		fi
		local _status=$?
		_restore_tty_cursor
		return ${_status}
	fi
}
emacs-eshell() {
	command -v emacsclient > "/dev/null" 2>&1 || command -v emacs > "/dev/null" 2>&1 || {
		echo "❌ emacs não encontrado no PATH." >&2
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
alias enw="emacs-nw"
alias oe="emacs-open"
alias open-emacs="emacs-open"
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
	if [ "$(_detect_os)" = "freebsd" ] && command -v ck-launch-session > "/dev/null" 2>&1; then
		if command -v dbus-run-session > "/dev/null" 2>&1; then
			exec ck-launch-session dbus-run-session "$@"
		else
			exec ck-launch-session "$@"
		fi
	elif command -v dbus-run-session > "/dev/null" 2>&1; then
		exec dbus-run-session "$@"
	else
		exec "$@"
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
				exec startx "$(command -v gnome-session)" --session=gnome-xorg
			elif [ "${_bin}" = "qtile" ]; then
				exec startx "$(command -v qtile)" start
			else
				exec startx "$(command -v "${_bin}")"
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
				exec startx
			fi
			_try_xorg startplasma-x11 startxfce4 gnome-session mate-session cinnamon-session startlxqt startlxde i3 bspwm awesome openbox-session dwm xmonad qtile startfluxbox
			exec startx
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
### Session Aliases
### --------------------------------
alias start-way="start-session way"
alias start-wayland="start-session way"
alias start-xorg="start-session xorg"
alias start-x11="start-session xorg"

alias way="start-session way"
alias wayland="start-session way"
alias xorg="start-session xorg"
alias x11="start-session xorg"

### --------------------------------
### Python Zero-Cruft Policy
### --------------------------------
export PYTHONDONTWRITEBYTECODE=1
unset PYTHONPYCACHEPREFIX
