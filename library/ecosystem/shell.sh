# ----------------------------------------------------------------
# Library: Universal Shell Self-Update, Reinstall & Benchmark
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
