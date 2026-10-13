### ================================
### BHYVE RUNTIME & LINUX-HOST
### ================================

_ensure_debian_running() {
	if ! vm list 2> "/dev/null" | grep -q "debian.*Running"; then
		_ui_step "Iniciando máquina virtual Debian no Bhyve..."
		if command -v _as_root > "/dev/null" 2>&1; then
			_as_root vm start debian
		else
			sudo vm start debian
		fi
		sleep 2
	fi
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
			"cd \"${_target_dir}\" 2> \"/dev/null\" || cd /home/gabrielf; env HOME=/home/gabrielf $*"
	else
		ssh -t gabriel@192.168.8.2 \
			"cd \"${_target_dir}\" 2> \"/dev/null\" || cd /home/gabrielf; env HOME=/home/gabrielf exec \${SHELL:-/bin/bash} -l"
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
		"cd \"${_target_dir}\" 2> \"/dev/null\" || cd /home/gabrielf; env HOME=/home/gabrielf agy $*"
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
