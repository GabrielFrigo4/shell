# ----------------------------------------------------------------
# Library: Cross-Platform Virtualization & Container Orchestrator
# ----------------------------------------------------------------

### ================================
### HELPERS DE HIPERVISOR E CONEXÃO
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
	_uri="${LIBVIRT_DEFAULT_URI:-qemu:///system}"
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
	_vm_name="$1"
	_fallback_ip="$2"
	_detected_ip="$(_hyp_virsh_cmd domifaddr "${_vm_name}" 2> "/dev/null" | awk '$3 == "ipv4" {print $4}' | cut -d'/' -f1 | head -n 1 || true)"
	if [ -n "${_detected_ip}" ]; then
		echo "${_detected_ip}"
	else
		echo "${_fallback_ip}"
	fi
}

_hyp_ssh_connect() {
	_user="$1"
	_host="$2"
	[ "$#" -ge 2 ] && shift 2

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	_host_os_name="$(_hyp_get_os)"
	[ "${_host_os_name}" = "unknown" ] && _host_os_name="$(uname -s 2> "/dev/null" || echo "unix")"

	_tty_env="export HOST_OS=\"${_host_os_name}\"; "
	_ssh_opts="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o SendEnv=HOST_OS -o SetEnv=HOST_OS=${_host_os_name}"
	_is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		_raw_term="xterm"
		[ "${TERM:-}" = "linux" ] && _raw_term="linux"
		_tty_env="${_tty_env}export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1; unset COLORTERM; export TERM=${_raw_term}; "
		_ssh_opts="${_ssh_opts} -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1"
	fi

	if [ "$#" -gt 0 ]; then
		# shellcheck disable=SC2086
		ssh ${_ssh_opts} ${_tty} "${_user}@${_host}" "${_tty_env}$*"
	else
		# shellcheck disable=SC2086
		ssh ${_ssh_opts} -t "${_user}@${_host}" "${_tty_env}exec \${SHELL:-/bin/sh} -l"
	fi
}

_hyp_bhyve_ensure_up() {
	_b_lbl="$1"
	_b_vm="$2"
	_b_ip="$3"
	_b_user="${4:-${LINUX_HOST_USER:-gabriel}}"

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
	_label="$1"
	_vm_name="$2"
	_vm_user="$3"
	_vm_ip="$4"
	_action="${5:-}"
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
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			_hyp_ssh_connect "${_vm_user}" "${_vm_ip}" "$@"
			;;
		"")
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			_hyp_ssh_connect "${_vm_user}" "${_vm_ip}"
			;;
		*)
			_hyp_bhyve_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}" "${_vm_user}"
			_hyp_ssh_connect "${_vm_user}" "${_vm_ip}" "${_action}" "$@"
			;;
	esac
}

_hyp_kvm_ensure_up() {
	_k_lbl="$1"
	_k_vm="$2"
	_k_ip="$3"

	_target_ip="$(_hyp_resolve_kvm_ip "${_k_vm}" "${_k_ip}")"
	if command -v nc > "/dev/null" 2>&1; then
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
		if command -v nc > "/dev/null" 2>&1; then
			if nc -z -w 1 "${_target_ip}" 22 > "/dev/null" 2>&1; then
				return 0
			fi
		fi
		sleep 1
		_wait_count=$(( _wait_count + 1 ))
	done
}

_hyp_kvm_dispatch() {
	_label="$1"
	_vm_name="$2"
	_vm_user="$3"
	_vm_ip="$4"
	_action="${5:-}"
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
			_hyp_ssh_connect "${_vm_user}" "${_target_ip}" "$@"
			;;
		"")
			_hyp_kvm_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}"
			_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_vm_ip}")"
			_hyp_ssh_connect "${_vm_user}" "${_target_ip}"
			;;
		*)
			_hyp_kvm_ensure_up "${_label}" "${_vm_name}" "${_vm_ip}"
			_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_vm_ip}")"
			_hyp_ssh_connect "${_vm_user}" "${_target_ip}" "${_action}" "$@"
			;;
	esac
}

_hyp_bastille_ensure_up() {
	_jail="$1"
	if command -v jls > "/dev/null" 2>&1; then
		jls -j "${_jail}" > "/dev/null" 2>&1 && return 0
	fi
	_ui_step "Iniciando Jail FreeBSD (${_jail}) sob demanda..."
	_as_root bastille start "${_jail}" > "/dev/null" 2>&1 || true
}

