# ----------------------------------------------------------------
# Library: Ephemeral GUI Launchers & Emacs OS Window Managers
# ----------------------------------------------------------------

### --------------------------------
### Graphical Helpers
### --------------------------------
if ! command -v _sanitize_graphical_env > "/dev/null" 2>&1; then
	_sanitize_graphical_env() {
		unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST _IS_RAW_TTY_CACHED
		export COLORTERM="truecolor"
		export MICRO_TRUECOLOR=1
	}
fi

if ! command -v _get_shell_log_dir > "/dev/null" 2>&1; then
	_get_shell_log_dir() {
		local _log_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/shell/logs"
		[ -d "${_log_dir}" ] || mkdir -p "${_log_dir}" 2> "/dev/null" || true
		printf '%s\n' "${_log_dir}"
	}
fi

if ! command -v _resolve_graphical_app > "/dev/null" 2>&1; then
	_resolve_graphical_app() {
		local _target="${1:-}"
		case "${_target}" in
			vscode|code|code-oss|codium)
				if ! command -v "${_target}" > "/dev/null" 2>&1; then
					for _c in code code-oss codium vscode; do
						if command -v "${_c}" > "/dev/null" 2>&1; then
							echo "${_c}"
							return 0
						fi
					done
				fi
				;;
			chrome|chromium|google-chrome)
				if ! command -v "${_target}" > "/dev/null" 2>&1; then
					for _c in chrome chromium google-chrome brave-browser brave; do
						if command -v "${_c}" > "/dev/null" 2>&1; then
							echo "${_c}"
							return 0
						fi
					done
				fi
				;;
		esac
		echo "${_target}"
	}
fi

