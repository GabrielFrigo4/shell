### ================================
### BHYVE RUNTIME & LINUX-HOST
### ================================

_ensure_debian_running() {
	_b_ip="192.168.8.2"
	_b_user="gabriel"

	if nc -z -w 1 "${_b_ip}" 22 > "/dev/null" 2>&1; then
		_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_b_user}@${_b_ip}" true 2>&1 || true)"
		case "${_probe}" in
			*nologin*|*"booting up"*) ;;
			*) return 0 ;;
		esac
	fi

	if ! pgrep -f "bhyve.*debian" > "/dev/null" 2>&1; then
		_ui_step "Iniciando máquina virtual Debian no Bhyve sob demanda..."
		if command -v _as_root > "/dev/null" 2>&1; then
			_as_root vm start debian > "/dev/null" 2>&1 || true
		else
			sudo vm start debian > "/dev/null" 2>&1 || true
		fi
	fi

	_wait_count=0
	while [ "${_wait_count}" -lt 30 ]; do
		if nc -z -w 1 "${_b_ip}" 22 > "/dev/null" 2>&1; then
			_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_b_user}@${_b_ip}" true 2>&1 || true)"
			case "${_probe}" in
				*nologin*|*"booting up"*) ;;
				*) return 0 ;;
			esac
		fi
		sleep 1
		_wait_count=$(( _wait_count + 1 ))
	done
}

linux-host() {
	if [ "$#" -gt 0 ]; then
		case "$1" in
			--start|-s|start|up)
				[ "$#" -ge 1 ] && shift 1
				_ensure_debian_running
				if [ "$#" -eq 0 ]; then
					_ui_ok "VM Debian iniciada e pronta para conexões!"
					return 0
				fi
				;;
		esac
	fi

	_ensure_debian_running

	_target_dir=""
	case "${PWD}" in
		/home/gabrielf|/home/gabrielf/*)
			_target_dir="${PWD}"
			;;
	esac

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	_tty_env="export HOST_OS=FreeBSD; "
	_ssh_opts="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o SendEnv=HOST_OS -o SetEnv=HOST_OS=FreeBSD"
	_is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		_is_raw=1
		_tty_env="${_tty_env}export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1; unset COLORTERM; "
		_ssh_opts="${_ssh_opts} -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	_tty_term=""
	if [ -n "${INSIDE_EMACS:-}" ]; then
		_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
	else
		case "${TERM:-}" in
			eat*|xterm*|alacritty*|kitty*|foot*|ghostty*|wezterm*|rxvt*|tmux*|screen*|"")
				_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
				;;
			linux|cons25*|wvt25*)
				_tty_term="export COLORTERM=\"\${COLORTERM:-truecolor}\"; "
				;;
			*)
				if [ "${_is_raw}" -eq 0 ]; then
					_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
				else
					_tty_term="export COLORTERM=\"\${COLORTERM:-truecolor}\"; "
				fi
				;;
		esac
	fi

	if [ $# -gt 0 ]; then

		_prefix="${_tty_env}${_tty_term}export PATH=\"\${HOME}/.local/bin:\${HOME}/.gemini/antigravity-cli/bin:\${HOME}/.cargo/bin:\${PATH}\";"
		if [ -n "${_target_dir}" ]; then
			ssh ${_ssh_opts} ${_tty} gabriel@192.168.8.2 "${_prefix} cd \"${_target_dir}\" 2> \"/dev/null\" || true; $*"
		else
			ssh ${_ssh_opts} ${_tty} gabriel@192.168.8.2 "${_prefix} $*"
		fi
	else
		if [ -n "${_target_dir}" ]; then
			ssh ${_ssh_opts} -t gabriel@192.168.8.2 "${_tty_env}cd \"${_target_dir}\" 2> \"/dev/null\" || true; exec \${SHELL:-/bin/zsh} -l"
		else
			ssh ${_ssh_opts} -t gabriel@192.168.8.2 "${_tty_env}exec \${SHELL:-/bin/zsh} -l"
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

	_tty_env="export HOST_OS=FreeBSD; "
	_ssh_opts="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o SendEnv=HOST_OS -o SetEnv=HOST_OS=FreeBSD"
	_is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		_is_raw=1
		_tty_env="${_tty_env}export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1; unset COLORTERM; "
		_ssh_opts="${_ssh_opts} -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	_tty_term=""
	if [ -n "${INSIDE_EMACS:-}" ]; then
		_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
	else
		case "${TERM:-}" in
			eat*|xterm*|alacritty*|kitty*|foot*|ghostty*|wezterm*|rxvt*|tmux*|screen*|"")
				_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
				;;
			linux|cons25*|wvt25*)
				_tty_term="export COLORTERM=\"\${COLORTERM:-truecolor}\"; "
				;;
			*)
				if [ "${_is_raw}" -eq 0 ]; then
					_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
				else
					_tty_term="export COLORTERM=\"\${COLORTERM:-truecolor}\"; "
				fi
				;;
		esac
	fi

	_prefix="${_tty_env}${_tty_term}export PATH=\"\${HOME}/.local/bin:\${HOME}/.gemini/antigravity-cli/bin:\${HOME}/.cargo/bin:\${PATH}\";"

	if [ -n "${_target_dir}" ]; then
		ssh ${_ssh_opts} ${_tty} gabriel@192.168.8.2 "${_prefix} cd \"${_target_dir}\" 2> \"/dev/null\" || true; exec agy $*"
	else
		ssh ${_ssh_opts} ${_tty} gabriel@192.168.8.2 "${_prefix} exec agy $*"
	fi
}

unalias agy > "/dev/null" 2>&1 || true
agy() {
	agy-lx "$@"
}

### --------------------------------
### ALIASES
### --------------------------------
alias debian="linux"
alias deb="linux"
