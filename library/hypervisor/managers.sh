# ----------------------------------------------------------------
# Library: Cross-Platform Guest Orchestrators
# ----------------------------------------------------------------

### ================================
### FREEBSD
### ================================
freebsd() {
	local _host_os="$(_hyp_get_os)"
	local _jail_name _action _fb_ip _fb_user _vm_name

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
				_fb_ip="${FREEBSD_HOST_IP:-${FREEBSD_IP:-}}"
				[ -n "${_fb_ip}" ] || { _ui_err "FREEBSD_HOST_IP não configurado (defina via Vault ou variável de ambiente)."; return 1; }
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
		_fb_ip="${FREEBSD_HOST_IP:-${FREEBSD_IP:-}}"
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
	local _host_os="$(_hyp_get_os)"
	local _container_name _action _lx_ip _lx_user _vm_name

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
					_hyp_incus_login_shell "${_container_name}"
				fi
				;;
			ssh)
				_lx_ip="${LINUX_HOST_IP:-}"
				_lx_user="${LINUX_HOST_USER:-${USER:-debian}}"
				if [ -z "${_lx_ip}" ]; then
					_ui_err "LINUX_HOST_IP não configurado. Defina LINUX_HOST_IP para conectar via SSH."
					return 1
				fi
				_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				;;
			"")
				_hyp_incus_ensure_up "${_container_name}"
				_hyp_incus_login_shell "${_container_name}"
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
				_lx_ip="${LINUX_HOST_IP:-}"
				_lx_user="${LINUX_HOST_USER:-${USER:-debian}}"
				_ui_step "Iniciando VM Linux no Bhyve (${_vm_name})..."
				if command -v _as_root > "/dev/null" 2>&1; then
					_as_root vm start "${_vm_name}" > "/dev/null" 2>&1 || true
				elif command -v vm > "/dev/null" 2>&1; then
					sudo vm start "${_vm_name}" > "/dev/null" 2>&1 || true
				fi
				if [ -n "${_lx_ip}" ]; then
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
				elif [ "$#" -gt 0 ]; then
					if command -v linux-host > "/dev/null" 2>&1; then
						linux-host "$@"
					else
						_ui_err "LINUX_HOST_IP não configurado. Defina LINUX_HOST_IP para conectar via SSH."
						return 1
					fi
				else
					_ui_ok "VM Linux (${_vm_name}) iniciada (defina LINUX_HOST_IP para aguardar SSH)."
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
				_lx_ip="${LINUX_HOST_IP:-}"
				_lx_user="${LINUX_HOST_USER:-${USER:-debian}}"
				if [ -z "${_lx_ip}" ]; then
					_ui_err "LINUX_HOST_IP não configurado. Defina LINUX_HOST_IP para conectar via SSH."
					return 1
				fi
				_hyp_bhyve_ensure_up "Linux" "${_vm_name}" "${_lx_ip}" "${_lx_user}"
				_hyp_ssh_connect "${_lx_user}" "${_lx_ip}" "$@"
				;;
			*)
				if command -v linux-host > "/dev/null" 2>&1; then
					linux-host "$@"
				else
					_lx_ip="${LINUX_HOST_IP:-}"
					_lx_user="${LINUX_HOST_USER:-${USER:-debian}}"
					if [ -z "${_lx_ip}" ]; then
						_ui_err "LINUX_HOST_IP não configurado. Defina LINUX_HOST_IP para conectar via SSH."
						return 1
					fi
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
	local _host_os="$(_hyp_get_os)"
	local _vm_name _ob_ip _ob_user _action

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
	_ob_ip="${OPENBSD_HOST_IP:-${OPENBSD_IP:-}}"
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
	local _host_os="$(_hyp_get_os)"
	local _vm_name _nb_ip _nb_user _action

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
	_nb_ip="${NETBSD_HOST_IP:-${NETBSD_IP:-}}"
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
