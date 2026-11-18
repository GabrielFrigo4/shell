# ----------------------------------------------------------------
# Library: Network, Wi-Fi, Ports Tree & Linux Guest Updaters
# ----------------------------------------------------------------

### --------------------------------
### UPDATE WI-FI
### --------------------------------
_wifi_xml_escape() {
	printf '%s' "${1:-}" | tr -d '\r\n' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g"
}

_wifi_conf_escape() {
	printf '%s' "${1:-}" | tr -d '\r\n' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

update-wifi() {
	local _rc=0
	_ui_step "Atualizando configurações de Wi-Fi..."

	if ! env | grep -q "^WIFI_SSID_"; then
		_ui_warn "Nenhuma credencial de Wi-Fi encontrada nas variáveis de ambiente."
		return 1
	fi

	if command -v nmcli > "/dev/null" 2>&1; then
		_ui_info "Network Manager (nmcli) detectado. Aplicando perfis..."

		env | grep "^WIFI_SSID_" | sort | {
			_pipe_rc=0
			while IFS='=' read -r _name _ssid; do
				_suffix="${_name#WIFI_SSID_}"
				_password_var="WIFI_PASS_${_suffix}"
				eval "_password=\"\${${_password_var}:-}\""

				if [ -n "${_ssid}" ] && [ -n "${_password}" ]; then
					if nmcli connection show "${_ssid}" > "/dev/null" 2>&1; then
						_ui_sub "Atualizando rede: '${_ssid}'"
						if ! nmcli connection modify "${_ssid}" wifi-sec.psk "${_password}" > "/dev/null" 2>&1; then
							_pipe_rc=1
						fi
					else
						_ui_sub "Adicionando rede: '${_ssid}'"
						if ! nmcli connection add type wifi con-name "${_ssid}" ssid "${_ssid}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${_password}" > "/dev/null" 2>&1; then
							_pipe_rc=1
						fi
					fi
				fi
			done
			exit "${_pipe_rc}"
		} || _rc=$?

		if [ "${_rc}" -eq 0 ]; then
			_ui_ok "Configurações de Wi-Fi aplicadas no Linux!"
		else
			_ui_err "Falha ao aplicar configurações de Wi-Fi via nmcli."
		fi
		return "${_rc}"

	elif [ "$(command uname -s 2> "/dev/null")" = "FreeBSD" ] || [ -f "/etc/wpa_supplicant.conf" ]; then
		_ui_info "FreeBSD/wpa_supplicant detectado. Sincronizando perfis..."

		(
			umask 077
			_temporary_config="$(command mktemp)" || exit 1
			trap 'command rm -f "${_temporary_config}"' EXIT INT TERM
			chmod 0600 "${_temporary_config}" 2> "/dev/null" || true

			cat <<- 'EOF' >| "${_temporary_config}"
				ctrl_interface=/var/run/wpa_supplicant
				ctrl_interface_group=wheel
				update_config=1

			EOF

			env | grep "^WIFI_SSID_" | sort | {
				_pipe_rc=0
				while IFS='=' read -r _name _ssid; do
					_suffix="${_name#WIFI_SSID_}"
					_password_var="WIFI_PASS_${_suffix}"
					eval "_password=\"\${${_password_var}:-}\""

					if [ -n "${_ssid}" ] && [ -n "${_password}" ]; then
						_ui_sub "Mapeando rede: '${_ssid}'"
						_ssid_esc="$(_wifi_conf_escape "${_ssid}")"
						_pass_esc="$(_wifi_conf_escape "${_password}")"
						if ! printf 'network={\n    ssid="%s"\n    psk="%s"\n}\n\n' "${_ssid_esc}" "${_pass_esc}" >> "${_temporary_config}"; then
							_pipe_rc=1
						fi
					fi
				done
				exit "${_pipe_rc}"
			} || exit $?

			_wifi_dir="/etc"
			_wifi_target="${_wifi_dir}/wpa_supplicant.conf"

			if _as_root cmp -s "${_temporary_config}" "${_wifi_target}" 2> "/dev/null"; then
				_ui_info "FreeBSD ${_wifi_target} já está atualizado."
			else
				_ui_sub "Alterações detectadas! Sobrescrevendo ${_wifi_target}..."
				_as_root cp "${_temporary_config}" "${_wifi_target}" || exit 1
				_as_root chmod 0600 "${_wifi_target}" 2> "/dev/null" || true

				_ui_sub "Reiniciando stack de rede (netif)..."
				_as_root service netif restart > "/dev/null" 2>&1 || true
			fi

			_wifibox_dir="/usr/local/etc/wifibox"
			_wifibox_target="${_wifibox_dir}/wpa_supplicant/wpa_supplicant.conf"

			if [ -d "${_wifibox_dir}" ] || command -v wifibox > "/dev/null" 2>&1 || [ -f "${_wifibox_target}" ]; then
				_ui_info "Wifibox detectado. Sincronizando configuração..."
				_as_root mkdir -p "${_wifibox_dir}/wpa_supplicant" || exit 1

				if _as_root cmp -s "${_temporary_config}" "${_wifibox_target}" 2> "/dev/null"; then
					_ui_info "Configuração do Wifibox já está atualizada."
				else
					_ui_sub "Alterações detectadas! Sobrescrevendo ${_wifibox_target}..."
					_as_root cp "${_temporary_config}" "${_wifibox_target}" || exit 1
					_as_root chmod 0600 "${_wifibox_target}" 2> "/dev/null" || true

					if _as_root service wifibox status > "/dev/null" 2>&1; then
						_ui_sub "Reiniciando serviço wifibox..."
						_as_root service wifibox restart > "/dev/null" 2>&1 || true
					fi
				fi
			fi
		) || _rc=$?

		if [ "${_rc}" -eq 0 ]; then
			_ui_ok "Configurações de Wi-Fi aplicadas no FreeBSD!"
		else
			_ui_err "Falha ao aplicar configurações de Wi-Fi no wpa_supplicant."
		fi
		return "${_rc}"

	elif command -v netsh > "/dev/null" 2>&1; then
		_ui_info "Windows Network Shell (netsh) detectado. Sincronizando perfis..."

		env | grep "^WIFI_SSID_" | sort | {
			_pipe_rc=0
			_xml_file=""
			trap '[ -n "${_xml_file:-}" ] && command rm -f "${_xml_file}"' EXIT INT TERM
			umask 077

			while IFS='=' read -r _name _ssid; do
				_suffix="${_name#WIFI_SSID_}"
				_password_var="WIFI_PASS_${_suffix}"
				eval "_password=\"\${${_password_var}:-}\""

				if [ -n "${_ssid}" ] && [ -n "${_password}" ]; then
					_ui_sub "Injetando perfil: '${_ssid}'"
					_ssid_xml="$(_wifi_xml_escape "${_ssid}")"
					_pass_xml="$(_wifi_xml_escape "${_password}")"
					_xml_file="$(command mktemp)" || { _pipe_rc=1; break; }
					chmod 0600 "${_xml_file}" 2> "/dev/null" || true

					cat <<- EOF >| "${_xml_file}"
						<?xml version="1.0"?>
						<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
						    <name>${_ssid_xml}</name>
						    <SSIDConfig>
						        <SSID>
						            <name>${_ssid_xml}</name>
						        </SSID>
						    </SSIDConfig>
						    <connectionType>ESS</connectionType>
						    <connectionMode>auto</connectionMode>
						    <MSM>
						        <security>
						            <authEncryption>
						                <authentication>WPA2PSK</authentication>
						                <encryption>AES</encryption>
						                <useOneX>false</useOneX>
						            </authEncryption>
						            <sharedKey>
						                <keyType>passPhrase</keyType>
						                <protected>false</protected>
						                <keyMaterial>${_pass_xml}</keyMaterial>
						            </sharedKey>
						        </security>
						    </MSM>
						</WLANProfile>
					EOF

					_windows_path="${_xml_file}"
					command -v cygpath > "/dev/null" 2>&1 && _windows_path="$(cygpath -w "${_xml_file}")"

					if ! command netsh wlan add profile filename="${_windows_path}" > "/dev/null" 2>&1; then
						_pipe_rc=1
					fi
					command rm -f "${_xml_file}"
					_xml_file=""
				fi
			done
			exit "${_pipe_rc}"
		} || _rc=$?

		if [ "${_rc}" -eq 0 ]; then
			_ui_ok "Configurações de Wi-Fi aplicadas no Windows!"
		else
			_ui_err "Falha ao aplicar perfil de Wi-Fi via netsh."
		fi
		return "${_rc}"

	else
		_ui_err "Nenhum gerenciador de Wi-Fi suportado (nmcli/wpa_supplicant/netsh) encontrado."
		return 1
	fi
}

### --------------------------------
### UPDATE NETWORK
### --------------------------------
update-network() {
	_ui_step "Atualizando subsistema de rede..."
	update-wifi || return $?
	_ui_ok "Atualização de rede concluída com sucesso!"
}

### --------------------------------
### UPDATE LINUX HOST BHYVE
### --------------------------------
update-linux() {
	local _arg _lx_ip _lx_user _lx_zvol _wait_count _probe _ret
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-linux [opções] (alias: uplx, updeb)

				Atualização de pacotes e distribuição da máquina virtual Linux-host (Bhyve Debian).

				Opções:
				  -h, --help    Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	if [ "$(_detect_os)" != "freebsd" ] && ! command -v vm > "/dev/null" 2>&1; then
		_ui_warn "update-linux é exclusivo para estações FreeBSD com virtualização Bhyve."
		return 0
	fi

	_lx_ip="${LINUX_HOST_IP:-}"
	_lx_user="${LINUX_HOST_USER:-${USER:-linux}}"
	_lx_zvol="${FREEBSD_LINUX_ZVOL:-}"

	if [ -z "${_lx_ip}" ]; then
		_ui_err "LINUX_HOST_IP não configurado. Defina LINUX_HOST_IP antes de executar update-linux."
		return 1
	fi

	_ui_step "Preparando atualização da máquina virtual Linux-host (Bhyve)..."
	if command -v _ensure_debian_running > "/dev/null" 2>&1; then
		_ensure_debian_running
	elif ! nc -z -w 1 "${_lx_ip}" 22 > "/dev/null" 2>&1; then
		if ! pgrep -f "bhyve.*debian" > "/dev/null" 2>&1; then
			_ui_step "Iniciando máquina virtual Debian no Bhyve..."
			if command -v _as_root > "/dev/null" 2>&1; then
				_as_root vm start debian > "/dev/null" 2>&1 || true
			else
				sudo vm start debian > "/dev/null" 2>&1 || true
			fi
		fi
		_wait_count=0
		while [ "${_wait_count}" -lt 30 ]; do
			if nc -z -w 1 "${_lx_ip}" 22 > "/dev/null" 2>&1; then
				_probe="$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "${_lx_user}@${_lx_ip}" true 2>&1 || true)"
				case "${_probe}" in
					*nologin*|*"booting up"*) ;;
					*) break ;;
				esac
			fi
			sleep 1
			_wait_count=$(( _wait_count + 1 ))
		done
	fi

	if command -v zfs > "/dev/null" 2>&1; then
		if [ -n "${_lx_zvol}" ]; then
			_ui_sub "Criando snapshot de proteção ZFS (pre-update) em ${_lx_zvol}..."
			_as_root zfs destroy "${_lx_zvol}@pre-update-old" 2> "/dev/null" || true
			_as_root zfs rename "${_lx_zvol}@pre-update" "${_lx_zvol}@pre-update-old" 2> "/dev/null" || true
			_as_root zfs snapshot "${_lx_zvol}@pre-update" 2> "/dev/null" || true
		else
			_ui_info "FREEBSD_LINUX_ZVOL não definido; snapshot ZFS ignorado."
		fi
	fi

	_ui_step "Disparando atualização completa no linux-host via Universal Shell..."
	if ssh -q "${_lx_user}@${_lx_ip}" "command -v zsh > '/dev/null' 2>&1 && [ -f \"\${HOME}/.zshrc\" ]"; then
		_ret=0
		ssh -t "${_lx_user}@${_lx_ip}" "zsh -ic 'update-all'" || _ret=$?
		if [ "${_ret}" -eq 0 ]; then
			_ui_ok "Máquina virtual Linux-host atualizada com sucesso via Universal Shell!"
		else
			_ui_err "Atualização remota no linux-host falhou (código ${_ret})."
		fi
		return "${_ret}"
	else
		_ui_warn "Universal Shell (~/.zshrc) não encontrado no linux-host. Instale o Universal Shell no guest para suportar 'update-all'."
		return 1
	fi
}

