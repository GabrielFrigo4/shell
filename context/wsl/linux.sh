### ================================
### WSL CONTEXT LINUX
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
### Path Converters
### --------------------------------
win-path() {
	command -v wslpath > "/dev/null" 2>&1 || { echo "❌ wslpath not found." >&2; return 127; }
	command wslpath -w "${1:-.}"
}

wsl-path() {
	command -v wslpath > "/dev/null" 2>&1 || { echo "❌ wslpath not found." >&2; return 127; }
	command wslpath -u "${1}"
}

### --------------------------------
### Windows Navigation
### --------------------------------
cd-win() {
	local _win_user="${USER}"
	[ -n "${WSL_USER:-}" ] && _win_user="${WSL_USER}"
	if [ -d "/mnt/c/Users/${_win_user}" ]; then
		cd "/mnt/c/Users/${_win_user}/${1:-}"
	elif [ -d "/mnt/c/Users" ]; then
		cd "/mnt/c/Users/${1:-}"
	else
		echo "❌ Windows Users directory not found at /mnt/c/Users." >&2
		return 1
	fi
}

### --------------------------------
### Windows File Launcher
### --------------------------------
open-win() {
	if command -v wslpath > "/dev/null" 2>&1 && command -v explorer.exe > "/dev/null" 2>&1; then
		command explorer.exe "$(command wslpath -w "${1:-.}")" > "/dev/null" 2>&1
	elif command -v explorer.exe > "/dev/null" 2>&1; then
		command explorer.exe "${1:-.}" > "/dev/null" 2>&1
	else
		echo "❌ Neither wslpath nor explorer.exe was found." >&2
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
