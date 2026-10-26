# ----------------------------------------------------------------
# Library: Operating System Package Managers & System Cleanup
# ----------------------------------------------------------------

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
	_as_root apt update && _as_root apt full-upgrade --yes "$@"
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
	_ui_step "Executando atualização de pacotes via pkg (FreeBSD/DragonFly)..."
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

update-tdnf() {
	command -v tdnf > "/dev/null" 2>&1 || { _ui_err "tdnf não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via tdnf (Azure Linux / Photon)..."
	_as_root tdnf upgrade --refresh -y "$@"
}

update-guix() {
	command -v guix > "/dev/null" 2>&1 || { _ui_err "guix não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via GNU Guix..."
	guix pull && guix package -u "$@"
}

update-opkg() {
	command -v opkg > "/dev/null" 2>&1 || { _ui_err "opkg não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via opkg (OpenWrt)..."
	_as_root opkg update && _as_root opkg upgrade "$@"
}

update-emerge() {
	command -v emerge > "/dev/null" 2>&1 || { _ui_err "emerge não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via Portage emerge (Gentoo)..."
	_as_root emerge --sync && _as_root emerge -uDN @world "$@"
}

update-nix() {
	if command -v nixos-rebuild > "/dev/null" 2>&1; then
		_ui_step "Executando atualização de pacotes via nixos-rebuild (NixOS)..."
		_as_root nixos-rebuild switch --upgrade "$@"
	elif command -v nix-channel > "/dev/null" 2>&1; then
		_ui_step "Executando atualização de pacotes via Nix..."
		nix-channel --update && nix-env -u "$@"
	else
		_ui_err "nixos-rebuild ou nix-channel não encontrado no sistema."
		return 127
	fi
}

update-eopkg() {
	command -v eopkg > "/dev/null" 2>&1 || { _ui_err "eopkg não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via eopkg (Solus)..."
	_as_root eopkg upgrade "$@"
}

update-slackpkg() {
	command -v slackpkg > "/dev/null" 2>&1 || { _ui_err "slackpkg não encontrado no sistema."; return 127; }
	_ui_step "Executando atualização de pacotes via slackpkg (Slackware)..."
	_as_root slackpkg update && _as_root slackpkg upgrade-all "$@"
}

### --------------------------------
### Update System
### --------------------------------
update-system() {
	_ui_step "Atualizando pacotes do sistema operacional..."
	case "$(_detect_distro_family)" in
		arch)      command -v pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
		debian)    command -v apt > "/dev/null" 2>&1 && update-apt "$@" ;;
		fedora)
			if command -v dnf > "/dev/null" 2>&1; then
				update-dnf "$@"
			elif command -v tdnf > "/dev/null" 2>&1; then
				update-tdnf "$@"
			fi
			;;
		suse)      command -v zypper > "/dev/null" 2>&1 && update-zypper "$@" ;;
		void)      command -v xbps-install > "/dev/null" 2>&1 && update-xbps "$@" ;;
		alpine)    command -v apk > "/dev/null" 2>&1 && update-apk "$@" ;;
		gentoo)    command -v emerge > "/dev/null" 2>&1 && update-emerge "$@" ;;
		nixos)     command -v nixos-rebuild > "/dev/null" 2>&1 && update-nix "$@" ;;
		solus)     command -v eopkg > "/dev/null" 2>&1 && update-eopkg "$@" ;;
		slackware) command -v slackpkg > "/dev/null" 2>&1 && update-slackpkg "$@" ;;
		guix)      command -v guix > "/dev/null" 2>&1 && update-guix "$@" ;;
		embedded)  command -v opkg > "/dev/null" 2>&1 && update-opkg "$@" ;;
		bsd)
			case "$(_detect_os)" in
				freebsd|dragonfly) command -v pkg > "/dev/null" 2>&1 && update-pkg "$@" ;;
				openbsd)           command -v pkg_add > "/dev/null" 2>&1 && update-pkg-add "$@" ;;
				netbsd)            command -v pkgin > "/dev/null" 2>&1 && update-pkgin "$@" ;;
			esac
			;;
		illumos)
			if [ -f "/etc/release" ] && grep -qiE "omnios|openindiana|solaris" "/etc/release" 2> "/dev/null"; then
				update-ips "$@"
			elif command -v pkgin > "/dev/null" 2>&1; then
				update-pkgin "$@"
			elif command -v pkg > "/dev/null" 2>&1; then
				update-ips "$@"
			fi
			;;
		darwin)    command -v brew > "/dev/null" 2>&1 && update-brew "$@" ;;
		*)
			case "$(_detect_os)" in
				freebsd|dragonfly) command -v pkg > "/dev/null" 2>&1 && update-pkg "$@" ;;
				openbsd)           command -v pkg_add > "/dev/null" 2>&1 && update-pkg-add "$@" ;;
				netbsd)            command -v pkgin > "/dev/null" 2>&1 && update-pkgin "$@" ;;
				illumos)
					if [ -f "/etc/release" ] && grep -qiE "omnios|openindiana|solaris" "/etc/release" 2> "/dev/null"; then
						update-ips "$@"
					elif command -v pkgin > "/dev/null" 2>&1; then
						update-pkgin "$@"
					elif command -v pkg > "/dev/null" 2>&1; then
						update-ips "$@"
					fi
					;;
				macos)             command -v brew > "/dev/null" 2>&1 && update-brew "$@" ;;
				windows)           command -v pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
			esac
			;;
	esac
	_ui_ok "Pacotes do sistema operacional atualizados com sucesso!"
}

### --------------------------------
### Clean System
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
				  - FreeBSD / DragonFly: pkg autoremove --yes && pkg clean --yes
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
				rm -rf /var/opkg-lists/* > "/dev/null" 2>&1 || true
			fi
			;;
		bsd|illumos|*)
			case "$(_detect_os)" in
				freebsd|dragonfly)
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
