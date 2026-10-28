# ----------------------------------------------------------------
# Library: Ephemeral GUI Launchers & Emacs OS Window Managers
# ----------------------------------------------------------------

### --------------------------------
### Ephemeral Graphical Launchers
### --------------------------------
graphical-launcher-wayland() {
	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1

	local _flavor=""
	local _had_wayland=1
	[ -z "${WAYLAND_DISPLAY:-}" ] && _had_wayland=0
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	local _app="${1:-foot}"
	[ "$#" -ge 1 ] && shift

	_wayland_session_env "${_flavor}"

	local _is_terminal=0
	_is_terminal_app "${_app}" && _is_terminal=1

	local _wayland_runner="${XDG_RUNTIME_DIR:-/tmp}/wayland-runner-$$.sh"
	local _sh="$(_detect_enabled_shell)"

	cat << EOF > "${_wayland_runner}"
#!/bin/sh
_app_target="\$1"
[ "\$#" -ge 1 ] && shift

if [ -z "\${_app_target}" ] || [ "\${_app_target}" = "foot" ]; then
	if [ "\$#" -eq 0 ]; then
		foot
	else
		foot "\$@"
	fi
elif [ "${_is_terminal}" -eq 1 ]; then
	if command -v "\${_app_target}" > "/dev/null" 2>&1; then
		foot "\${_app_target}" "\$@"
	else
		foot "${_sh}" -i -c "\${_app_target} \$*"
	fi
elif [ "\${_app_target}" = "emacs" ]; then
	_emacs_wayland_bin="\$(command -v emacs-pgtk 2> "/dev/null" || command -v emacs 2> "/dev/null" || true)"
	"\${_emacs_wayland_bin}" -mm "\$@"
else
	"\${_app_target}" "\$@"
fi
_ret=\$?

if command -v swaymsg > "/dev/null" 2>&1 && [ -n "\${SWAYSOCK:-}" ]; then
	swaymsg exit > "/dev/null" 2>&1 || true
fi
if command -v riverctl > "/dev/null" 2>&1 && [ -n "\${RIVER_SOCKET:-}" ]; then
	riverctl exit > "/dev/null" 2>&1 || true
fi
if command -v labwc > "/dev/null" 2>&1; then
	labwc --exit > "/dev/null" 2>&1 || true
fi
exit "\${_ret}"
EOF
	chmod 0755 "${_wayland_runner}"

	local _exec_invocation="\"${_wayland_runner}\" \"${_app}\""
	local _arg
	for _arg in "$@"; do
		[ -n "${_arg}" ] && _exec_invocation="${_exec_invocation} \"$(printf '%s' "${_arg}" | sed 's/"/\\"/g')\""
	done

	if [ "${_app}" = "foot" ] || [ "${_is_terminal}" -eq 1 ]; then
		local _foot_target="${HOME}/.config/foot/foot.ini"
		local _foot_src=""
		if [ -f "${HOME}/.local/share/profile/terminals/foot/foot.ini" ]; then
			_foot_src="${HOME}/.local/share/profile/terminals/foot/foot.ini"
		elif [ -f "${PROFILE_REPO_DIR:-}/terminals/foot/foot.ini" ]; then
			_foot_src="${PROFILE_REPO_DIR}/terminals/foot/foot.ini"
		fi
		if [ -n "${_foot_src}" ]; then
			mkdir -p "${HOME}/.config/foot"
			if [ ! -f "${_foot_target}" ] || ! cmp -s "${_foot_src}" "${_foot_target}"; then
				cp -f "${_foot_src}" "${_foot_target}" 2> "/dev/null" || true
			fi
		fi
	fi

	local _cur_theme="${XCURSOR_THEME:-default}"
	local _cur_size="${XCURSOR_SIZE:-24}"

	if command -v sway > "/dev/null" 2>&1; then
		local _sway_cfg="${XDG_RUNTIME_DIR}/sway-gui-$$.conf"
		cat << EOF > "${_sway_cfg}"
default_border none
default_floating_border none
titlebar_border_thickness 0
seat * xcursor_theme ${_cur_theme} ${_cur_size}
seat * fallback true
seat * hide_cursor when-typing disable
seat * pointer_constraint enable
input type:pointer {
    accel_profile flat
    pointer_accel 0
}
input type:touchpad {
    tap enabled
    natural_scroll enabled
    dwt enabled
}
focus_follows_mouse yes
xwayland enable
for_window [app_id=".*" tiling] fullscreen enable
for_window [app_id=".*"] focus
for_window [class=".*" window_type="normal" tiling] fullscreen enable
for_window [class=".*"] focus
for_window [window_type="dialog"] floating enable, fullscreen disable
for_window [window_type="utility"] floating enable, fullscreen disable
for_window [window_type="popup_menu"] floating enable, fullscreen disable
for_window [window_type="dropdown_menu"] floating enable, fullscreen disable
for_window [floating] fullscreen disable
bindsym Mod4+Shift+q exec swaymsg exit
bindsym Mod4+q exec swaymsg exit
input type:keyboard {
    xkb_layout br
    xkb_model abnt2
    xkb_options numpad:mac
    repeat_delay 200
    repeat_rate 50
    xkb_numlock enabled
}
exec ${_exec_invocation}
EOF
		command sway -c "${_sway_cfg}" > "/dev/null" 2>&1
		rm -f "${_sway_cfg}"
	elif command -v river > "/dev/null" 2>&1; then
		local _river_init="${XDG_RUNTIME_DIR:-/tmp}/river-gui-$$.sh"
		cat << EOF > "${_river_init}"
#!/bin/sh
riverctl border-width 0
riverctl xcursor-theme "${_cur_theme}" "${_cur_size}"
riverctl keyboard-layout -model abnt2 -options numpad:mac br
riverctl set-repeat 50 200
riverctl default-attach-mode top
riverctl map normal Super F toggle-fullscreen
riverctl map normal Super Q spawn "riverctl exit"
${_exec_invocation} &
EOF
		chmod 0755 "${_river_init}"
		command river -c "${_river_init}" > "/dev/null" 2>&1
		rm -f "${_river_init}"
	elif command -v labwc > "/dev/null" 2>&1; then
		local _labwc_dir="${XDG_RUNTIME_DIR:-/tmp}/labwc-gui-$$"
		mkdir -p "${_labwc_dir}"
		cat << EOF > "${_labwc_dir}/rc.xml"
<?xml version="1.0"?>
<labwc_config>
  <theme>
    <cornerRadius>0</cornerRadius>
  </theme>
  <keyboard>
    <repeatRate>50</repeatRate>
    <repeatDelay>200</repeatDelay>
    <numlock>on</numlock>
  </keyboard>
  <windowRules>
    <windowRule identifier="*" serverDecoration="no">
      <action name="Maximize"/>
    </windowRule>
  </windowRules>
</labwc_config>
EOF
		command labwc -C "${_labwc_dir}" -s "${_exec_invocation}" > "/dev/null" 2>&1
		rm -rf "${_labwc_dir}"
	elif command -v cage > "/dev/null" 2>&1; then
		command cage -s -- ${_exec_invocation} > "/dev/null" 2>&1
	else
		_ui_err "Nenhum micro-compositor Wayland (sway, river, labwc, cage) foi encontrado."
		rm -f "${_wayland_runner}" 2> "/dev/null" || true
		return 1
	fi

	rm -f "${_wayland_runner}" 2> "/dev/null" || true
	[ "${_had_wayland}" -eq 0 ] && unset WAYLAND_DISPLAY
	_freebsd_vt_bounce
}
alias wgui="graphical-launcher-wayland"

