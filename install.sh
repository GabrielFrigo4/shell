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
	desktop|server|container|wsl) ;;
	*)
		echo "ERROR: Invalid context '${SHELL_CONTEXT}'. Use 'desktop', 'server', 'container' or 'wsl'."
		echo "Usage: install.sh [--context desktop|server|container|wsl] [-c desktop|server|container|wsl]"
		exit 1
		;;
esac

### --------------------------------
### Detect OS
### --------------------------------
. "${SHELL_REPO_DIR}/library/detect.sh"
OS_NAME="$(_detect_os)"

### --------------------------------
### Detect Shell
### --------------------------------
SHELL_NAME="$(_detect_shell)"

echo "=== Shell Installer ==="
echo "Detected repo:  ${SHELL_REPO_DIR}"
echo "Detected OS:    ${OS_NAME}"
echo "Detected shell: ${SHELL_NAME}"
echo "Context:        ${SHELL_CONTEXT}"

### --------------------------------
### Permissions (shell repo)
### --------------------------------
if [ "${OS_NAME}" != "windows" ]; then
	_as_root chown -R "$(id -un):$(id -gn)" "${SHELL_REPO_DIR}"
	_as_root find "${SHELL_REPO_DIR}" -type d -exec chmod 0755 {} +
	_as_root find "${SHELL_REPO_DIR}" -type f -exec chmod 0644 {} +
	[ -f "${SHELL_REPO_DIR}/install.sh" ] && _as_root chmod 0755 "${SHELL_REPO_DIR}/install.sh"
fi

### --------------------------------
### Validate
### --------------------------------
PROMPT_FILE="${SHELL_REPO_DIR}/target/${OS_NAME}/${SHELL_NAME}/prompt.sh"
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
	dash) RC_FILE="${HOME}/.dashrc" ;;
	*)    RC_FILE="${HOME}/.${SHELL_NAME}rc" ;;
esac

### --------------------------------
### Determine RC file (root)
### --------------------------------
case "${SHELL_NAME}" in
	bash) ROOT_RC_FILE="/root/.bashrc" ;;
	zsh)  ROOT_RC_FILE="/root/.zshrc" ;;
	sh)   ROOT_RC_FILE="/root/.shrc" ;;
	dash) ROOT_RC_FILE="/root/.dashrc" ;;
	*)    ROOT_RC_FILE="/root/.${SHELL_NAME}rc" ;;
esac

### --------------------------------
### Clean RC file (user)
### --------------------------------
rm -f "${RC_FILE}"

### --------------------------------
### Clean RC file (root)
### --------------------------------
if [ "${OS_NAME}" != "windows" ]; then
	_as_root rm -f "${ROOT_RC_FILE}"
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
		if [ "${OS_NAME}" != "windows" ]; then
			if [ ! -d "/root/.oh-my-zsh" ]; then
				_as_root env KEEP_ZSHRC=no OVERWRITE_CONFIRMATION=no sh -c 'curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | zsh -s -- --unattended'
			else
				_as_root cp "/root/.oh-my-zsh/templates/zshrc.zsh-template" "/root/.zshrc"
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
		if [ "${OS_NAME}" != "windows" ]; then
			if [ ! -d "/root/.oh-my-bash" ]; then
				_as_root env KEEP_BASHRC=no sh -c 'curl -fsSL "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh" | bash -s -- --unattended'
			else
				_as_root cp "/root/.oh-my-bash/templates/bashrc.osh-template" "/root/.bashrc"
			fi
			_as_root sed -i.bak 's/OSH_THEME="[^"]*"/OSH_THEME=""/' "/root/.bashrc" && _as_root rm -f "/root/.bashrc.bak"
		fi
		;;
esac

### --------------------------------
### Source lines to inject
### --------------------------------
SOURCE_CMD="."

REPO_DIR_LINE="export SHELL_REPO_DIR=\"${SHELL_REPO_DIR}\""
CONTEXT_LINE="export SHELL_CONTEXT=\"${SHELL_CONTEXT}\""
SOURCE_LINE="${SOURCE_CMD} \"\${SHELL_REPO_DIR}/target/${OS_NAME}/${SHELL_NAME}/prompt.sh\""
SETUP_BLOCK="$(cat << EOF

# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │   S H E L L   E N V I R O N M E N T   S E T U P          │
# │                                                          │
# │   [!] Auto-generated by install.sh                       │
# │   [!] Do not edit this block directly                    │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
${REPO_DIR_LINE}
${CONTEXT_LINE}

for _f in "\${SHELL_REPO_DIR}/library/"*.sh; do [ -f "\${_f}" ] && ${SOURCE_CMD} "\${_f}"; done
for _f in "\${SHELL_REPO_DIR}/core/"*.sh; do [ -f "\${_f}" ] && ${SOURCE_CMD} "\${_f}"; done
unset _f

${SOURCE_LINE}
EOF
)"

### --------------------------------
### Install (user)
### --------------------------------
echo "Target RC file: ${RC_FILE}"
if grep -qF "${SOURCE_LINE}" "${RC_FILE}" 2> "/dev/null"; then
	echo "Shell config already installed in ${RC_FILE}"
	echo "Skipping."
else
	echo "${SETUP_BLOCK}" | tee -a "${RC_FILE}" > "/dev/null"
	echo "Done! Added source lines to ${RC_FILE}"
	echo "Restart your shell or run: . ${RC_FILE}"
fi

### --------------------------------
### Install (root)
### --------------------------------
if [ "${OS_NAME}" != "windows" ]; then
	echo "Target RC file: ${ROOT_RC_FILE} (root)"
	if _as_root grep -qF "${SOURCE_LINE}" "${ROOT_RC_FILE}" 2> "/dev/null"; then
		echo "Shell config already installed in ${ROOT_RC_FILE}"
		echo "Skipping."
	else
		echo "${SETUP_BLOCK}" | _as_root tee -a "${ROOT_RC_FILE}" > "/dev/null"
		echo "Done! Added source lines to ${ROOT_RC_FILE}"
	fi
fi
