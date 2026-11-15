# ----------------------------------------------------------------
# Library: Desktop Kiosk Lazy Loader & Alias Registry
# ----------------------------------------------------------------

### --------------------------------
### LAZY LOADER
### --------------------------------
_shell_load_desktop_kiosk() {
	[ -n "${_SHELL_DESKTOP_KIOSK_LOADED:-}" ] && return 0
	if [ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/library/desktop/kiosk.sh" ]; then
		. "${SHELL_REPO_DIR}/library/desktop/kiosk.sh"
	elif [ -f "${HOME}/.local/share/shell/library/desktop/kiosk.sh" ]; then
		. "${HOME}/.local/share/shell/library/desktop/kiosk.sh"
	elif [ -f "/usr/local/share/shell/library/desktop/kiosk.sh" ]; then
		. "/usr/local/share/shell/library/desktop/kiosk.sh"
	elif [ -f "./library/desktop/kiosk.sh" ]; then
		. "./library/desktop/kiosk.sh"
	else
		return 1
	fi
	_SHELL_DESKTOP_KIOSK_LOADED=1
}

### --------------------------------
### LAZY WRAPPERS & ALIASES
### --------------------------------
graphical_launcher_wayland()    { _shell_load_desktop_kiosk && graphical_launcher_wayland "$@"; }
graphical_launcher_x11()        { _shell_load_desktop_kiosk && graphical_launcher_x11 "$@"; }
graphical_launcher()            { _shell_load_desktop_kiosk && graphical_launcher "$@"; }
emacs_window_manager_wayland()  { _shell_load_desktop_kiosk && emacs_window_manager_wayland "$@"; }
emacs_window_manager_x11()      { _shell_load_desktop_kiosk && emacs_window_manager_x11 "$@"; }
emacs_window_manager()          { _shell_load_desktop_kiosk && emacs_window_manager "$@"; }

alias graphical-launcher-wayland="graphical_launcher_wayland" wgui="graphical_launcher_wayland"
alias graphical-launcher-x11="graphical_launcher_x11" xgui="graphical_launcher_x11"
alias graphical-launcher="graphical_launcher" gui="graphical_launcher"
alias emacs-window-manager-wayland="emacs_window_manager_wayland" wewm="emacs_window_manager_wayland" wew="emacs_window_manager_wayland"
alias emacs-window-manager-x11="emacs_window_manager_x11" xewm="emacs_window_manager_x11" xew="emacs_window_manager_x11" exwm="emacs_window_manager_x11" exw="emacs_window_manager_x11"
alias emacs-window-manager="emacs_window_manager" ewm="emacs_window_manager" ew="emacs_window_manager"
