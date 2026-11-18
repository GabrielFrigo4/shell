# ----------------------------------------------------------------
# Library: Cross-Platform System Package Updaters
# ----------------------------------------------------------------

### --------------------------------
### PACKAGE MANAGERS
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
### UPDATE SYSTEM
### --------------------------------
update-system() {
	_ui_step "Atualizando pacotes do sistema operacional..."
	local _ret=0 _handled=1

	case "$(_detect_distro_family)" in
		arch)
			if command -v pacman > "/dev/null" 2>&1; then update-pacman "$@" || _ret=$?; else _handled=0; fi
			;;
		debian)
			if command -v apt > "/dev/null" 2>&1; then update-apt "$@" || _ret=$?; else _handled=0; fi
			;;
		fedora)
			if command -v dnf > "/dev/null" 2>&1; then
				update-dnf "$@" || _ret=$?
			elif command -v tdnf > "/dev/null" 2>&1; then
				update-tdnf "$@" || _ret=$?
			else
				_handled=0
			fi
			;;
		suse)
			if command -v zypper > "/dev/null" 2>&1; then update-zypper "$@" || _ret=$?; else _handled=0; fi
			;;
		void)
			if command -v xbps-install > "/dev/null" 2>&1; then update-xbps "$@" || _ret=$?; else _handled=0; fi
			;;
		alpine)
			if command -v apk > "/dev/null" 2>&1; then update-apk "$@" || _ret=$?; else _handled=0; fi
			;;
		gentoo)
			if command -v emerge > "/dev/null" 2>&1; then update-emerge "$@" || _ret=$?; else _handled=0; fi
			;;
		nixos)
			if command -v nixos-rebuild > "/dev/null" 2>&1; then update-nix "$@" || _ret=$?; else _handled=0; fi
			;;
		solus)
			if command -v eopkg > "/dev/null" 2>&1; then update-eopkg "$@" || _ret=$?; else _handled=0; fi
			;;
		slackware)
			if command -v slackpkg > "/dev/null" 2>&1; then update-slackpkg "$@" || _ret=$?; else _handled=0; fi
			;;
		guix)
			if command -v guix > "/dev/null" 2>&1; then update-guix "$@" || _ret=$?; else _handled=0; fi
			;;
		embedded)
			if command -v opkg > "/dev/null" 2>&1; then update-opkg "$@" || _ret=$?; else _handled=0; fi
			;;
		*)
			case "$(_detect_os)" in
				freebsd)
					if command -v pkg > "/dev/null" 2>&1; then update-pkg "$@" || _ret=$?; else _handled=0; fi
					;;
				openbsd)
					if command -v pkg_add > "/dev/null" 2>&1; then update-pkg-add "$@" || _ret=$?; else _handled=0; fi
					;;
				netbsd)
					if command -v pkgin > "/dev/null" 2>&1; then update-pkgin "$@" || _ret=$?; else _handled=0; fi
					;;
				illumos)
					if [ -f "/etc/release" ] && grep -qiE "omnios|openindiana|solaris" "/etc/release" 2> "/dev/null"; then
						update-ips "$@" || _ret=$?
					elif command -v pkgin > "/dev/null" 2>&1; then
						update-pkgin "$@" || _ret=$?
					elif command -v pkg > "/dev/null" 2>&1; then
						update-ips "$@" || _ret=$?
					else
						_handled=0
					fi
					;;
				macos)
					if command -v brew > "/dev/null" 2>&1; then update-brew "$@" || _ret=$?; else _handled=0; fi
					;;
				windows)
					if command -v pacman > "/dev/null" 2>&1; then update-pacman "$@" || _ret=$?; else _handled=0; fi
					;;
				*)
					_handled=0
					;;
			esac
			;;
	esac

	if [ "${_handled}" -eq 0 ]; then
		_ui_err "Nenhum gerenciador de pacotes suportado foi detectado para esta plataforma."
		return 127
	fi
	if [ "${_ret}" -ne 0 ]; then
		_ui_err "Falha na atualização dos pacotes do sistema (código ${_ret})."
		return "${_ret}"
	fi
	_ui_ok "Pacotes do sistema operacional atualizados com sucesso!"
}