### --------------------------------
### Ephemeral Graphical Launchers
### --------------------------------
graphical-launcher-wayland() {
	_sanitize_graphical_env

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

	local _raw_app="${1:-foot}"
	[ "$#" -ge 1 ] && shift
	local _app="$(_resolve_graphical_app "${_raw_app}")"

	_wayland_session_env "${_flavor}"

	export GTK_THEME="${GTK_THEME:-Breeze-Dark:dark}"
	export GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DEBUG_COLOR_SCHEME="prefer-dark"
	export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
	export XCURSOR_THEME="${XCURSOR_THEME:-breeze_cursors}"
	export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"

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
		foot -o dpi-aware=no
	else
		foot -o dpi-aware=no "\$@"
	fi
elif [ "${_is_terminal}" -eq 1 ]; then
	if command -v "\${_app_target}" > "/dev/null" 2>&1; then
		foot -o dpi-aware=no "\${_app_target}" "\$@"
	else
		foot -o dpi-aware=no "${_sh}" -i -c "\${_app_target} \$*"
	fi
elif [ "\${_app_target}" = "code" ] || [ "\${_app_target}" = "code-oss" ] || [ "\${_app_target}" = "vscode" ] || [ "\${_app_target}" = "codium" ]; then
	"\${_app_target}" --ozone-platform-hint=auto "\$@"
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
		if [ -f "${_foot_target}" ]; then
			if ! grep -q "^dpi-aware" "${_foot_target}" 2> "/dev/null"; then
				printf '\ndpi-aware=no\n' >> "${_foot_target}" 2> "/dev/null" || true
			fi
		fi
	fi

	local _cur_theme="${XCURSOR_THEME:-breeze_cursors}"
	local _cur_size="${XCURSOR_SIZE:-24}"
	local _log_dir="$(_get_shell_log_dir)"
	local _log_file="${_log_dir}/wayland-kiosk.log"
	local _ret=0

	if command -v sway > "/dev/null" 2>&1; then
		local _sway_cfg="${XDG_RUNTIME_DIR:-/tmp}/sway-gui-$$.conf"
		cat << EOF > "${_sway_cfg}"
default_border none
default_floating_border none
titlebar_border_thickness 0
seat * xcursor_theme ${_cur_theme} ${_cur_size}
seat * fallback true
seat * hide_cursor when-typing disable
seat * pointer_constraint enable
input type:pointer {
    accel_profile adaptive
    pointer_accel 0.35
    natural_scroll disabled
}
input type:touchpad {
    accel_profile adaptive
    pointer_accel 0.4
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
		command sway -c "${_sway_cfg}" >| "${_log_file}" 2>&1
		_ret=$?
		rm -f "${_sway_cfg}" 2> "/dev/null" || true
	elif command -v labwc > "/dev/null" 2>&1; then
		local _labwc_dir="${XDG_RUNTIME_DIR:-/tmp}/labwc-gui-$$"
		mkdir -p "${_labwc_dir}"
		cat << 'EOF' > "${_labwc_dir}/themerc"
window.active.title.bg.color: #1f1f28
window.active.label.text.color: #dcd7ba
window.inactive.title.bg.color: #16161e
window.inactive.label.text.color: #727169
border.width: 1
border.color: #54546d
window.active.border.color: #7e9cd8
window.inactive.border.color: #54546d
menu.border.width: 1
menu.border.color: #54546d
menu.items.bg.color: #1f1f28
menu.items.text.color: #dcd7ba
menu.items.active.bg.color: #2a2a37
menu.items.active.text.color: #e6c384
EOF
		cat << 'EOF' > "${_labwc_dir}/menu.xml"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Universal Labwc">
    <item label="Terminal (foot)">
      <action name="Execute" command="foot -o dpi-aware=no"/>
    </item>
    <item label="Web Browser">
      <action name="Execute" command="sh -c 'command -v firefox >/dev/null 2>&amp;1 &amp;&amp; exec firefox || command -v chrome >/dev/null 2>&amp;1 &amp;&amp; exec chrome || command -v chromium >/dev/null 2>&amp;1 &amp;&amp; exec chromium'"/>
    </item>
    <item label="Emacs">
      <action name="Execute" command="sh -c 'command -v emacs-pgtk >/dev/null 2>&amp;1 &amp;&amp; exec emacs-pgtk || exec emacs'"/>
    </item>
    <item label="File Manager">
      <action name="Execute" command="sh -c 'command -v pcmanfm >/dev/null 2>&amp;1 &amp;&amp; exec pcmanfm || command -v thunar >/dev/null 2>&amp;1 &amp;&amp; exec thunar || exec dolphin'"/>
    </item>
    <separator/>
    <item label="Reconfigure">
      <action name="Reconfigure"/>
    </item>
    <item label="Exit">
      <action name="Exit"/>
    </item>
  </menu>
</openbox_menu>
EOF
		cat << EOF > "${_labwc_dir}/rc.xml"
<?xml version="1.0"?>
<labwc_config>
  <theme>
    <name>kiosk</name>
    <cornerRadius>0</cornerRadius>
    <border.width>1</border.width>
    <border.color>#54546d</border.color>
  </theme>
  <keyboard>
    <repeatRate>50</repeatRate>
    <repeatDelay>200</repeatDelay>
    <numlock>on</numlock>
    <keybind key="W-Return"><action name="Execute" command="foot -o dpi-aware=no"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
    <keybind key="W-S-q"><action name="Exit"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
  </keyboard>
  <mouse>
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
  </mouse>
  <libinput>
    <device category="default">
      <accelProfile>adaptive</accelProfile>
      <accelSpeed>0.35</accelSpeed>
      <tap>yes</tap>
    </device>
    <device category="touchpad">
      <accelProfile>adaptive</accelProfile>
      <accelSpeed>0.4</accelSpeed>
      <tap>yes</tap>
      <naturalScroll>yes</naturalScroll>
    </device>
  </libinput>
  <windowRules>
    <windowRule identifier="*" serverDecoration="no">
      <action name="Maximize"/>
    </windowRule>
  </windowRules>
</labwc_config>
EOF
		command labwc -C "${_labwc_dir}" -s "${_exec_invocation}" >| "${_log_file}" 2>&1
		_ret=$?
		rm -rf "${_labwc_dir}" 2> "/dev/null" || true
	elif command -v river > "/dev/null" 2>&1; then
		local _river_init="${XDG_RUNTIME_DIR:-/tmp}/river-gui-$$.sh"
		cat << EOF > "${_river_init}"
#!/bin/sh
riverctl border-width 0
riverctl xcursor-theme "${_cur_theme}" "${_cur_size}"
riverctl input pointer-* accel-profile adaptive
riverctl input pointer-* pointer-accel 0.35
riverctl input touchpad-* accel-profile adaptive
riverctl input touchpad-* pointer-accel 0.4
riverctl input touchpad-* tap enabled
riverctl input touchpad-* natural-scroll enabled
riverctl keyboard-layout -model abnt2 -options numpad:mac br
riverctl set-repeat 50 200
riverctl default-attach-mode top
riverctl map normal Super F toggle-fullscreen
riverctl map normal Super Q spawn "riverctl exit"
${_exec_invocation} &
EOF
		chmod 0755 "${_river_init}"
		command river -c "${_river_init}" >| "${_log_file}" 2>&1
		_ret=$?
		rm -f "${_river_init}" 2> "/dev/null" || true
	elif command -v cage > "/dev/null" 2>&1; then
		command cage -s -- ${_exec_invocation} >| "${_log_file}" 2>&1
		_ret=$?
	elif command -v emacs > "/dev/null" 2>&1 || [ -f "${HOME}/.local/lib/libewm_core.so" ] || [ -f "${HOME}/.local/lib/libewm.so" ]; then
		emacs-window-manager-wayland "${_app}" "$@"
		_ret=$?
	else
		_ui_err "Nenhum compositor Wayland (sway, labwc, river, cage, ewm) encontrado."
		rm -f "${_wayland_runner}" 2> "/dev/null" || true
		return 1
	fi

	rm -f "${_wayland_runner}" 2> "/dev/null" || true
	[ "${_had_wayland}" -eq 0 ] && unset WAYLAND_DISPLAY
	_freebsd_vt_bounce

	if [ "${_ret}" -ne 0 ]; then
		_ui_err "Lançador Wayland encerrou com erro (código ${_ret}). Log: ${_log_file}"
		return "${_ret}"
	fi
	return 0
}
alias wgui="graphical-launcher-wayland"

graphical-launcher-x11() {
	command -v xinit > "/dev/null" 2>&1 || command -v startx > "/dev/null" 2>&1 || {
		_ui_err "xinit ou startx não encontrado para lançador Xorg."
		return 1
	}

	_sanitize_graphical_env

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

	local _raw_app="${1:-xterm}"
	[ "$#" -ge 1 ] && shift
	local _app="$(_resolve_graphical_app "${_raw_app}")"

	if ! command -v openbox > "/dev/null" 2>&1 && ! command -v matchbox-window-manager > "/dev/null" 2>&1 && ! command -v cwm > "/dev/null" 2>&1; then
		if command -v emacs > "/dev/null" 2>&1; then
			emacs-window-manager-x11 "${_app}" "$@"
			return $?
		fi
	fi

	local _display="$(_resolve_free_display)"
	export DISPLAY="${_display}"
	_x11_session_env "${_flavor}"
	_x11_driver_preflight

	export GTK_THEME="${GTK_THEME:-Breeze-Dark:dark}"
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
	export XCURSOR_THEME="${XCURSOR_THEME:-breeze_cursors}"
	export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"

	local _kiosk_theme_dir="${HOME}/.local/share/themes/kiosk/openbox-3"
	if [ ! -f "${_kiosk_theme_dir}/themerc" ]; then
		mkdir -p "${_kiosk_theme_dir}" 2> "/dev/null" || true
		cat << 'OTM' > "${_kiosk_theme_dir}/themerc"
border.width: 1
border.color: #54546d
padding.width: 1
padding.height: 1
window.handle.width: 0
window.client.padding.width: 0
window.active.title.bg.color: #1f1f28
window.active.label.text.color: #dcd7ba
window.inactive.title.bg.color: #16161e
window.inactive.label.text.color: #727169
menu.border.width: 1
menu.border.color: #54546d
menu.items.bg.color: #1f1f28
menu.items.text.color: #dcd7ba
menu.items.active.bg.color: #2a2a37
menu.items.active.text.color: #e6c384
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
export GTK_THEME="${GTK_THEME:-Breeze-Dark:dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1
export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
export XCURSOR_THEME="${XCURSOR_THEME:-breeze_cursors}"
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

	local _log_dir="$(_get_shell_log_dir)"
	local _persistent_kiosk_log="${_log_dir}/xorg-kiosk.log"
	mkdir -p "${_log_dir}" 2> "/dev/null" || true
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

	if [ "${_xinit_ret}" -ne 0 ] && [ -f "${_persistent_kiosk_log}" ] && [ -s "${_persistent_kiosk_log}" ]; then
		_ui_err "Lançador Xorg encerrou com erro (código ${_xinit_ret}). Log: ${_persistent_kiosk_log}"
	fi
	rm -f "${_xinit_script}" "${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-$$.xml" 2> "/dev/null" || true
	[ "${_had_display}" -eq 0 ] && unset DISPLAY
	_freebsd_vt_bounce
	return "${_xinit_ret}"
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
	_sanitize_graphical_env

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

		local _log_dir="$(_get_shell_log_dir)"
		local _ewm_log="${_log_dir}/ewm-wayland.log"
		${_bus_wrapper:-command} emacs --fg-daemon=ewm -L "${HOME}/.local/share/emacs/site-lisp/ewm" -l ewm -f ewm-start-module "$@" >| "${_ewm_log}" 2>&1
		local _emacs_ret=$?

		if [ "${_emacs_ret}" -ne 0 ]; then
			_ui_err "EWM Wayland encerrou com erro (código ${_emacs_ret}). Log: ${_ewm_log}"
		fi
	else
		graphical-launcher-wayland emacs "$@"
	fi

	_restore_tty_cursor 2> "/dev/null" || true
	_freebsd_vt_bounce
}
alias wewm="emacs-window-manager-wayland"
alias wew="emacs-window-manager-wayland"

emacs-window-manager-x11() {
	_sanitize_graphical_env

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
	_restore_tty_cursor 2> "/dev/null" || true
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