_hyp_incus_ensure_up() {
	_ct="$1"
	if incus info "${_ct}" 2> "/dev/null" | grep -qi "^Status:[[:space:]]*Running"; then
		return 0
	fi
	_ui_step "Iniciando container Linux Incus (${_ct}) sob demanda..."
	incus start "${_ct}" > "/dev/null" 2>&1 || true
}

### ================================
### FREEBSD
### ================================
freebsd() {
	_host_os="$(_hyp_get_os)"

	if [ "$#" -gt 0 ]; then
		case "$1" in
			-h|--help|help)
				cat <<- EOF
				Uso: fb [subcomando] [argumentos...] (alias: freebsd)

				Orquestrador multiplataforma do ambiente FreeBSD:
				  • No Linux Host: Opera a Máquina Virtual FreeBSD no KVM/QEMU via virsh
				  • No FreeBSD Host: Opera a Jail FreeBSD nativa via BastilleBSD

				Subcomandos:
				  --start, -s, start, up     Inicia a VM (KVM) ou a Jail (Bastille)
				  --stop, -c, stop, down     Desliga a VM ou para a Jail
				  --restart, -r, restart     Reinicia a VM ou reinicia a Jail
				  --status, -l, status       Exibe o status, interfaces de rede e informações
				  --console, console         Abre o console de terminal direto da VM ou Jail
				  ssh [...]                  Conecta via SSH ou executa comandos remotos
				  [cmd...]                   Sem argumentos abre shell; com argumentos executa
				EOF
				return 0
				;;
		esac
	fi

	if [ "${_host_os}" = "freebsd" ]; then
		_jail_name="${FREEBSD_JAIL_NAME:-freebsd}"
		if ! command -v bastille > "/dev/null" 2>&1; then
			_ui_err "BastilleBSD não encontrado. Instale com 'pkg install bastille' ou via Setup."
			return 1
		fi

		_action="${1:-}"
		[ "$#" -gt 0 ] && shift

		case "${_action}" in
			--start|-s|start|up)
				_ui_step "Iniciando Jail FreeBSD (${_jail_name})..."
				_as_root bastille start "${_jail_name}"
				;;
			--stop|--close|-c|-k|stop|down|poweroff)
				_ui_step "Parando Jail FreeBSD (${_jail_name})..."
				_as_root bastille stop "${_jail_name}"
				;;
			--restart|-r|restart|reboot)
				_ui_step "Reiniciando Jail FreeBSD (${_jail_name})..."
				_as_root bastille restart "${_jail_name}"
				;;
			--status|--list|-l|status|list)
				_as_root bastille list
				;;
			--console|console)
				_hyp_bastille_ensure_up "${_jail_name}"
				_as_root bastille console "${_jail_name}"
				;;
			ssh)
				_fb_ip="${FREEBSD_HOST_IP:-${FREEBSD_IP:-192.168.8.3}}"
				_fb_user="${FREEBSD_HOST_USER:-${FREEBSD_USER:-freebsd}}"
				_hyp_ssh_connect "${_fb_user}" "${_fb_ip}" "$@"
				;;
			"")
				_hyp_bastille_ensure_up "${_jail_name}"
				_as_root bastille console "${_jail_name}"
				;;
			*)
				_hyp_bastille_ensure_up "${_jail_name}"
				_as_root bastille cmd "${_jail_name}" "${_action}" "$@"
				;;
		esac
	else
		_vm_name="${FREEBSD_VM_NAME:-FreeBSD}"
		_fb_ip="${FREEBSD_HOST_IP:-${FREEBSD_IP:-192.168.8.3}}"
		_fb_user="${FREEBSD_HOST_USER:-${FREEBSD_USER:-freebsd}}"
		_action="${1:-}"
		[ "$#" -gt 0 ] && shift
		_hyp_kvm_dispatch "FreeBSD" "${_vm_name}" "${_fb_user}" "${_fb_ip}" "${_action}" "$@"
	fi
}
unalias fb > "/dev/null" 2>&1 || true
fb() { freebsd "$@"; }

