# ----------------------------------------------------------------
# Library: Resilient Git Synchronization & Game of Trees
# ----------------------------------------------------------------

### --------------------------------
### RESILIENT GIT PULL & PUSH
### --------------------------------
_git_pull_exec() {
	local _dir="${1}" _ran_as_root="${2}" _escalator="${3}"
	shift 3
	if [ "${_ran_as_root}" -eq 1 ] && [ -n "${_escalator}" ]; then
		command "${_escalator}" git -C "${_dir}" "$@"
	else
		command git -C "${_dir}" "$@"
	fi
}

_git_pull_heal_perms() {
	local _dir="${1}" _is_windows="${2}" _cur_uid="${3}" _ran_as_root="${4}" _real_u="${5}" _real_g="${6}"
	local _git_dir="${7:-}" _is_vault="${8:-0}" _chmod_spec="${9:-u+rwX,go+rX}"
	if [ "${_is_windows}" -eq 0 ]; then
		if [ "${_cur_uid}" -eq 0 ] || [ "${_ran_as_root}" -eq 1 ]; then
			if [ -n "${_real_u}" ] && [ "${_real_u}" != "root" ]; then
				if [ "${_cur_uid}" -eq 0 ]; then
					chown -R "${_real_u}:${_real_g}" "${_dir}" 2> "/dev/null" || true
					chmod -R "${_chmod_spec}" "${_dir}" 2> "/dev/null" || true
					if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_dir}/.git" ]; then
						chown -R "${_real_u}:${_real_g}" "${_git_dir}" 2> "/dev/null" || true
						chmod -R "${_chmod_spec}" "${_git_dir}" 2> "/dev/null" || true
					fi
				else
					_as_root chown -R "${_real_u}:${_real_g}" "${_dir}" 2> "/dev/null" || true
					_as_root chmod -R "${_chmod_spec}" "${_dir}" 2> "/dev/null" || true
					if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_dir}/.git" ]; then
						_as_root chown -R "${_real_u}:${_real_g}" "${_git_dir}" 2> "/dev/null" || true
						_as_root chmod -R "${_chmod_spec}" "${_git_dir}" 2> "/dev/null" || true
					fi
				fi
			elif [ "${_is_vault}" -eq 1 ]; then
				chmod -R "${_chmod_spec}" "${_dir}" 2> "/dev/null" || true
				if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_dir}/.git" ]; then
					chmod -R "${_chmod_spec}" "${_git_dir}" 2> "/dev/null" || true
				fi
			fi
		elif [ "${_is_vault}" -eq 1 ]; then
			chmod -R "${_chmod_spec}" "${_dir}" 2> "/dev/null" || true
			if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_dir}/.git" ]; then
				chmod -R "${_chmod_spec}" "${_git_dir}" 2> "/dev/null" || true
			fi
		fi
	fi
	command git config --global --add safe.directory "${_dir}" 2> "/dev/null" || true
}

