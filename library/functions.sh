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
		*)
			if [ ! -d "${1}" ]; then
				case "${1}" in
					"${HOME}/"*) mkdir -p "${1}" 2> "/dev/null" || true ;;
				esac
			fi
			[ -d "${1}" ] && export PATH="${1}:${PATH}"
			;;
	esac
}

### --------------------------------
### Path Back
### --------------------------------
path-back() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*)
			if [ ! -d "${1}" ]; then
				case "${1}" in
					"${HOME}/"*) mkdir -p "${1}" 2> "/dev/null" || true ;;
				esac
			fi
			[ -d "${1}" ] && export PATH="${PATH}:${1}"
			;;
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
		_as_root true || return 1
		local _escalator="$(_detect_privilege_escalator)"
		case "${_escalator}" in
			sudo|doas) _cmd="${_escalator} git -C \"${_dir}\"" ;;
		esac
	fi

	eval "${_cmd} diff --numstat" 2> "/dev/null" | while IFS="$(printf '\t')" read -r _additions _deletions _file; do
		if [ "${_additions}" = "0" ] && [ "${_deletions}" = "0" ] && [ -n "${_file}" ]; then
			eval "${_cmd} checkout -- \"${_file}\"" > "/dev/null" 2>&1 || true
		fi
	done

	local _has_stash=0
	local _status
	_status="$(eval "${_cmd} status --porcelain" 2> "/dev/null" || true)"
	if [ -n "${_status}" ]; then
		local _stash_before _stash_after
		_stash_before="$(eval "${_cmd} rev-parse -q --verify refs/stash" 2> "/dev/null" || true)"
		_ui_warn "Alterações locais ou arquivos novos detectados em ${_dir}."
		_ui_sub "Criando auto-stash defensivo antes da sincronização..."
		eval "${_cmd} stash push -u -m 'autostash-before-update-$(date +%s)'" > "/dev/null" 2>&1 || true
		_stash_after="$(eval "${_cmd} rev-parse -q --verify refs/stash" 2> "/dev/null" || true)"
		if [ -n "${_stash_after}" ] && [ "${_stash_before}" != "${_stash_after}" ]; then
			_has_stash=1
		fi
	fi

	local _current_branch
	_current_branch="$(eval "${_cmd} branch --show-current" 2> "/dev/null" || true)"
	if [ -z "${_current_branch}" ]; then
		local _default_branch
		_default_branch="$(eval "${_cmd} symbolic-ref --short refs/remotes/origin/HEAD" 2> "/dev/null" | sed 's|^origin/||' || true)"
		[ -z "${_default_branch}" ] && _default_branch="main"
		if eval "${_cmd} show-ref --verify --quiet refs/heads/${_default_branch}" 2> "/dev/null"; then
			if eval "${_cmd} checkout \"${_default_branch}\"" > "/dev/null" 2>&1; then
				_current_branch="${_default_branch}"
			fi
		fi
	fi

	local _pull_ok=0
	if [ -n "${_current_branch}" ]; then
		if eval "${_cmd} pull --ff-only" > "/dev/null" 2>&1; then
			_pull_ok=1
		elif eval "${_cmd} pull --rebase" > "/dev/null" 2>&1; then
			_pull_ok=1
		elif eval "${_cmd} pull" > "/dev/null" 2>&1; then
			_pull_ok=1
		fi
	else
		if eval "${_cmd} fetch" > "/dev/null" 2>&1; then
			_pull_ok=1
		fi
	fi

	if [ "${_pull_ok}" -eq 1 ]; then
		if [ "${_has_stash}" -eq 1 ]; then
			if ! eval "${_cmd} stash pop" > "/dev/null" 2>&1; then
				eval "${_cmd} reset --merge" > "/dev/null" 2>&1 || eval "${_cmd} checkout -f" > "/dev/null" 2>&1 || true
				_ui_warn "Conflito detectado ao restaurar alterações locais em ${_dir}."
				_ui_info "Sua versão local foi preservada com segurança em 'git stash list'."
			fi
			eval "${_cmd} diff --numstat" 2> "/dev/null" | while IFS="$(printf '\t')" read -r _additions _deletions _file; do
				if [ "${_additions}" = "0" ] && [ "${_deletions}" = "0" ] && [ -n "${_file}" ]; then
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

