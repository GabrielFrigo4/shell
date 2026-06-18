#!/usr/bin/env sh

### ================================
### Shell Install Script
### ================================

SHELL_REPO_DIR="$(cd "$(dirname "${0}")" && pwd)"

### --------------------------------
### Parse Arguments
### --------------------------------
SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
for arg in "$@"; do
	case "${arg}" in
		--context=*) SHELL_CONTEXT="${arg#*=}" ;;
		-c=*)        SHELL_CONTEXT="${arg#*=}" ;;
	esac
done

_skip_next=0
for arg in "$@"; do
	if [ "${_skip_next}" -eq 1 ]; then
		SHELL_CONTEXT="${arg}"
		_skip_next=0
		continue
	fi
	case "${arg}" in
		--context|-c) _skip_next=1 ;;
	esac
done
unset _skip_next

case "${SHELL_CONTEXT}" in
	desktop|server|container) ;;
	*)
		echo "ERROR: Invalid context '${SHELL_CONTEXT}'. Use 'desktop', 'server' or 'container'."
		echo "Usage: install.sh [--context desktop|server|container] [-c desktop|server|container]"
		exit 1
		;;
esac

### --------------------------------
### Detect Shell
### --------------------------------
SHELL_NAME="$(ps -p "${PPID}" -o comm= 2> "/dev/null" | sed 's/^-//')"
if [ "${SHELL_NAME}" = "sudo" ] || [ "${SHELL_NAME}" = "su" ]; then
	GPID="$(ps -p "${PPID}" -o ppid= 2> "/dev/null" | tr -d ' ')"
	SHELL_NAME="$(ps -p "${GPID}" -o comm= 2> "/dev/null" | sed 's/^-//')"
fi
[ -z "${SHELL_NAME}" ] && SHELL_NAME="$(basename "${SHELL}")"

### --------------------------------
### Detect OS
### --------------------------------
OS="unknown"
case "$(uname -s)" in
	Linux*)               OS="linux" ;;
	FreeBSD*)             OS="freebsd" ;;
	MINGW*|CYGWIN*|MSYS*) OS="windows" ;;
esac

echo "=== Shell Installer ==="
echo "Detected repo:  ${SHELL_REPO_DIR}"
echo "Detected OS:    ${OS}"
echo "Detected shell: ${SHELL_NAME}"
echo "Context:        ${SHELL_CONTEXT}"

### --------------------------------
### Permissions (shell repo)
### --------------------------------
if [ "${OS}" != "windows" ]; then
	sudo chown -R "$(id -un):$(id -gn)" "${SHELL_REPO_DIR}"
	sudo find "${SHELL_REPO_DIR}" -type d -exec chmod 755 {} +
	sudo find "${SHELL_REPO_DIR}" -type f -exec chmod 644 {} +
	sudo find "${SHELL_REPO_DIR}" -name "*.sh" -exec chmod 755 {} +
fi

### --------------------------------
### Validate
### --------------------------------
PROMPT_FILE="${SHELL_REPO_DIR}/target/${OS}/${SHELL_NAME}/prompt.sh"
if [ ! -f "${PROMPT_FILE}" ]; then
	echo "ERROR: No prompt file found at: ${PROMPT_FILE}"
	echo "Available configs:"
	ls -R "${SHELL_REPO_DIR}/target/" 2> "/dev/null"
	exit 1
fi

echo "Found prompt:   ${PROMPT_FILE}"

### --------------------------------
### Determine RC file (user)
### --------------------------------
case "${SHELL_NAME}" in
	bash) RC_FILE="${HOME}/.bashrc" ;;
	zsh)  RC_FILE="${HOME}/.zshrc" ;;
	sh)   RC_FILE="${HOME}/.shrc" ;;
	*)    RC_FILE="${HOME}/.${SHELL_NAME}rc" ;;
esac

### --------------------------------
### Determine RC file (root)
### --------------------------------
case "${SHELL_NAME}" in
	bash) ROOT_RC_FILE="/root/.bashrc" ;;
	zsh)  ROOT_RC_FILE="/root/.zshrc" ;;
	sh)   ROOT_RC_FILE="/root/.shrc" ;;
	*)    ROOT_RC_FILE="/root/.${SHELL_NAME}rc" ;;
esac

### --------------------------------
### Clean RC file (user)
### --------------------------------
rm -f "${RC_FILE}"

### --------------------------------
### Clean RC file (root)
### --------------------------------
if [ "${OS}" != "windows" ]; then
	sudo rm -f "${ROOT_RC_FILE}"
