### ================================
### CORE FUNCTIONS
### ================================

### --------------------------------
### Privilege Escalation
### --------------------------------
_as_root() {
	local _escalator="$(_detect_privilege_escalator)"
	case "${_escalator}" in
		root)
			"$@"
			;;
		doas|sudo)
			command "${_escalator}" "$@"
			;;
		*)
			_ui_err "Neither 'doas' nor 'sudo' was found to execute command with root privileges."
			return 1
			;;
	esac
}

### --------------------------------
### Path Front
### --------------------------------
path-front() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${1}:${PATH}" ;;
	esac
}

### --------------------------------
### Path Back
### --------------------------------
path-back() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${PATH}:${1}" ;;
	esac
}

### --------------------------------
### Path Dedup
### --------------------------------
path-dedup() {
	local _old_ifs="${IFS+x}"
	local _saved_ifs="${IFS:-}"
	local _new_path=""
	local _dir
	IFS=":"
	for _dir in ${PATH}; do
		[ -z "${_dir}" ] && continue
		case ":${_new_path}:" in
			*":${_dir}:"*) ;;
			*)
				if [ -z "${_new_path}" ]; then
					_new_path="${_dir}"
				else
					_new_path="${_new_path}:${_dir}"
				fi
				;;
		esac
	done
	if [ -n "${_old_ifs}" ]; then
		IFS="${_saved_ifs}"
	else
		unset IFS
	fi
	PATH="${_new_path}"
	export PATH
}

### --------------------------------
### Clean Cache
### --------------------------------
clean-cache() {
	_ui_step "Limpando cache do Universal Shell..."
	_cache_clean
	_ui_ok "Cache do Universal Shell limpo com sucesso!"
}
alias cleancache="clean-cache"
alias ccache="clean-cache"

### --------------------------------
### Resilient Git Pull Helper
### --------------------------------
_git_pull_resilient() {
	local _dir="$1"
	[ -d "${_dir}/.git" ] || [ -f "${_dir}/.git" ] || return 1

	local _cmd="command git -C \"${_dir}\""
	if [ ! -w "${_dir}" ]; then
		if command -v sudo > "/dev/null" 2>&1; then
			_cmd="sudo git -C \"${_dir}\""
		elif command -v doas > "/dev/null" 2>&1; then
			_cmd="doas git -C \"${_dir}\""
		fi
	fi

	eval "${_cmd} diff --numstat" 2> "/dev/null" | while IFS="$(printf '\t')" read -r _add _del _file; do
		if [ "${_add}" = "0" ] && [ "${_del}" = "0" ] && [ -n "${_file}" ]; then
			eval "${_cmd} checkout -- \"${_file}\"" > "/dev/null" 2>&1 || true
		fi
	done

	local _has_dirty=0
	local _status
	_status="$(eval "${_cmd} status --porcelain" 2> "/dev/null" || true)"
	if [ -n "${_status}" ]; then
		_has_dirty=1
		_ui_warn "Alterações locais ou arquivos novos detectados em ${_dir}."
		_ui_sub "Criando auto-stash defensivo antes da sincronização..."
		eval "${_cmd} stash push -u -m 'autostash-before-update-$(date +%s)'" > "/dev/null" 2>&1 || true
	fi

	local _pull_ok=0
	if eval "${_cmd} pull --ff-only" > "/dev/null" 2>&1; then
		_pull_ok=1
	elif eval "${_cmd} pull --rebase" > "/dev/null" 2>&1; then
		_pull_ok=1
	elif eval "${_cmd} pull" > "/dev/null" 2>&1; then
		_pull_ok=1
	fi

	if [ "${_pull_ok}" -eq 1 ]; then
		if [ "${_has_dirty}" -eq 1 ]; then
			if ! eval "${_cmd} stash pop" > "/dev/null" 2>&1; then
				eval "${_cmd} reset --merge" > "/dev/null" 2>&1 || eval "${_cmd} checkout -f" > "/dev/null" 2>&1 || true
				_ui_warn "Conflito detectado ao restaurar alterações locais em ${_dir}."
				_ui_info "Sua versão local foi preservada com segurança em 'git stash list'."
			fi
			eval "${_cmd} diff --numstat" 2> "/dev/null" | while IFS="$(printf '\t')" read -r _add _del _file; do
				if [ "${_add}" = "0" ] && [ "${_del}" = "0" ] && [ -n "${_file}" ]; then
					eval "${_cmd} checkout -- \"${_file}\"" > "/dev/null" 2>&1 || true
				fi
			done
		fi

		if [ -d "${_dir}/.githooks" ]; then
			chmod 0755 "${_dir}/.githooks/"* 2> "/dev/null" || true
		fi

		if [ -f "${_dir}/.gitmodules" ]; then
			eval "${_cmd} submodule update --init --recursive" > "/dev/null" 2>&1 || true
		fi
		return 0
	fi

	_ui_err "Falha na sincronização Git de ${_dir}."
	return 1
}

