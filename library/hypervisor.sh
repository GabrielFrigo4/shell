# ----------------------------------------------------------------
# Library: Cross-Platform Virtualization & Container Orchestrator
# ----------------------------------------------------------------

### ================================
# HELPERS DE HIPERVISOR & CONEXÃO
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
	shift 2

	_tty=""
	[ -t 0 ] && [ -t 1 ] && _tty="-t"

	_tty_env=""
	_ssh_opts="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"
	_is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		_raw_term="xterm"
		[ "${TERM:-}" = "linux" ] && _raw_term="linux"
		_tty_env="export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1; unset COLORTERM; export TERM=${_raw_term}; "
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
				  start      Inicia a VM (KVM) ou a Jail (Bastille)
				  stop       Desliga a VM ou para a Jail
				  restart    Reinicia a VM ou reinicia a Jail
				  status     Exibe o status, interfaces de rede e informações
				  console    Abre o console de terminal direto da VM ou Jail
				  ssh [...]  Conecta via SSH ou executa comandos remotos
				  [cmd...]   Sem argumentos abre shell; com argumentos executa no convidado
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

		_action="${1:-console}"
		[ "$#" -gt 0 ] && shift

		case "${_action}" in
			start)
				_ui_step "Iniciando Jail FreeBSD (${_jail_name})..."
				_as_root bastille start "${_jail_name}"
				;;
			stop)
				_ui_step "Parando Jail FreeBSD (${_jail_name})..."
				_as_root bastille stop "${_jail_name}"
				;;
			restart)
				_ui_step "Reiniciando Jail FreeBSD (${_jail_name})..."
				_as_root bastille restart "${_jail_name}"
				;;
			status|list)
				_as_root bastille list
				;;
			console)
				_as_root bastille console "${_jail_name}"
				;;
			ssh)
				_fb_ip="${FREEBSD_HOST_IP:-${FREEBSD_IP:-192.168.8.3}}"
				_fb_user="${FREEBSD_HOST_USER:-${FREEBSD_USER:-freebsd}}"
				_hyp_ssh_connect "${_fb_user}" "${_fb_ip}" "$@"
				;;
			*)
				_as_root bastille cmd "${_jail_name}" "${_action}" "$@"
				;;
		esac
	else
		_vm_name="${FREEBSD_VM_NAME:-FreeBSD}"
		_fb_ip="${FREEBSD_HOST_IP:-${FREEBSD_IP:-192.168.8.3}}"
		_fb_user="${FREEBSD_HOST_USER:-${FREEBSD_USER:-freebsd}}"

		if ! command -v virsh > "/dev/null" 2>&1; then
			_ui_err "virsh (libvirt) não encontrado. Instale o stack QEMU/KVM ou configure o hypervisor."
			return 1
		fi

		_action="${1:-ssh}"
		[ "$#" -gt 0 ] && shift

		case "${_action}" in
			start)
				_ui_step "Iniciando VM FreeBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd start "${_vm_name}"
				;;
			stop)
				_ui_step "Desligando VM FreeBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd shutdown "${_vm_name}"
				;;
			restart)
				_ui_step "Reiniciando VM FreeBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd reboot "${_vm_name}"
				;;
			status|info)
				_hyp_virsh_cmd dominfo "${_vm_name}" 2> "/dev/null" || true
				_hyp_virsh_cmd domifaddr "${_vm_name}" 2> "/dev/null" || true
				;;
			console)
				_hyp_virsh_cmd console "${_vm_name}"
				;;
			ssh)
				_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_fb_ip}")"
				_hyp_ssh_connect "${_fb_user}" "${_target_ip}" "$@"
				;;
			*)
				_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_fb_ip}")"
				_hyp_ssh_connect "${_fb_user}" "${_target_ip}" "${_action}" "$@"
				;;
		esac
	fi
}
fb() { freebsd "$@"; }
alias fb="freebsd"

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
				  start      Inicia o Container (Incus) ou a VM (Bhyve)
				  stop       Para o Container ou desliga a VM
				  restart    Reinicia o Container ou a VM
				  status     Exibe o status e listagem dos containers/VMs
				  console    Abre o console direto do container ou da VM
				  ssh [...]  Conecta via SSH ou executa comandos remotos
				  [cmd...]   Sem argumentos abre shell interativo; com argumentos executa
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

		_action="${1:-console}"
		[ "$#" -gt 0 ] && shift

		case "${_action}" in
			start)
				_ui_step "Iniciando container Linux Incus (${_container_name})..."
				incus start "${_container_name}"
				;;
			stop)
				_ui_step "Parando container Linux Incus (${_container_name})..."
				incus stop "${_container_name}"
				;;
			restart)
				_ui_step "Reiniciando container Linux Incus (${_container_name})..."
				incus restart "${_container_name}"
				;;
			status|list)
				incus list
				;;
			console)
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
			*)
				incus exec "${_container_name}" -- "${_action}" "$@"
				;;
		esac
	else
		_vm_name="${LINUX_VM_NAME:-debian}"
		_action="${1:-}"

		case "${_action}" in
			start)
				_ui_step "Iniciando VM Linux no Bhyve (${_vm_name})..."
				_as_root vm start "${_vm_name}"
				;;
			stop)
				_ui_step "Desligando VM Linux no Bhyve (${_vm_name})..."
				_as_root vm poweroff "${_vm_name}"
				;;
			restart)
				_ui_step "Reiniciando VM Linux no Bhyve (${_vm_name})..."
				_as_root vm restart "${_vm_name}"
				;;
			status|list)
				_as_root vm list
				;;
			console)
				_as_root vm console "${_vm_name}"
				;;
			ssh)
				shift
				_lx_ip="${LINUX_HOST_IP:-192.168.8.2}"
				_lx_user="${LINUX_HOST_USER:-gabriel}"
				_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				;;
			*)
				if command -v linux-host > "/dev/null" 2>&1; then
					linux-host "$@"
				else
					_lx_ip="${LINUX_HOST_IP:-192.168.8.2}"
					_lx_user="${LINUX_HOST_USER:-gabriel}"
					_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				fi
				;;
		esac
	fi
}
lx() { linux "$@"; }
alias lx="linux"

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
				  start      Inicia a VM OpenBSD
				  stop       Desliga a VM OpenBSD
				  restart    Reinicia a VM OpenBSD
				  status     Exibe o status da VM
				  console    Abre o console de terminal direto da VM
				  ssh [...]  Conecta via SSH ou executa comandos remotos
				  [cmd...]   Sem argumentos abre shell; com argumentos executa no convidado
				EOF
				return 0
				;;
		esac
	fi

	_vm_name="${OPENBSD_VM_NAME:-OpenBSD}"
	_ob_ip="${OPENBSD_HOST_IP:-${OPENBSD_IP:-192.168.8.4}}"
	_ob_user="${OPENBSD_HOST_USER:-${OPENBSD_USER:-openbsd}}"

	_action="${1:-ssh}"
	[ "$#" -gt 0 ] && shift

	if [ "${_host_os}" = "freebsd" ]; then
		case "${_action}" in
			start)
				_ui_step "Iniciando VM OpenBSD no Bhyve (${_vm_name})..."
				_as_root vm start "${_vm_name}"
				;;
			stop)
				_ui_step "Desligando VM OpenBSD no Bhyve (${_vm_name})..."
				_as_root vm poweroff "${_vm_name}"
				;;
			restart)
				_ui_step "Reiniciando VM OpenBSD no Bhyve (${_vm_name})..."
				_as_root vm restart "${_vm_name}"
				;;
			status|list)
				_as_root vm list
				;;
			console)
				_as_root vm console "${_vm_name}"
				;;
			ssh)
				_hyp_ssh_connect "${_ob_user}" "${_ob_ip}" "$@"
				;;
			*)
				_hyp_ssh_connect "${_ob_user}" "${_ob_ip}" "${_action}" "$@"
				;;
		esac
	else
		if ! command -v virsh > "/dev/null" 2>&1; then
			_ui_err "virsh (libvirt) não encontrado. Instale o stack QEMU/KVM ou configure o hypervisor."
			return 1
		fi

		case "${_action}" in
			start)
				_ui_step "Iniciando VM OpenBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd start "${_vm_name}"
				;;
			stop)
				_ui_step "Desligando VM OpenBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd shutdown "${_vm_name}"
				;;
			restart)
				_ui_step "Reiniciando VM OpenBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd reboot "${_vm_name}"
				;;
			status|info)
				_hyp_virsh_cmd dominfo "${_vm_name}" 2> "/dev/null" || true
				_hyp_virsh_cmd domifaddr "${_vm_name}" 2> "/dev/null" || true
				;;
			console)
				_hyp_virsh_cmd console "${_vm_name}"
				;;
			ssh)
				_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_ob_ip}")"
				_hyp_ssh_connect "${_ob_user}" "${_target_ip}" "$@"
				;;
			*)
				_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_ob_ip}")"
				_hyp_ssh_connect "${_ob_user}" "${_target_ip}" "${_action}" "$@"
				;;
		esac
	fi
}
ob() { openbsd "$@"; }
alias ob="openbsd"

