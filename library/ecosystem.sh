# ----------------------------------------------------------------
# Library: Ecosystem Updaters & Maintenance Tools
# ----------------------------------------------------------------

### --------------------------------
### UPDATE SHELL
### --------------------------------
update-shell() {
	local _arg _target _sh_mode _branch _status
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
### UPDATE EDITORS
### --------------------------------
_resolve_windows_editor_roots() {
	_win_home=""
	_win_appdata=""
	_win_localappdata=""

	if [ -n "${USERPROFILE:-}" ]; then
		if command -v cygpath > "/dev/null" 2>&1; then
			_win_home="$(cygpath -u "${USERPROFILE}" 2> "/dev/null" || printf '%s\n' "${USERPROFILE}")"
		else
			_win_home="$(printf '%s\n' "${USERPROFILE}" | tr '\\' '/')"
		fi
	fi

	if [ -n "${APPDATA:-}" ]; then
		if command -v cygpath > "/dev/null" 2>&1; then
			_win_appdata="$(cygpath -u "${APPDATA}" 2> "/dev/null" || printf '%s\n' "${APPDATA}")"
		else
			_win_appdata="$(printf '%s\n' "${APPDATA}" | tr '\\' '/')"
		fi
	elif [ -n "${_win_home}" ]; then
		_win_appdata="${_win_home}/AppData/Roaming"
	fi

	if [ -n "${LOCALAPPDATA:-}" ]; then
		if command -v cygpath > "/dev/null" 2>&1; then
			_win_localappdata="$(cygpath -u "${LOCALAPPDATA}" 2> "/dev/null" || printf '%s\n' "${LOCALAPPDATA}")"
		else
			_win_localappdata="$(printf '%s\n' "${LOCALAPPDATA}" | tr '\\' '/')"
		fi
	elif [ -n "${_win_home}" ]; then
		_win_localappdata="${_win_home}/AppData/Local"
	fi
}

_remove_windows_vim_link() {
	local _destination _win_destination
	_destination="$1"

	if unlink "${_destination}" 2> "/dev/null" || rm -f "${_destination}" 2> "/dev/null" || rmdir "${_destination}" 2> "/dev/null"; then
		return 0
	fi
	if command -v cmd.exe > "/dev/null" 2>&1; then
		if command -v cygpath > "/dev/null" 2>&1; then
			_win_destination="$(cygpath -w "${_destination}" 2> "/dev/null" || printf '%s\n' "${_destination}")"
		else
			_win_destination="$(printf '%s\n' "${_destination}" | sed 's|/|\\|g')"
		fi
		MSYS2_ARG_CONV_EXCL="*" cmd.exe /c rmdir "${_win_destination}" > "/dev/null" 2>&1 && return 0
	fi
	return 1
}

_create_windows_vim_junction() {
	local _destination _vimfiles_dir _win_destination _win_source
	_destination="$1"
	_vimfiles_dir="$2"

	if command -v cygpath > "/dev/null" 2>&1; then
		_win_destination="$(cygpath -w "${_destination}" 2> "/dev/null" || printf '%s\n' "${_destination}")"
		_win_source="$(cygpath -w "${_vimfiles_dir}" 2> "/dev/null" || printf '%s\n' "${_vimfiles_dir}")"
	else
		_win_destination="$(printf '%s\n' "${_destination}" | sed 's|/|\\|g')"
		_win_source="$(printf '%s\n' "${_vimfiles_dir}" | sed 's|/|\\|g')"
	fi

	if command -v cmd.exe > "/dev/null" 2>&1; then
		if MSYS2_ARG_CONV_EXCL="*" cmd.exe /c mklink /J "${_win_destination}" "${_win_source}" > "/dev/null" 2>&1; then
			_ui_ok "Junction Vim criada: ${_destination} -> ${_vimfiles_dir}"
			return 0
		fi
		_ui_warn "Falha ao criar junction Vim em ${_destination}."
		return 1
	elif ln -s "${_vimfiles_dir}" "${_destination}" > "/dev/null" 2>&1; then
		_ui_ok "Link Vim criado: ${_destination} -> ${_vimfiles_dir}"
		return 0
	else
		_ui_warn "Falha ao criar link Vim em ${_destination}."
		return 1
	fi
}

_ensure_windows_vim_junction() {
	local _editor_mode _vimfiles_dir _windows_home _candidate _real_source
	local _processed_destinations _newline_sep _destination _dest_parent
	local _real_parent _canonical_destination _real_destination

	_editor_mode="${1:-update}"
	_vimfiles_dir="${2:-}"

	case "$(uname -s 2> "/dev/null")" in
		MINGW*|MSYS*|CYGWIN*|*_NT*) ;;
		*) return 0 ;;
	esac

	_windows_home="${_win_home:-}"
	if [ -z "${_windows_home}" ] && [ -n "${USERPROFILE:-}" ]; then
		if command -v cygpath > "/dev/null" 2>&1; then
			_windows_home="$(cygpath -u "${USERPROFILE}" 2> "/dev/null" || printf '%s\n' "${USERPROFILE}")"
		else
			_windows_home="$(printf '%s\n' "${USERPROFILE}" | sed 's|\\|/|g')"
		fi
	fi

	if [ -z "${_vimfiles_dir}" ]; then
		for _candidate in "${HOME}/vimfiles" "${_windows_home:+${_windows_home}/vimfiles}"; do
			if [ -n "${_candidate}" ] && [ -d "${_candidate}" ]; then
				_vimfiles_dir="${_candidate}"
				break
			fi
		done
	fi
	[ -n "${_vimfiles_dir}" ] && [ -d "${_vimfiles_dir}" ] || return 0

	_real_source="$(CDPATH="" cd -P "${_vimfiles_dir}" 2> "/dev/null" && pwd -P || printf '%s\n' "${_vimfiles_dir}")"
	_processed_destinations=""
	_newline_sep="
