# ----------------------------------------------------------------
# Library: Ecosystem Updaters & Maintenance Tools
# ----------------------------------------------------------------

### --------------------------------
### Update Shell
### --------------------------------
update-shell() {
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-shell [opções] (alias: upsh)

				Atualiza o repositório Universal Shell via git pull resiliente e recarrega o ambiente.

				Opções:
				  -s, --status    Audita o status do repositório Git local sem puxar
				  -n, --dry-run   Simula a sincronização sem efetuar pull
				  -h, --help      Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

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

	if [ -z "${_target}" ] || [ ! -d "${_target}" ]; then
		_ui_info "Nenhum repositório de shell encontrado em /usr/local/share/shell, ~/.local/share/shell, ~/.config/shell ou ~/.shell."
		return 1
	fi

	_sh_mode="update"
	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _sh_mode="status" ;;
			--dry-run|-n) _sh_mode="dry-run" ;;
		esac
	done

	if [ "${_sh_mode}" = "status" ]; then
		_ui_step "Auditando repositório do Universal Shell em ${_target}..."
		_branch="$(git -C "${_target}" branch --show-current 2> "/dev/null" || true)"
		[ -z "${_branch}" ] && _branch="detached"
		_status="$(git -C "${_target}" status -s 2> "/dev/null" || true)"
		if [ -n "${_status}" ]; then
			_ui_warn "Universal Shell [${_branch}]: alterações pendentes em ${_target}"
		else
			_ui_ok "Universal Shell [${_branch}]: limpo e sincronizado"
		fi
		return 0
	elif [ "${_sh_mode}" = "dry-run" ]; then
		_ui_sub "[DRY-RUN PULL] ${_target}"
		return 0
	fi

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
	unset _target _sh_mode _arg _branch _status
}

### --------------------------------
### Update Editors
### --------------------------------
update-editors() {
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-editors [opções] (alias: uped)

				Atualiza os repositórios da Suíte de Editores (Emacs, Helix, NeoVim, Vim).

				Opções:
				  -s, --status        Audita o status Git de cada editor instalado
				  -n, --dry-run       Simula a sincronização sem puxar alterações
				  -e, --extensions    Sincroniza também as extensões declarativas de IDE
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	_found=0
	_editor_mode="update"
	_with_extensions=0
	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)     _editor_mode="status" ;;
			--dry-run|-n)    _editor_mode="dry-run" ;;
			--extensions|-e) _with_extensions=1 ;;
		esac
	done

	if [ "${_editor_mode}" = "status" ]; then
		_ui_step "Auditando Suíte de Editores..."
	elif [ "${_editor_mode}" = "dry-run" ]; then
		_ui_step "Simulando atualização da Suíte de Editores..."
	else
		_ui_step "Atualizando a Suíte de Editores..."
	fi

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
			if [ "${_editor_mode}" = "status" ]; then
				_branch="$(git -C "${_target}" branch --show-current 2> "/dev/null" || true)"
				[ -z "${_branch}" ] && _branch="detached"
				_status="$(git -C "${_target}" status -s 2> "/dev/null" || true)"
				if [ -n "${_status}" ]; then
					_ui_warn "${_editor} em ${_target} [${_branch}]: alterações pendentes"
				else
					_ui_ok "${_editor} em ${_target} [${_branch}]: limpo"
				fi
			elif [ "${_editor_mode}" = "dry-run" ]; then
				_ui_sub "[DRY-RUN PULL] ${_editor} -> ${_target}"
			else
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
			fi
			_found=1
		fi
	done

	if [ "${_with_extensions}" -eq 1 ] && command -v sync-extensions > "/dev/null" 2>&1; then
		echo ""
		sync-extensions "$@"
	fi

	if [ "${_found}" -eq 0 ]; then
		_ui_info "Nenhum repositório de editor encontrado nos caminhos canônicos (~/.emacs.d, ~/.config/nvim, ~/.config/helix, ~/.vim, ~/vimfiles)."
	else
		_ui_ok "Suíte de Editores finalizada (${_editor_mode})!"
	fi
	unset _found _editor_mode _with_extensions _editor _target _branch _status _arg
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
			sh "${_target}/profile.sh" sync "$@" || true
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
### Synchronize IDE Extensions
### --------------------------------
sync-extensions() {
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

	_sync_script=""
	if [ -n "${PROFILE_DIR:-}" ] && [ -f "${PROFILE_DIR}/profile.sh" ]; then
		sh "${PROFILE_DIR}/profile.sh" extensions "${_action}" "${_target_editor}" ${_ext_flags}
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
		sh "${_sync_script}" extensions "${_action}" "${_target_editor}" ${_ext_flags}
	elif [ -f "${SHELL_REPO_DIR:-}/../Setup/common/editors/sync-extensions.sh" ]; then
		sh "${SHELL_REPO_DIR}/../Setup/common/editors/sync-extensions.sh" "${_target_editor}" "${_action}"
	elif [ -f "${HOME}/.local/share/setup/common/editors/sync-extensions.sh" ]; then
		sh "${HOME}/.local/share/setup/common/editors/sync-extensions.sh" "${_target_editor}" "${_action}"
	else
		_ui_warn "Mecanismo de sincronização de extensões não encontrado no Profile ou Setup."
		return 1
	fi
	unset _target_editor _action _ext_flags _sync_script _cand _arg
}
alias update-extensions="sync-extensions"
alias upext="sync-extensions"

### --------------------------------
### Reinstall & Benchmark Shell
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

bench-shell() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -f "${SHELL_REPO_DIR}/benchmark.sh" ]; then
		local _cur_bin="$(_detect_enabled_shell)"
		"${_cur_bin}" "${SHELL_REPO_DIR}/benchmark.sh" "$@"
	else
		_ui_err "Script de benchmark não encontrado em ${SHELL_REPO_DIR}/benchmark.sh."
		return 1
	fi
}