### ================================
### NETBSD
### ================================
netbsd() {
	_host_os="$(_hyp_get_os)"

	if [ "$#" -gt 0 ]; then
		case "$1" in
			-h|--help|help)
				cat <<- EOF
				Uso: nt [subcomando] [argumentos...] (alias: netbsd)

				Orquestrador multiplataforma do ambiente NetBSD:
				  • No Linux Host: Opera a Máquina Virtual NetBSD no KVM/QEMU via virsh
				  • No FreeBSD Host: Opera a Máquina Virtual NetBSD no Bhyve via vm-bhyve

				Subcomandos:
				  start      Inicia a VM NetBSD
				  stop       Desliga a VM NetBSD
				  restart    Reinicia a VM NetBSD
				  status     Exibe o status da VM
				  console    Abre o console de terminal direto da VM
				  ssh [...]  Conecta via SSH ou executa comandos remotos
				  [cmd...]   Sem argumentos abre shell; com argumentos executa no convidado
				EOF
				return 0
				;;
		esac
	fi

	_vm_name="${NETBSD_VM_NAME:-NetBSD}"
	_nt_ip="${NETBSD_HOST_IP:-${NETBSD_IP:-192.168.8.5}}"
	_nt_user="${NETBSD_HOST_USER:-${NETBSD_USER:-netbsd}}"

	_action="${1:-ssh}"
	[ "$#" -gt 0 ] && shift

	if [ "${_host_os}" = "freebsd" ]; then
		case "${_action}" in
			start)
				_ui_step "Iniciando VM NetBSD no Bhyve (${_vm_name})..."
				_as_root vm start "${_vm_name}"
				;;
			stop)
				_ui_step "Desligando VM NetBSD no Bhyve (${_vm_name})..."
				_as_root vm poweroff "${_vm_name}"
				;;
			restart)
				_ui_step "Reiniciando VM NetBSD no Bhyve (${_vm_name})..."
				_as_root vm restart "${_vm_name}"
				;;
			status|list)
				_as_root vm list
				;;
			console)
				_as_root vm console "${_vm_name}"
				;;
			ssh)
				_hyp_ssh_connect "${_nt_user}" "${_nt_ip}" "$@"
				;;
			*)
				_hyp_ssh_connect "${_nt_user}" "${_nt_ip}" "${_action}" "$@"
				;;
		esac
	else
		if ! command -v virsh > "/dev/null" 2>&1; then
			_ui_err "virsh (libvirt) não encontrado. Instale o stack QEMU/KVM ou configure o hypervisor."
			return 1
		fi

		case "${_action}" in
			start)
				_ui_step "Iniciando VM NetBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd start "${_vm_name}"
				;;
			stop)
				_ui_step "Desligando VM NetBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd shutdown "${_vm_name}"
				;;
			restart)
				_ui_step "Reiniciando VM NetBSD no KVM (${_vm_name})..."
				_hyp_virsh_cmd reboot "${_vm_name}"
				;;
			status|info)
				_hyp_virsh_cmd dominfo "${_vm_name}" 2> "/dev/null" || true
				_hyp_virsh_cmd domifaddr "${_vm_name}" 2> "/dev/null" || true
				;;
			console)
				_hyp_virsh_cmd console "${_vm_name}"
				;;
			ssh)
				_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_nt_ip}")"
				_hyp_ssh_connect "${_nt_user}" "${_target_ip}" "$@"
				;;
			*)
				_target_ip="$(_hyp_resolve_kvm_ip "${_vm_name}" "${_nt_ip}")"
				_hyp_ssh_connect "${_nt_user}" "${_target_ip}" "${_action}" "$@"
				;;
		esac
	fi
}
nt() { netbsd "$@"; }
alias nt="netbsd"