"

	for _destination in "${_windows_home:+${_windows_home}/.vim}" "${HOME}/.vim"; do
		[ -z "${_destination}" ] && continue
		_dest_parent="$(dirname "${_destination}")"
		[ -d "${_dest_parent}" ] || continue
		_real_parent="$(CDPATH="" cd -P "${_dest_parent}" 2> "/dev/null" && pwd -P || printf '%s\n' "${_dest_parent}")"
		_canonical_destination="${_real_parent}/.vim"

		case "${_newline_sep}${_processed_destinations}${_newline_sep}" in
			*"${_newline_sep}${_canonical_destination}${_newline_sep}"*) continue ;;
		esac
		_processed_destinations="${_processed_destinations}${_newline_sep}${_canonical_destination}"

		if [ -L "${_destination}" ]; then
			if [ -d "${_destination}" ]; then
				_real_destination="$(CDPATH="" cd -P "${_destination}" 2> "/dev/null" && pwd -P || true)"
				if [ "${_real_destination}" = "${_real_source}" ]; then
					if [ "${_editor_mode}" = "dry-run" ]; then
						_ui_sub "[IN-SYNC] Junction Vim: ${_destination} -> ${_vimfiles_dir}"
					else
						_ui_ok "Junction Vim sincronizada: ${_destination} -> ${_vimfiles_dir}"
					fi
				elif [ "${_editor_mode}" = "status" ]; then
					_ui_warn "Junction Vim divergente: ${_destination} -> ${_real_destination:-desconhecido} (esperado: ${_vimfiles_dir})"
				elif [ "${_editor_mode}" = "dry-run" ]; then
					_ui_sub "[DRY-RUN JUNCTION] Recriar ${_destination} -> ${_vimfiles_dir}"
				elif _remove_windows_vim_link "${_destination}"; then
					_create_windows_vim_junction "${_destination}" "${_vimfiles_dir}" || true
				else
					_ui_warn "Não foi possível remover link divergente em ${_destination}."
				fi
			elif [ "${_editor_mode}" = "status" ]; then
				_ui_warn "Link Vim quebrado em ${_destination} (esperado: ${_vimfiles_dir})"
			elif [ "${_editor_mode}" = "dry-run" ]; then
				_ui_sub "[DRY-RUN JUNCTION] Recriar ${_destination} -> ${_vimfiles_dir}"
			elif _remove_windows_vim_link "${_destination}"; then
				_create_windows_vim_junction "${_destination}" "${_vimfiles_dir}" || true
			else
				_ui_warn "Não foi possível remover link quebrado em ${_destination}."
			fi
		elif [ ! -e "${_destination}" ]; then
			if [ "${_editor_mode}" = "status" ]; then
				_ui_warn "Junction Vim ausente: ${_destination} -> ${_vimfiles_dir}"
			elif [ "${_editor_mode}" = "dry-run" ]; then
				_ui_sub "[DRY-RUN JUNCTION] ${_destination} -> ${_vimfiles_dir}"
			else
				_create_windows_vim_junction "${_destination}" "${_vimfiles_dir}" || true
			fi
		elif [ -d "${_destination}" ]; then
			_real_destination="$(CDPATH="" cd -P "${_destination}" 2> "/dev/null" && pwd -P || true)"
			if [ "${_real_destination}" = "${_real_source}" ]; then
				if [ "${_editor_mode}" = "dry-run" ]; then
					_ui_sub "[IN-SYNC] Junction Vim: ${_destination} -> ${_vimfiles_dir}"
				else
					_ui_ok "Junction Vim sincronizada: ${_destination} -> ${_vimfiles_dir}"
				fi
			elif [ ! -r "${_destination}" ] || [ -n "$(ls -A "${_destination}" 2> "/dev/null")" ]; then
				_ui_warn "Diretório real não-vazio em ${_destination}; preservando dados do usuário sem criar junction."
			elif [ "${_editor_mode}" = "status" ]; then
				_ui_warn "Diretório vazio em ${_destination} bloqueia junction para ${_vimfiles_dir}"
			elif [ "${_editor_mode}" = "dry-run" ]; then
				_ui_sub "[DRY-RUN JUNCTION] Remover diretório vazio e criar ${_destination} -> ${_vimfiles_dir}"
			elif rmdir "${_destination}" 2> "/dev/null"; then
				_create_windows_vim_junction "${_destination}" "${_vimfiles_dir}" || true
			else
				_ui_warn "Falha ao remover diretório vazio em ${_destination}."
			fi
		else
			_ui_warn "Arquivo existente em ${_destination} impede criação da junction para ${_vimfiles_dir}."
		fi
	done
}

