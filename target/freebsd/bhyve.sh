### ================================
### BHYVE RUNTIME & LINUX-HOST
### ================================

_bhyve_err() {
	if command -v _ui_err > "/dev/null" 2>&1; then
		_ui_err "$*"
	else
		echo "❌ $*" >&2
	fi
}

_bhyve_has_local_agy() {
	[ -x "/usr/local/bin/agy" ] && return 0
	local _remaining_path="${PATH:-}" _path_entry
	while [ -n "${_remaining_path}" ]; do
		case "${_remaining_path}" in
			*:*) _path_entry="${_remaining_path%%:*}"; _remaining_path="${_remaining_path#*:}" ;;
			*)   _path_entry="${_remaining_path}"; _remaining_path="" ;;
		esac
		[ -n "${_path_entry}" ] && [ -f "${_path_entry}/agy" ] && [ -x "${_path_entry}/agy" ] && return 0
	done
	return 1
}

_bhyve_ensure_linux() {
	local _bhyve_vm="${1}" _bhyve_ip="${2}" _bhyve_user="${3}"
	local _probe _wait_count

	if [ -z "${_bhyve_ip}" ]; then
		_bhyve_err "IP da VM Linux Bhyve não configurado (defina BHYVE_LINUX_IP ou LINUX_HOST_IP)."
		return 1
	fi

	if command -v nc > "/dev/null" 2>&1 && nc -z -w 1 "${_bhyve_ip}" 22 > "/dev/null" 2>&1; then
		_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_bhyve_user}@${_bhyve_ip}" true 2>&1 || true)"
		case "${_probe}" in
			*nologin*|*"booting up"*) ;;
			*) return 0 ;;
		esac
	fi

	if ! pgrep -f "bhyve.*${_bhyve_vm}" > "/dev/null" 2>&1; then
		if ! command -v vm > "/dev/null" 2>&1; then
			_bhyve_err "Utilitário 'vm' (vm-bhyve) não encontrado para iniciar '${_bhyve_vm}'."
			return 1
		fi
		if command -v _ui_step > "/dev/null" 2>&1; then
			_ui_step "Iniciando máquina virtual ${_bhyve_vm} no Bhyve sob demanda..."
		fi
		if command -v _as_root > "/dev/null" 2>&1; then
			_as_root vm start "${_bhyve_vm}" > "/dev/null" 2>&1 || true
		else
			sudo vm start "${_bhyve_vm}" > "/dev/null" 2>&1 || true
		fi
	fi

	_wait_count=0
	while [ "${_wait_count}" -lt 30 ]; do
		if command -v nc > "/dev/null" 2>&1 && nc -z -w 1 "${_bhyve_ip}" 22 > "/dev/null" 2>&1; then
			_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_bhyve_user}@${_bhyve_ip}" true 2>&1 || true)"
			case "${_probe}" in
				*nologin*|*"booting up"*) ;;
				*) return 0 ;;
			esac
		fi
		sleep 1
		_wait_count=$(( _wait_count + 1 ))
	done

	_bhyve_err "Timeout aguardando SSH da VM '${_bhyve_vm}' em ${_bhyve_ip}."
	return 1
}

_bhyve_quote_args() {
	_bhyve_quoted_args=""
	local _arg _escaped_arg
	for _arg in "$@"; do
		_escaped_arg="${_arg}"
		case "${_escaped_arg}" in
			*"'"*)
				_escaped_arg="$(printf '%s' "${_escaped_arg}" | sed "s/'/'\\\\''/g")"
				;;
		esac
		_bhyve_quoted_args="${_bhyve_quoted_args:+${_bhyve_quoted_args} }'${_escaped_arg}'"
	done
}

