# ----------------------------------------------------------------
# Library: Hypervisor & Container Common Transport Helpers
# ----------------------------------------------------------------

### ================================
### HELPERS DE HIPERVISOR
### ================================

_hyp_get_os() {
	if command -v _detect_os > "/dev/null" 2>&1; then
		_detect_os
	else
		case "$(uname -s)" in
			Linux*)   echo "linux" ;;
			FreeBSD*) echo "freebsd" ;;
			OpenBSD*) echo "openbsd" ;;
			NetBSD*)  echo "netbsd" ;;
			*)        echo "unknown" ;;
		esac
	fi
}

_hyp_virsh_cmd() {
	local _uri="${LIBVIRT_DEFAULT_URI:-qemu:///system}"
	if virsh -c "${_uri}" list > "/dev/null" 2>&1; then
		virsh -c "${_uri}" "$@"
	elif virsh list > "/dev/null" 2>&1; then
		virsh "$@"
	elif command -v _as_root > "/dev/null" 2>&1; then
		_as_root virsh -c "${_uri}" "$@"
	else
		sudo virsh -c "${_uri}" "$@"
	fi
}

_hyp_resolve_kvm_ip() {
	local _vm_name="$1"
	local _fallback_ip="$2"
	local _detected_ip="$(_hyp_virsh_cmd domifaddr "${_vm_name}" 2> "/dev/null" | awk '$3 == "ipv4" {print $4}' | cut -d'/' -f1 | head -n 1 || true)"
	if [ -n "${_detected_ip}" ]; then
		echo "${_detected_ip}"
	else
		echo "${_fallback_ip}"
	fi
}

_hyp_ssh_connect() {
	local _user="$1"
	local _host="$2"
	[ "$#" -ge 2 ] && shift 2

	local _tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	local _host_os_name="$(_hyp_get_os)"
	[ "${_host_os_name}" = "unknown" ] && _host_os_name="$(uname -s 2> "/dev/null" || echo "unix")"

	local _tty_env="export HOST_OS=\"${_host_os_name}\"; "
	local _ssh_opts="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o SendEnv=HOST_OS -o SetEnv=HOST_OS=${_host_os_name}"
	local _is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		local _raw_term="xterm"
		[ "${TERM:-}" = "linux" ] && _raw_term="linux"
		_tty_env="${_tty_env}export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1; unset COLORTERM; export TERM=${_raw_term}; "
		_ssh_opts="${_ssh_opts} -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	if [ "$#" -gt 0 ]; then
		# shellcheck disable=SC2086
		ssh ${_ssh_opts} ${_tty} "${_user}@${_host}" "${_tty_env}$*"
	else
		# shellcheck disable=SC2086
		ssh ${_ssh_opts} -t "${_user}@${_host}" "${_tty_env}exec \${SHELL:-sh} -l"
	fi
}

_hyp_bhyve_ensure_up() {
	local _b_lbl="$1"
	local _b_vm="$2"
	local _b_ip="$3"
	local _b_user="${4:-${LINUX_HOST_USER:-${USER:-debian}}}"
	local _probe _is_run _wait_count

	[ -z "${_b_ip}" ] && return 1

	if command -v nc > "/dev/null" 2>&1; then
		if nc -z -w 1 "${_b_ip}" 22 > "/dev/null" 2>&1; then
			_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_b_user}@${_b_ip}" true 2>&1 || true)"
			case "${_probe}" in
				*nologin*|*"booting up"*) ;;
				*) return 0 ;;
			esac
		fi
	fi

	_is_run=0
	if command -v vm > "/dev/null" 2>&1; then
		if command -v _as_root > "/dev/null" 2>&1; then
			_as_root vm list 2> "/dev/null" | awk -v v="${_b_vm}" '$1 == v {print $0}' | grep -qi "Running" && _is_run=1
		else
			vm list 2> "/dev/null" | awk -v v="${_b_vm}" '$1 == v {print $0}' | grep -qi "Running" && _is_run=1
		fi
	fi
	if [ "${_is_run}" -eq 0 ] && pgrep -f "bhyve.*${_b_vm}" > "/dev/null" 2>&1; then
		_is_run=1
	fi

	if [ "${_is_run}" -eq 0 ]; then
		_ui_step "Iniciando VM ${_b_lbl} no Bhyve (${_b_vm}) sob demanda..."
		if command -v _as_root > "/dev/null" 2>&1; then
			_as_root vm start "${_b_vm}" > "/dev/null" 2>&1 || true
		else
			sudo vm start "${_b_vm}" > "/dev/null" 2>&1 || true
		fi
	fi

	_wait_count=0
	while [ "${_wait_count}" -lt 30 ]; do
		if command -v nc > "/dev/null" 2>&1; then
			if nc -z -w 1 "${_b_ip}" 22 > "/dev/null" 2>&1; then
				_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_b_user}@${_b_ip}" true 2>&1 || true)"
				case "${_probe}" in
					*nologin*|*"booting up"*) ;;
					*) return 0 ;;
				esac
			fi
		fi
		sleep 1
		_wait_count=$(( _wait_count + 1 ))
	done
}