fi

### --------------------------------
### Install Oh-My-Zsh / Oh-My-Bash
### --------------------------------
case "${SHELL_NAME}" in
	zsh)
		if [ ! -d "${HOME}/.oh-my-zsh" ]; then
			KEEP_ZSHRC=no OVERWRITE_CONFIRMATION=no curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | zsh -s -- --unattended
		else
			cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc"
		fi
		if [ "${OS}" != "windows" ]; then
			if [ ! -d "/root/.oh-my-zsh" ]; then
				sudo env KEEP_ZSHRC=no OVERWRITE_CONFIRMATION=no sh -c 'curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | zsh -s -- --unattended'
			else
				sudo cp "/root/.oh-my-zsh/templates/zshrc.zsh-template" "/root/.zshrc"
			fi
		fi
		;;
	bash)
		if [ ! -d "${HOME}/.oh-my-bash" ]; then
			KEEP_BASHRC=no curl -fsSL "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh" | bash -s -- --unattended
		else
			cp "${HOME}/.oh-my-bash/templates/bashrc.osh-template" "${HOME}/.bashrc"
		fi
		sed -i.bak 's/OSH_THEME="[^"]*"/OSH_THEME=""/' "${HOME}/.bashrc" && rm -f "${HOME}/.bashrc.bak"
		if [ "${OS}" != "windows" ]; then
			if [ ! -d "/root/.oh-my-bash" ]; then
				sudo env KEEP_BASHRC=no sh -c 'curl -fsSL "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh" | bash -s -- --unattended'
			else
				sudo cp "/root/.oh-my-bash/templates/bashrc.osh-template" "/root/.bashrc"
			fi
			sudo sed -i.bak 's/OSH_THEME="[^"]*"/OSH_THEME=""/' "/root/.bashrc" && sudo rm -f "/root/.bashrc.bak"
		fi
		;;
esac

### --------------------------------
### Source lines to inject
### --------------------------------
case "${SHELL_NAME}" in
	bash|zsh) SOURCE_CMD="source" ;;
	*)        SOURCE_CMD="." ;;
esac

SOURCE_LINE="${SOURCE_CMD} \"${PROMPT_FILE}\""
CORE_ENV_LINE="${SOURCE_CMD} \"${SHELL_REPO_DIR}/core/environment.sh\""
CORE_FUNC_LINE="${SOURCE_CMD} \"${SHELL_REPO_DIR}/core/functions.sh\""
CORE_VAULT_LINE="${SOURCE_CMD} \"${SHELL_REPO_DIR}/core/vault.sh\""
CONTEXT_LINE="export SHELL_CONTEXT=\"${SHELL_CONTEXT}\""

echo "Target RC file: ${RC_FILE}"

### --------------------------------
### Install (user)
### --------------------------------
if grep -qF "${SOURCE_LINE}" "${RC_FILE}" 2> "/dev/null"; then
	echo "Shell config already installed in ${RC_FILE}"
	echo "Skipping."
else
		cat << EOF | tee -a "${RC_FILE}" > "/dev/null"

# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │   S H E L L   E N V I R O N M E N T   S E T U P          │
# │                                                          │
# │   [!] Auto-generated by install.sh                       │
# │   [!] Do not edit this block directly                    │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
${CONTEXT_LINE}
${CORE_ENV_LINE}
${CORE_FUNC_LINE}
${CORE_VAULT_LINE}
${SOURCE_LINE}
EOF
	echo "Done! Added source lines to ${RC_FILE}"
	echo "Restart your shell or run: . ${RC_FILE}"
fi

### --------------------------------
### Install (root)
### --------------------------------
if [ "${OS}" != "windows" ]; then
	echo "Target RC file: ${ROOT_RC_FILE} (root)"
	if sudo grep -qF "${SOURCE_LINE}" "${ROOT_RC_FILE}" 2> "/dev/null"; then
		echo "Shell config already installed in ${ROOT_RC_FILE}"
		echo "Skipping."
	else
		cat << EOF | sudo tee -a "${ROOT_RC_FILE}" > "/dev/null"

# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │   S H E L L   E N V I R O N M E N T   S E T U P          │
# │                                                          │
# │   [!] Auto-generated by install.sh                       │
# │   [!] Do not edit this block directly                    │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
${CONTEXT_LINE}
${CORE_ENV_LINE}
${CORE_FUNC_LINE}
${CORE_VAULT_LINE}
${SOURCE_LINE}
EOF
		echo "Done! Added source lines to ${ROOT_RC_FILE}"
	fi
fi