graphical-launcher-x11() {
	command -v xinit > "/dev/null" 2>&1 || command -v startx > "/dev/null" 2>&1 || {
		_ui_err "xinit ou startx não encontrado para lançador Xorg."
		return 1
	}

	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1

	local _flavor=""
	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	local _app="${1:-xterm}"
	[ "$#" -ge 1 ] && shift

	local _display="$(_resolve_free_display)"
	export DISPLAY="${_display}"
	_x11_session_env "${_flavor}"
	_x11_driver_preflight

	local _kiosk_theme_dir="${HOME}/.local/share/themes/kiosk/openbox-3"
	if [ ! -f "${_kiosk_theme_dir}/themerc" ]; then
		mkdir -p "${_kiosk_theme_dir}" 2> "/dev/null" || true
		cat << 'OTM' > "${_kiosk_theme_dir}/themerc"
border.width: 0
padding.width: 0
padding.height: 0
window.handle.width: 0
window.client.padding.width: 0
menu.border.width: 1
menu.border.color: #2b2b2b
OTM
	fi

	local _is_terminal=0
	_is_terminal_app "${_app}" && _is_terminal=1

	local _sh="$(_detect_enabled_shell)"
	local _vt_arg="$(_resolve_vt_arg)"
	local _xinit_script="${XDG_RUNTIME_DIR:-/tmp}/xinit-gui-$$.sh"
	cat << EOF > "${_xinit_script}"
#!/bin/sh
export XDG_SESSION_TYPE="x11"
unset WAYLAND_DISPLAY
export GDK_BACKEND="x11"
export QT_QPA_PLATFORM="xcb"
export SDL_VIDEODRIVER="x11"
export CLUTTER_BACKEND="x11"
export GTK_CSD=0
export GTK_THEME="${GTK_THEME:-Adwaita:dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1
export XCURSOR_THEME="${XCURSOR_THEME:-Adwaita}"
export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"
export MOZ_GTK_TITLEBAR_DECORATION="system"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

if [ -z "\${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -e "\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}/bus" ]; then
	export DBUS_SESSION_BUS_ADDRESS="unix:path=\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}/bus"
fi

if [ -f "\${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "\${HOME}/.Xresources" 2> "/dev/null" || true
fi
if command -v xrdb > "/dev/null" 2>&1; then
	printf "Xcursor.theme: %s\nXcursor.size: %s\n" "\${XCURSOR_THEME}" "\${XCURSOR_SIZE}" | xrdb -merge - 2> "/dev/null" || true
fi
command -v xsetroot > "/dev/null" 2>&1 && xsetroot -cursor_name left_ptr 2> "/dev/null" || true

if command -v setxkbmap > "/dev/null" 2>&1; then
	setxkbmap -model abnt2 -layout br -option numpad:mac 2> "/dev/null" || true
fi
if command -v xset > "/dev/null" 2>&1; then
	xset r rate 200 50 2> "/dev/null" || true
	xset led named "Num Lock" 2> "/dev/null" || true
fi
if command -v numlockx > "/dev/null" 2>&1; then
	numlockx on 2> "/dev/null" || true
fi

if command -v openbox > "/dev/null" 2>&1; then
	_ob_cfg="\${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-\$\$.xml"
	cat << 'XOB' > "\${_ob_cfg}"
<?xml version="1.0"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>kiosk</name>
    <titleLayout></titleLayout>
    <keepBorder>no</keepBorder>
    <animateIconify>no</animateIconify>
  </theme>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusModel>Smart</focusModel>
  </focus>
  <mouse>
    <dragThreshold>0</dragThreshold>
    <doubleClickTime>500</doubleClickTime>
    <screenEdgeWarpTime>0</screenEdgeWarpTime>
    <screenEdgeWarpMouse>false</screenEdgeWarpMouse>
    <context name="Frame"/><context name="Titlebar"/><context name="Top"/><context name="Bottom"/>
    <context name="Left"/><context name="Right"/><context name="TopLeft"/><context name="TopRight"/>
    <context name="BottomLeft"/><context name="BottomRight"/><context name="Maximize"/><context name="Iconify"/>
    <context name="Close"/><context name="AllDesktops"/><context name="Shade"/><context name="Root"/><context name="Client"/>
  </mouse>
  <keyboard>
    <keybind key="A-F4"><action name="Close"/></keybind>
  </keyboard>
  <applications>
    <application class="*"><decor>no</decor><shade>no</shade><focus>yes</focus><maximized>yes</maximized></application>
    <application type="dialog"><decor>no</decor><focus>yes</focus><maximized>no</maximized></application>
  </applications>
</openbox_config>
XOB
	openbox --config-file "\${_ob_cfg}" > "/dev/null" 2>&1 &
elif command -v matchbox-window-manager > "/dev/null" 2>&1; then
	matchbox-window-manager -use_titlebar no > "/dev/null" 2>&1 &
elif command -v cwm > "/dev/null" 2>&1; then
	cwm > "/dev/null" 2>&1 &
elif command -v ratpoison > "/dev/null" 2>&1; then
	ratpoison > "/dev/null" 2>&1 &
elif command -v xdotool > "/dev/null" 2>&1; then
	(
		for _i in \$(seq 1 20); do
			sleep 0.1
			for _wid in \$(command xdotool search --onlyvisible --class ".*" 2> "/dev/null"); do
				command xdotool windowsize "\${_wid}" 100% 100% windowmove "\${_wid}" 0 0 2> "/dev/null" || true
			done
		done
	) &
fi

_target_bin="\$1"
[ "\$#" -ge 1 ] && shift

if [ -z "\${_target_bin}" ] || [ "\${_target_bin}" = "xterm" ]; then
	exec xterm -bc -bcf 600 -bcn 600 -xrm 'XTerm*cursorBlink: always' -xrm 'XTerm*cursorBlinkXOR: false' -xrm 'XTerm*vt100.cursorBlink: always' -xrm '*cursorBlink: always' -maximized "\$@"
elif [ "${_is_terminal}" -eq 1 ]; then
	if command -v "\${_target_bin}" > "/dev/null" 2>&1; then
		exec xterm -bc -bcf 600 -bcn 600 -xrm 'XTerm*cursorBlink: always' -xrm 'XTerm*cursorBlinkXOR: false' -xrm 'XTerm*vt100.cursorBlink: always' -xrm '*cursorBlink: always' -maximized -e "\${_target_bin}" "\$@"
	else
		exec xterm -bc -bcf 600 -bcn 600 -xrm 'XTerm*cursorBlink: always' -xrm 'XTerm*cursorBlinkXOR: false' -xrm 'XTerm*vt100.cursorBlink: always' -xrm '*cursorBlink: always' -maximized -e "${_sh}" -i -c "\${_target_bin} \$*"
	fi
elif [ "\${_target_bin}" = "emacs" ]; then
	_emacs_kiosk_bin="\$(command -v emacs-gtk+x11 2> "/dev/null" || command -v emacs-gtk 2> "/dev/null" || command -v emacs 2> "/dev/null" || command -v emacs-lucid 2> "/dev/null" || true)"
	exec "\${_emacs_kiosk_bin}" -mm "\$@"
else
	exec "\${_target_bin}" "\$@"
fi
EOF
	chmod 0755 "${_xinit_script}"

	local _persistent_kiosk_log="${HOME}/.local/state/environment/xorg-kiosk.log"
	mkdir -p "${HOME}/.local/state/environment" 2> "/dev/null" || true
	rm -f "${_persistent_kiosk_log}" 2> "/dev/null" || true
	local _server_auth="${XDG_RUNTIME_DIR:-/tmp}/.serverauth-gui-$$"
	local _xinit_ret=0
	local _auth_args=""

	if command -v xauth > "/dev/null" 2>&1; then
		( umask 0077; : >> "${_server_auth}"; [ -f "${HOME}/.Xauthority" ] || : >> "${HOME}/.Xauthority" ) 2> "/dev/null" || true
		local _cookie=""
		if command -v mcookie > "/dev/null" 2>&1; then
			_cookie="$(command mcookie 2> "/dev/null" || true)"
		elif [ -r "/dev/urandom" ]; then
			_cookie="$(command dd if=/dev/urandom bs=16 count=1 2> "/dev/null" | command hexdump -e '16/1 "%02x"' 2> "/dev/null" || true)"
		fi
		if [ -n "${_cookie}" ]; then
			command xauth -q -f "${_server_auth}" add "${_display}" . "${_cookie}" 2> "/dev/null" || true
			command xauth -q add "${_display}" . "${_cookie}" 2> "/dev/null" || true
			_auth_args="-auth ${_server_auth}"
		fi
	fi

	if command -v xinit > "/dev/null" 2>&1 && [ -n "${_auth_args}" ]; then
		command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" ${_vt_arg} ${_auth_args} >| "${_persistent_kiosk_log}" 2>&1
		_xinit_ret=$?
	elif command -v startx > "/dev/null" 2>&1; then
		command startx "${_xinit_script}" "${_app}" "$@" -- "${_display}" ${_vt_arg} >| "${_persistent_kiosk_log}" 2>&1
		_xinit_ret=$?
	else
		command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" ${_vt_arg} >| "${_persistent_kiosk_log}" 2>&1
		_xinit_ret=$?
	fi
	rm -f "${_server_auth}" 2> "/dev/null" || true
	command -v xauth > "/dev/null" 2>&1 && command xauth -q remove "${_display}" 2> "/dev/null" || true

	if [ -f "${_persistent_kiosk_log}" ] && [ -s "${_persistent_kiosk_log}" ]; then
		if [ "${_xinit_ret}" -ne 0 ]; then
			_ui_warn "Xorg encerrou com código ${_xinit_ret}. Diagnóstico:"
			_filter_xorg_noise < "${_persistent_kiosk_log}" | command tail -n 15
		fi
	fi
	rm -f "${_xinit_script}" "${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-$$.xml" 2> "/dev/null" || true
	[ "${_had_display}" -eq 0 ] && unset DISPLAY
	_freebsd_vt_bounce
}
alias xgui="graphical-launcher-x11"

graphical-launcher() {
	_dispatch_display_server "graphical-launcher" "$@"
}
alias gui="graphical-launcher"

### --------------------------------
### Emacs OS Window Managers
### --------------------------------
emacs-window-manager-wayland() {
	local _flavor=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	_wayland_session_env "${_flavor}"
	export EMACS_OS_MODE="wayland"

	if ! command -v emacs > "/dev/null" 2>&1; then
		_ui_err "emacs não encontrado."
		return 127
	fi

	local _ewm_so=""
	if [ -f "${HOME}/.local/lib/libewm_core.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm_core.so"
	elif [ -f "${HOME}/.local/lib/libewm.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm.so"
	fi

	if [ -n "${_ewm_so}" ]; then
		if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus" ]; then
			export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
		fi
		local _bus_wrapper=""
		if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
			if command -v dbus-run-session > "/dev/null" 2>&1; then
				_bus_wrapper="dbus-run-session --"
			elif command -v dbus-launch > "/dev/null" 2>&1; then
				_bus_wrapper="dbus-launch --exit-with-session"
			fi
		fi
		export EWM_MODULE_PATH="${_ewm_so}"
		export EMACSLOADPATH="${HOME}/.local/share/emacs/site-lisp/ewm:${EMACSLOADPATH:-}:"
		export RUST_LOG="${RUST_LOG:-ewm=info,ewm_core::dbus_login1=error,ewm_core::xwayland::satellite=error,smithay=warn}"
		rm -f "${XDG_RUNTIME_DIR:-/tmp}/emacs/ewm" 2> "/dev/null" || true

		local _ewm_log="${XDG_RUNTIME_DIR:-/tmp}/ewm-$$.log"
		${_bus_wrapper:-command} emacs --fg-daemon=ewm -L "${HOME}/.local/share/emacs/site-lisp/ewm" -l ewm -f ewm-start-module "$@" 2> "${_ewm_log}"
		local _emacs_ret=$?

		if [ "${_emacs_ret}" -ne 0 ] && [ -f "${_ewm_log}" ]; then
			command grep -v -E "Due to a limitation in GTK 3|unlikely ever to be able|display connection is closed|Failed to connect to user scope bus|org.freedesktop.login1|xwayland-satellite" "${_ewm_log}" 2> "/dev/null" | command tail -n 10
		fi
		rm -f "${_ewm_log}" 2> "/dev/null" || true
	else
		graphical-launcher-wayland emacs "$@"
	fi

	_restore_tty_cursor
	_freebsd_vt_bounce
}
alias wewm="emacs-window-manager-wayland"
alias wew="emacs-window-manager-wayland"

emacs-window-manager-x11() {
	local _flavor=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	export EMACS_OS_MODE="x11"
	export _X11_FLAVOR_OVERRIDE="${_flavor}"

	local _emacs_bin="$(command -v emacs-gtk+x11 2> "/dev/null" || command -v emacs-gtk 2> "/dev/null" || command -v emacs 2> "/dev/null" || command -v emacs-lucid 2> "/dev/null" || true)"
	if [ -z "${_emacs_bin}" ]; then
		_ui_err "emacs não encontrado."
		unset _X11_FLAVOR_OVERRIDE
		return 127
	fi

	_exec_x11 "${_emacs_bin}" -mm "$@"
	unset _X11_FLAVOR_OVERRIDE
	_restore_tty_cursor
	_freebsd_vt_bounce
}
alias xewm="emacs-window-manager-x11"
alias xew="emacs-window-manager-x11"
alias exwm="emacs-window-manager-x11"
alias exw="emacs-window-manager-x11"

emacs-window-manager() {
	_dispatch_display_server "emacs-window-manager" "$@"
}
alias ewm="emacs-window-manager"
alias ew="emacs-window-manager"
