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

	_target_dir="/home/gabrielf"
	case "${PWD}" in
		/home/gabrielf|/home/gabrielf/*)
			_target_dir="${PWD}"
			;;
	esac

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	if [ $# -gt 0 ]; then
		ssh ${_tty} gabriel@192.168.8.2 \
			"cd \"${_target_dir}\" 2> \"/dev/null\" || cd /home/gabrielf; export HOME=/home/gabrielf; $*"
	else
		ssh -t gabriel@192.168.8.2 \
			"cd \"${_target_dir}\" 2> \"/dev/null\" || cd /home/gabrielf; export HOME=/home/gabrielf; exec \${SHELL:-/bin/bash} -l"
	fi
}

agy-lx() {
	_ensure_debian_running

	_target_dir="/home/gabrielf"
	case "${PWD}" in
		/home/gabrielf|/home/gabrielf/*)
			_target_dir="${PWD}"
			;;
	esac

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	ssh ${_tty} gabriel@192.168.8.2 \
		"cd \"${_target_dir}\" 2> \"/dev/null\" || cd /home/gabrielf; export HOME=/home/gabrielf; agy $*"
}

### --------------------------------
### Aliases
### --------------------------------
alias linux="linux-host"
alias lx="linux-host"
alias debian="linux-host"
alias deb="linux-host"
alias agy="agy-lx"
alias agy-bh="agy-lx"