### --------------------------------
### Update Shell
### --------------------------------
update-shell() {
	_target=""
	if [ -n "${SHELL_REPO_DIR:-}" ] && [ -e "${SHELL_REPO_DIR}/.git" ]; then
		_target="${SHELL_REPO_DIR}"
	elif [ -e "/usr/local/share/shell/.git" ]; then
		_target="/usr/local/share/shell"
	elif [ -e "${HOME}/.local/share/shell/.git" ]; then
		_target="${HOME}/.local/share/shell"
	elif [ -e "${HOME}/.config/shell/.git" ]; then
		_target="${HOME}/.config/shell"
	elif [ -e "${HOME}/.shell/.git" ]; then
		_target="${HOME}/.shell"
	elif [ -n "${SHELL_REPO_DIR:-}" ] && [ -d "${SHELL_REPO_DIR}" ]; then
		_target="${SHELL_REPO_DIR}"
	fi

	if [ -n "${_target}" ] && [ -d "${_target}" ]; then
		_ui_step "Atualizando repositório do Universal Shell em ${_target}..."
		_ui_sub "Sincronizando com o upstream com autoproteção contra conflitos..."
		_git_pull_resilient "${_target}" || _ui_warn "Falha ao sincronizar ${_target}"

		if [ -d "${OSH:-${HOME}/.oh-my-bash}" ]; then
			_ui_sub "Atualizando Oh-My-Bash..."
			_git_pull_resilient "${OSH:-${HOME}/.oh-my-bash}" 2> "/dev/null" || true
		fi
		if [ -d "${ZSH:-${HOME}/.oh-my-zsh}" ]; then
			_ui_sub "Atualizando Oh-My-Zsh..."
			_git_pull_resilient "${ZSH:-${HOME}/.oh-my-zsh}" 2> "/dev/null" || true
		fi
		command -v _cache_clean > "/dev/null" 2>&1 && _cache_clean || true
		_ui_ok "Universal Shell atualizado com sucesso!"
		_ui_info "Recarregando ambiente do shell..."
		if [ -n "${ZSH_VERSION:-}" ] && [ -f "${HOME}/.zshrc" ]; then
			. "${HOME}/.zshrc" 2> "/dev/null" || true
		elif [ -n "${BASH_VERSION:-}" ] && [ -f "${HOME}/.bashrc" ]; then
			. "${HOME}/.bashrc" 2> "/dev/null" || true
		elif [ -f "${HOME}/.$(_detect_enabled_shell --name 2> "/dev/null")rc" ]; then
			. "${HOME}/.$(_detect_enabled_shell --name)rc" 2> "/dev/null" || true
		fi
	else
		_ui_info "Nenhum repositório de shell encontrado em /usr/local/share/shell, ~/.local/share/shell, ~/.config/shell ou ~/.shell."
	fi
	unset _target
}