### --------------------------------
### UPDATE FREEBSD PORTS TREE
### --------------------------------
update-ports() {
	_ports_branch=""
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-ports [branch] (alias: upp, upport)

				Sincronização rasa e rápida da árvore do FreeBSD Ports (/usr/ports) via Git.
				Atualiza simultaneamente a branch main e a branch trimestral corrente,
				expurgando automaticamente branches trimestrais legadas sem histórico redundante.

				Argumentos:
				  [branch]      Branch alvo para checkout final (main ou quarterly).

				Opções:
				  -h, --help    Exibe esta ajuda
				EOF
				return 0
				;;
			*)
				_ports_branch="${_arg}"
				;;
		esac
	done

	if [ "$(_detect_os)" != "freebsd" ]; then
		_ui_warn "update-ports é exclusivo para estações FreeBSD."
		return 0
	fi

	_ports_dir="${PORTSDIR:-}"
	if [ -z "${_ports_dir}" ]; then
		if [ -d "/usr/local/ports/.git" ] && [ ! -d "/usr/ports/.git" ]; then
			_ports_dir="/usr/local/ports"
		else
			_ports_dir="/usr/ports"
		fi
	fi
	_ports_quarter="$(date +%Y)Q$(date +%m | awk '{print int(($1-1)/3)+1}')"

	if [ ! -d "${_ports_dir}/.git" ]; then
		_ui_step "Clonagem rasa inicial da árvore de Ports..."
		_as_root git clone --branch main --single-branch --depth 1 https://git.FreeBSD.org/ports.git "${_ports_dir}" || return 1
	fi

	_ui_step "Configurando referências de busca rasa (main e ${_ports_quarter})..."
	_as_root git -C "${_ports_dir}" config --unset-all remote.origin.fetch 2> "/dev/null" || true
	_as_root git -C "${_ports_dir}" config --add remote.origin.fetch "+refs/heads/main:refs/remotes/origin/main"
	_as_root git -C "${_ports_dir}" config --add remote.origin.fetch "+refs/heads/${_ports_quarter}:refs/remotes/origin/${_ports_quarter}"

	_ui_step "Buscando atualizações rasas do FreeBSD Ports..."
	_as_root git -C "${_ports_dir}" fetch --depth 1 --prune origin || return 1

	_ui_step "Sincronizando branch main..."
	_as_root git -C "${_ports_dir}" checkout -B main origin/main > "/dev/null" 2>&1
	_as_root git -C "${_ports_dir}" reset --hard origin/main > "/dev/null" 2>&1
	_as_root git -C "${_ports_dir}" clean -fd > "/dev/null" 2>&1 || true

	_ui_step "Sincronizando branch trimestral corrente (${_ports_quarter})..."
	_as_root git -C "${_ports_dir}" checkout -B "${_ports_quarter}" "origin/${_ports_quarter}" > "/dev/null" 2>&1
	_as_root git -C "${_ports_dir}" reset --hard "origin/${_ports_quarter}" > "/dev/null" 2>&1
	_as_root git -C "${_ports_dir}" clean -fd > "/dev/null" 2>&1 || true

	for _existing_branch in $(git -C "${_ports_dir}" for-each-ref --format='%(refname:short)' refs/heads/ 2> "/dev/null"); do
		case "${_existing_branch}" in
			[1-2][0-9][0-9][0-9]Q[1-4])
				if [ "${_existing_branch}" != "${_ports_quarter}" ] && [ "${_existing_branch}" != "${_ports_branch}" ]; then
					_ui_info "Expurgando branch trimestral obsoleta: ${_existing_branch}..."
					_as_root git -C "${_ports_dir}" branch -D "${_existing_branch}" > "/dev/null" 2>&1 || true
				fi
				;;
		esac
	done

	if [ "${_ports_branch}" = "main" ]; then
		_as_root git -C "${_ports_dir}" checkout main > "/dev/null" 2>&1
		_ui_ok "FreeBSD Ports atualizado com sucesso em branch main!"
	elif [ -n "${_ports_branch}" ] && [ "${_ports_branch}" != "${_ports_quarter}" ]; then
		_as_root git -C "${_ports_dir}" checkout "${_ports_branch}" > "/dev/null" 2>&1 || true
		_ui_ok "FreeBSD Ports atualizado com sucesso em branch ${_ports_branch}!"
	else
		_as_root git -C "${_ports_dir}" checkout "${_ports_quarter}" > "/dev/null" 2>&1
		_ui_ok "FreeBSD Ports atualizado com sucesso em branch ${_ports_quarter}!"
	fi
	unset _arg _ports_branch _ports_dir _ports_quarter _existing_branch
}

alias upp="update-ports"
alias upport="update-ports"
