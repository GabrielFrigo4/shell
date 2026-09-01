### ================================
### DESKTOP CONTEXT (COMMON)
### ================================

### --------------------------------
### Terminal Editors
### --------------------------------
alias on="nvim ."
alias ov="vim ."
alias oh="hx ."
alias om="micro ."

### --------------------------------
### GUI Editors
### --------------------------------
alias ok="nohup kate . > \"/dev/null\" 2>&1 &"
alias og="nohup geany . > \"/dev/null\" 2>&1 &"
alias oc="code ."
alias ocm="codium ."
alias oa="antigravity-ide ."
alias oz="zed ."
alias ant="antigravity-ide"

### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="emacs --daemon"
alias er="ek && es"
alias ec="emacsclient --create-frame --alternate-editor \"\""
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . > \"/dev/null\" 2>&1 &"

### --------------------------------
### Servers
### --------------------------------
alias frigo-server='ssh -i "${FRIGO_SERVER_KEY}" "ubuntu@${FRIGO_SERVER_IP}"'
alias orbs-server='ssh -i "${ORBS_SERVER_KEY}" "ubuntu@${ORBS_SERVER_IP}"'

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
	_gtk_theme="$(_detect_gtk_theme)"
	if [ -n "${_gtk_theme}" ]; then
		export GTK_THEME="${_gtk_theme}"
	else
		unset GTK_THEME
	fi
	unset _gtk_theme

	_qt_style="$(_detect_qt_theme)"
	if [ -n "${_qt_style}" ]; then
		export QT_STYLE_OVERRIDE="${_qt_style}"
	else
		unset QT_STYLE_OVERRIDE
	fi
	unset _qt_style

	_qt_platform="$(_detect_qt_platform_theme)"
	if [ -n "${_qt_platform}" ]; then
		export QT_QPA_PLATFORMTHEME="${_qt_platform}"
	else
		unset QT_QPA_PLATFORMTHEME
	fi
	unset _qt_platform

	export ELECTRON_OZONE_PLATFORM_HINT="auto"
	export _JAVA_AWT_WM_NONREPARENTING=1
fi
