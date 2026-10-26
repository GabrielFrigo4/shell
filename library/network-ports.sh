# ----------------------------------------------------------------
# Library: Network, Ports, Bhyve Guest & Global Updaters
# ----------------------------------------------------------------

### --------------------------------
### Update Wi-Fi
### --------------------------------
update-wifi() {
	_ui_step "Atualizando configurações de Wi-Fi..."

	if ! env | grep -q "^WIFI_SSID_"; then
		_ui_warn "Nenhuma credencial de Wi-Fi encontrada nas variáveis de ambiente."
		return 1
	fi

	if command -v nmcli > "/dev/null" 2>&1; then
		_ui_info "Network Manager (nmcli) detectado. Aplicando perfis..."

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r _name _ssid; do
			_suffix="${_name#WIFI_SSID_}"
			_password_var="WIFI_PASS_${_suffix}"
			eval _password="\$${_password_var}"

			if [ -n "${_ssid}" ] && [ -n "${_password}" ]; then
				if nmcli connection show "${_ssid}" > "/dev/null" 2>&1; then
					_ui_sub "Atualizando rede: '${_ssid}'"
					nmcli connection modify "${_ssid}" wifi-sec.psk "${_password}" > "/dev/null" 2>&1
				else
					_ui_sub "Adicionando rede: '${_ssid}'"
					nmcli connection add type wifi con-name "${_ssid}" ssid "${_ssid}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${_password}" > "/dev/null" 2>&1
				fi
			fi
		done
		_ui_ok "Configurações de Wi-Fi aplicadas no Linux!"

	elif [ "$(command uname -s 2> "/dev/null")" = "FreeBSD" ] || [ -f "/etc/wpa_supplicant.conf" ]; then
		_ui_info "FreeBSD/wpa_supplicant detectado. Sincronizando perfis..."

		_temporary_config=$(command mktemp)
		cat <<-EOF >| "${_temporary_config}"
			ctrl_interface=/var/run/wpa_supplicant
			ctrl_interface_group=wheel
			update_config=1

		EOF

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r _name _ssid; do
			_suffix="${_name#WIFI_SSID_}"
			_password_var="WIFI_PASS_${_suffix}"
			eval _password="\$${_password_var}"

			if [ -n "${_ssid}" ] && [ -n "${_password}" ]; then
				_ui_sub "Mapeando rede: '${_ssid}'"
				cat <<-EOF >> "${_temporary_config}"
					network={
					    ssid="${_ssid}"
					    psk="${_password}"
					}

				EOF
			fi
		done

		_wifi_dir="/etc"
		_wifi_target="${_wifi_dir}/wpa_supplicant.conf"

		if _as_root cmp -s "${_temporary_config}" "${_wifi_target}" 2> "/dev/null"; then
			_ui_info "FreeBSD ${_wifi_target} já está atualizado."
		else
			_ui_sub "Alterações detectadas! Sobrescrevendo ${_wifi_target}..."
			_as_root cp "${_temporary_config}" "${_wifi_target}"

			_ui_sub "Reiniciando stack de rede (netif)..."
			_as_root service netif restart > "/dev/null" 2>&1 || true
		fi

		_wifibox_dir="/usr/local/etc/wifibox"
		_wifibox_target="${_wifibox_dir}/wpa_supplicant/wpa_supplicant.conf"

		if [ -d "${_wifibox_dir}" ] || command -v wifibox > "/dev/null" 2>&1 || [ -f "${_wifibox_target}" ]; then
			_ui_info "Wifibox detectado. Sincronizando configuração..."
			_as_root mkdir -p "${_wifibox_dir}/wpa_supplicant"

			if _as_root cmp -s "${_temporary_config}" "${_wifibox_target}" 2> "/dev/null"; then
				_ui_info "Configuração do Wifibox já está atualizada."
			else
				_ui_sub "Alterações detectadas! Sobrescrevendo ${_wifibox_target}..."
				_as_root cp "${_temporary_config}" "${_wifibox_target}"

				if _as_root service wifibox status > "/dev/null" 2>&1; then
					_ui_sub "Reiniciando serviço wifibox..."
					_as_root service wifibox restart > "/dev/null" 2>&1 || true
				fi
			fi
		fi

		command rm -f "${_temporary_config}"
		_ui_ok "Configurações de Wi-Fi aplicadas no FreeBSD!"

	elif command -v netsh > "/dev/null" 2>&1; then
		_ui_info "Windows Network Shell (netsh) detectado. Sincronizando perfis..."

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r _name _ssid; do
			_suffix="${_name#WIFI_SSID_}"
			_password_var="WIFI_PASS_${_suffix}"
			eval _password="\$${_password_var}"

			if [ -n "${_ssid}" ] && [ -n "${_password}" ]; then
				_ui_sub "Injetando perfil: '${_ssid}'"
				_xml_file=$(command mktemp)

				cat <<-EOF >| "${_xml_file}"
					<?xml version="1.0"?>
					<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
					    <name>${_ssid}</name>
					    <SSIDConfig>
					        <SSID>
					            <name>${_ssid}</name>
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
					                <keyMaterial>${_password}</keyMaterial>
					            </sharedKey>
					        </security>
					    </MSM>
					</WLANProfile>
				EOF

				_windows_path="${_xml_file}"
				command -v cygpath > "/dev/null" 2>&1 && _windows_path=$(cygpath -w "${_xml_file}")

				command netsh wlan add profile filename="${_windows_path}" > "/dev/null" 2>&1
				command rm -f "${_xml_file}"
			fi
		done
		_ui_ok "Configurações de Wi-Fi aplicadas no Windows!"

	else
		_ui_err "Nenhum gerenciador de Wi-Fi suportado (nmcli/wpa_supplicant/netsh) encontrado."
	fi

	unset _name _ssid _suffix _password_var _password _temporary_config _xml_file _windows_path _wifi_dir _wifi_target _wifibox_dir _wifibox_target 2> "/dev/null" || true
}