_git_push_resilient() {
	local _dir="$1"
	if [ ! -d "${_dir}/.git" ] && [ ! -f "${_dir}/.git" ]; then
		return 0
	fi

	local _cmd="git -C \"${_dir}\""
	local _has_remote
	_has_remote="$(eval "${_cmd} remote" 2> "/dev/null" || true)"
	if [ -z "${_has_remote}" ]; then
		_ui_info "${_dir}: sem remote configurado, pulando."
		return 0
	fi

	local _branch
	_branch="$(eval "${_cmd} branch --show-current" 2> "/dev/null" || true)"
	if [ -z "${_branch}" ]; then
		_ui_info "${_dir}: branch indefinida (detached HEAD), pulando."
		return 0
	fi

	local _unpushed
	_unpushed="$(eval "${_cmd} cherry -v" 2> "/dev/null" || true)"
	if [ -z "${_unpushed}" ]; then
		_ui_ok "${_dir}: já atualizado com o remote (${_branch})."
		return 0
	fi

	_ui_sub "Enviando ${_dir} (${_branch})..."
	if eval "${_cmd} push" > "/dev/null" 2>&1 || eval "${_cmd} push origin \"${_branch}\"" > "/dev/null" 2>&1; then
		_ui_ok "${_dir}: push concluído com sucesso!"
		return 0
	else
		_ui_err "${_dir}: falha ao enviar commits para o remote."
		return 1
	fi
}

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
### Update Git Repositories
### --------------------------------
update-git() {
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: update-git [diretório] [opções] (alias: upgit, plgit, pull-git)

				Localiza e atualiza repositórios Git recursivamente com proteção resiliente.

				Argumentos:
				  diretório           Diretório raiz da busca (padrão: diretório atual)

				Opções:
				  -s, --status        Audita status de branches, commits divergentes e alterações
				  -n, --dry-run       Simula a sincronização sem efetuar git pull
				  --depth=N           Profundidade máxima de busca no diretório (padrão: 3)
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	_target_root="${PWD}"
	_git_mode="pull"
	_max_depth=3

	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)   _git_mode="status" ;;
			--dry-run|-n)  _git_mode="dry-run" ;;
			--depth=*)     _max_depth="${_arg#*=}" ;;
			-*) ;;
			*)
				if [ -d "${_arg}" ]; then
					_target_root="${_arg}"
				fi
				;;
		esac
	done

	if [ ! -d "${_target_root}" ]; then
		_ui_err "Diretório não encontrado: ${_target_root}"
		return 1
	fi

	if [ "${_git_mode}" = "status" ]; then
		_ui_step "Auditando status Git em: ${_target_root} (profundidade: ${_max_depth})"
	elif [ "${_git_mode}" = "dry-run" ]; then
		_ui_step "Simulando atualização Git em: ${_target_root} (profundidade: ${_max_depth})"
	else
		_ui_step "Buscando e atualizando repositórios Git em: ${_target_root}"
	fi
	echo ""

	find "${_target_root}" -maxdepth "${_max_depth}" -name ".git" 2> "/dev/null" | \
		awk '{ n=split($0, a, "/"); print n, $0 }' | \
		sort -n -k1,1 | \
		cut -d' ' -f2- | while read -r _git_entry; do
			_repo_dir="$(dirname "${_git_entry}")"
			if [ "${_git_mode}" = "status" ]; then
				_branch="$(git -C "${_repo_dir}" branch --show-current 2> "/dev/null" || true)"
				[ -z "${_branch}" ] && _branch="detached"
				_status="$(git -C "${_repo_dir}" status -s 2> "/dev/null" || true)"
				_ahead_behind="$(git -C "${_repo_dir}" rev-list --left-right --count HEAD...@{upstream} 2> "/dev/null" || true)"
				_diverged=0
				if [ -n "${_status}" ]; then
					_diverged=1
				elif [ -n "${_ahead_behind}" ] && [ "${_ahead_behind}" != "0	0" ] && [ "${_ahead_behind}" != "0 0" ]; then
					_diverged=1
				fi

				if [ "${_diverged}" -eq 1 ]; then
					_ui_warn "${_repo_dir} [${_branch}]: divergências locais ou remotas"
					if [ -n "${_ahead_behind}" ] && [ "${_ahead_behind}" != "0	0" ] && [ "${_ahead_behind}" != "0 0" ]; then
						_ui_sub "  ↳ Commits (local/remote): ${_ahead_behind}"
					fi
					[ -n "${_status}" ] && git -C "${_repo_dir}" status -s | head -n 5 | while read -r _status_line; do _ui_sub "    ${_status_line}"; done
				else
					_ui_ok "${_repo_dir} [${_branch}]: sincronizado e limpo"
				fi
			elif [ "${_git_mode}" = "dry-run" ]; then
				_ui_sub "[DRY-RUN PULL] ${_repo_dir}"
			else
				_ui_sub "Atualizando ${_repo_dir}..."
				_git_pull_resilient "${_repo_dir}" || _ui_warn "Falha ao atualizar ${_repo_dir}"
			fi
		done

	echo ""
	_ui_ok "Operação Git (${_git_mode}) concluída!"
	unset _target_root _git_mode _max_depth _arg _git_entry _repo_dir _branch _status _ahead_behind
}

