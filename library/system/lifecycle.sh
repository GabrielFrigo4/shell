# ----------------------------------------------------------------
# Library: System Lifecycle, Cleanup & Global Orchestration
# ----------------------------------------------------------------

### CLEAN SYSTEM
### --------------------------------
clean-system() {
	for _arg in "$@"; do
		case "${_arg}" in
			--dry-run|-n)
				_ui_info "Simulação: pacotes órfãos e caches de sistema seriam limpos."
				return 0
				;;
			--help|-h)
				cat <<- 'EOF'
				Uso: clean-system [opções] (alias: cleansys, sysclean, syscls, clear-system, clearsys)

				Limpeza de pacotes órfãos, dependências obsoletas e caches do sistema operacional.

				Ações por plataforma:
				  - Debian / Ubuntu:     apt autoremove --yes && apt clean
				  - Fedora / RHEL:       dnf autoremove --assumeyes && dnf clean packages
				  - Azure Linux:         tdnf clean all
				  - Arch Linux:          pacman -Rns (órfãos) && paccache -r
				  - Void Linux:          xbps-remove -o && xbps-remove -O
				  - Alpine Linux:        apk cache clean
				  - openSUSE:            zypper clean --all
				  - Gentoo:              emerge --depclean
				  - NixOS:               nix-collect-garbage -d
				  - Solus:               eopkg delete-cache
				  - Guix:                guix gc
				  - OpenWrt:             limpeza de listas do opkg
				  - FreeBSD:             pkg autoremove --yes && pkg clean --yes
				  - OpenBSD:             pkg_delete -a
				  - NetBSD / illumos:    pkgin autoremove && pkgin clean
				  - macOS:               brew cleanup --prune=all
				  - Flatpak:             flatpak uninstall --unused --assumeyes

				Opções:
				  -n, --dry-run        Simula a limpeza sem remover pacotes
				  -h, --help           Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	_ui_step "Executando limpeza de pacotes órfãos e caches do sistema..."

	case "$(_detect_distro_family)" in
		arch)
			if command -v pacman > "/dev/null" 2>&1; then
				_orphans="$(pacman -Qtdq 2> "/dev/null" || true)"
				if [ -n "${_orphans}" ]; then
					_ui_sub "Removendo pacotes órfãos via pacman..."
					if [ "$(_detect_os)" = "windows" ]; then
						# shellcheck disable=SC2086
						command pacman -Rns --noconfirm ${_orphans}
					else
						# shellcheck disable=SC2086
						_as_root pacman -Rns --noconfirm ${_orphans}
					fi
				fi
				if command -v paccache > "/dev/null" 2>&1; then
					_ui_sub "Limpando cache de pacotes antigos via paccache..."
					_as_root paccache -r > "/dev/null" 2>&1 || true
				fi
			fi
			;;
		debian)
			if command -v apt > "/dev/null" 2>&1; then
				_ui_sub "Removendo pacotes órfãos via apt autoremove..."
				_as_root apt autoremove --yes
				_ui_sub "Limpando cache de pacotes baixados pelo apt..."
				_as_root apt clean > "/dev/null" 2>&1 || true
			elif command -v apt-get > "/dev/null" 2>&1; then
				_ui_sub "Removendo pacotes órfãos via apt-get autoremove..."
				_as_root apt-get autoremove --yes
				_ui_sub "Limpando cache de pacotes baixados pelo apt-get..."
				_as_root apt-get clean > "/dev/null" 2>&1 || true
			fi
			;;
		fedora)
			if command -v dnf > "/dev/null" 2>&1; then
				_ui_sub "Removendo pacotes órfãos via dnf autoremove..."
				_as_root dnf autoremove --assumeyes
				_ui_sub "Limpando cache de pacotes baixados pelo dnf..."
				_as_root dnf clean packages > "/dev/null" 2>&1 || true
			elif command -v tdnf > "/dev/null" 2>&1; then
				_ui_sub "Limpando cache de pacotes do tdnf..."
				_as_root tdnf clean all > "/dev/null" 2>&1 || true
			fi
			;;
		suse)
			if command -v zypper > "/dev/null" 2>&1; then
				_ui_sub "Limpando cache de pacotes via zypper..."
				_as_root zypper clean --all > "/dev/null" 2>&1 || true
			fi
			;;
		void)
			if command -v xbps-remove > "/dev/null" 2>&1; then
				_ui_sub "Removendo pacotes órfãos via xbps-remove..."
				_as_root xbps-remove --yes --remove-orphans > "/dev/null" 2>&1 || true
				_ui_sub "Limpando cache de pacotes do xbps..."
				_as_root xbps-remove --yes --clean-cache > "/dev/null" 2>&1 || true
			fi
			;;
		alpine)
			if command -v apk > "/dev/null" 2>&1; then
				_ui_sub "Limpando cache de pacotes do apk..."
				_as_root apk cache clean > "/dev/null" 2>&1 || true
			fi
			;;
		gentoo)
			if command -v emerge > "/dev/null" 2>&1; then
				_ui_sub "Removendo dependências órfãs via emerge --depclean..."
				_as_root emerge --depclean -q > "/dev/null" 2>&1 || true
			fi
			;;
		nixos)
			if command -v nix-collect-garbage > "/dev/null" 2>&1; then
				_ui_sub "Coletando lixo do Nix store..."
				_as_root nix-collect-garbage -d > "/dev/null" 2>&1 || true
			fi
			;;
		solus)
			if command -v eopkg > "/dev/null" 2>&1; then
				_ui_sub "Limpando cache de pacotes via eopkg..."
				_as_root eopkg delete-cache > "/dev/null" 2>&1 || true
			fi
			;;
		guix)
			if command -v guix > "/dev/null" 2>&1; then
				_ui_sub "Coletando lixo do Guix store..."
				guix gc > "/dev/null" 2>&1 || true
			fi
			;;
		embedded)
			if command -v opkg > "/dev/null" 2>&1; then
				_ui_sub "Limpando caches de listas do opkg..."
				_as_root rm -rf /var/opkg-lists/* > "/dev/null" 2>&1 || true
			fi
			;;
		bsd|illumos|*)
			case "$(_detect_os)" in
				freebsd)
					if command -v pkg > "/dev/null" 2>&1; then
						_ui_sub "Removendo pacotes órfãos via pkg autoremove..."
						_as_root pkg autoremove --yes
						_ui_sub "Limpando cache de pacotes via pkg clean..."
						_as_root pkg clean --yes > "/dev/null" 2>&1 || true
					fi
					;;
				openbsd)
					if command -v pkg_delete > "/dev/null" 2>&1; then
						_ui_sub "Removendo dependências órfãs via pkg_delete..."
						_as_root pkg_delete -a > "/dev/null" 2>&1 || true
					fi
					;;
				netbsd|illumos)
					if command -v pkgin > "/dev/null" 2>&1; then
						_ui_sub "Removendo pacotes órfãos via pkgin autoremove..."
						_as_root pkgin -y autoremove > "/dev/null" 2>&1 || true
						_as_root pkgin -y clean > "/dev/null" 2>&1 || true
					fi
					;;
				macos)
					if command -v brew > "/dev/null" 2>&1; then
						_ui_sub "Executando limpeza de dependências obsoletas via Homebrew..."
						brew cleanup --prune=all
					fi
					;;
				windows)
					if command -v pacman > "/dev/null" 2>&1; then
						_orphans="$(pacman -Qtdq 2> "/dev/null" || true)"
						if [ -n "${_orphans}" ]; then
							# shellcheck disable=SC2086
							command pacman -Rns --noconfirm ${_orphans}
						fi
					fi
					;;
			esac
			;;
	esac

	if [ "$(_detect_os)" != "macos" ] && command -v brew > "/dev/null" 2>&1; then
		_ui_sub "Executando limpeza de dependências obsoletas via Linuxbrew..."
		brew cleanup --prune=all > "/dev/null" 2>&1 || true
	fi

	if command -v flatpak > "/dev/null" 2>&1; then
		_ui_sub "Removendo runtimes órfãos do Flatpak..."
		command flatpak uninstall --unused --assumeyes 2> "/dev/null" || true
	fi

	_ui_ok "Limpeza do sistema concluída com sucesso!"
}

alias cleansys="clean-system"
alias clearsys="clean-system"
alias sysclean="clean-system"
alias syscls="clean-system"
alias clear-system="clean-system"

### --------------------------------
### UPDATE ALL PACKAGES
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

### --------------------------------
### POWEROFF & REBOOT SYSTEM
### --------------------------------
poweroff() {
	local _os="${_DETECTED_OS:-$(_detect_os)}"
	local _flag="-h"
	case "${_os}" in
		windows)                shutdown.exe /s /t 0 "$@"; return $? ;;
		illumos|sunos)          _as_root poweroff "$@"; return $? ;;
		freebsd|openbsd|netbsd) _flag="-p" ;;
	esac
	_as_root shutdown "${_flag}" now "$@"
}

reboot() {
	local _os="${_DETECTED_OS:-$(_detect_os)}"
	case "${_os}" in
		windows) shutdown.exe /r /t 0 "$@"; return $? ;;
		*)       _as_root shutdown -r now "$@" ;;
	esac
}