### --------------------------------
### Update Editors
### --------------------------------
update-editors() {
	_found=0
	_ui_step "Atualizando a Suíte de Editores..."

	for _editor in Emacs Helix NeoVim Vim; do
		_target=""
		case "${_editor}" in
			Emacs)
				if [ -d "${HOME}/.emacs.d/.git" ]; then
					_target="${HOME}/.emacs.d"
				elif [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/emacs/.git" ]; then
					_target="${XDG_CONFIG_HOME:-${HOME}/.config}/emacs"
				fi
				;;
			Helix)
				if [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/helix/.git" ]; then
					_target="${XDG_CONFIG_HOME:-${HOME}/.config}/helix"
				elif [ -d "${APPDATA:-${HOME}/AppData/Roaming}/helix/.git" ]; then
					_target="${APPDATA:-${HOME}/AppData/Roaming}/helix"
				fi
				;;
			NeoVim)
				if [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/nvim/.git" ]; then
					_target="${XDG_CONFIG_HOME:-${HOME}/.config}/nvim"
				elif [ -d "${LOCALAPPDATA:-${HOME}/AppData/Local}/nvim/.git" ]; then
					_target="${LOCALAPPDATA:-${HOME}/AppData/Local}/nvim"
				fi
				;;
			Vim)
				if [ -d "${HOME}/.vim/.git" ]; then
					_target="${HOME}/.vim"
				elif [ -d "${HOME}/vimfiles/.git" ]; then
					_target="${HOME}/vimfiles"
				fi
				;;
		esac

		if [ -n "${_target}" ]; then
			_ui_sub "Atualizando ${_editor} em ${_target}..."
			if _git_pull_resilient "${_target}"; then
				_ui_ok "${_editor} atualizado com sucesso!"
			else
				_ui_warn "${_editor}: sincronização falhou."
			fi
			if [ "${_editor}" = "Emacs" ] && [ -f "${_target}/.gitmodules" ]; then
				_ui_sub "Sincronizando submódulos Elisp locais em ${_target}..."
				if git -C "${_target}" submodule update --init --recursive --remote --merge > "/dev/null" 2>&1; then
					_ui_ok "Submódulos Elisp atualizados com sucesso!"
				else
					_ui_warn "Falha na sincronização dos submódulos Elisp com upstream."
				fi
			fi
			_found=1
		fi
	done

	if [ "${_found}" -eq 0 ]; then
		_ui_info "Nenhum repositório de editor encontrado nos caminhos canônicos (~/.emacs.d, ~/.config/nvim, ~/.config/helix, ~/.vim, ~/vimfiles)."
	else
		_ui_ok "Suíte de Editores sincronizada!"
	fi
	unset _found _editor _target
}

