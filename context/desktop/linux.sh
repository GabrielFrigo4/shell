### ================================
### DESKTOP CONTEXT LINUX
### ================================

### --------------------------------
### CLIPBOARD INTEGRATION
### --------------------------------
clip() {
	if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy > "/dev/null" 2>&1; then
		command wl-copy "$@"
	elif command -v xclip > "/dev/null" 2>&1; then
		command xclip -selection clipboard "$@"
	elif command -v xsel > "/dev/null" 2>&1; then
		command xsel --clipboard --input "$@"
	else
		_ui_err "No clipboard tool found (wl-copy/xclip/xsel)."
		return 127
	fi
}

paste() {
	if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste > "/dev/null" 2>&1; then
		command wl-paste "$@"
	elif command -v xclip > "/dev/null" 2>&1; then
		command xclip -selection clipboard -o "$@"
	elif command -v xsel > "/dev/null" 2>&1; then
		command xsel --clipboard --output "$@"
	else
		_ui_err "No clipboard tool found (wl-paste/xclip/xsel)."
		return 127
	fi
}

### --------------------------------
### WSL SUBSYSTEM EXTENSIONS
### --------------------------------
if command -v _is_wsl > "/dev/null" 2>&1 && _is_wsl; then
	[ -f "${SHELL_REPO_DIR:-}/context/desktop/wsl.sh" ] && \
		. "${SHELL_REPO_DIR:-}/context/desktop/wsl.sh"
fi