_bhyve_ssh_prepare() {
	_bhyve_ip="${BHYVE_LINUX_IP:-${LINUX_HOST_IP:-}}"
	_bhyve_user="${BHYVE_LINUX_USER:-${LINUX_HOST_USER:-${USER:-debian}}}"
	_bhyve_vm="${BHYVE_LINUX_VM:-${LINUX_VM_NAME:-debian}}"

	_bhyve_ensure_linux "${_bhyve_vm}" "${_bhyve_ip}" "${_bhyve_user}" || return 1

	_bhyve_target_dir=""
	if [ -n "${BHYVE_LINUX_WORKDIR:-}" ]; then
		case "${PWD}" in
			"${BHYVE_LINUX_WORKDIR}"|"${BHYVE_LINUX_WORKDIR}/"*) _bhyve_target_dir="${PWD}" ;;
			*) _bhyve_target_dir="${BHYVE_LINUX_WORKDIR}" ;;
		esac
	fi

	_bhyve_tty=""
	[ -t 0 ] && [ -t 1 ] && _bhyve_tty="-t"

	_bhyve_tty_env="export HOST_OS=FreeBSD; "
	_bhyve_ssh_opts="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o SendEnv=HOST_OS -o SetEnv=HOST_OS=FreeBSD"
	local _is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		_is_raw=1
		_bhyve_tty_env="${_bhyve_tty_env}export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1; unset COLORTERM; "
		_bhyve_ssh_opts="${_bhyve_ssh_opts} -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	_bhyve_tty_term=""
	if [ -n "${INSIDE_EMACS:-}" ]; then
		_bhyve_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
	else
		case "${TERM:-}" in
			eat*|xterm*|alacritty*|kitty*|foot*|ghostty*|wezterm*|rxvt*|tmux*|screen*|"")
				_bhyve_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
				;;
			linux|cons25*|wvt25*)
				_bhyve_tty_term="export COLORTERM=\"\${COLORTERM:-truecolor}\"; "
				;;
			*)
				if [ "${_is_raw}" -eq 0 ]; then
					_bhyve_tty_term="export TERM=xterm-256color COLORTERM=truecolor; "
				else
					_bhyve_tty_term="export COLORTERM=\"\${COLORTERM:-truecolor}\"; "
				fi
				;;
		esac
	fi

	_bhyve_path_prefix="${_bhyve_tty_env}${_bhyve_tty_term}export PATH=\"\${HOME}/.local/bin:\${HOME}/.gemini/antigravity-cli/bin:\${HOME}/.cargo/bin:\${PATH}\";"
	_bhyve_cd_cmd=""
	if [ -n "${_bhyve_target_dir}" ]; then
		_bhyve_quote_args "${_bhyve_target_dir}"
		_bhyve_cd_cmd="cd ${_bhyve_quoted_args} 2> \"/dev/null\" || true; "
	fi
}

_bhyve_cleanup_vars() {
	unset -v _bhyve_ip _bhyve_user _bhyve_vm _bhyve_target_dir _bhyve_tty \
		_bhyve_tty_env _bhyve_ssh_opts _bhyve_tty_term _bhyve_path_prefix \
		_bhyve_cd_cmd _bhyve_quoted_args
}

linux-host() {
	if [ "$#" -gt 0 ]; then
		case "$1" in
			--start|-s|start|up)
				[ "$#" -ge 1 ] && shift 1
				local _start_ip="${BHYVE_LINUX_IP:-${LINUX_HOST_IP:-}}"
				local _start_user="${BHYVE_LINUX_USER:-${LINUX_HOST_USER:-${USER:-debian}}}"
				local _start_vm="${BHYVE_LINUX_VM:-${LINUX_VM_NAME:-debian}}"
				_bhyve_ensure_linux "${_start_vm}" "${_start_ip}" "${_start_user}" || return 1
				if [ "$#" -eq 0 ]; then
					if command -v _ui_ok > "/dev/null" 2>&1; then
						_ui_ok "VM ${_start_vm} iniciada e pronta para conexões!"
					fi
					return 0
				fi
				;;
		esac
	fi

	if ! _bhyve_ssh_prepare; then
		_bhyve_cleanup_vars
		return 1
	fi

	local _exit_code=0
	if [ "$#" -gt 0 ]; then
		ssh ${_bhyve_ssh_opts} ${_bhyve_tty} "${_bhyve_user}@${_bhyve_ip}" "${_bhyve_path_prefix} ${_bhyve_cd_cmd}$*"
		_exit_code=$?
	else
		ssh ${_bhyve_ssh_opts} -t "${_bhyve_user}@${_bhyve_ip}" "${_bhyve_tty_env}${_bhyve_cd_cmd}exec \${SHELL:-/bin/zsh} -l"
		_exit_code=$?
	fi

	_bhyve_cleanup_vars
	return "${_exit_code}"
}

agy-lx() {
	if ! _bhyve_ssh_prepare; then
		_bhyve_cleanup_vars
		return 1
	fi

	local _remote_exec="exec agy"
	if [ "$#" -gt 0 ]; then
		_bhyve_quote_args "$@"
		_remote_exec="exec agy ${_bhyve_quoted_args}"
	fi

	ssh ${_bhyve_ssh_opts} ${_bhyve_tty} "${_bhyve_user}@${_bhyve_ip}" "${_bhyve_path_prefix} ${_bhyve_cd_cmd}${_remote_exec}"
	local _exit_code=$?

	_bhyve_cleanup_vars
	return "${_exit_code}"
}

if [ "${BHYVE_AGY_DEFAULT:-0}" = "1" ] || { ! _bhyve_has_local_agy && [ -n "${BHYVE_LINUX_IP:-${LINUX_HOST_IP:-}}" ]; }; then
	unalias agy > "/dev/null" 2>&1 || true
	agy() {
		agy-lx "$@"
	}
fi

### --------------------------------
### ALIASES
### --------------------------------
alias debian="linux"
alias deb="linux"