alias plgit="update-git"
alias upgit="update-git"
alias pull-git="update-git"

### --------------------------------
### Push Git Repositories
### --------------------------------
push-git() {
	for _arg in "$@"; do
		case "${_arg}" in
			--help|-h)
				cat <<- 'EOF'
				Uso: push-git [diretório] [opções] (alias: psgit)

				Localiza repositórios Git recursivamente e envia commits pendentes upstream.

				Argumentos:
				  diretório           Diretório raiz da busca (padrão: diretório atual)

				Opções:
				  -s, --status        Audita commits locais pendentes de envio (cherry -v)
				  -n, --dry-run       Simula o push sem enviar commits
				  --depth=N           Profundidade máxima de busca no diretório (padrão: 3)
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	_target_root="${PWD}"
	_git_mode="push"
	_max_depth=3

	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _git_mode="status" ;;
			--dry-run|-n) _git_mode="dry-run" ;;
			--depth=*)    _max_depth="${_arg#*=}" ;;
			-*) ;;
			*)
				if [ -d "${_arg}" ]; then
					_target_root="${_arg}"
				fi
				;;
		esac
	done

	if [ ! -d "${_target_root}" ]; then
		_ui_err "Diretório não encontrado: ${_target_root}"
		return 1
	fi

	if [ "${_git_mode}" = "status" ]; then
		_ui_step "Auditando commits pendentes de envio em: ${_target_root}"
	elif [ "${_git_mode}" = "dry-run" ]; then
		_ui_step "Simulando push de repositórios Git em: ${_target_root}"
	else
		_ui_step "Buscando e enviando repositórios Git em: ${_target_root}"
	fi
	echo ""

	find "${_target_root}" -maxdepth "${_max_depth}" -name ".git" 2> "/dev/null" | \
		awk '{ n=split($0, a, "/"); print n, $0 }' | \
		sort -nr -k1,1 | \
		cut -d' ' -f2- | while read -r _git_entry; do
			_repo_dir="$(dirname "${_git_entry}")"
			_unpushed="$(git -C "${_repo_dir}" cherry -v 2> "/dev/null" || true)"
			_branch="$(git -C "${_repo_dir}" branch --show-current 2> "/dev/null" || true)"
			[ -z "${_branch}" ] && _branch="detached"
			if [ -n "${_unpushed}" ]; then
				if [ "${_git_mode}" = "status" ]; then
					_ui_warn "${_repo_dir} [${_branch}]: commits pendentes de envio"
					echo "${_unpushed}" | while read -r _commit_line; do _ui_sub "  ↳ ${_commit_line}"; done
				elif [ "${_git_mode}" = "dry-run" ]; then
					_ui_sub "[DRY-RUN PUSH] ${_repo_dir} (${_branch})"
				else
					_ui_sub "Enviando ${_repo_dir} (${_branch})..."
					_git_push_resilient "${_repo_dir}" || _ui_warn "Falha ao enviar ${_repo_dir}"
				fi
			else
				[ "${_git_mode}" = "status" ] && _ui_ok "${_repo_dir} [${_branch}]: nada a enviar"
			fi
		done

	echo ""
	_ui_ok "Operação Push Git (${_git_mode}) concluída!"
	unset _target_root _git_mode _max_depth _arg _git_entry _repo_dir _unpushed _branch _commit_line
}
alias psgit="push-git"

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
				Uso: clean-system [opções] (alias: cleansys, sysclean, syscls)

				Limpeza de pacotes órfãos, dependências obsoletas e caches do sistema operacional.

				Ações por plataforma:
				  - Debian / Ubuntu:   apt autoremove --yes && apt clean
				  - Fedora / RHEL:     dnf autoremove --assumeyes && dnf clean packages
				  - Arch Linux:        pacman -Rns (órfãos) && paccache -r
				  - Void Linux:        xbps-remove -o && xbps-remove -O
				  - Alpine Linux:      apk cache clean
				  - openSUSE:          zypper clean --all
				  - FreeBSD:           pkg autoremove --yes && pkg clean --yes
				  - OpenBSD:           pkg_delete -a
				  - NetBSD:            pkgin autoremove && pkgin clean
				  - macOS:             brew cleanup --prune=all
				  - Flatpak:           flatpak uninstall --unused --assumeyes

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
		*)
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
				netbsd)
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
alias sysclean="clean-system"
alias syscls="clean-system"

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

	# Snapshot de proteção atômico no ZFS antes de atualizar
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
