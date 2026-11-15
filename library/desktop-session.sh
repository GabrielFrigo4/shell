# ----------------------------------------------------------------
# Library: Desktop Session Lazy Loader & Alias Registry
# ----------------------------------------------------------------

### --------------------------------
### LAZY LOADER
### --------------------------------
_shell_load_desktop_session() {
	[ -n "${_SHELL_DESKTOP_SESSION_LOADED:-}" ] && return 0
	if [ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/library/desktop/session.sh" ]; then
		. "${SHELL_REPO_DIR}/library/desktop/session.sh"
	elif [ -f "${HOME}/.local/share/shell/library/desktop/session.sh" ]; then
		. "${HOME}/.local/share/shell/library/desktop/session.sh"
	elif [ -f "/usr/local/share/shell/library/desktop/session.sh" ]; then
		. "/usr/local/share/shell/library/desktop/session.sh"
	elif [ -f "./library/desktop/session.sh" ]; then
		. "./library/desktop/session.sh"
	else
		return 1
	fi
	_SHELL_DESKTOP_SESSION_LOADED=1
}

### --------------------------------
### LAZY WRAPPERS & ALIASES
### --------------------------------
_propagate_session_theme_env() { _shell_load_desktop_session && _propagate_session_theme_env "$@"; }
_setup_cursor_env()            { _shell_load_desktop_session && _setup_cursor_env "$@"; }
_wayland_session_env()         { _shell_load_desktop_session && _wayland_session_env "$@"; }
_x11_session_env()             { _shell_load_desktop_session && _x11_session_env "$@"; }
_resolve_graphical_app()       { _shell_load_desktop_session && _resolve_graphical_app "$@"; }
_resolve_desktop_font()        { _shell_load_desktop_session && _resolve_desktop_font "$@"; }
_has_wayland()                 { _shell_load_desktop_session && _has_wayland "$@"; }
_has_x11()                     { _shell_load_desktop_session && _has_x11 "$@"; }
_dispatch_display_server()     { _shell_load_desktop_session && _dispatch_display_server "$@"; }
start_session()                { _shell_load_desktop_session && start_session "$@"; }
desktop_session_wayland()      { _shell_load_desktop_session && desktop_session_wayland "$@"; }
desktop_session_x11()          { _shell_load_desktop_session && desktop_session_x11 "$@"; }
window_manager_wayland()       { _shell_load_desktop_session && window_manager_wayland "$@"; }
window_manager_x11()           { _shell_load_desktop_session && window_manager_x11 "$@"; }
window_manager()               { _shell_load_desktop_session && window_manager "$@"; }

alias start-session="start_session"
alias desktop-session-wayland="desktop_session_wayland" way="desktop_session_wayland" wayland="desktop_session_wayland" start-way="desktop_session_wayland" start-wayland="desktop_session_wayland"
alias desktop-session-x11="desktop_session_x11" xorg="desktop_session_x11" x11="desktop_session_x11" start-xorg="desktop_session_x11" start-x11="desktop_session_x11"
alias window-manager-wayland="window_manager_wayland" wwm="window_manager_wayland"
alias window-manager-x11="window_manager_x11" xwm="window_manager_x11"
alias window-manager="window_manager" wm="window_manager" win="window_manager" win-man="window_manager" window="window_manager"
