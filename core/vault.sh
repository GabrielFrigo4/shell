### ================================
### VAULT LOADER
### ================================

VAULT_DIR="${HOME}/.vault"

### --------------------------------
### Config
### --------------------------------
[ -f "${VAULT_DIR}/config.env" ] && . "${VAULT_DIR}/config.env"

### --------------------------------
### Servers
### --------------------------------
[ -f "${VAULT_DIR}/servers/servers.env" ] && . "${VAULT_DIR}/servers/servers.env"

### --------------------------------
### SSH Keys
### --------------------------------
vault-keys() {
	if [ -z "${SSH_AUTH_SOCK}" ]; then
		echo "ssh-agent not running"
		return 1
	fi
	for key in "${VAULT_DIR}/keys/"*.key; do
		[ -f "${key}" ] || continue
		command ssh-add "${key}" 2> "/dev/null" && echo "Loaded: $(command basename "${key}")"
	done
}

[ -S "${SSH_AUTH_SOCK}" ] && vault-keys 2> "/dev/null"