### --------------------------------
### Update Emacs Modes
### --------------------------------
update-emacs-modes() {
	_target=""
	if [ -d "${HOME}/.emacs.d/.git" ]; then
		_target="${HOME}/.emacs.d"
	elif [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/emacs/.git" ]; then
		_target="${XDG_CONFIG_HOME:-${HOME}/.config}/emacs"
	fi

	if [ -z "${_target}" ]; then
		_ui_warn "Diretório do GNU Emacs não encontrado em ~/.emacs.d ou ~/.config/emacs."
		return 1
	fi

	_ui_step "Atualizando submódulos Elisp locais em ${_target}..."
	if git -C "${_target}" submodule update --init --recursive --remote --merge; then
		_ui_ok "Submódulos Elisp (aweshell, aweww, emacs-lisp-ts-mode) atualizados com sucesso!"
	else
		_ui_err "Falha na sincronização dos submódulos Elisp."
		return 1
	fi
	unset _target
}

### --------------------------------
### Update Profile
### --------------------------------
update-profile() {
	_target=""
	if [ -n "${PROFILE_DIR:-}" ] && [ -e "${PROFILE_DIR}/.git" ]; then
		_target="${PROFILE_DIR}"
	elif [ -e "${HOME}/.local/share/profile/.git" ]; then
		_target="${HOME}/.local/share/profile"
	elif [ -e "${HOME}/.config/profile/.git" ]; then
		_target="${HOME}/.config/profile"
	elif [ -e "${HOME}/.profile/.git" ]; then
		_target="${HOME}/.profile"
	elif [ -e "/usr/local/share/profile/.git" ]; then
		_target="/usr/local/share/profile"
	fi

	if [ -n "${_target}" ]; then
		_ui_step "Atualizando Universal Profile em ${_target}..."
		_ui_sub "Sincronizando com o upstream com autoproteção..."
		if _git_pull_resilient "${_target}"; then
			_ui_ok "Repositório Profile atualizado!"
		else
			_ui_warn "Profile: sincronização falhou."
		fi

		if [ -f "${_target}/profile.sh" ]; then
			_ui_sub "Executando sincronização via profile.sh..."
			sh "${_target}/profile.sh" sync 2> "/dev/null" || true
		else
			if [ -f "${_target}/scripts/sync/sync-dotfiles.sh" ]; then
				_ui_sub "Sincronizando dotfiles declarativos..."
				sh "${_target}/scripts/sync/sync-dotfiles.sh" 2> "/dev/null" || true
			fi
			if [ -f "${_target}/scripts/sync/sync-skills.sh" ]; then
				_ui_sub "Sincronizando skills de IA..."
				sh "${_target}/scripts/sync/sync-skills.sh" 2> "/dev/null" || true
			fi
		fi
		_ui_ok "Universal Profile atualizado e sincronizado com sucesso!"
	else
		_ui_info "Nenhum repositório Profile encontrado em ~/.local/share/profile, ~/.config/profile ou \$PROFILE_DIR."
	fi

	if [ -f "${HOME}/.profile" ]; then
		_ui_info "Recarregando ${HOME}/.profile..."
		. "${HOME}/.profile" > "/dev/null" 2>&1 || true
	fi
	unset _target
}

### --------------------------------
### Update Git Repositories
### --------------------------------
update-git() {
	_target_root="${1:-${PWD}}"
	if [ ! -d "${_target_root}" ]; then
		_ui_err "Diretório não encontrado: ${_target_root}"
		return 1
	fi

	_ui_step "Buscando e atualizando repositórios Git em: ${_target_root}"
	echo ""

	find "${_target_root}" -maxdepth 3 -name ".git" 2> "/dev/null" | while read -r _git_entry; do
		_repo_dir="$(dirname "${_git_entry}")"
		_ui_sub "Atualizando ${_repo_dir}..."
		_git_pull_resilient "${_repo_dir}" || _ui_warn "Falha ao atualizar ${_repo_dir}"
	done

	echo ""
	_ui_ok "Varredura e atualização de repositórios Git concluída!"
	unset _target_root _git_entry _repo_dir
}

### --------------------------------
### Reinstall Shell
### --------------------------------
reinstall-shell() {
	if [ -z "${SHELL_REPO_DIR}" ] || [ ! -d "${SHELL_REPO_DIR}" ]; then
		_ui_err "SHELL_REPO_DIR is not set or invalid."
		_ui_info "Please re-run the install.sh script from your shell repository."
		return 1
	fi

	_ui_step "Atualizando repositório do Universal Shell em ${SHELL_REPO_DIR}..."
	command git -C "${SHELL_REPO_DIR}" pull || {
		_ui_err "git pull failed."
		return 1
	}

	_cache_clean

	local _args="--context ${SHELL_CONTEXT:-desktop}"
	if [ "${SHELL_FRAMEWORK:-0}" -eq 1 ]; then
		_args="${_args} --framework"
	fi

	local _cur_bin="$(_detect_enabled_shell)"
	local _cur_shell="$(_detect_enabled_shell --name)"

	_ui_sub "Reinstalando via install.sh com contexto '${SHELL_CONTEXT:-desktop}' (${_cur_shell})..."
	"${_cur_bin}" "${SHELL_REPO_DIR}/install.sh" ${_args} "$@"

	_ui_info "Recarregando ambiente do shell..."
	. "${HOME}/.${_cur_shell}rc" 2> "/dev/null" || true

	_ui_ok "Universal Shell totalmente reinstalado e recarregado!"
}

### --------------------------------
### Benchmark Shell
### --------------------------------
bench-shell() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -f "${SHELL_REPO_DIR}/benchmark.sh" ]; then
		local _cur_bin="$(_detect_enabled_shell)"
		"${_cur_bin}" "${SHELL_REPO_DIR}/benchmark.sh" "$@"
	else
		_ui_err "Script de benchmark não encontrado em ${SHELL_REPO_DIR}/benchmark.sh."
		return 1
	fi
}

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
### Package Managers
### --------------------------------
update-pacman() {
	command -v pacman > "/dev/null" 2>&1 || { _ui_err "pacman não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via pacman..."
	if [ "$(_detect_os)" = "windows" ]; then
		command pacman --noconfirm -Syu "$@"
	else
		_as_root pacman --noconfirm -Syu "$@"
	fi
}

update-apt() {
	command -v apt > "/dev/null" 2>&1 || { _ui_err "apt não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via apt..."
	_as_root apt update && _as_root apt upgrade --yes "$@"
}

update-dnf() {
	command -v dnf > "/dev/null" 2>&1 || { _ui_err "dnf não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via dnf..."
	_as_root dnf upgrade --assumeyes "$@"
}

update-zypper() {
	command -v zypper > "/dev/null" 2>&1 || { _ui_err "zypper não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via zypper..."
	_as_root zypper --non-interactive update "$@"
}

update-xbps() {
	command -v xbps-install > "/dev/null" 2>&1 || { _ui_err "xbps-install não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via xbps..."
	_as_root xbps-install --yes -Su "$@"
}

update-apk() {
	command -v apk > "/dev/null" 2>&1 || { _ui_err "apk não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via apk..."
	_as_root apk update && _as_root apk upgrade "$@"
}

update-pkg() {
	command -v pkg > "/dev/null" 2>&1 || { _ui_err "pkg não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via pkg (FreeBSD)..."
	_as_root pkg update && _as_root pkg upgrade --yes "$@"
}

update-aur() {
	if command -v paru > "/dev/null" 2>&1; then
		_ui_step "Executando atualização de pacotes AUR via paru..."
		command paru --noconfirm -Syu "$@"
	elif command -v yay > "/dev/null" 2>&1; then
		_ui_step "Executando atualização de pacotes AUR via yay..."
		command yay --noconfirm -Syu "$@"
	else
		_ui_err "Nenhum helper AUR ('paru' ou 'yay') encontrado no sistema."
		return 127
	fi
}

update-flatpak() {
	command -v flatpak > "/dev/null" 2>&1 || { _ui_err "flatpak não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via Flatpak..."
	command flatpak update --assumeyes "$@"
}

update-snap() {
	command -v snap > "/dev/null" 2>&1 || { _ui_err "snap não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via Snap..."
	_as_root snap refresh "$@"
}

update-pkg-add() {
	command -v pkg_add > "/dev/null" 2>&1 || { _ui_err "pkg_add não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via pkg_add (OpenBSD)..."
	command -v syspatch > "/dev/null" 2>&1 && _as_root syspatch
	_as_root pkg_add -u "$@"
}

update-pkgin() {
	command -v pkgin > "/dev/null" 2>&1 || { _ui_err "pkgin não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via pkgin..."
	_as_root pkgin -y update && _as_root pkgin -y upgrade "$@"
}

update-ips() {
	command -v pkg > "/dev/null" 2>&1 || { _ui_err "pkg (IPS) não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via pkg IPS (illumos/Solaris)..."
	_as_root pkg refresh && _as_root pkg update "$@"
}

update-brew() {
	command -v brew > "/dev/null" 2>&1 || { _ui_err "brew não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via Homebrew..."
	brew update && brew upgrade "$@"
}

update-mas() {
	command -v mas > "/dev/null" 2>&1 || { _ui_err "mas não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via Mac App Store (mas)..."
	mas upgrade "$@"
}

### --------------------------------
### Update System
### --------------------------------
update-system() {
	_ui_step "Atualizando pacotes do sistema operacional..."
	case "$(_detect_distro_family)" in
		arch)   command -v pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
		debian) command -v apt > "/dev/null" 2>&1 && update-apt "$@" ;;
		fedora) command -v dnf > "/dev/null" 2>&1 && update-dnf "$@" ;;
		suse)   command -v zypper > "/dev/null" 2>&1 && update-zypper "$@" ;;
		void)   command -v xbps-install > "/dev/null" 2>&1 && update-xbps "$@" ;;
		alpine) command -v apk > "/dev/null" 2>&1 && update-apk "$@" ;;
		*)
			case "$(_detect_os)" in
				freebsd) command -v pkg > "/dev/null" 2>&1 && update-pkg "$@" ;;
				openbsd) command -v pkg_add > "/dev/null" 2>&1 && update-pkg-add "$@" ;;
				netbsd)  command -v pkgin > "/dev/null" 2>&1 && update-pkgin "$@" ;;
				illumos)
					if [ -f "/etc/release" ] && grep -qiE "omnios|openindiana|solaris" "/etc/release" 2> "/dev/null"; then
						update-ips "$@"
					elif command -v pkgin > "/dev/null" 2>&1; then
						update-pkgin "$@"
					elif command -v pkg > "/dev/null" 2>&1; then
						update-ips "$@"
					fi
					;;
				macos)   command -v brew > "/dev/null" 2>&1 && update-brew "$@" ;;
				windows) command -v pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
			esac
			;;
	esac
	_ui_ok "Pacotes do sistema operacional atualizados com sucesso!"
}

### --------------------------------
### Update All Packages
### --------------------------------
update-all() {
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

	_ui_banner "Atualização Geral Concluída com Sucesso!"
}

### --------------------------------
### Poweroff System
### --------------------------------
poweroff() {
	case "$(_detect_os)" in
		windows)
			shutdown.exe /s /t 0 "$@"
			return $?
			;;
		freebsd)
			_flag="-p"
			;;
		*)
			_flag="-h"
			;;
	esac

	_as_root shutdown "${_flag}" now "$@"
	unset _flag
}