### --------------------------------
### Update Network
### --------------------------------
update-network() {
	_ui_step "Atualizando subsistema de rede..."
	update-wifi
	_ui_ok "Atualização de rede concluída com sucesso!"
}

### --------------------------------
### Update Linux Host Bhyve
### --------------------------------
update-linux() {
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

	_ui_step "Preparando atualização da máquina virtual Linux-host (Bhyve)..."
	if command -v _ensure_debian_running > "/dev/null" 2>&1; then
		_ensure_debian_running
	elif ! nc -z -w 1 192.168.8.2 22 > "/dev/null" 2>&1; then
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
				break
			fi
			sleep 1
			_wait_count=$(( _wait_count + 1 ))
		done
	fi

	if command -v zfs > "/dev/null" 2>&1; then
		_ui_sub "Criando snapshot de proteção ZFS (pre-update)..."
		_as_root zfs destroy zroot/vm/debian@pre-update-old 2> "/dev/null" || true
		_as_root zfs rename zroot/vm/debian@pre-update zroot/vm/debian@pre-update-old 2> "/dev/null" || true
		_as_root zfs snapshot zroot/vm/debian@pre-update 2> "/dev/null" || true
	fi

	_ui_step "Disparando atualização completa no linux-host via Universal Shell..."
	if ssh -q gabriel@192.168.8.2 "command -v zsh > '/dev/null' 2>&1 && [ -f \"\${HOME}/.zshrc\" ]"; then
		ssh -t gabriel@192.168.8.2 "zsh -ic 'update-all'" && \
			_ui_ok "Máquina virtual Linux-host atualizada com sucesso via Universal Shell!"
	else
		_ui_warn "Universal Shell (~/.zshrc) não encontrado no linux-host. Instale o Universal Shell no guest para suportar 'update-all'."
		return 1
	fi
}

### --------------------------------
### Update FreeBSD Ports Tree
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

