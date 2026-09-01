### ================================
### CORE ENVIRONMENT
### ================================

### --------------------------------
### Variables
### --------------------------------
export COLORTERM="truecolor"
export MICRO_TRUECOLOR=1

### --------------------------------
### Auto-Correct SHELL
### --------------------------------
export SHELL="$(command -v "$(_detect_shell)" 2> "/dev/null")"

### --------------------------------
### Privilege Escalation Aliases
### --------------------------------
if command -v doas > "/dev/null" 2>&1; then
	if ! command -v sudo > "/dev/null" 2>&1; then
		alias sudo="doas"
	fi
elif command -v sudo > "/dev/null" 2>&1; then
	if ! command -v doas > "/dev/null" 2>&1; then
		alias doas="sudo"
	fi
fi

### --------------------------------
### AUR Compatibility Aliases
### --------------------------------
if command -v paru > "/dev/null" 2>&1; then
	if ! command -v yay > "/dev/null" 2>&1; then
		alias yay="paru"
	fi
elif command -v yay > "/dev/null" 2>&1; then
	if ! command -v paru > "/dev/null" 2>&1; then
		alias paru="yay"
	fi
fi

### --------------------------------
### Default Editor (Conscious Cascade)
### --------------------------------
_is_generic_editor() {
	case "${1}" in
		""|nano|*/nano|vi|*/vi|ee|*/ee|ed|*/ed) return 0 ;;
		*) return 1 ;;
	esac
}

if _is_generic_editor "${EDITOR}"; then
	for _ed in nvim hx micro kak vim nano ee mg mcedit vi; do
		if command -v "${_ed}" > "/dev/null" 2>&1; then
			export EDITOR="${_ed}"
			export VISUAL="${_ed}"
			break
		fi
	done
	unset _ed
fi

### --------------------------------
### Universal Editor
### --------------------------------
editor() {
	if [ "$#" -eq 0 ]; then
		${VISUAL:-${EDITOR:-vi}} .
	else
		${VISUAL:-${EDITOR:-vi}} "$@"
	fi
}
alias e="editor"