### --------------------------------
### Reboot System
### --------------------------------
reboot() {
	case "$(_detect_os)" in
		windows)
			shutdown.exe /r /t 0 "$@"
			return $?
			;;
		*)
			_as_root shutdown -r now "$@"
			;;
	esac
}

### ================================
### Version Control: Got & Git
### ================================
vcs-status() {
	if [ -d ".got" ] || [ -f ".got/base-commit" ]; then
		got status "$@"
	elif [ -d ".git" ] || git rev-parse --git-dir > "/dev/null" 2>&1; then
		git status --short "$@"
	else
		_ui_warn "Não é um repositório Git ou Work Tree Got."
		return 1
	fi
}

vcs-diff() {
	if [ -d ".got" ] || [ -f ".got/base-commit" ]; then
		got diff "$@"
	elif [ -d ".git" ] || git rev-parse --git-dir > "/dev/null" 2>&1; then
		git diff "$@"
	else
		_ui_warn "Não é um repositório Git ou Work Tree Got."
		return 1
	fi
}

got-init() {
	if [ "$#" -lt 2 ]; then
		_ui_err "Uso: got-init <url-do-repositorio> <diretorio-destino>"
		_ui_info "Exemplo: got-init https://github.com/usuario/repo.git meu-projeto"
		return 1
	fi
	_got_url="$1"
	_got_dir="$2"
	_got_bare="${_got_dir}.git"

	_ui_step "[Got]: Clonando repositório bare..."
	got clone "${_got_url}" "${_got_bare}" || return 1

	_ui_sub "[Got]: Criando work tree em ${_got_dir}..."
	got checkout "${_got_bare}" "${_got_dir}" || return 1

	_ui_ok "[Got]: Inicializado com sucesso! Acesse: cd ${_got_dir}"
	unset _got_url _got_dir _got_bare
}

