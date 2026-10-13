### ================================
### BHYVE RUNTIME & LINUX-HOST
### ================================

_ensure_debian_running() {
	if nc -z -w 1 192.168.8.2 22 > "/dev/null" 2>&1; then
		return 0
	fi

	if ! pgrep -f "bhyve.*debian" > "/dev/null" 2>&1; then
		_ui_step "Iniciando máquina virtual Debian no Bhyve..."
		if command -v _as_root > "/dev/null" 2>&1; then
			_as_root vm start debian > "/dev/null" 2>&1 || true
		else
			sudo vm start debian > "/dev/null" 2>&1 || true
		fi
	fi

	_wait_count=0
	while [ "${_wait_count}" -lt 10 ]; do
		if nc -z -w 1 192.168.8.2 22 > "/dev/null" 2>&1; then
			return 0
		fi
		sleep 1
		_wait_count=$(( _wait_count + 1 ))
	done
}

linux-host() {
	_ensure_debian_running

	_target_dir=""
	case "${PWD}" in
		/home/gabrielf|/home/gabrielf/*)
			_target_dir="${PWD}"
			;;
	esac

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	if [ $# -gt 0 ]; then
		_prefix="export PATH=\"\${HOME}/.local/bin:\${HOME}/.gemini/antigravity-cli/bin:\${HOME}/.cargo/bin:\${PATH}\";"
		if [ -n "${_target_dir}" ]; then
			ssh ${_tty} gabriel@192.168.8.2 "${_prefix} cd \"${_target_dir}\" 2> \"/dev/null\" || true; $*"
		else
			ssh ${_tty} gabriel@192.168.8.2 "${_prefix} $*"
		fi
	else
		if [ -n "${_target_dir}" ]; then
			ssh -t gabriel@192.168.8.2 "cd \"${_target_dir}\" 2> \"/dev/null\" || true; exec \${SHELL:-/bin/zsh} -l"
		else
			ssh -t gabriel@192.168.8.2 "exec \${SHELL:-/bin/zsh} -l"
		fi
	fi
}

agy-lx() {
	_ensure_debian_running

	_target_dir=""
	case "${PWD}" in
		/home/gabrielf|/home/gabrielf/*)
			_target_dir="${PWD}"
			;;
	esac

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	_prefix="export PATH=\"\${HOME}/.local/bin:\${HOME}/.gemini/antigravity-cli/bin:\${HOME}/.cargo/bin:\${PATH}\";"

	if [ -n "${_target_dir}" ]; then
		ssh ${_tty} gabriel@192.168.8.2 "${_prefix} cd \"${_target_dir}\" 2> \"/dev/null\" || true; exec agy $*"
	else
		ssh ${_tty} gabriel@192.168.8.2 "${_prefix} exec agy $*"
	fi
}

agy() {
	agy-lx "$@"
}

### --------------------------------
### Aliases
### --------------------------------
alias linux="linux-host"
alias lx="linux-host"
alias debian="linux-host"
alias deb="linux-host"
alias agy="agy-lx"
