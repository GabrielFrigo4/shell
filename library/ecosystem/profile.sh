# ----------------------------------------------------------------
# Library: Profile & IDE Extensions Synchronization
# ----------------------------------------------------------------

### --------------------------------
### UPDATE PROFILE
### --------------------------------
update-profile() {
	local _arg _target _is_dry _is_status _exec_sh
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-profile [opções] [argumentos-do-profile.sh] (alias: uprc, upprofile, sync-profile)

				Atualiza o repositório Universal Profile e executa sincronização de dotfiles.

				Opções:
				  -s, --status        Audita o status e compara divergências (drift)
				  -n, --dry-run       Simula a sincronização sem alterar arquivos
				  -b, --backup        Cria backup (.bak) antes de substituir arquivos
				  -e, --extensions    Sincroniza extensões declarativas de IDE
				  --pull              Reconcilia alterações do sistema de volta ao Git
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

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
		_is_dry=0
		_is_status=0
		for _arg in "$@"; do
			case "${_arg}" in
				--dry-run|-n) _is_dry=1 ;;
				--status|-s)  _is_status=1 ;;
			esac
		done

		if [ "${_is_dry}" -eq 0 ] && [ "${_is_status}" -eq 0 ]; then
			_ui_step "Atualizando Universal Profile em ${_target}..."
			_ui_sub "Sincronizando com o upstream com autoproteção..."
			if _git_pull_resilient "${_target}"; then
				_ui_ok "Repositório Profile atualizado!"
			else
				_ui_warn "Profile: sincronização falhou."
			fi
		fi

		if [ -f "${_target}/profile.sh" ]; then
			_ui_sub "Executando sincronização via profile.sh..."
			local _exec_sh="$(command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || command -v sh)"
			"${_exec_sh}" "${_target}/profile.sh" sync "$@" || true
		fi
		_ui_ok "Universal Profile finalizado com sucesso!"
	else
		_ui_info "Nenhum repositório Profile encontrado em ~/.local/share/profile, ~/.config/profile ou \$PROFILE_DIR."
	fi

	_ui_info "Recarregando ambiente do shell..."
	if [ -n "${ZSH_VERSION:-}" ] && [ -f "${HOME}/.zshrc" ]; then
		. "${HOME}/.zshrc" 2> "/dev/null" || true
	elif [ -n "${BASH_VERSION:-}" ] && [ -f "${HOME}/.bashrc" ]; then
		. "${HOME}/.bashrc" 2> "/dev/null" || true
	elif [ -f "${HOME}/.$(_detect_enabled_shell --name 2> "/dev/null")rc" ]; then
		. "${HOME}/.$(_detect_enabled_shell --name)rc" 2> "/dev/null" || true
	fi
	unset _target _is_dry _is_status _arg
}

### --------------------------------
### SYNCHRONIZE IDE EXTENSIONS
### --------------------------------
sync-extensions() {
	local _arg _target_editor _action _ext_flags _exec_sh _sync_script _cand
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: sync-extensions [editor] [ação] [opções] (alias: upext, update-extensions)

				Sincroniza extensões declarativas de IDE (VS Code, VSCodium, Antigravity).

				Editores:
				  auto (padrão), vscode, vscodium, antigravity

				Ações:
				  install (padrão)    Instala extensões listadas no manifesto declarativo
				  export, dump        Exporta extensões instaladas para o manifesto
				  status              Audita e compara extensões instaladas com o manifesto

				Opções:
				  -n, --dry-run       Simula a ação sem modificar nada
				  -f, --force         Força reinstalação de extensões já presentes
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	_target_editor="auto"
	_action="install"
	_ext_flags=""

	for _arg in "$@"; do
		case "${_arg}" in
			vscode|antigravity|vscodium) _target_editor="${_arg}" ;;
			install|export|dump|status)  _action="${_arg}" ;;
			--dry-run|-n)                _ext_flags="${_ext_flags} --dry-run" ;;
			--force|-f)                  _ext_flags="${_ext_flags} --force" ;;
		esac
	done

	local _exec_sh="$(command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || command -v sh)"
	local _sync_script=""
	if [ -n "${PROFILE_DIR:-}" ] && [ -f "${PROFILE_DIR}/profile.sh" ]; then
		"${_exec_sh}" "${PROFILE_DIR}/profile.sh" extensions "${_action}" "${_target_editor}" ${_ext_flags}
		return $?
	fi

	for _cand in \
		"${HOME}/.local/share/profile/profile.sh" \
		"${HOME}/.config/profile/profile.sh" \
		"${SHELL_REPO_DIR:-}/../Profile/profile.sh" \
		"${HOME}/Documents/Environment/Profile/profile.sh"; do
		if [ -f "${_cand}" ]; then
			_sync_script="${_cand}"
			break
		fi
	done

	if [ -n "${_sync_script}" ]; then
		"${_exec_sh}" "${_sync_script}" extensions "${_action}" "${_target_editor}" ${_ext_flags}
	elif [ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/../Setup/common/editors/sync-extensions.sh" ]; then
		"${_exec_sh}" "${SHELL_REPO_DIR}/../Setup/common/editors/sync-extensions.sh" "${_target_editor}" "${_action}"
	elif [ -f "${HOME}/.local/share/setup/common/editors/sync-extensions.sh" ]; then
		"${_exec_sh}" "${HOME}/.local/share/setup/common/editors/sync-extensions.sh" "${_target_editor}" "${_action}"
	else
		_ui_warn "Mecanismo de sincronização de extensões não encontrado no Profile ou Setup."
		return 1
	fi
	unset _target_editor _action _ext_flags _sync_script _cand _arg
}
alias update-extensions="sync-extensions"
alias upext="sync-extensions"
