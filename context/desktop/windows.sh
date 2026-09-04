### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Emacs (Defensive)
### --------------------------------
if command -v runemacs > "/dev/null" 2>&1 || command -v emacsclientw > "/dev/null" 2>&1; then
	emacs-kill() {
		pkill emacs
	}
	emacs-start() {
		runemacs --fg-daemon
	}
	emacs-restart() {
		emacs-kill && emacs-start
	}
	emacs-client() {
		emacsclientw --create-frame --alternate-editor "" "$@"
	}
	emacs-open() {
		emacsclientw --create-frame --alternate-editor "" "${1:-.}"
	}
	alias ek="emacs-kill"
	alias es="emacs-start"
	alias er="emacs-restart"
	alias ec="emacs-client"
	alias oe="emacs-open"
fi