_update_editor_candidates() {
	local _editor _editor_mode _target _real_target _branch _status _newline_sep
	_editor="$1"
	_editor_mode="$2"
	[ "$#" -ge 2 ] && shift 2 || return 0
	_newline_sep="
"

	for _target in "$@"; do
		[ -z "${_target}" ] && continue
		[ -d "${_target}/.git" ] || [ -f "${_target}/.git" ] || continue
		_real_target="$(CDPATH="" cd -P "${_target}" 2> "/dev/null" && pwd -P || printf '%s\n' "${_target}")"
		case "${_newline_sep}${_processed_targets}${_newline_sep}" in
			*"${_newline_sep}${_real_target}${_newline_sep}"*) continue ;;
		esac
		_processed_targets="${_processed_targets}${_newline_sep}${_real_target}"
		_found=1

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
	done
}

update-editors() {
	local _arg _found _editor_mode _with_extensions _win_home _win_appdata _win_localappdata _processed_targets
	local _vimfiles_dir _vimfiles_candidate
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

	_resolve_windows_editor_roots

	_processed_targets=""
	_update_editor_candidates "Emacs" "${_editor_mode}" \
		"${HOME}/.emacs.d" \
		"${XDG_CONFIG_HOME:-${HOME}/.config}/emacs" \
		"${_win_home:+${_win_home}/.emacs.d}" \
		"${_win_appdata:+${_win_appdata}/.emacs.d}"

	_update_editor_candidates "Helix" "${_editor_mode}" \
		"${XDG_CONFIG_HOME:-${HOME}/.config}/helix" \
		"${_win_appdata:+${_win_appdata}/helix}" \
		"${_win_home:+${_win_home}/AppData/Roaming/helix}"

	_update_editor_candidates "NeoVim" "${_editor_mode}" \
		"${XDG_CONFIG_HOME:-${HOME}/.config}/nvim" \
		"${_win_localappdata:+${_win_localappdata}/nvim}" \
		"${_win_home:+${_win_home}/AppData/Local/nvim}"

	_update_editor_candidates "Vim" "${_editor_mode}" \
		"${HOME}/vimfiles" \
		"${_win_home:+${_win_home}/vimfiles}" \
		"${HOME}/.vim" \
		"${_win_home:+${_win_home}/.vim}"

	_vimfiles_dir=""
	for _vimfiles_candidate in "${HOME}/vimfiles" "${_win_home:+${_win_home}/vimfiles}"; do
		if [ -n "${_vimfiles_candidate}" ] && [ -d "${_vimfiles_candidate}" ]; then
			_vimfiles_dir="${_vimfiles_candidate}"
			break
		fi
	done
	if [ -n "${_vimfiles_dir}" ]; then
		_ensure_windows_vim_junction "${_editor_mode}" "${_vimfiles_dir}"
		case "$(uname -s 2> "/dev/null")" in
			MINGW*|MSYS*|CYGWIN*|*_NT*) _found=1 ;;
		esac
	fi

	if [ "${_with_extensions}" -eq 1 ] && command -v sync-extensions > "/dev/null" 2>&1; then
		echo ""
		sync-extensions "$@"
	fi

	if [ "${_found}" -eq 0 ]; then
		_ui_info "Nenhum repositório de editor encontrado nos caminhos canônicos (~/.emacs.d, ~/.config/nvim, ~/.config/helix, ~/.vim, ~/vimfiles)."
	else
		_ui_ok "Suíte de Editores finalizada (${_editor_mode})!"
	fi
}

