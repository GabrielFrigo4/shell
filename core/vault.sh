### ================================
### VAULT LOADER & SSH
### ================================

if [ -z "${VAULT_DIR:-}" ]; then
	if [ -d "${HOME}/.vault" ]; then
		VAULT_DIR="${HOME}/.vault"
	elif [ -d "/usr/local/share/vault" ]; then
		VAULT_DIR="/usr/local/share/vault"
	else
		VAULT_DIR="${HOME}/.vault"
	fi
fi

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
	elif [ -d "${HOME}/.vault/.git" ]; then
		_target="${HOME}/.vault"
	elif [ -d "/usr/local/share/vault/.git" ]; then
		_target="/usr/local/share/vault"
	fi

	if [ -n "${_target}" ]; then
		echo "🔄 Updating vault repository at ${_target}..."
		if [ -w "${_target}" ]; then
			command git -C "${_target}" pull
		else
			_as_root git -C "${_target}" pull
		fi
		echo "♻️ Reloading shell environment..."
		_rc_name="$(_detect_enabled_shell --name 2> "/dev/null" || echo "sh")"
		[ -f "${HOME}/.${_rc_name}rc" ] && . "${HOME}/.${_rc_name}rc" 2> "/dev/null" || true
		unset _rc_name
	else
		echo "ℹ️  No active vault repository found at ~/.vault or /usr/local/share/vault."
	fi
	unset _target
}
alias upvt="update-vault"
