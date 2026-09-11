### ================================
### VAULT LOADER & SSH
### ================================

VAULT_DIR="${VAULT_DIR:-${HOME}/.vault}"

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
	if [ -d "${VAULT_DIR}" ]; then
		echo "🔄 Updating vault repository at ${VAULT_DIR}..."
		command git -C "${VAULT_DIR}" pull
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(_detect_enabled_shell --name)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: VAULT_DIR is not set or invalid."
	fi
}
alias upvt="update-vault"
