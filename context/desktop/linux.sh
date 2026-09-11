### ================================
### DESKTOP CONTEXT LINUX
### ================================

### --------------------------------
### Clipboard Integration
### --------------------------------
clip() {
	if [ -n "${WAYLAND_DISPLAY}" ] && command -v wl-copy > "/dev/null" 2>&1; then
		command wl-copy "$@"
	elif command -v xclip > "/dev/null" 2>&1; then
		command xclip -selection clipboard "$@"
	elif command -v xsel > "/dev/null" 2>&1; then
		command xsel --clipboard --input "$@"
	else
		echo "❌ No clipboard tool found (wl-copy/xclip/xsel)." >&2
		return 127
	fi
}

paste() {
	if [ -n "${WAYLAND_DISPLAY}" ] && command -v wl-paste > "/dev/null" 2>&1; then
		command wl-paste "$@"
	elif command -v xclip > "/dev/null" 2>&1; then
		command xclip -selection clipboard -o "$@"
	elif command -v xsel > "/dev/null" 2>&1; then
		command xsel --clipboard --output "$@"
	else
		echo "❌ No clipboard tool found (wl-paste/xclip/xsel)." >&2
		return 127
	fi
}

### --------------------------------
### File Opener
### --------------------------------
o() {
	command -v xdg-open > "/dev/null" 2>&1 || { echo "❌ xdg-open not found." >&2; return 127; }
	command nohup xdg-open "$@" > "/dev/null" 2>&1 &
}
