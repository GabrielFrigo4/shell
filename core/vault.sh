### ================================
### VAULT LOADER E SSH
### ================================

VAULT_DIR="${HOME}/.vault"

### --------------------------------
### Variáveis de Ambiente
### --------------------------------
[ -f "${VAULT_DIR}/vault.sh" ] && . "${VAULT_DIR}/vault.sh"

### --------------------------------
### SSH Keys
### --------------------------------
vault-keys() {
	if [ -z "${SSH_AUTH_SOCK}" ]; then
		echo "⚠️  ssh-agent não está em execução."
		return 1
	fi
	for key in "${VAULT_DIR}/keys/"*.key; do
		[ -f "${key}" ] || continue
		command ssh-add "${key}" 2> "/dev/null" && echo "Loaded: $(command basename "${key}")"
	done
}

[ -S "${SSH_AUTH_SOCK}" ] && ! ssh-add -l > "/dev/null" 2>&1 && vault-keys > "/dev/null" 2>&1

### --------------------------------
### Update Vault (upvt)
### --------------------------------
upvt() {
	if [ -d "${VAULT_DIR}" ]; then
		echo "🔄 Updating vault repository at ${VAULT_DIR}..."
		command git -C "${VAULT_DIR}" pull
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(detect_shell)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: VAULT_DIR is not set or invalid."
	fi
}
