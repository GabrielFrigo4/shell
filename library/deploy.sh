# ----------------------------------------------------------------
# Module: Shell Declarative Deployment Engine
# ----------------------------------------------------------------

### ================================
### PATH RESOLUTION
### ================================
_deploy_win_paths() {
	_cfg="${XDG_CONFIG_HOME:-${HOME}/.config}"
	_is_win=0
	_win_home="${USERPROFILE:-${HOME}}"
	_win_app="${APPDATA:-${_win_home}/AppData/Roaming}"
	_win_local="${LOCALAPPDATA:-${_win_home}/AppData/Local}"

	case "$(uname -s 2> "/dev/null" || echo "unknown")" in
		MINGW*|MSYS*|CYGWIN*|*_NT*)
			_is_win=1
			if command -v cygpath > "/dev/null" 2>&1; then
				_win_home="$(cygpath -u "${USERPROFILE:-/c/Users/${USER}}")"
				_win_app="$(cygpath -u "${APPDATA:-${_win_home}/AppData/Roaming}")"
				_win_local="$(cygpath -u "${LOCALAPPDATA:-${_win_home}/AppData/Local}")"
				_od_win="${OneDriveConsumer:-${OneDrive:-${USERPROFILE}\\OneDrive}}"
				_win_onedrive="$(cygpath -u "${_od_win}")"
			else
				_win_onedrive="${_win_home}/OneDrive"
			fi

			_win_docs=""
			if [ -n "${_win_onedrive}" ] && [ -d "${_win_onedrive}" ]; then
				for _cand in "${_win_onedrive}/Documentos" "${_win_onedrive}/Documents"; do
					[ -d "${_cand}" ] && _win_docs="${_cand}" && break
				done
				[ -z "${_win_docs}" ] && _win_docs="${_win_onedrive}/Documentos"
			else
				for _cand in "${_win_home}/Documentos" "${_win_home}/Documents"; do
					[ -d "${_cand}" ] && _win_docs="${_cand}" && break
				done
				[ -z "${_win_docs}" ] && _win_docs="${_win_home}/Documents"
			fi
			;;
	esac
}

### ================================
### DECLARATIVE LINK ENGINE
### ================================
_deploy_item() {
	_src="$1"
	_dst="$2"

	if [ ! -e "${_src}" ]; then
		return 0
	fi

	mkdir -p "$(dirname "${_dst}")"

	if [ -L "${_dst}" ] || [ -e "${_dst}" ]; then
		if [ -L "${_dst}" ] && [ "$(readlink "${_dst}" 2> "/dev/null" || true)" = "${_src}" ]; then
			_ui_sub "[IN-SYNC] ${_dst}"
			return 0
		fi
		if [ -f "${_dst}" ] && cmp -s "${_src}" "${_dst}" 2> "/dev/null"; then
			_ui_sub "[IN-SYNC] ${_dst}"
			return 0
		fi
		rm -rf "${_dst}" 2> "/dev/null" || true
	fi

	export MSYS="winsymlinks:nativestrict"
	if ln -sf "${_src}" "${_dst}" 2> "/dev/null"; then
		_ui_ok "[LINK] ${_dst}"
	else
		cp -rf "${_src}" "${_dst}"
		_ui_warn "[COPY] ${_dst}"
	fi
	chmod 0644 "${_dst}" 2> "/dev/null" || true
}

### ================================
### EXTENDED SHELL INSTALLER
### ================================
_install_extended_shell() {
	_target_shell="$1"
	_deploy_win_paths

	case "${_target_shell}" in
		fish)
			_ui_step "Implantando perfil Fish Shell..."
			_fish_src="${SHELL_REPO_DIR}/target/common/fish/config.fish"
			_fish_dst="${_cfg}/fish/config.fish"
			_deploy_item "${_fish_src}" "${_fish_dst}"
			;;
		pwsh|powershell)
			_ui_step "Implantando perfil PowerShell..."
			_pwsh_dir="${SHELL_REPO_DIR}/target/windows/powershell"
			if [ "${_is_win}" -eq 1 ]; then
				_deploy_item "${_pwsh_dir}/profile.ps1" "${_win_docs}/PowerShell/profile.ps1"
				_deploy_item "${_pwsh_dir}/Microsoft.PowerShell_profile.ps1" "${_win_docs}/PowerShell/Microsoft.PowerShell_profile.ps1"
				_deploy_item "${_pwsh_dir}/profile.ps1" "${_win_docs}/WindowsPowerShell/profile.ps1"
				_deploy_item "${_pwsh_dir}/Microsoft.PowerShell_profile.ps1" "${_win_docs}/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"

				if [ -n "${_win_onedrive}" ] && [ "${_win_docs}" != "${_win_home}/Documents" ] && [ "${_win_docs}" != "${_win_home}/Documentos" ]; then
					for _legacy_doc in "${_win_home}/Documents" "${_win_home}/Documentos" "${HOME}/Documents" "${HOME}/Documentos"; do
						if [ -d "${_legacy_doc}" ] && [ "${_legacy_doc}" != "${_win_docs}" ]; then
							rm -f "${_legacy_doc}/PowerShell/profile.ps1" "${_legacy_doc}/PowerShell/Microsoft.PowerShell_profile.ps1" 2> "/dev/null" || true
							rm -f "${_legacy_doc}/WindowsPowerShell/profile.ps1" "${_legacy_doc}/WindowsPowerShell/Microsoft.PowerShell_profile.ps1" 2> "/dev/null" || true
							rmdir "${_legacy_doc}/PowerShell" 2> "/dev/null" || true
							rmdir "${_legacy_doc}/WindowsPowerShell" 2> "/dev/null" || true
						fi
					done
				fi
			else
				_deploy_item "${_pwsh_dir}/profile.ps1" "${_cfg}/powershell/profile.ps1"
				_deploy_item "${_pwsh_dir}/Microsoft.PowerShell_profile.ps1" "${_cfg}/powershell/Microsoft.PowerShell_profile.ps1"
			fi
			;;
		nu|nushell)
			_ui_step "Implantando perfil NuShell..."
			_nu_dir="${SHELL_REPO_DIR}/target/windows/nushell"
			if [ "${_is_win}" -eq 1 ]; then
				_deploy_item "${_nu_dir}/config.nu" "${_win_app}/nushell/config.nu"
				_deploy_item "${_nu_dir}/env.nu" "${_win_app}/nushell/env.nu"
			else
				_deploy_item "${_nu_dir}/config.nu" "${_cfg}/nushell/config.nu"
				_deploy_item "${_nu_dir}/env.nu" "${_cfg}/nushell/env.nu"
			fi
			;;
		cmd)
			_ui_step "Implantando perfis CMD e Clink..."
			_cmd_dir="${SHELL_REPO_DIR}/target/windows/cmd"
			if [ "${_is_win}" -eq 1 ]; then
				_deploy_item "${_cmd_dir}/profile.lua" "${_win_local}/clink/profile.lua"
				_deploy_item "${_cmd_dir}/profile.cmd" "${_win_local}/clink/profile.cmd"
				_deploy_item "${_cmd_dir}/profile.cmd" "${_win_home}/profile.cmd"
				_deploy_item "${_cmd_dir}/autorun.cmd" "${_win_home}/autorun.cmd"
			else
				_ui_info "CMD (Clink) é exclusivo para ambientes Windows."
			fi
			;;
	esac
}
