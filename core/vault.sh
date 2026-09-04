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
if [ -S "${SSH_AUTH_SOCK}" ] && ! ssh-add -l > "/dev/null" 2>&1; then
	command -v vault-keys > "/dev/null" 2>&1 && vault-keys > "/dev/null" 2>&1
fi

### --------------------------------
### Update Vault (update-vault)
### --------------------------------
update-vault() {
	if [ -d "${VAULT_DIR}" ]; then
		echo "🔄 Updating vault repository at ${VAULT_DIR}..."
		command git -C "${VAULT_DIR}" pull
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(_detect_shell)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: VAULT_DIR is not set or invalid."
	fi
}
alias upvt="update-vault"
