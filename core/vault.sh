### ================================
### VAULT LOADER & SSH
### ================================

if [ -z "${VAULT_DIR:-}" ]; then
	if [ -d "${HOME}/.local/share/vault" ]; then
		VAULT_DIR="${HOME}/.local/share/vault"
	elif [ -d "${HOME}/.config/vault" ]; then
		VAULT_DIR="${HOME}/.config/vault"
	elif [ -d "${HOME}/.vault" ]; then
		VAULT_DIR="${HOME}/.vault"
	elif [ -d "/usr/local/share/vault" ]; then
		VAULT_DIR="/usr/local/share/vault"
	else
		VAULT_DIR="${HOME}/.local/share/vault"
	fi
fi
export VAULT_DIR

### --------------------------------
### Vault Environment
### --------------------------------
[ -f "${VAULT_DIR}/vault.sh" ] && . "${VAULT_DIR}/vault.sh"

### --------------------------------
### SSH Keys
### --------------------------------
_ssh_cache="${_SHELL_CACHE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/.universal_shell_cache_${USER:-user}}/ssh_agent_verified"
if [ -n "${SSH_AUTH_SOCK}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
	if [ -z "${SSH_AUTH_CHECKED:-}" ] && [ ! -f "${_ssh_cache}" ]; then
		if ! ssh-add -l > "/dev/null" 2>&1; then
			command -v vault-keys > "/dev/null" 2>&1 && vault-keys > "/dev/null" 2>&1
		fi
		[ -d "${_SHELL_CACHE_DIR:-}" ] && : >| "${_ssh_cache}" 2> "/dev/null" || true
		export SSH_AUTH_CHECKED=1
	fi
fi
unset _ssh_cache


### --------------------------------
### Update Vault
### --------------------------------
update-vault() {
	_target=""
	if [ -n "${VAULT_DIR:-}" ] && [ -d "${VAULT_DIR}/.git" ]; then
		_target="${VAULT_DIR}"
	elif [ -d "${HOME}/.local/share/vault/.git" ]; then
		_target="${HOME}/.local/share/vault"
	elif [ -d "${HOME}/.config/vault/.git" ]; then
		_target="${HOME}/.config/vault"
	elif [ -d "${HOME}/.vault/.git" ]; then
		_target="${HOME}/.vault"
	elif [ -d "/usr/local/share/vault/.git" ]; then
		_target="/usr/local/share/vault"
	fi

	if [ -z "${_target}" ]; then
		_ui_info "Nenhum repositório de Vault encontrado em ~/.local/share/vault, ~/.config/vault ou ~/.vault."
		return 1
	fi

	_v_mode="update"
	for _arg in "$@"; do
		case "${_arg}" in
			--status|-s)  _v_mode="status" ;;
			--keys|-k)    _v_mode="keys" ;;
			--perms|-p)   _v_mode="perms" ;;
			--dry-run|-n) _v_mode="dry-run" ;;
		esac
	done

	if [ "${_v_mode}" = "status" ]; then
		_ui_step "Auditando Universal Vault em ${_target}..."
		command -v vault-status > "/dev/null" 2>&1 && vault-status || git -C "${_target}" status -s
		return 0
	elif [ "${_v_mode}" = "keys" ]; then
		_ui_step "Recarregando chaves SSH do Vault..."
		command -v vault-keys > "/dev/null" 2>&1 && vault-keys || _ui_warn "vault-keys indisponível"
		return 0
	elif [ "${_v_mode}" = "perms" ]; then
		_ui_step "Auto-curando permissões do Vault (0700/0600)..."
		command -v vault-perms > "/dev/null" 2>&1 && vault-perms || _ui_warn "vault-perms indisponível"
		return 0
	elif [ "${_v_mode}" = "dry-run" ]; then
		_ui_sub "[DRY-RUN PULL] ${_target}"
		return 0
	fi

	_ui_step "Atualizando Universal Vault em ${_target}..."
	_ui_sub "Sincronizando com o upstream com autoproteção..."
	if command -v _git_pull_resilient > "/dev/null" 2>&1; then
		_git_pull_resilient "${_target}" || _ui_warn "Falha ao sincronizar ${_target}"
	else
		git -C "${_target}" pull || _ui_warn "Falha ao sincronizar ${_target}"
	fi

	command -v vault-perms > "/dev/null" 2>&1 && vault-perms > "/dev/null" 2>&1 || true
	command -v vault-keys > "/dev/null" 2>&1 && vault-keys > "/dev/null" 2>&1 || true

	_ui_ok "Universal Vault atualizado com sucesso!"
	_ui_info "Recarregando ambiente do shell..."
	_rc_name="$(_detect_enabled_shell --name 2> "/dev/null" || echo "sh")"
	[ -f "${HOME}/.${_rc_name}rc" ] && . "${HOME}/.${_rc_name}rc" 2> "/dev/null" || true
	unset _target _v_mode _arg _rc_name
}
alias upvt="update-vault"
