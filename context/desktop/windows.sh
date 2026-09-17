### ================================
### DESKTOP CONTEXT WINDOWS
### ================================

### --------------------------------
### Emacs
### --------------------------------
emacs-kill() {
	command -v runemacs > "/dev/null" 2>&1 || command -v emacsclientw > "/dev/null" 2>&1 || { echo "❌ emacs not found." >&2; return 127; }
	pkill emacs
}
emacs-start() {
	command -v runemacs > "/dev/null" 2>&1 || { echo "❌ runemacs not found." >&2; return 127; }
	runemacs --fg-daemon
}
emacs-restart() {
	emacs-kill && emacs-start
}
emacs-client() {
	command -v emacsclientw > "/dev/null" 2>&1 || { echo "❌ emacsclientw not found." >&2; return 127; }
	emacsclientw --create-frame --alternate-editor "" "$@"
}
emacs-open() {
	command -v emacsclientw > "/dev/null" 2>&1 || { echo "❌ emacsclientw not found." >&2; return 127; }
	if [ "$#" -eq 0 ]; then
		emacsclientw --create-frame --alternate-editor "" .
	else
		emacsclientw --create-frame --alternate-editor "" "$@"
	fi
}
emacs-eshell() {
	command -v emacsclientw > "/dev/null" 2>&1 || command -v runemacs > "/dev/null" 2>&1 || {
		echo "❌ emacs not found." >&2
		return 127
	}

	local _dir="${1:-.}"
	[ -d "${_dir}" ] && _dir="$(cd "${_dir}" && pwd)" || _dir="${PWD}"

	if command -v emacsclientw > "/dev/null" 2>&1; then
		emacsclientw --create-frame --alternate-editor "" --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
	else
		runemacs --eval "(progn (cd \"${_dir}/\") (aweshell/new))"
	fi
}
alias ek="emacs-kill"
alias es="emacs-start"
alias er="emacs-restart"
alias ec="emacs-client"
alias oe="emacs-open"
alias open-eshell="emacs-eshell"
alias oes="emacs-eshell"
alias esh="emacs-eshell"
