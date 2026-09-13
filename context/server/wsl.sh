### ================================
### SERVER CONTEXT WSL
### ================================

### --------------------------------
### Host Networking
### --------------------------------
_wsl_host=""
if [ -r "/etc/resolv.conf" ]; then
	while read -r _wsl_kw _wsl_val _wsl_rest; do
		if [ "${_wsl_kw}" = "nameserver" ]; then
			_wsl_host="${_wsl_val}"
			break
		fi
	done < "/etc/resolv.conf"
fi
[ -n "${_wsl_host}" ] && export WSL_HOST_IP="${_wsl_host}"
unset _wsl_kw _wsl_val _wsl_rest _wsl_host

### --------------------------------
### Windows Clipboard
### --------------------------------
clip() {
	if command -v win32yank.exe > "/dev/null" 2>&1; then
		command win32yank.exe "$@"
	elif command -v clip.exe > "/dev/null" 2>&1; then
		command clip.exe "$@"
	else
		echo "❌ No Windows clipboard tool found (win32yank.exe/clip.exe)." >&2
		return 127
	fi
}

### --------------------------------
### Virtual Machine Helpers
### --------------------------------
wsl-ip() {
	command hostname -I 2> "/dev/null" || command ip -4 addr show eth0 2> "/dev/null"
}

wsl-drop-caches() {
	if [ -w "/proc/sys/vm/drop_caches" ]; then
		echo 3 > "/proc/sys/vm/drop_caches"
	elif command -v sudo > "/dev/null" 2>&1; then
		echo 3 | sudo tee "/proc/sys/vm/drop_caches" > "/dev/null"
	elif command -v doas > "/dev/null" 2>&1; then
		echo 3 | doas tee "/proc/sys/vm/drop_caches" > "/dev/null"
	fi
	echo "⚡ WSL drop_caches executed."
}
