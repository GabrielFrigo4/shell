### ================================
### DESKTOP CONTEXT MACOS
### ================================

### --------------------------------
### SYSTEM INTEGRATION
### --------------------------------
clip() {
	command -v pbcopy > "/dev/null" 2>&1 || { _ui_err "pbcopy not found."; return 127; }
	command pbcopy "$@"
}

paste() {
	command -v pbpaste > "/dev/null" 2>&1 || { _ui_err "pbpaste not found."; return 127; }
	command pbpaste "$@"
}
