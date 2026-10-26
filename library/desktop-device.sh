# ----------------------------------------------------------------
# Library: Remote Servers & Mobile Device Mounting
# ----------------------------------------------------------------

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
		# shellcheck disable=SC2086
		ssh ${_ssh_opts} -i "${_key}" "${_user}@${_ip}" "$@"
	else
		# shellcheck disable=SC2086
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
		# shellcheck disable=SC2086
		ssh ${_ssh_opts} -i "${_key}" "${_user}@${_ip}" "$@"
	else
		# shellcheck disable=SC2086
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

	_ui_info "Abrindo gerenciador de arquivos..."
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
		_ui_info "Dispositivo já está acessível em ~/Device (vinculado a $(readlink "${_target}"))."
		_open_file_manager "${_target}"
		return 0
	elif command mount 2> "/dev/null" | command grep -qF " ${_target} "; then
		_ui_info "Dispositivo já está montado em ~/Device."
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
		_ui_ok "Dispositivo conectado via KDE/GNOME e vinculado a ~/Device!"
		_open_file_manager "${_target}"
		return 0
	fi

	if command -v "adbfs" > "/dev/null" 2>&1 && command adb devices 2> "/dev/null" | command grep -qE '\bdevice\b'; then
		command mkdir -p "${_target}"
		_ui_step "Montando dispositivo Android via ADB em ~/Device..."
		if adbfs "${_target}" > "/dev/null" 2>&1 || _as_root adbfs -o "allow_other,uid=$(id -u),gid=$(id -g)" "${_target}" > "/dev/null" 2>&1; then
			_ui_ok "Dispositivo Android montado com sucesso em ~/Device via ADB!"
			_open_file_manager "${_target}"
			return 0
		fi
	fi

	[ -d "${_target}" ] && [ ! -L "${_target}" ] && command rmdir "${_target}" 2> "/dev/null"
	_ui_err "Nenhum dispositivo encontrado via KDE/GNOME (MTP/GSConnect), KDE Connect ou ADB."
	_ui_info "Conecte via cabo USB (MTP/ADB) ou sem fio (KDE Connect / GSConnect)."
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
		_ui_ok "Vínculo ~/Device removido com sucesso."
		return 0
	fi

	if ! command mount 2> "/dev/null" | command grep -qF " ${_target} "; then
		if [ -d "${_target}" ]; then
			command rmdir "${_target}" 2> "/dev/null" && _ui_info "Diretório não utilizado ~/Device foi removido."
		fi
		_ui_info "O diretório ~/Device não está montado."
		return 0
	fi

	_ui_step "Desmontando ~/Device com segurança..."

	if command -v kdeconnect-cli > "/dev/null" 2>&1; then
		_kde_dev="$(command kdeconnect-cli -a --id-only 2> "/dev/null" | command head -n 1)"
		[ -n "${_kde_dev}" ] && command kdeconnect-cli -d "${_kde_dev}" --unmount > "/dev/null" 2>&1 || true
	fi

	_unmount_target "${_target}"

	if ! command mount 2> "/dev/null" | command grep -qF " ${_target} "; then
		[ -d "${_target}" ] && command rmdir "${_target}" 2> "/dev/null" || true
		_ui_ok "Dispositivo desmontado e pasta ~/Device removida com sucesso."
		return 0
	fi

	_ui_err "Não foi possível desmontar ~/Device. Verifique processos abertos no diretório."
	return 1
}

alias mntdev="mount-device"
alias mdev="mount-device"
alias umntdev="umount-device"
alias umdev="umount-device"
alias unmount-device="umount-device"

if ! command -v udev > "/dev/null" 2>&1; then
	alias udev="umount-device"
fi