### --------------------------------
### Directory Creation & Navigation
### --------------------------------
take-dir() {
	if [ "$#" -eq 0 ]; then
		echo "Uso: take <diretorio>" >&2
		return 1
	fi
	command mkdir -p "$1" && cd "$1"
}

### --------------------------------
### Git Root Navigation
### --------------------------------
cd-git-root() {
	local _root
	_root="$(command git rev-parse --show-toplevel 2> "/dev/null")" || {
		_ui_err "Não está dentro de um repositório git."
		return 1
	}
	cd "${_root}"
}

### --------------------------------
### History Keyword Search
### --------------------------------
hist-search() {
	if [ "$#" -eq 0 ]; then
		if [ -n "${BASH_VERSION:-}" ]; then
			command history 30
		elif [ -n "${ZSH_VERSION:-}" ]; then
			command history -30
		else
			command fc -l -30 2> "/dev/null" || command fc -l -1 2> "/dev/null"
		fi
	else
		if [ -n "${BASH_VERSION:-}" ]; then
			command history | command grep -i "$@"
		elif [ -n "${ZSH_VERSION:-}" ]; then
			command history 1 | command grep -i "$@"
		else
			command fc -l 1 2> "/dev/null" | command grep -i "$@"
		fi
	fi
}

### --------------------------------
### Smart Archive Extraction
### --------------------------------
extract-archive() {
	if [ "$#" -eq 0 ]; then
		echo "Uso: extract <arquivo>" >&2
		return 1
	fi
	if [ ! -f "$1" ]; then
		_ui_err "Arquivo '$1' não encontrado."
		return 1
	fi
	case "$1" in
		*.tar.bz2|*.tbz2)   command tar -xjvf "$1" ;;
		*.tar.gz|*.tgz)     command tar -xzvf "$1" ;;
		*.tar.xz|*.txz)     command tar -xJvf "$1" ;;
		*.tar.zst)          command tar --zstd -xvf "$1" 2> "/dev/null" || command tar -xvf "$1" ;;
		*.tar)              command tar -xvf "$1" ;;
		*.gz)               command gunzip "$1" ;;
		*.bz2)              command bunzip2 "$1" ;;
		*.xz)               command unxz "$1" ;;
		*.zip)              command unzip "$1" ;;
		*.7z)               command 7z x "$1" ;;
		*.rar)              command unrar x "$1" ;;
		*.Z)                command uncompress "$1" ;;
		*)                  _ui_err "Formato não suportado para extração: '$1'"; return 1 ;;
	esac
}