### ================================
### LINUX
### ================================
linux() {
	_host_os="$(_hyp_get_os)"

	if [ "$#" -gt 0 ]; then
		case "$1" in
			-h|--help|help)
				cat <<- EOF
				Uso: lx [subcomando] [argumentos...] (alias: linux)

				Orquestrador multiplataforma do ambiente Linux:
				  • No Linux Host: Opera o Container LXC via Incus
				  • No FreeBSD Host: Opera a Máquina Virtual Debian no Bhyve via vm-bhyve

				Subcomandos:
				  --start, -s, start, up     Inicia o Container (Incus) ou a VM (Bhyve)
				  --stop, -c, stop, down     Para o Container ou desliga a VM
				  --restart, -r, restart     Reinicia o Container ou a VM
				  --status, -l, status       Exibe o status e listagem dos containers/VMs
				  --console, console         Abre o console direto do container ou da VM
				  ssh [...]                  Conecta via SSH ou executa comandos remotos
				  [cmd...]                   Sem argumentos abre shell interativo; com argumentos executa
				EOF
				return 0
				;;
		esac
	fi

	if [ "${_host_os}" = "linux" ]; then
		_container_name="${LINUX_CONTAINER_NAME:-debian}"

		if ! command -v incus > "/dev/null" 2>&1; then
			_ui_err "Incus não encontrado. Instale o Incus ou execute a receita de containers do Setup."
			return 1
		fi

		_action="${1:-}"
		[ "$#" -gt 0 ] && shift

		case "${_action}" in
			--start|-s|start|up)
				_ui_step "Iniciando container Linux Incus (${_container_name})..."
				incus start "${_container_name}"
				;;
			--stop|--close|-c|-k|stop|down|poweroff)
				_ui_step "Parando container Linux Incus (${_container_name})..."
				incus stop "${_container_name}"
				;;
			--restart|-r|restart|reboot)
				_ui_step "Reiniciando container Linux Incus (${_container_name})..."
				incus restart "${_container_name}"
				;;
			--status|--list|-l|status|list)
				incus list
				;;
			--console|console)
				_hyp_incus_ensure_up "${_container_name}"
				if [ "$#" -gt 0 ]; then
					incus exec "${_container_name}" -- "$@"
				else
					incus exec "${_container_name}" -- /bin/sh -c 'exec $(which zsh 2>/dev/null || which bash 2>/dev/null || echo /bin/sh) -l'
				fi
				;;
			ssh)
				_lx_ip="${LINUX_HOST_IP:-192.168.8.2}"
				_lx_user="${LINUX_HOST_USER:-${USER}}"
				_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				;;
			"")
				_hyp_incus_ensure_up "${_container_name}"
				incus exec "${_container_name}" -- /bin/sh -c 'exec $(which zsh 2>/dev/null || which bash 2>/dev/null || echo /bin/sh) -l'
				;;
			*)
				_hyp_incus_ensure_up "${_container_name}"
				incus exec "${_container_name}" -- "${_action}" "$@"
				;;
		esac
	else
		_vm_name="${LINUX_VM_NAME:-debian}"
		_action="${1:-}"

		case "${_action}" in
			--start|-s|start|up)
				[ "$#" -ge 1 ] && shift 1
				_lx_ip="${LINUX_HOST_IP:-192.168.8.2}"
				_lx_user="${LINUX_HOST_USER:-gabriel}"
				_ui_step "Iniciando VM Linux no Bhyve (${_vm_name})..."
				if command -v _as_root > "/dev/null" 2>&1; then
					_as_root vm start "${_vm_name}" > "/dev/null" 2>&1 || true
				elif command -v vm > "/dev/null" 2>&1; then
					sudo vm start "${_vm_name}" > "/dev/null" 2>&1 || true
				fi
				_hyp_bhyve_ensure_up "Linux" "${_vm_name}" "${_lx_ip}" "${_lx_user}"
				if [ "$#" -gt 0 ]; then
					if command -v linux-host > "/dev/null" 2>&1; then
						linux-host "$@"
					else
						_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
					fi
				else
					_ui_ok "VM Linux (${_vm_name}) iniciada e pronta para conexões!"
				fi
				;;
			--stop|--close|-c|-k|stop|down|poweroff)
				_ui_step "Desligando VM Linux no Bhyve (${_vm_name})..."
				_as_root vm stop "${_vm_name}" > "/dev/null" 2>&1 || _as_root vm poweroff "${_vm_name}"
				;;
			--restart|-r|restart|reboot)
				_ui_step "Reiniciando VM Linux no Bhyve (${_vm_name})..."
				_as_root vm restart "${_vm_name}"
				;;
			--status|--list|-l|status|list)
				_as_root vm list
				;;
			--console|console)
				_as_root vm console "${_vm_name}"
				;;
			ssh)
				[ "$#" -ge 1 ] && shift 1
				_lx_ip="${LINUX_HOST_IP:-192.168.8.2}"
				_lx_user="${LINUX_HOST_USER:-gabriel}"
				_hyp_bhyve_ensure_up "Linux" "${_vm_name}" "${_lx_ip}" "${_lx_user}"
				_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				;;
			*)
				if command -v linux-host > "/dev/null" 2>&1; then
					linux-host "$@"
				else
					_lx_ip="${LINUX_HOST_IP:-192.168.8.2}"
					_lx_user="${LINUX_HOST_USER:-gabriel}"
					_hyp_bhyve_ensure_up "Linux" "${_vm_name}" "${_lx_ip}" "${_lx_user}"
					_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				fi
				;;
		esac
	fi
}
unalias lx > "/dev/null" 2>&1 || true
lx() { linux "$@"; }

