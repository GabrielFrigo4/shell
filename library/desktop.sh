# ----------------------------------------------------------------
# Library: Desktop Context Dispatcher & Lazy Module Registry
# ----------------------------------------------------------------

### ================================
### DESKTOP SUBMODULE LOADER
### ================================
_desktop_lib_base="${SHELL_REPO_DIR:-}"
if [ -z "${_desktop_lib_base}" ] || [ ! -d "${_desktop_lib_base}/library/desktop" ]; then
	if [ -d "./library/desktop" ]; then
		_desktop_lib_base="."
	elif [ -d "/usr/local/share/shell/library/desktop" ]; then
		_desktop_lib_base="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell/library/desktop" ]; then
		_desktop_lib_base="${HOME}/.local/share/shell"
	fi
fi

for _desktop_part in detect.sh theme.sh emacs.sh apps.sh; do
	[ -f "${_desktop_lib_base}/library/desktop/${_desktop_part}" ] && . "${_desktop_lib_base}/library/desktop/${_desktop_part}"
done
unset _desktop_lib_base _desktop_part

_shell_load_desktop_module() {
	local _submod="${1:-}"
	[ -n "${_submod}" ] || return 1
	if [ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/library/desktop/${_submod}" ]; then
		. "${SHELL_REPO_DIR}/library/desktop/${_submod}"
	elif [ -f "${HOME}/.local/share/shell/library/desktop/${_submod}" ]; then
		. "${HOME}/.local/share/shell/library/desktop/${_submod}"
	elif [ -f "/usr/local/share/shell/library/desktop/${_submod}" ]; then
		. "/usr/local/share/shell/library/desktop/${_submod}"
	elif [ -f "./library/desktop/${_submod}" ]; then
		. "./library/desktop/${_submod}"
	else
		return 1
	fi
}

### ================================
### LAZY DEVICE MODULE
### ================================
_shell_load_desktop_device() {
	[ -n "${_SHELL_DESKTOP_DEVICE_LOADED:-}" ] && return 0
	_shell_load_desktop_module "device.sh" && _SHELL_DESKTOP_DEVICE_LOADED=1
}

_resolve_vault_ssh_key() { _shell_load_desktop_device && _resolve_vault_ssh_key "$@"; }
personal-server()        { _shell_load_desktop_device && personal-server "$@"; }
venture-server()         { _shell_load_desktop_device && venture-server "$@"; }
mount-device()           { _shell_load_desktop_device && mount-device "$@"; }
umount-device()          { _shell_load_desktop_device && umount-device "$@"; }

alias mntdev="mount-device"
alias mdev="mount-device"
alias umntdev="umount-device"
alias umdev="umount-device"
alias unmount-device="umount-device"

if ! command -v udev > "/dev/null" 2>&1; then
	alias udev="umount-device"
fi

### ================================
### LAZY KIOSK MODULE
### ================================
_shell_load_desktop_kiosk() {
	[ -n "${_SHELL_DESKTOP_KIOSK_LOADED:-}" ] && return 0
	_shell_load_desktop_module "kiosk.sh" && _SHELL_DESKTOP_KIOSK_LOADED=1
}

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

### ================================
### LAZY SESSION MODULE
### ================================
_shell_load_desktop_session() {
	[ -n "${_SHELL_DESKTOP_SESSION_LOADED:-}" ] && return 0
	_shell_load_desktop_module "session.sh" && _SHELL_DESKTOP_SESSION_LOADED=1
}

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