### --------------------------------
### UPDATE EMACS MODES
### --------------------------------
update-emacs-modes() {
	local _win_home _win_appdata _win_localappdata _target
	_resolve_windows_editor_roots

	_target=""
	if [ -d "${HOME}/.emacs.d/.git" ]; then
		_target="${HOME}/.emacs.d"
	elif [ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/emacs/.git" ]; then
		_target="${XDG_CONFIG_HOME:-${HOME}/.config}/emacs"
	elif [ -n "${_win_home}" ] && [ -d "${_win_home}/.emacs.d/.git" ]; then
		_target="${_win_home}/.emacs.d"
	elif [ -n "${_win_appdata}" ] && [ -d "${_win_appdata}/.emacs.d/.git" ]; then
		_target="${_win_appdata}/.emacs.d"
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
}

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

### --------------------------------
### REINSTALL & BENCHMARK SHELL
### --------------------------------
reinstall-shell() {
	if [ -z "${SHELL_REPO_DIR:-}" ] || [ ! -d "${SHELL_REPO_DIR}" ]; then
		_ui_err "SHELL_REPO_DIR is not set or invalid."
		_ui_info "Please re-run the install.sh script from your shell repository."
		return 1
	fi

	_ui_step "Atualizando repositório do Universal Shell em ${SHELL_REPO_DIR}..."
	_git_pull_resilient "${SHELL_REPO_DIR}" || {
		_ui_err "git pull failed."
		return 1
	}

	_cache_clean

	local _args="--context ${SHELL_CONTEXT:-desktop}"
	case "${SHELL_FRAMEWORK:-0}" in
		*[!0-9]*|"") ;;
		*)
			if [ "${SHELL_FRAMEWORK:-0}" -eq 1 ]; then
				_args="${_args} --framework"
			fi
			;;
	esac

	local _cur_bin="$(_detect_enabled_shell)"
	local _cur_shell="$(_detect_enabled_shell --name)"

	_ui_sub "Reinstalando via install.sh com contexto '${SHELL_CONTEXT:-desktop}' (${_cur_shell})..."
	"${_cur_bin}" "${SHELL_REPO_DIR}/install.sh" ${_args} "$@"

	_ui_info "Recarregando ambiente do shell..."
	. "${HOME}/.${_cur_shell}rc" 2> "/dev/null" || true

	_ui_ok "Universal Shell totalmente reinstalado e recarregado!"
}

bench-shell() {
	if [ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/benchmark.sh" ]; then
		local _cur_bin="$(_detect_enabled_shell)"
		"${_cur_bin}" "${SHELL_REPO_DIR}/benchmark.sh" "$@"
	else
		_ui_err "Script de benchmark não encontrado em ${SHELL_REPO_DIR:-}/benchmark.sh."
		return 1
	fi
}
