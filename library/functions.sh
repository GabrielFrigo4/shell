### ================================
### CORE FUNCTIONS
### ================================

### --------------------------------
### Path Front (highest priority)
### --------------------------------
path_front() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${1}:${PATH}" ;;
	esac
}

### --------------------------------
### Path Back (lowest priority)
### --------------------------------
path_back() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${PATH}:${1}" ;;
	esac
}

### --------------------------------
### Path Dedup
### --------------------------------
path_dedup() {
	PATH=$(command printf "%s" "${PATH}" | command awk -v RS=: -v ORS=: '!a[$(0)]++' | command sed 's/:$//')
	export PATH
}

### --------------------------------
### Update Shell (upsh)
### --------------------------------
upsh() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -d "${SHELL_REPO_DIR}" ]; then
		echo "🔄 Updating shell repository at ${SHELL_REPO_DIR}..."
		command git -C "${SHELL_REPO_DIR}" pull
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(detect_shell)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: SHELL_REPO_DIR is not set or invalid."
		echo "Please re-run the install.sh script from your shell repository."
	fi
}

### --------------------------------
### Reinstall Shell (resh)
### --------------------------------
resh() {
	if [ -z "${SHELL_REPO_DIR}" ] || [ ! -d "${SHELL_REPO_DIR}" ]; then
		echo "❌ ERROR: SHELL_REPO_DIR is not set or invalid."
		echo "Please re-run the install.sh script from your shell repository."
		return 1
	fi

	echo "🔄 Updating shell repository at ${SHELL_REPO_DIR}..."
	command git -C "${SHELL_REPO_DIR}" pull || {
		echo "❌ ERROR: git pull failed."
		return 1
	}

	echo "🔧 Re-running install.sh with context '${SHELL_CONTEXT:-desktop}'..."
	"$(command -v "$(detect_shell)" 2> "/dev/null")" "${SHELL_REPO_DIR}/install.sh" --context "${SHELL_CONTEXT:-desktop}"

	echo "♻️ Reloading shell environment..."
	. "${HOME}/.$(detect_shell)rc" 2> "/dev/null" || true

	echo "✅ Shell fully reinstalled and reloaded!"
}