### --------------------------------
### Update All Packages
### --------------------------------
update-all() {
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-all [opções] (alias: upall)

				Atualização geral e coordenada de todo o ecossistema e pacotes do sistema.

				Componentes sincronizados:
				  1. Gerenciadores de pacotes do SO (pacman, apt, dnf, pkg, brew, etc.)
				  2. Universal Shell (~/.local/share/shell)
				  3. Universal Vault (~/.local/share/vault)
				  4. Suíte de Editores (Emacs, Helix, NeoVim, Vim)
				  5. Universal Profile (~/.local/share/profile)

				Opções:
				  -s, --status        Executa auditoria e diagnóstico geral sem atualizar
				  -n, --dry-run       Simula a atualização de todos os componentes
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	_is_query=0
	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s|--dry-run|-n) _is_query=1 ;;
		esac
	done

	if [ "${_is_query}" -eq 1 ]; then
		_ui_banner "Diagnóstico & Auditoria Global do Ecossistema"
	else
		_ui_banner "Iniciando Atualização Geral do Ecossistema"
		update-system "$@"

		if command -v paru > "/dev/null" 2>&1 || command -v yay > "/dev/null" 2>&1; then
			echo ""
			update-aur "$@" && _ui_ok "Pacotes AUR atualizados!"
		fi

		if [ "$(_detect_os)" != "macos" ] && command -v brew > "/dev/null" 2>&1; then
			echo ""
			update-brew "$@" && _ui_ok "Pacotes Linuxbrew atualizados!"
		fi

		if command -v flatpak > "/dev/null" 2>&1; then
			echo ""
			update-flatpak "$@" && _ui_ok "Pacotes Flatpak atualizados!"
		fi

		if command -v snap > "/dev/null" 2>&1; then
			echo ""
			update-snap "$@" && _ui_ok "Pacotes Snap atualizados!"
		fi

		if command -v mas > "/dev/null" 2>&1; then
			echo ""
			update-mas "$@" && _ui_ok "Pacotes Mac App Store atualizados!"
		fi

		if [ "$(_detect_os)" = "freebsd" ]; then
			_has_ports="0"
			[ -d "/usr/ports/.git" ] && _has_ports="1"
			[ -d "/usr/local/ports/.git" ] && _has_ports="1"
			[ -n "${PORTSDIR:-}" ] && [ -d "${PORTSDIR:-}/.git" ] && _has_ports="1"
			if [ "${_has_ports}" = "1" ]; then
				echo ""
				update-ports "$@"
			fi
			if command -v vm > "/dev/null" 2>&1 && vm list 2> "/dev/null" | grep -q "debian"; then
				echo ""
				update-linux "$@"
			fi
		fi

		echo ""
		clean-system
	fi

	if [ -e "${HOME}/.local/share/shell/.git" ] || [ -e "${HOME}/.config/shell/.git" ] || [ -e "/usr/local/share/shell/.git" ] || [ -e "${HOME}/.shell/.git" ]; then
		echo ""
		update-shell "$@"
	fi

	if [ -d "${HOME}/.local/share/vault/.git" ] || [ -d "${HOME}/.config/vault/.git" ] || [ -d "${HOME}/.vault/.git" ] || [ -d "/usr/local/share/vault/.git" ]; then
		echo ""
		update-vault "$@"
	fi

	if [ -d "${HOME}/.emacs.d/.git" ] || [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/nvim/.git" ] || [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/helix/.git" ] || [ -d "${HOME}/vimfiles/.git" ]; then
		echo ""
		update-editors "$@"
	fi

	if [ -d "${HOME}/.local/share/profile/.git" ] || [ -d "${HOME}/.config/profile/.git" ] || [ -d "${HOME}/.profile/.git" ]; then
		echo ""
		update-profile "$@"
	fi

	if [ "${_is_query}" -eq 1 ]; then
		_ui_banner "Diagnóstico & Auditoria Global Concluídos!"
	else
		_ui_banner "Atualização Geral Concluída com Sucesso!"
	fi
	unset _is_query _arg
}