_git_pull_resilient() {
	local _dir="$1"
	if command -v cygpath > "/dev/null" 2>&1; then
		_dir="$(cygpath -u "${_dir}" 2> "/dev/null" || echo "${_dir}")"
	else
		_dir="$(echo "${_dir}" | tr '\\' '/')"
	fi
	[ -d "${_dir}/.git" ] || [ -f "${_dir}/.git" ] || return 1

	local _is_windows=0
	case "${OSTYPE:-$(uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}" in
		msys*|cygwin*|mingw*|windows*|win32*) _is_windows=1 ;;
	esac

	local _real_u="${SUDO_USER:-${DOAS_USER:-$(id -un 2> "/dev/null")}}"
	local _real_g="$(id -gn "${_real_u}" 2> "/dev/null" || id -gn 2> "/dev/null")"
	local _cur_uid="$(id -u 2> "/dev/null" || echo 1000)"
	local _ran_as_root=0
	local _escalator=""

	local _is_vault=0
	local _chmod_spec="u+rwX,go+rX"
	local _hook_mode="0755"
	if [ -f "${_dir}/vault.sh" ] && [ -d "${_dir}/keys" ]; then
		_is_vault=1
		_chmod_spec="u+rwX,go="
		_hook_mode="0700"
	fi

	local _git_dir=""
	if [ -d "${_dir}/.git" ]; then
		_git_dir="${_dir}/.git"
	elif [ -f "${_dir}/.git" ]; then
		_git_dir="$(command git -C "${_dir}" rev-parse --absolute-git-dir 2> "/dev/null" || true)"
		if [ -z "${_git_dir}" ]; then
			local _gitlink="" _git_rel=""
			IFS= read -r _gitlink < "${_dir}/.git" 2> "/dev/null" || _gitlink=""
			case "${_gitlink}" in
				"gitdir: "*)
					_git_rel="${_gitlink#gitdir: }"
					case "${_git_rel}" in
						/*) _git_dir="${_git_rel}" ;;
						*)  _git_dir="${_dir}/${_git_rel}" ;;
					esac
					;;
			esac
		fi
	fi

	if [ "${_is_windows}" -eq 0 ] && [ "${_cur_uid}" -ne 0 ]; then
		local _needs_heal=0
		if [ ! -w "${_dir}" ] || [ ! -w "${_dir}/.git" ] || [ -z "${_git_dir}" ] || [ ! -w "${_git_dir}" ] || { [ -e "${_git_dir}/objects" ] && [ ! -w "${_git_dir}/objects" ]; }; then
			_needs_heal=1
		elif find "${_git_dir}" -maxdepth 2 \( -user 0 -o ! -writable \) -print -quit 2> "/dev/null" | grep -q .; then
			_needs_heal=1
		fi
		if [ "${_needs_heal}" -eq 1 ]; then
			_ui_sub "Auto-curando permissões de ${_dir}..."
			_as_root chown -R "${_real_u}:${_real_g}" "${_dir}" 2> "/dev/null" || true
			_as_root chmod -R "${_chmod_spec}" "${_dir}" 2> "/dev/null" || true
			if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_dir}/.git" ]; then
				_as_root chown -R "${_real_u}:${_real_g}" "${_git_dir}" 2> "/dev/null" || true
				_as_root chmod -R "${_chmod_spec}" "${_git_dir}" 2> "/dev/null" || true
			fi
			command git config --global --add safe.directory "${_dir}" 2> "/dev/null" || true
		fi
	fi

	if [ "${_is_windows}" -eq 0 ] && [ ! -w "${_dir}" ]; then
		_as_root true || return 1
		_escalator="$(_detect_privilege_escalator)"
		case "${_escalator}" in
			sudo|doas)
				_ran_as_root=1
				;;
		esac
	fi

	_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" diff --numstat 2> "/dev/null" | while IFS="$(printf '\t')" read -r _additions _deletions _file; do
		if [ "${_additions}" = "0" ] && [ "${_deletions}" = "0" ] && [ -n "${_file}" ]; then
			_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" checkout -- "${_file}" < "/dev/null" > "/dev/null" 2>&1 || true
		fi
	done

	local _has_stash=0
	local _status
	_status="$(_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" status --porcelain 2> "/dev/null" || true)"
	if [ -n "${_status}" ]; then
		local _stash_before _stash_after
		_stash_before="$(_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" rev-parse -q --verify refs/stash 2> "/dev/null" || true)"
		_ui_warn "Alterações locais ou arquivos novos detectados em ${_dir}."
		_ui_sub "Criando auto-stash defensivo antes da sincronização..."
		_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" stash push -u -m "autostash-before-update-$(date +%s)" > "/dev/null" 2>&1 || true
		_stash_after="$(_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" rev-parse -q --verify refs/stash 2> "/dev/null" || true)"
		if [ -n "${_stash_after}" ] && [ "${_stash_before}" != "${_stash_after}" ]; then
			_has_stash=1
		fi
	fi

	local _current_branch
	_current_branch="$(_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" branch --show-current 2> "/dev/null" || true)"
	if [ -z "${_current_branch}" ]; then
		local _default_branch
		_default_branch="$(_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" symbolic-ref --short refs/remotes/origin/HEAD 2> "/dev/null" | sed 's|^origin/||' || true)"
		[ -z "${_default_branch}" ] && _default_branch="main"
		if _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" show-ref --verify --quiet "refs/heads/${_default_branch}" 2> "/dev/null"; then
			if _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" checkout "${_default_branch}" > "/dev/null" 2>&1; then
				_current_branch="${_default_branch}"
			fi
		fi
	fi

	local _pull_ok=0
	if [ -n "${_current_branch}" ]; then
		if _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" pull --ff-only > "/dev/null" 2>&1; then
			_pull_ok=1
		elif _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" pull --rebase > "/dev/null" 2>&1; then
			_pull_ok=1
		elif _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" pull > "/dev/null" 2>&1; then
			_pull_ok=1
		fi
	else
		if _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" fetch > "/dev/null" 2>&1; then
			_pull_ok=1
		fi
	fi

	if [ "${_pull_ok}" -eq 1 ]; then
		if [ "${_has_stash}" -eq 1 ]; then
			if ! _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" stash pop > "/dev/null" 2>&1; then
				_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" reset --merge > "/dev/null" 2>&1 || _git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" checkout -f > "/dev/null" 2>&1 || true
				_ui_warn "Conflito detectado ao restaurar alterações locais em ${_dir}."
				_ui_info "Sua versão local foi preservada com segurança em 'git stash list'."
			fi
			_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" diff --numstat 2> "/dev/null" | while IFS="$(printf '\t')" read -r _additions _deletions _file; do
				if [ "${_additions}" = "0" ] && [ "${_deletions}" = "0" ] && [ -n "${_file}" ]; then
					_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" checkout -- "${_file}" < "/dev/null" > "/dev/null" 2>&1 || true
				fi
			done
		fi

		if [ -d "${_dir}/.githooks" ]; then
			chmod "${_hook_mode}" "${_dir}/.githooks/"* 2> "/dev/null" || true
		fi

		if [ -f "${_dir}/.gitmodules" ]; then
			_git_pull_exec "${_dir}" "${_ran_as_root}" "${_escalator}" submodule update --init --recursive > "/dev/null" 2>&1 || true
		fi
		_git_pull_heal_perms "${_dir}" "${_is_windows}" "${_cur_uid}" "${_ran_as_root}" "${_real_u}" "${_real_g}" "${_git_dir}" "${_is_vault}" "${_chmod_spec}"
		return 0
	fi

	_git_pull_heal_perms "${_dir}" "${_is_windows}" "${_cur_uid}" "${_ran_as_root}" "${_real_u}" "${_real_g}" "${_git_dir}" "${_is_vault}" "${_chmod_spec}"
	_ui_err "Falha na sincronização Git de ${_dir}."
	return 1
}

_git_push_resilient() {
	local _dir="$1"
	if command -v cygpath > "/dev/null" 2>&1; then
		_dir="$(cygpath -u "${_dir}" 2> "/dev/null" || echo "${_dir}")"
	else
		_dir="$(echo "${_dir}" | tr '\\' '/')"
	fi
	if [ ! -d "${_dir}/.git" ] && [ ! -f "${_dir}/.git" ]; then
		return 0
	fi

	local _has_remote
	_has_remote="$(command git -C "${_dir}" remote 2> "/dev/null" || true)"
	if [ -z "${_has_remote}" ]; then
		_ui_info "${_dir}: sem remote configurado, pulando."
		return 0
	fi

	local _branch
	_branch="$(command git -C "${_dir}" branch --show-current 2> "/dev/null" || true)"
	if [ -z "${_branch}" ]; then
		_ui_info "${_dir}: branch indefinida (detached HEAD), pulando."
		return 0
	fi

	local _unpushed
	_unpushed="$(command git -C "${_dir}" cherry -v 2> "/dev/null" || true)"
	if [ -z "${_unpushed}" ]; then
		_ui_ok "${_dir}: já atualizado com o remote (${_branch})."
		return 0
	fi

	_ui_sub "Enviando ${_dir} (${_branch})..."
	if command git -C "${_dir}" push > "/dev/null" 2>&1 || command git -C "${_dir}" push origin "${_branch}" > "/dev/null" 2>&1; then
		_ui_ok "${_dir}: push concluído com sucesso!"
		return 0
	else
		_ui_err "${_dir}: falha ao enviar commits para o remote."
		return 1
	fi
}

### --------------------------------
### UPDATE & PUSH GIT REPOSITORIES
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
				  --depth=N           Profundidade máxima de busca no diretório (padrão: ilimitada)
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	local _target_root="${PWD}"
	local _git_mode="pull"
	local _max_depth=""
	local _root_set=0
	local _depth_label _arg _repo_list _git_entry _repo_dir _branch _status _ahead_behind _diverged _status_line _fail_count

	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _git_mode="status" ;;
			--dry-run|-n) _git_mode="dry-run" ;;
			--depth=*)
				_max_depth="${_arg#*=}"
				case "${_max_depth}" in
					""|*[!0-9]*)
						_ui_err "Profundidade inválida: ${_arg}"
						return 1
						;;
				esac
				;;
			-*)
				_ui_err "Opção inválida: ${_arg}"
				return 1
				;;
			*)
				if [ "${_root_set}" -eq 1 ]; then
					_ui_err "Argumento inesperado: ${_arg}"
					return 1
				fi
				_target_root="${_arg}"
				_root_set=1
				;;
		esac
	done

	if [ ! -d "${_target_root}" ]; then
		_ui_err "Diretório não encontrado: ${_target_root}"
		return 1
	fi

	_depth_label="${_max_depth:-ilimitada}"
	if [ "${_git_mode}" = "status" ]; then
		_ui_step "Auditando status Git em: ${_target_root} (profundidade: ${_depth_label})"
	elif [ "${_git_mode}" = "dry-run" ]; then
		_ui_step "Simulando atualização Git em: ${_target_root} (profundidade: ${_depth_label})"
	else
		_ui_step "Buscando e atualizando repositórios Git em: ${_target_root} (profundidade: ${_depth_label})"
	fi
	printf '\n'

	set -- "${_target_root}"
	if [ -n "${_max_depth}" ]; then
		set -- "$@" -maxdepth "$(( _max_depth + 1 ))"
	fi

	_repo_list="$(find "$@" \( -type d -name ".git" -print -prune \) -o \( -type f -name ".git" -print \) 2> "/dev/null" | \
		awk '{ n=split($0, a, "/"); print n, $0 }' | \
		sort -n -k1,1 | \
		cut -d' ' -f2-)"

	_fail_count=0
	if [ -n "${_repo_list}" ]; then
		while IFS= read -r _git_entry <&3; do
			[ -z "${_git_entry}" ] && continue
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
					if [ -n "${_status}" ]; then
						while IFS= read -r _status_line <&4; do
							[ -n "${_status_line}" ] && _ui_sub "    ${_status_line}"
						done 4<< EOF
$(printf '%s\n' "${_status}" | head -n 5)
EOF
					fi
				else
					_ui_ok "${_repo_dir} [${_branch}]: sincronizado e limpo"
				fi
			elif [ "${_git_mode}" = "dry-run" ]; then
				_ui_sub "[DRY-RUN PULL] ${_repo_dir}"
			else
				_ui_sub "Atualizando ${_repo_dir}..."
				if ! _git_pull_resilient "${_repo_dir}"; then
					_ui_warn "Falha ao atualizar ${_repo_dir}"
					_fail_count="$(( _fail_count + 1 ))"
				fi
			fi
		done 3<< EOF
${_repo_list}
EOF
	fi

	printf '\n'
	if [ "${_fail_count}" -gt 0 ]; then
		_ui_warn "Operação Git (${_git_mode}) concluída com ${_fail_count} falha(s)."
		return 1
	fi
	_ui_ok "Operação Git (${_git_mode}) concluída!"
}
alias plgit="update-git"
alias upgit="update-git"
alias pull-git="update-git"

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
				  --depth=N           Profundidade máxima de busca no diretório (padrão: ilimitada)
				  -h, --help          Exibe esta ajuda
				EOF
				return 0
				;;
		esac
	done

	local _target_root="${PWD}"
	local _git_mode="push"
	local _max_depth=""
	local _root_set=0
	local _depth_label _arg _repo_list _git_entry _repo_dir _unpushed _branch _commit_line _fail_count

	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _git_mode="status" ;;
			--dry-run|-n) _git_mode="dry-run" ;;
			--depth=*)
				_max_depth="${_arg#*=}"
				case "${_max_depth}" in
					""|*[!0-9]*)
						_ui_err "Profundidade inválida: ${_arg}"
						return 1
						;;
				esac
				;;
			-*)
				_ui_err "Opção inválida: ${_arg}"
				return 1
				;;
			*)
				if [ "${_root_set}" -eq 1 ]; then
					_ui_err "Argumento inesperado: ${_arg}"
					return 1
				fi
				_target_root="${_arg}"
				_root_set=1
				;;
		esac
	done

	if [ ! -d "${_target_root}" ]; then
		_ui_err "Diretório não encontrado: ${_target_root}"
		return 1
	fi

	_depth_label="${_max_depth:-ilimitada}"
	if [ "${_git_mode}" = "status" ]; then
		_ui_step "Auditando commits pendentes de envio em: ${_target_root} (profundidade: ${_depth_label})"
	elif [ "${_git_mode}" = "dry-run" ]; then
		_ui_step "Simulando push de repositórios Git em: ${_target_root} (profundidade: ${_depth_label})"
	else
		_ui_step "Buscando e enviando repositórios Git em: ${_target_root} (profundidade: ${_depth_label})"
	fi
	printf '\n'

	set -- "${_target_root}"
	if [ -n "${_max_depth}" ]; then
		set -- "$@" -maxdepth "$(( _max_depth + 1 ))"
	fi

	_repo_list="$(find "$@" \( -type d -name ".git" -print -prune \) -o \( -type f -name ".git" -print \) 2> "/dev/null" | \
		awk '{ n=split($0, a, "/"); print n, $0 }' | \
		sort -nr -k1,1 | \
		cut -d' ' -f2-)"

	_fail_count=0
	if [ -n "${_repo_list}" ]; then
		while IFS= read -r _git_entry <&3; do
			[ -z "${_git_entry}" ] && continue
			_repo_dir="$(dirname "${_git_entry}")"
			_unpushed="$(git -C "${_repo_dir}" cherry -v 2> "/dev/null" || true)"
			_branch="$(git -C "${_repo_dir}" branch --show-current 2> "/dev/null" || true)"
			[ -z "${_branch}" ] && _branch="detached"
			if [ -n "${_unpushed}" ]; then
				if [ "${_git_mode}" = "status" ]; then
					_ui_warn "${_repo_dir} [${_branch}]: commits pendentes de envio"
					while IFS= read -r _commit_line <&4; do
						[ -n "${_commit_line}" ] && _ui_sub "  ↳ ${_commit_line}"
					done 4<< EOF
${_unpushed}
EOF
				elif [ "${_git_mode}" = "dry-run" ]; then
					_ui_sub "[DRY-RUN PUSH] ${_repo_dir} (${_branch})"
				else
					_ui_sub "Enviando ${_repo_dir} (${_branch})..."
					if ! _git_push_resilient "${_repo_dir}"; then
						_ui_warn "Falha ao enviar ${_repo_dir}"
						_fail_count="$(( _fail_count + 1 ))"
					fi
				fi
			else
				[ "${_git_mode}" = "status" ] && _ui_ok "${_repo_dir} [${_branch}]: nada a enviar"
			fi
		done 3<< EOF
${_repo_list}
EOF
	fi

	printf '\n'
	if [ "${_fail_count}" -gt 0 ]; then
		_ui_warn "Operação Push Git (${_git_mode}) concluída com ${_fail_count} falha(s)."
		return 1
	fi
	_ui_ok "Operação Push Git (${_git_mode}) concluída!"
}
alias psgit="push-git"

### ================================
### VERSION CONTROL - GOT & GIT
### ================================
_is_got_worktree() {
	local _dir="${PWD}"
	while :; do
		if [ -d "${_dir}/.got" ] || [ -f "${_dir}/.got/base-commit" ]; then
			return 0
		fi
		case "${_dir}" in
			""|"/") return 1 ;;
		esac
		[ "${_dir%/*}" = "${_dir}" ] && return 1
		_dir="${_dir%/*}"
		[ -z "${_dir}" ] && _dir="/"
	done
}

vcs-status() {
	if _is_got_worktree; then
		got status "$@"
	elif [ -d ".git" ] || git rev-parse --git-dir > "/dev/null" 2>&1; then
		git status --short "$@"
	else
		_ui_warn "Não é um repositório Git ou Work Tree Got."
		return 1
	fi
}

vcs-diff() {
	if _is_got_worktree; then
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