_hyp_bhyve_dispatch() {
	local _label="$1"
	local _vm_name="$2"
	local _vm_user="$3"
	local _vm_ip="$4"
	local _action="${5:-}"
	[ "$#" -ge 5 ] && shift 5

	case "${_action}" in
		--start|-s|start|up)
			_ui_step "Iniciando VM ${_label} no Bhyve (${_vm_name})..."
			if command -v _as_root > "/dev/null" 2>&1; then
				_as_root vm start "${_vm_name}" > "/dev/null" 2>&1 || true
			else
				sudo vm start "${_vm_name}" > "/dev/null" 2>&1 || true
			fi
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			if [ "$#" -gt 0 ]; then
				_hyp_ssh_connect "${_vm_user}" "${_vm_ip}" "$@"
			else
				_ui_ok "VM ${_label} (${_vm_name}) iniciada e pronta para conexões!"
			fi
			;;
		--stop|--close|-c|-k|stop|down|poweroff)
			_ui_step "Desligando VM ${_label} no Bhyve (${_vm_name})..."
			_as_root vm stop "${_vm_name}" > "/dev/null" 2>&1 || _as_root vm poweroff "${_vm_name}"
			;;
		--restart|-r|restart|reboot)
			_ui_step "Reiniciando VM ${_label} no Bhyve (${_vm_name})..."
			_as_root vm restart "${_vm_name}"
			;;
		--status|--list|-l|status|list)
			_as_root vm list
			;;
		--console|console)
			_as_root vm console "${_vm_name}"
			;;
		ssh)
			[ -n "${_vm_ip}" ] || { _ui_err "${_label}: host IP não configurado (defina via Vault ou variável de ambiente)."; return 1; }
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			_hyp_ssh_connect "${_vm_user}" "${_vm_ip}" "$@"
			;;
		"")
			[ -n "${_vm_ip}" ] || { _ui_err "${_label}: host IP não configurado (defina via Vault ou variável de ambiente)."; return 1; }
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			_hyp_ssh_connect "${_vm_user}" "${_vm_ip}"
			;;
		*)
			[ -n "${_vm_ip}" ] || { _ui_err "${_label}: host IP não configurado (defina via Vault ou variável de ambiente)."; return 1; }
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			_hyp_ssh_connect "${_vm_user}" "${_vm_ip}" "${_action}" "$@"
			;;
	esac
}

_hyp_kvm_ensure_up() {
	local _k_lbl="$1"
	local _k_vm="$2"
	local _k_ip="$3"
	local _target_ip _wait_count

	_target_ip="$(_hyp_resolve_kvm_ip "${_k_vm}" "${_k_ip}")"
	if [ -n "${_target_ip}" ] && command -v nc > "/dev/null" 2>&1; then
		if nc -z -w 1 "${_target_ip}" 22 > "/dev/null" 2>&1; then
			return 0
		fi
	fi

	if ! _hyp_virsh_cmd domstate "${_k_vm}" 2> "/dev/null" | grep -qi "running"; then
		_ui_step "Iniciando VM ${_k_lbl} no KVM (${_k_vm}) sob demanda..."
		_hyp_virsh_cmd start "${_k_vm}" > "/dev/null" 2>&1 || true
	fi

	_wait_count=0
	while [ "${_wait_count}" -lt 15 ]; do
		_target_ip="$(_hyp_resolve_kvm_ip "${_k_vm}" "${_k_ip}")"
		if [ -n "${_target_ip}" ] && command -v nc > "/dev/null" 2>&1; then
			if nc -z -w 1 "${_target_ip}" 22 > "/dev/null" 2>&1; then
				return 0
			fi
		fi
		sleep 1
		_wait_count=$(( _wait_count + 1 ))
	done
}