### ================================
### OPENBSD
### ================================
openbsd() {
	_host_os="$(_hyp_get_os)"

	if [ "$#" -gt 0 ]; then
		case "$1" in
			-h|--help|help)
				cat <<- EOF
				Uso: ob [subcomando] [argumentos...] (alias: openbsd)

				Orquestrador multiplataforma do ambiente OpenBSD:
				  • No Linux Host: Opera a Máquina Virtual OpenBSD no KVM/QEMU via virsh
				  • No FreeBSD Host: Opera a Máquina Virtual OpenBSD no Bhyve via vm-bhyve

				Subcomandos:
				  --start, -s, start, up     Inicia a VM OpenBSD sob demanda
				  --stop, -c, stop, down     Desliga a VM OpenBSD
				  --restart, -r, restart     Reinicia a VM OpenBSD
				  --status, -l, status       Exibe o status da VM
				  --console, console         Abre o console de terminal direto da VM
				  ssh [...]                  Conecta via SSH ou executa comandos remotos
				  [cmd...]                   Sem argumentos abre shell; com argumentos executa
				EOF
				return 0
				;;
		esac
	fi

	_vm_name="${OPENBSD_VM_NAME:-OpenBSD}"
	_ob_ip="${OPENBSD_HOST_IP:-${OPENBSD_IP:-192.168.8.4}}"
	_ob_user="${OPENBSD_HOST_USER:-${OPENBSD_USER:-openbsd}}"
	_action="${1:-}"
	[ "$#" -gt 0 ] && shift

	if [ "${_host_os}" = "freebsd" ]; then
		_hyp_bhyve_dispatch "OpenBSD" "${_vm_name}" "${_ob_user}" "${_ob_ip}" "${_action}" "$@"
	else
		_hyp_kvm_dispatch "OpenBSD" "${_vm_name}" "${_ob_user}" "${_ob_ip}" "${_action}" "$@"
	fi
}
unalias ob > "/dev/null" 2>&1 || true
ob() { openbsd "$@"; }

### ================================
### NETBSD
### ================================
netbsd() {
	_host_os="$(_hyp_get_os)"

	if [ "$#" -gt 0 ]; then
		case "$1" in
			-h|--help|help)
				cat <<- EOF
				Uso: nb [subcomando] [argumentos...] (alias: netbsd)

				Orquestrador multiplataforma do ambiente NetBSD:
				  • No Linux Host: Opera a Máquina Virtual NetBSD no KVM/QEMU via virsh
				  • No FreeBSD Host: Opera a Máquina Virtual NetBSD no Bhyve via vm-bhyve

				Subcomandos:
				  --start, -s, start, up     Inicia a VM NetBSD sob demanda
				  --stop, -c, stop, down     Desliga a VM NetBSD
				  --restart, -r, restart     Reinicia a VM NetBSD
				  --status, -l, status       Exibe o status da VM
				  --console, console         Abre o console de terminal direto da VM
				  ssh [...]                  Conecta via SSH ou executa comandos remotos
				  [cmd...]                   Sem argumentos abre shell; com argumentos executa
				EOF
				return 0
				;;
		esac
	fi

	_vm_name="${NETBSD_VM_NAME:-NetBSD}"
	_nb_ip="${NETBSD_HOST_IP:-${NETBSD_IP:-192.168.8.5}}"
	_nb_user="${NETBSD_HOST_USER:-${NETBSD_USER:-netbsd}}"
	_action="${1:-}"
	[ "$#" -gt 0 ] && shift

	if [ "${_host_os}" = "freebsd" ]; then
		_hyp_bhyve_dispatch "NetBSD" "${_vm_name}" "${_nb_user}" "${_nb_ip}" "${_action}" "$@"
	else
		_hyp_kvm_dispatch "NetBSD" "${_vm_name}" "${_nb_user}" "${_nb_ip}" "${_action}" "$@"
	fi
}
unalias nb > "/dev/null" 2>&1 || true
nb() { netbsd "$@"; }
