### ================================
### SERVER CONTEXT WSL
### ================================

### --------------------------------
### HOST NETWORKING
### --------------------------------
_wsl_host_ip=""
if [ -r "/etc/resolv.conf" ]; then
	while read -r _wsl_keyword _wsl_value _wsl_rest; do
		if [ "${_wsl_keyword:-}" = "nameserver" ] && [ -n "${_wsl_value:-}" ]; then
			_wsl_host_ip="${_wsl_value}"
			break
		fi
	done < "/etc/resolv.conf"
fi
[ -n "${_wsl_host_ip}" ] && export WSL_HOST_IP="${_wsl_host_ip}"
unset _wsl_keyword _wsl_value _wsl_rest _wsl_host_ip

### --------------------------------
### WINDOWS CLIPBOARD
### --------------------------------
clip() {
	if command -v win32yank.exe > "/dev/null" 2>&1; then
		command win32yank.exe "$@"
	elif command -v clip.exe > "/dev/null" 2>&1; then
		command clip.exe "$@"
	else
		_ui_err "No Windows clipboard tool found (win32yank.exe/clip.exe)."
		return 127
	fi
}

### --------------------------------
### VIRTUAL MACHINE HELPERS
### --------------------------------
wsl-ip() {
	command hostname -I 2> "/dev/null" || command ip -4 addr show eth0 2> "/dev/null" || command ip -4 addr show scope global 2> "/dev/null"
}

wsl-drop-caches() {
	if [ -w "/proc/sys/vm/drop_caches" ]; then
		printf '3\n' >| "/proc/sys/vm/drop_caches"
	elif command -v _as_root > "/dev/null" 2>&1; then
		_as_root sh -c 'printf "3\n" > "/proc/sys/vm/drop_caches"'
	elif command -v sudo > "/dev/null" 2>&1; then
		printf '3\n' | command sudo tee "/proc/sys/vm/drop_caches" > "/dev/null"
	elif command -v doas > "/dev/null" 2>&1; then
		printf '3\n' | command doas tee "/proc/sys/vm/drop_caches" > "/dev/null"
	else
		_ui_err "Insufficient privileges to drop WSL caches."
		return 1
	fi
	local _status=$?
	if [ "${_status}" -ne 0 ]; then
		_ui_err "Failed to execute WSL drop_caches."
		return "${_status}"
	fi
	_ui_ok "WSL drop_caches executed."
}