_hyp_kvm_dispatch() {
	local _label="$1"
	local _vm_name="$2"
	local _vm_user="$3"
	local _vm_ip="$4"
	local _action="${5:-}"
	local _target_ip
	[ "$#" -ge 5 ] && shift 5

	if ! command -v virsh > "/dev/null" 2>&1; then
		_ui_err "virsh (libvirt) não encontrado. Instale o stack QEMU/KVM ou configure o hypervisor."
		return 1
	fi

	case "${_action}" in
		--start|-s|start|up)
			_ui_step "Iniciando VM ${_label} no KVM (${_vm_name})..."
			_hyp_virsh_cmd start "${_vm_name}"
			;;
		--stop|--close|-c|-k|stop|down|poweroff)
			_ui_step "Desligando VM ${_label} no KVM (${_vm_name})..."
			_hyp_virsh_cmd shutdown "${_vm_name}" 2> "/dev/null" || _hyp_virsh_cmd destroy "${_vm_name}" 2> "/dev/null" || true
			;;
		--restart|-r|restart|reboot)
			_ui_step "Reiniciando VM ${_label} no KVM (${_vm_name})..."
			_hyp_virsh_cmd reboot "${_vm_name}"
			;;
		--status|--list|-l|status|list|info)
			_hyp_virsh_cmd dominfo "${_vm_name}" 2> "/dev/null" || true
			_hyp_virsh_cmd domifaddr "${_vm_name}" 2> "/dev/null" || true
			;;
		--console|console)
			_hyp_virsh_cmd console "${_vm_name}"
			;;
		ssh)
			_hyp_kvm_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}"
			_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_vm_ip}")"
			[ -n "${_target_ip}" ] || { _ui_err "${_label}: IP não resolvido via domifaddr/env."; return 1; }
			_hyp_ssh_connect "${_vm_user}" "${_target_ip}" "$@"
			;;
		"")
			_hyp_kvm_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}"
			_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_vm_ip}")"
			[ -n "${_target_ip}" ] || { _ui_err "${_label}: IP não resolvido via domifaddr/env."; return 1; }
			_hyp_ssh_connect "${_vm_user}" "${_target_ip}"
			;;
		*)
			_hyp_kvm_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}"
			_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_vm_ip}")"
			[ -n "${_target_ip}" ] || { _ui_err "${_label}: IP não resolvido via domifaddr/env."; return 1; }
			_hyp_ssh_connect "${_vm_user}" "${_target_ip}" "${_action}" "$@"
			;;
	esac
}

_hyp_bastille_ensure_up() {
	local _jail="$1"
	if command -v jls > "/dev/null" 2>&1; then
		jls -j "${_jail}" > "/dev/null" 2>&1 && return 0
	fi
	_ui_step "Iniciando Jail FreeBSD (${_jail}) sob demanda..."
	_as_root bastille start "${_jail}" > "/dev/null" 2>&1 || true
}

_hyp_incus_ensure_up() {
	local _ct="$1"
	if incus info "${_ct}" 2> "/dev/null" | grep -qi "^Status:[[:space:]]*Running"; then
		return 0
	fi
	_ui_step "Iniciando container Linux Incus (${_ct}) sob demanda..."
	incus start "${_ct}" > "/dev/null" 2>&1 || true
}

_hyp_incus_login_shell() {
	local _ct="$1"
	incus exec "${_ct}" -- /usr/bin/env sh -c 's="$(command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || command -v sh 2> "/dev/null" || echo sh)"; exec "${s}" -l'
}
