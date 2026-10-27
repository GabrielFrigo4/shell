# ----------------------------------------------------------------
# Library: Core PATH, VCS, Navigation & Utility Functions
# ----------------------------------------------------------------

### --------------------------------
### Privilege Escalation
### --------------------------------
_as_root() {
	local _escalator="$(_detect_privilege_escalator)"
	case "${_escalator}" in
		root)      "$@" ;;
		doas|sudo) command "${_escalator}" "$@" ;;
		*)
			_ui_err "Neither 'doas' nor 'sudo' was found to execute command with root privileges."
			return 1
			;;
	esac
}

### --------------------------------
### Path Manipulation
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

path-dedup() {
	local _old_ifs="${IFS+x}" _saved_ifs="${IFS:-}" _new_path="" _dir
	IFS=":"
	for _dir in ${PATH}; do
		[ -z "${_dir}" ] && continue
		case ":${_new_path}:" in
			*":${_dir}:"*) ;;
			*) _new_path="${_new_path:+${_new_path}:}${_dir}" ;;
		esac
	done
	if [ -n "${_old_ifs}" ]; then IFS="${_saved_ifs}"; else unset IFS; fi
	export PATH="${_new_path}"
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
### Resilient Git Pull & Push
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
### Update & Push Git Repositories
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

	_target_root="${PWD}"
	_git_mode="pull"
	_max_depth=""

	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _git_mode="status" ;;
			--dry-run|-n) _git_mode="dry-run" ;;
			--depth=*)    _max_depth="${_arg#*=}" ;;
			-*) ;;
			*)            [ -d "${_arg}" ] && _target_root="${_arg}" ;;
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
	echo ""

	set -- "${_target_root}"
	if [ -n "${_max_depth}" ]; then
		set -- "$@" -maxdepth "$(( _max_depth + 1 ))"
	fi

	find "$@" \( -type d -name ".git" -print -prune \) -o \( -type f -name ".git" -print \) 2> "/dev/null" | \
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
	unset _target_root _git_mode _max_depth _depth_label _arg _git_entry _repo_dir _branch _status _ahead_behind _diverged _status_line
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

	_target_root="${PWD}"
	_git_mode="push"
	_max_depth=""

	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _git_mode="status" ;;
			--dry-run|-n) _git_mode="dry-run" ;;
			--depth=*)    _max_depth="${_arg#*=}" ;;
			-*) ;;
			*)            [ -d "${_arg}" ] && _target_root="${_arg}" ;;
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
	echo ""

	set -- "${_target_root}"
	if [ -n "${_max_depth}" ]; then
		set -- "$@" -maxdepth "$(( _max_depth + 1 ))"
	fi

	find "$@" \( -type d -name ".git" -print -prune \) -o \( -type f -name ".git" -print \) 2> "/dev/null" | \
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
	unset _target_root _git_mode _max_depth _depth_label _arg _git_entry _repo_dir _unpushed _branch _commit_line
}
alias psgit="push-git"

### --------------------------------
### Poweroff & Reboot System
### --------------------------------
poweroff() {
	case "$(_detect_os)" in
		windows) shutdown.exe /s /t 0 "$@"; return $? ;;
		freebsd) _flag="-p" ;;
		*)       _flag="-h" ;;
	esac
	_as_root shutdown "${_flag}" now "$@"
	unset _flag
}

reboot() {
	case "$(_detect_os)" in
		windows) shutdown.exe /r /t 0 "$@"; return $? ;;
		*)       _as_root shutdown -r now "$@" ;;
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
### Navigation, History & Archives
### --------------------------------
take-dir() {
	if [ "$#" -eq 0 ]; then
		echo "Uso: take <diretorio>" >&2
		return 1
	fi
	command mkdir -p "$1" && cd "$1"
}

cd-git-root() {
	local _root
	_root="$(command git rev-parse --show-toplevel 2> "/dev/null")" || {
		_ui_err "Não está dentro de um repositório git."
		return 1
	}
	cd "${_root}"
}

hist-search() {
	if [ "$#" -eq 0 ]; then
		if [ -n "${BASH_VERSION:-}" ]; then command history 30
		elif [ -n "${ZSH_VERSION:-}" ]; then command history -30
		else command fc -l -30 2> "/dev/null" || command fc -l -1 2> "/dev/null"; fi
	else
		if [ -n "${BASH_VERSION:-}" ]; then command history | command grep -i "$@"
		elif [ -n "${ZSH_VERSION:-}" ]; then command history 1 | command grep -i "$@"
		else command fc -l 1 2> "/dev/null" | command grep -i "$@"; fi
	fi
}

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
		*.tar.bz2|*.tbz2) command tar -xjvf "$1" ;;
		*.tar.gz|*.tgz)   command tar -xzvf "$1" ;;
		*.tar.xz|*.txz)   command tar -xJvf "$1" ;;
		*.tar.zst)        command tar --zstd -xvf "$1" 2> "/dev/null" || command tar -xvf "$1" ;;
		*.tar)            command tar -xvf "$1" ;;
		*.gz)             command gunzip "$1" ;;
		*.bz2)            command bunzip2 "$1" ;;
		*.xz)             command unxz "$1" ;;
		*.zip)            command unzip "$1" ;;
		*.7z)             command 7z x "$1" ;;
		*.rar)            command unrar x "$1" ;;
		*.Z)              command uncompress "$1" ;;
		*)                _ui_err "Formato não suportado para extração: '$1'"; return 1 ;;
	esac
}
