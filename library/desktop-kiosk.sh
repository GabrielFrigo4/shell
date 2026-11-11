# ----------------------------------------------------------------
# Library: Ephemeral GUI Launchers & Emacs OS Window Managers
# ----------------------------------------------------------------

### --------------------------------
### GRAPHICAL HELPERS
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

if ! command -v _resolve_desktop_font > "/dev/null" 2>&1; then
	_resolve_desktop_font() {
		local _target_flavor="${1:-}"
		if command -v fc-list > "/dev/null" 2>&1; then
			if fc-list : family 2> "/dev/null" | grep -qi "JetBrainsMono Nerd Font"; then
				printf '%s\n' "JetBrainsMono Nerd Font"
				return 0
			fi
			case "${_target_flavor}" in
				kde|plasma|lxqt)
					if fc-list : family 2> "/dev/null" | grep -qi "^Noto Sans$"; then
						printf '%s\n' "Noto Sans"
						return 0
					fi
					;;
				gnome|budgie)
					for _f in "Adwaita Sans" "Cantarell"; do
						if fc-list : family 2> "/dev/null" | grep -qi "^${_f}$"; then
							printf '%s\n' "${_f}"
							return 0
						fi
					done
					;;
				pantheon)
					for _f in "Inter" "Open Sans" "Cantarell"; do
						if fc-list : family 2> "/dev/null" | grep -qi "^${_f}$"; then
							printf '%s\n' "${_f}"
							return 0
						fi
					done
					;;
				deepin)
					for _f in "Noto Sans" "Source Han Sans" "Cantarell"; do
						if fc-list : family 2> "/dev/null" | grep -qi "^${_f}$"; then
							printf '%s\n' "${_f}"
							return 0
						fi
					done
					;;
				cosmic)
					for _f in "Fira Sans" "Noto Sans"; do
						if fc-list : family 2> "/dev/null" | grep -qi "^${_f}$"; then
							printf '%s\n' "${_f}"
							return 0
						fi
					done
					;;
				mate|cinnamon|xfce|lxde)
					for _f in "Ubuntu" "DejaVu Sans"; do
						if fc-list : family 2> "/dev/null" | grep -qi "^${_f}$"; then
							printf '%s\n' "${_f}"
							return 0
						fi
					done
					;;
			esac
			for _f in "Adwaita Sans" "Cantarell" "Noto Sans" "Ubuntu" "DejaVu Sans"; do
				if fc-list : family 2> "/dev/null" | grep -qi "^${_f}$"; then
					printf '%s\n' "${_f}"
					return 0
				fi
			done
		fi
		printf '%s\n' "Sans"
	}
fi

### --------------------------------
### EPHEMERAL GRAPHICAL LAUNCHERS
### --------------------------------
graphical_launcher_wayland() {
	unset EMACS_OS_MODE
	_sanitize_graphical_env

	local _flavor="" _selected_wm=""
	local _had_wayland=1
	[ -z "${WAYLAND_DISPLAY:-}" ] && _had_wayland=0
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-l|--list|--pipeline)
				_show_wm_pipeline "wayland"
				return 0
				;;
			-w|--wm)
				if [ "$#" -ge 2 ]; then
					_selected_wm="$2"
					shift 2
				else
					shift
				fi
				;;
			--wm=*)
				_selected_wm="${1#--wm=}"
				shift
				;;
			--sway|--labwc|--river|--cage|--hyprland|--niri|--wayfire|--dwl)
				_selected_wm="${1#--}"
				shift
				;;
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--lxqt)        _flavor="lxqt"; shift ;;
			--lxde)        _flavor="lxde"; shift ;;
			--budgie)      _flavor="budgie"; shift ;;
			--pantheon)    _flavor="pantheon"; shift ;;
			--deepin)      _flavor="deepin"; shift ;;
			--cosmic)      _flavor="cosmic"; shift ;;
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

	local _is_terminal=0
	_is_terminal_app "${_app}" && _is_terminal=1

	local _wayland_runner="${XDG_RUNTIME_DIR:-/tmp}/wayland-runner-$$.sh"
	local _sh="$(_detect_enabled_shell)"

	cat << EOF >| "${_wayland_runner}"
#!/usr/bin/env sh
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
if command -v hyprctl > "/dev/null" 2>&1 && [ -n "\${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
	hyprctl dispatch exit > "/dev/null" 2>&1 || true
fi
if command -v niri > "/dev/null" 2>&1 && [ -n "\${NIRI_SOCKET:-}" ]; then
	niri msg action quit --skip-confirmation > "/dev/null" 2>&1 || true
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

	local _cur_theme="${XCURSOR_THEME}"
	local _cur_size="${XCURSOR_SIZE:-24}"
	local _ui_font="$(_resolve_desktop_font "${_flavor}")"
	local _log_dir="$(_get_shell_log_dir)"
	local _log_file="${_log_dir}/wayland-kiosk.log"
	local _ret=0

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	local _dbus_run=""
	if command -v dbus-run-session > "/dev/null" 2>&1; then
		_dbus_run="dbus-run-session --"
	elif command -v dbus-launch > "/dev/null" 2>&1; then
		_dbus_run="dbus-launch --exit-with-session"
	fi

	local _target_wm="${_selected_wm}"
	if [ -n "${_target_wm}" ]; then
		if ! command -v "${_target_wm}" > "/dev/null" 2>&1; then
			_ui_err "Compositor Wayland '${_target_wm}' não está instalado."
			rm -f "${_wayland_runner}" 2> "/dev/null" || true
			return 1
		fi
	else
		local _w_cand
		for _w_cand in $(_get_wayland_wm_pipeline); do
			if command -v "${_w_cand}" > "/dev/null" 2>&1; then
				_target_wm="${_w_cand}"
				break
			fi
		done
	fi

	case "${_target_wm}" in
		sway)
			local _sway_cfg="${XDG_RUNTIME_DIR:-/tmp}/sway-gui-$$.conf"
			local _tabwatch="${XDG_RUNTIME_DIR:-/tmp}/wgui-tabwatch-$$.sh"
			cat << 'EOF' >| "${_tabwatch}"
#!/usr/bin/env sh
while :; do
	_count=$(swaymsg -t get_tree 2> "/dev/null" | grep -c '"pid":' || true)
	if [ "${_count:-0}" -ge 2 ]; then
		swaymsg "[workspace=__focused__] layout tabbed, border normal 1" > "/dev/null" 2>&1 || true
	else
		swaymsg "[workspace=__focused__] layout splith, border none" > "/dev/null" 2>&1 || true
	fi
	sleep 1
done
EOF
			chmod 0755 "${_tabwatch}"

			cat << EOF >| "${_sway_cfg}"
font pango:${_ui_font} Bold 10
titlebar_padding 10 4
default_border none
default_floating_border pixel 1
titlebar_border_thickness 0
gaps inner 0
gaps outer 0
workspace_layout default
hide_edge_borders both
popup_during_fullscreen smart
client.focused #3584e4 #2b2b30 #ffffff #3584e4 #3584e4
client.focused_inactive #38383d #1e1e22 #9a9996 #38383d #38383d
client.unfocused #38383d #1e1e22 #9a9996 #38383d #38383d
client.urgent #e01b24 #2b2b30 #ffffff #e01b24 #e01b24
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
for_window [window_type="dialog"] floating enable
for_window [window_type="utility"] floating enable
for_window [window_type="toolbar"] floating enable
for_window [window_type="splash"] floating enable
for_window [window_type="menu"] floating enable
for_window [window_role="pop-up"] floating enable
for_window [window_role="bubble"] floating enable
for_window [window_role="dialog"] floating enable
for_window [app_id=".*"] focus
bindsym Mod1+Tab focus next
bindsym Mod4+Tab focus next
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
exec "${_tabwatch}"
exec ${_exec_invocation}
EOF
			${_dbus_run} command sway -c "${_sway_cfg}" >| "${_log_file}" 2>&1
			_ret=$?
			rm -f "${_sway_cfg}" "${_tabwatch}" 2> "/dev/null" || true
			;;
		labwc)
			local _labwc_dir="${XDG_RUNTIME_DIR:-/tmp}/labwc-gui-$$"
			mkdir -p "${_labwc_dir}"
			cat << 'EOF' >| "${_labwc_dir}/themerc"
window.active.title.bg.color: #2b2b30
window.active.label.text.color: #ffffff
window.inactive.title.bg.color: #1e1e22
window.inactive.label.text.color: #9a9996
border.width: 1
border.color: #38383d
window.active.border.color: #3584e4
window.inactive.border.color: #38383d
menu.border.width: 1
menu.border.color: #38383d
menu.items.bg.color: #1e1e22
menu.items.text.color: #ffffff
menu.items.active.bg.color: #3584e4
menu.items.active.text.color: #ffffff
EOF
			cat << 'EOF' >| "${_labwc_dir}/menu.xml"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Universal Labwc">
    <item label="Terminal (foot)">
      <action name="Execute" command="foot -o dpi-aware=no"/>
    </item>
    <item label="Web Browser">
      <action name="Execute" command="sh -c 'command -v firefox > &quot;/dev/null&quot; 2>&amp;1 &amp;&amp; exec firefox || command -v chrome > &quot;/dev/null&quot; 2>&amp;1 &amp;&amp; exec chrome || command -v chromium > &quot;/dev/null&quot; 2>&amp;1 &amp;&amp; exec chromium'"/>
    </item>
    <item label="Emacs">
      <action name="Execute" command="sh -c 'command -v emacs-pgtk > &quot;/dev/null&quot; 2>&amp;1 &amp;&amp; exec emacs-pgtk || exec emacs'"/>
    </item>
    <item label="File Manager">
      <action name="Execute" command="sh -c 'command -v pcmanfm > &quot;/dev/null&quot; 2>&amp;1 &amp;&amp; exec pcmanfm || command -v thunar > &quot;/dev/null&quot; 2>&amp;1 &amp;&amp; exec thunar || exec dolphin'"/>
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
			cat << EOF >| "${_labwc_dir}/rc.xml"
<?xml version="1.0"?>
<labwc_config>
  <theme>
    <name>kiosk</name>
    <cornerRadius>0</cornerRadius>
    <border.width>1</border.width>
    <border.color>#38383d</border.color>
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
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
    </context>
    <context name="Root">
      <mousebind button="Middle" action="Press">
        <action name="ShowMenu"><menu>client-list-combined-menu</menu></action>
      </mousebind>
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
			${_dbus_run} command labwc -C "${_labwc_dir}" -s "${_exec_invocation}" >| "${_log_file}" 2>&1
			_ret=$?
			rm -rf "${_labwc_dir}" 2> "/dev/null" || true
			;;
		river)
			local _river_init="${XDG_RUNTIME_DIR:-/tmp}/river-gui-$$.sh"
			cat << EOF >| "${_river_init}"
#!/usr/bin/env sh
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
			${_dbus_run} command river -c "${_river_init}" >| "${_log_file}" 2>&1
			_ret=$?
			rm -f "${_river_init}" 2> "/dev/null" || true
			;;
		hyprland)
			local _hypr_cfg="${XDG_RUNTIME_DIR:-/tmp}/hyprland-gui-$$.conf"
			cat << EOF >| "${_hypr_cfg}"
monitor=,preferred,auto,1
general {
    border_size = 0
    gaps_in = 0
    gaps_out = 0
}
decoration {
    rounding = 0
    drop_shadow = false
}
misc {
    disable_hyprland_logo = true
    background_color = rgb(1e1e22)
}
input {
    kb_layout = br
    kb_model = abnt2
    repeat_rate = 50
    repeat_delay = 200
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}
bind = SUPER, Q, killactive
bind = SUPER SHIFT, Q, exit
exec-once = ${_exec_invocation}
EOF
			if command -v Hyprland > "/dev/null" 2>&1; then
				${_dbus_run} command Hyprland --config "${_hypr_cfg}" >| "${_log_file}" 2>&1
			else
				${_dbus_run} command hyprland --config "${_hypr_cfg}" >| "${_log_file}" 2>&1
			fi
			_ret=$?
			rm -f "${_hypr_cfg}" 2> "/dev/null" || true
			;;
		niri)
			local _niri_cfg="${XDG_RUNTIME_DIR:-/tmp}/niri-gui-$$.kdl"
			cat << EOF >| "${_niri_cfg}"
prefer-no-csd
layout {
    border {
        width 0
    }
}
binds {
    Mod+Q { close-window; }
    Mod+Shift+Q { quit; }
}
EOF
			printf 'spawn-at-startup "%s" "%s"\n' "${_wayland_runner}" "${_app}" >> "${_niri_cfg}"
			${_dbus_run} command niri --config "${_niri_cfg}" >| "${_log_file}" 2>&1
			_ret=$?
			rm -f "${_niri_cfg}" 2> "/dev/null" || true
			;;
		wayfire)
			local _wf_cfg="${XDG_RUNTIME_DIR:-/tmp}/wayfire-gui-$$.ini"
			cat << EOF >| "${_wf_cfg}"
[core]
plugins = autostart
[autostart]
app = ${_exec_invocation}
EOF
			${_dbus_run} command wayfire -c "${_wf_cfg}" >| "${_log_file}" 2>&1
			_ret=$?
			rm -f "${_wf_cfg}" 2> "/dev/null" || true
			;;
		dwl)
			local _dwl_startup="${XDG_RUNTIME_DIR:-/tmp}/dwl-gui-$$.sh"
			cat << EOF >| "${_dwl_startup}"
#!/usr/bin/env sh
exec ${_exec_invocation}
EOF
			chmod 0755 "${_dwl_startup}"
			${_dbus_run} command dwl -s "${_dwl_startup}" >| "${_log_file}" 2>&1
			_ret=$?
			rm -f "${_dwl_startup}" 2> "/dev/null" || true
			;;
		cage)
			${_dbus_run} command cage -s -- ${_exec_invocation} >| "${_log_file}" 2>&1
			_ret=$?
			;;
		*)
			_ui_err "Nenhum compositor Wayland (sway, labwc, river, hyprland, niri, wayfire, dwl, cage) encontrado."
			rm -f "${_wayland_runner}" 2> "/dev/null" || true
			return 1
			;;
	esac

	rm -f "${_wayland_runner}" 2> "/dev/null" || true
	[ "${_had_wayland}" -eq 0 ] && unset WAYLAND_DISPLAY
	_freebsd_vt_bounce

	if [ "${_ret}" -ne 0 ]; then
		_ui_err "Lançador Wayland encerrou com erro (código ${_ret}). Log: ${_log_file}"
		return "${_ret}"
	fi
	return 0
}
alias graphical-launcher-wayland="graphical_launcher_wayland" wgui="graphical_launcher_wayland"

graphical_launcher_x11() {
	unset EMACS_OS_MODE
	_sanitize_graphical_env

	local _flavor="" _selected_wm=""
	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	while [ "$#" -gt 0 ]; do
		case "$1" in
			-l|--list|--pipeline)
				_show_wm_pipeline "x11"
				return 0
				;;
			-w|--wm)
				if [ "$#" -ge 2 ]; then
					_selected_wm="$2"
					shift 2
				else
					shift
				fi
				;;
			--wm=*)
				_selected_wm="${1#--wm=}"
				shift
				;;
			--openbox|--cwm|--dwm|--fvwm|--twm)
				_selected_wm="${1#--}"
				shift
				;;
			--matchbox|--matchbox-window-manager)
				_selected_wm="matchbox-window-manager"
				shift
				;;
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--lxqt)        _flavor="lxqt"; shift ;;
			--lxde)        _flavor="lxde"; shift ;;
			--budgie)      _flavor="budgie"; shift ;;
			--pantheon)    _flavor="pantheon"; shift ;;
			--deepin)      _flavor="deepin"; shift ;;
			--cosmic)      _flavor="cosmic"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	command -v xinit > "/dev/null" 2>&1 || command -v startx > "/dev/null" 2>&1 || {
		_ui_err "xinit ou startx não encontrado para lançador Xorg."
		return 1
	}

	local _raw_app="${1:-xterm}"
	[ "$#" -ge 1 ] && shift
	local _app="$(_resolve_graphical_app "${_raw_app}")"

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	local _display="$(_resolve_free_display)"
	export DISPLAY="${_display}"
	_x11_session_env "${_flavor}"
	_setup_cursor_env "${_flavor}"
	_x11_driver_preflight

	local _theme_flavor="$(_detect_desktop_theme "${_flavor}")"
	local _valid_theme="${XCURSOR_THEME:-Adwaita}"
	local _icon_theme=""
	case "${_theme_flavor}" in
		kde|plasma|lxqt) _icon_theme="breeze-dark" ;;
		pantheon)        _icon_theme="elementary" ;;
		deepin)          _icon_theme="bloom" ;;
		cosmic)          _icon_theme="cosmic" ;;
		*)               _icon_theme="Adwaita" ;;
	esac

	local _ui_font="$(_resolve_desktop_font "${_flavor}")"
	export GTK_THEME="${GTK_THEME:-adw-gtk3-dark}"
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	export SAL_USE_VCLPLUGIN="gtk3"
	export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"

	local _kiosk_theme_dir="${HOME}/.local/share/themes/kiosk/openbox-3"
	mkdir -p "${_kiosk_theme_dir}" 2> "/dev/null" || true
	cat << 'OTM' >| "${_kiosk_theme_dir}/themerc"
border.width: 3
border.color: #38383d
padding.width: 8
padding.height: 6
window.handle.width: 3
window.client.padding.width: 0

window.active.border.color: #3584e4
window.active.title.bg: flat solid
window.active.title.bg.color: #2b2b30
window.active.label.bg: parentrelative
window.active.label.text.color: #ffffff
window.active.handle.bg: flat solid
window.active.handle.bg.color: #2b2b30
window.active.grip.bg: flat solid
window.active.grip.bg.color: #3584e4
window.active.button.unpressed.bg: parentrelative
window.active.button.unpressed.image.color: #ffffff
window.active.button.pressed.bg: flat solid
window.active.button.pressed.bg.color: #3584e4
window.active.button.pressed.image.color: #ffffff
window.active.button.hover.bg: flat solid
window.active.button.hover.bg.color: #3584e4
window.active.button.hover.image.color: #ffffff
window.active.button.disabled.bg: parentrelative
window.active.button.disabled.image.color: #5e5c64
window.inactive.border.color: #38383d
window.inactive.title.bg: flat solid
window.inactive.title.bg.color: #1e1e22
window.inactive.label.bg: parentrelative
window.inactive.label.text.color: #9a9996
window.inactive.handle.bg: flat solid
window.inactive.handle.bg.color: #1e1e22
window.inactive.grip.bg: flat solid
window.inactive.grip.bg.color: #2b2b30
window.inactive.button.unpressed.bg: parentrelative
window.inactive.button.unpressed.image.color: #9a9996
window.inactive.button.pressed.bg: flat solid
window.inactive.button.pressed.bg.color: #38383d
window.inactive.button.pressed.image.color: #ffffff
window.inactive.button.hover.bg: flat solid
window.inactive.button.hover.bg.color: #38383d
window.inactive.button.hover.image.color: #ffffff
window.inactive.button.disabled.bg: parentrelative
window.inactive.button.disabled.image.color: #5e5c64
osd.border.width: 2
osd.border.color: #3584e4
osd.bg: flat solid
osd.bg.color: #2b2b30
osd.label.bg: parentrelative
osd.label.text.color: #ffffff
osd.hilight.bg: flat solid
osd.hilight.bg.color: #3584e4
osd.unhilight.bg: flat solid
osd.unhilight.bg.color: #1e1e22
osd.button.unpressed.bg: flat solid
osd.button.unpressed.bg.color: #1e1e22
osd.button.unpressed.text.color: #ffffff
osd.button.unpressed.border.color: #38383d
osd.button.pressed.bg: flat solid
osd.button.pressed.bg.color: #3584e4
osd.button.pressed.text.color: #ffffff
osd.button.pressed.border.color: #3584e4
osd.button.focused.bg: flat solid
osd.button.focused.bg.color: #3584e4
osd.button.focused.text.color: #ffffff
osd.button.focused.border.color: #3584e4
menu.border.width: 2
menu.border.color: #38383d
menu.title.bg: flat solid
menu.title.bg.color: #1e1e22
menu.title.text.color: #3584e4
menu.items.bg: flat solid
menu.items.bg.color: #242428
menu.items.text.color: #ffffff
menu.items.disabled.text.color: #5e5c64
menu.items.active.bg: flat solid
menu.items.active.bg.color: #3584e4
menu.items.active.text.color: #ffffff
menu.separator.color: #38383d
OTM

	local _is_terminal=0
	_is_terminal_app "${_app}" && _is_terminal=1

	local _tabbar_script=""
	if command -v python3 > "/dev/null" 2>&1 && python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' > "/dev/null" 2>&1; then
		_tabbar_script="${XDG_RUNTIME_DIR:-/tmp}/xgui-tabbar-$$.py"
		cat << 'EOF_TABBAR' >| "${_tabbar_script}"
import os, sys, subprocess, time
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GdkX11, GLib, Pango
from Xlib import display, X, Xatom
import Xlib.protocol.event

BAR_H = 26

class XguiTabBar(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_accept_focus(False)
        self.set_focus_on_map(False)
        self.set_title("xgui-tabbar")
        self.set_wmclass("xgui-tabbar", "xgui-tabbar")

        self.bar_h = BAR_H
        self.d = display.Display()
        self.screen_obj = self.d.screen()
        self.root = self.screen_obj.root
        self.screen_w = self.screen_obj.width_in_pixels
        self.screen_h = self.screen_obj.height_in_pixels

        self.set_default_size(self.screen_w, self.bar_h)
        self.set_size_request(self.screen_w, self.bar_h)
        self.move(0, 0)
        self.realize()
        self.self_xid = self.get_window().get_xid()
        self.self_xwin = self.d.create_resource_object("window", self.self_xid)

        self.atom_net_client_list = self.d.intern_atom("_NET_CLIENT_LIST")
        self.atom_net_active = self.d.intern_atom("_NET_ACTIVE_WINDOW")
        self.atom_net_wm_name = self.d.intern_atom("_NET_WM_NAME")
        self.atom_utf8_string = self.d.intern_atom("UTF8_STRING")
        self.atom_net_wm_type = self.d.intern_atom("_NET_WM_WINDOW_TYPE")
        self.atom_wm_state = self.d.intern_atom("WM_STATE")
        self.atom_net_strut = self.d.intern_atom("_NET_WM_STRUT")
        self.atom_net_strut_partial = self.d.intern_atom("_NET_WM_STRUT_PARTIAL")
        self.atom_cardinal = self.d.intern_atom("CARDINAL")
        self.atom_net_wm_state = self.d.intern_atom("_NET_WM_STATE")
        self.atom_max_vert = self.d.intern_atom("_NET_WM_STATE_MAXIMIZED_VERT")
        self.atom_max_horz = self.d.intern_atom("_NET_WM_STATE_MAXIMIZED_HORZ")

        self.skip_types = set([
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_DOCK"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_DESKTOP"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_MENU"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_TOOLBAR"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_SPLASH"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_UTILITY"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_DIALOG"),
            self.d.intern_atom("_NET_WM_WINDOW_TYPE_NOTIFICATION")
        ])

        font_name = os.environ.get("XGUI_FONT", "JetBrainsMono Nerd Font")

        css_provider = Gtk.CssProvider()
        css = f"""
        window {{
            background-color: #1e1e22;
            background-image: none;
            border-bottom: 1px solid #38383d;
            padding: 0;
            margin: 0;
        }}
        * {{
            font-family: "{font_name}", "JetBrainsMono Nerd Font", monospace;
            font-size: 10pt;
            font-weight: bold;
        }}
        button {{
            background-image: none;
            box-shadow: none;
            text-shadow: none;
            padding: 2px 10px;
            margin: 0;
            border-radius: 0;
            min-height: 20px;
        }}
        button.inactive-tab {{
            background-color: #1e1e22;
            background-image: none;
            color: #9a9996;
            border: 1px solid #38383d;
        }}
        button.inactive-tab:hover {{
            background-color: #2b2b30;
            background-image: none;
            color: #ffffff;
            border-color: #3584e4;
        }}
        button.active-tab {{
            background-color: #2b2b30;
            background-image: none;
            color: #ffffff;
            border: 1px solid #3584e4;
            border-top: 2px solid #3584e4;
        }}
        button.active-tab:hover {{
            background-color: #323238;
            background-image: none;
            color: #ffffff;
            border-color: #4a96ef;
        }}
        """
        css_provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.add(self.box)

        self.is_bar_visible = False
        self.last_windows = []
        self.last_active = None
        self.positioned_wids = set()

        self.poll()
        GLib.timeout_add(200, self.poll)

    def set_struts(self, enable):
        try:
            if enable:
                strut = [0, 0, self.bar_h, 0]
                strut_p = [0, 0, self.bar_h, 0, 0, 0, 0, 0, 0, self.screen_w - 1, 0, 0]
                self.self_xwin.change_property(self.atom_net_strut, self.atom_cardinal, 32, strut)
                self.self_xwin.change_property(self.atom_net_strut_partial, self.atom_cardinal, 32, strut_p)
            else:
                self.self_xwin.delete_property(self.atom_net_strut)
                self.self_xwin.delete_property(self.atom_net_strut_partial)
            self.d.sync()
        except Exception:
            pass

    def unmaximize_window(self, xid):
        try:
            ev = Xlib.protocol.event.ClientMessage(
                window=xid,
                client_type=self.atom_net_wm_state,
                data=(32, [0, self.atom_max_vert, self.atom_max_horz, 1, 0])
            )
            self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
            self.d.sync()
        except Exception:
            pass

    def maximize_window(self, xid):
        try:
            ev = Xlib.protocol.event.ClientMessage(
                window=xid,
                client_type=self.atom_net_wm_state,
                data=(32, [1, self.atom_max_vert, self.atom_max_horz, 1, 0])
            )
            self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
            self.d.sync()
        except Exception:
            pass

    def activate_window(self, xid):
        try:
            ev = Xlib.protocol.event.ClientMessage(
                window=xid,
                client_type=self.atom_net_active,
                data=(32, [1, X.CurrentTime, 0, 0, 0])
            )
            self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
            self.d.sync()
        except Exception:
            try:
                subprocess.Popen(["xdotool", "windowactivate", str(xid)])
            except Exception:
                pass

    def get_title(self, xid):
        try:
            xwin = self.d.create_resource_object("window", xid)
            prop = xwin.get_full_property(self.atom_net_wm_name, self.atom_utf8_string)
            if prop and prop.value:
                val = prop.value
                return val.decode("utf-8", errors="replace") if isinstance(val, bytes) else str(val)
            name = xwin.get_wm_name()
            if name:
                return name
        except Exception:
            pass
        return "Window"

    def is_normal(self, xid):
        if xid == self.self_xid:
            return False
        try:
            xwin = self.d.create_resource_object("window", xid)
            trans = xwin.get_wm_transient_for()
            if trans:
                return False
            type_prop = xwin.get_full_property(self.atom_net_wm_type, Xatom.ATOM)
            if type_prop and type_prop.value:
                if any(t in self.skip_types for t in type_prop.value):
                    return False
            state_prop = xwin.get_full_property(self.atom_wm_state, 0)
            if state_prop and state_prop.value and state_prop.value[0] == 0:
                return False
            return True
        except Exception:
            return False

    def poll(self):
        try:
            prop = self.root.get_full_property(self.atom_net_client_list, Xatom.WINDOW)
            all_xids = list(prop.value) if prop and prop.value else []
        except Exception:
            all_xids = []

        active_xid = None
        try:
            act_prop = self.root.get_full_property(self.atom_net_active, Xatom.WINDOW)
            if act_prop and act_prop.value:
                active_xid = act_prop.value[0]
        except Exception:
            pass

        normal_windows = [x for x in all_xids if self.is_normal(x)]

        if len(normal_windows) < 2:
            if self.is_bar_visible:
                self.hide()
                self.set_struts(False)
                self.is_bar_visible = False
                self.positioned_wids.clear()
                for w in normal_windows:
                    self.unmaximize_window(w)
                    try:
                        w_obj = self.d.create_resource_object("window", w)
                        w_obj.configure(x=0, y=0, width=self.screen_w, height=self.screen_h)
                    except Exception:
                        pass
                    self.maximize_window(w)
                    self.d.sync()
            return True

        self.positioned_wids.intersection_update(normal_windows)

        if not self.is_bar_visible:
            self.set_struts(True)
            self.move(0, 0)
            self.resize(self.screen_w, self.bar_h)
            self.show_all()
            self.is_bar_visible = True

        for w in normal_windows:
            if w not in self.positioned_wids:
                self.unmaximize_window(w)
                try:
                    w_obj = self.d.create_resource_object("window", w)
                    w_obj.configure(x=0, y=self.bar_h, width=self.screen_w, height=self.screen_h - self.bar_h)
                except Exception:
                    pass
                self.maximize_window(w)
                self.d.sync()
                self.positioned_wids.add(w)

        if normal_windows != self.last_windows or active_xid != self.last_active:
            self.last_windows = normal_windows
            self.last_active = active_xid
            for child in self.box.get_children():
                self.box.remove(child)

            for w in normal_windows:
                title = self.get_title(w)
                btn = Gtk.Button()
                lbl = Gtk.Label(label=title)
                lbl.set_ellipsize(Pango.EllipsizeMode.END)
                lbl.set_max_width_chars(32)
                btn.add(lbl)
                ctx = btn.get_style_context()
                if w == active_xid:
                    ctx.add_class("active-tab")
                else:
                    ctx.add_class("inactive-tab")
                btn.connect("clicked", lambda widget, target=w: self.activate_window(target))
                self.box.pack_start(btn, True, True, 0)

            self.box.show_all()

        return True

win = XguiTabBar()
Gtk.main()
EOF_TABBAR
	fi


	local _target_wm="${_selected_wm}"
	if [ -n "${_target_wm}" ]; then
		if ! command -v "${_target_wm}" > "/dev/null" 2>&1; then
			_ui_err "Gerenciador X11 '${_target_wm}' não está instalado."
			rm -f "${_tabbar_script}" 2> "/dev/null" || true
			return 1
		fi
	else
		local _x_cand
		for _x_cand in $(_get_x11_wm_pipeline); do
			if command -v "${_x_cand}" > "/dev/null" 2>&1; then
				_target_wm="${_x_cand}"
				break
			fi
		done
	fi

	local _sh="$(_detect_enabled_shell)"
	local _vt_arg="$(_resolve_vt_arg)"
	local _xinit_script="${XDG_RUNTIME_DIR:-/tmp}/xinit-gui-$$.sh"
	cat << EOF >| "${_xinit_script}"
#!/usr/bin/env sh
unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-GNOME}"
export DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}"
export SAL_USE_VCLPLUGIN="gtk3"
export GTK_THEME="${GTK_THEME:-adw-gtk3-dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1

if [ -z "\${ENVIRONMENT_SESSION_WRAPPED:-}" ]; then
	export ENVIRONMENT_SESSION_WRAPPED=1
	_ck=""
	[ "\$(uname -s)" = "FreeBSD" ] && command -v ck-launch-session > "/dev/null" 2>&1 && _ck="ck-launch-session"
	if command -v dbus-run-session > "/dev/null" 2>&1; then
		exec dbus-run-session -- \${_ck} "\$0" "\$@"
	elif command -v dbus-launch > "/dev/null" 2>&1; then
		exec dbus-launch --exit-with-session \${_ck} "\$0" "\$@"
	elif [ -n "\${_ck}" ]; then
		exec ck-launch-session "\$0" "\$@"
	fi
fi
unset ENVIRONMENT_SESSION_WRAPPED

export XDG_SESSION_TYPE="x11"
unset WAYLAND_DISPLAY
export GDK_BACKEND="x11"
export QT_QPA_PLATFORM="xcb"
export SDL_VIDEODRIVER="x11"
export CLUTTER_BACKEND="x11"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-GNOME}"
export DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}"
export SAL_USE_VCLPLUGIN="gtk3"
export GTK_CSD=0
export GTK_THEME="${GTK_THEME:-adw-gtk3-dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1
export QT_QPA_PLATFORMTHEME="\${QT_QPA_PLATFORMTHEME:-qt6ct}"
export XCURSOR_THEME="\${XCURSOR_THEME}"
export XCURSOR_SIZE="\${XCURSOR_SIZE:-24}"
export MOZ_GTK_TITLEBAR_DECORATION="system"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

if [ -f "\${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "\${HOME}/.Xresources" 2> "/dev/null" || true
fi
if command -v xrdb > "/dev/null" 2>&1; then
	printf "Xcursor.theme: %s\nXcursor.size: %s\n" "\${XCURSOR_THEME}" "\${XCURSOR_SIZE}" | xrdb -merge - 2> "/dev/null" || true
fi
command -v xsetroot > "/dev/null" 2>&1 && xsetroot -solid "#16161e" -cursor_name left_ptr 2> "/dev/null" || true

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

if command -v gnome-keyring-daemon > "/dev/null" 2>&1; then
	eval "\$(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2> "/dev/null")"
	[ -n "\${SSH_AUTH_SOCK:-}" ] && export SSH_AUTH_SOCK
	if command -v dbus-update-activation-environment > "/dev/null" 2>&1; then
		dbus-update-activation-environment --systemd SSH_AUTH_SOCK DISPLAY XDG_CURRENT_DESKTOP 2> "/dev/null" || \
		dbus-update-activation-environment SSH_AUTH_SOCK DISPLAY XDG_CURRENT_DESKTOP 2> "/dev/null" || true
	fi
fi

if command -v xrandr > "/dev/null" 2>&1; then
	for _out in \$(xrandr 2> "/dev/null" | grep " connected" | cut -d ' ' -f1); do
		xrandr --output "\${_out}" --set "TearFree" "on" 2> "/dev/null" || true
	done
fi

if command -v xsettingsd > "/dev/null" 2>&1; then
	_xsettings_cfg="\${XDG_RUNTIME_DIR:-/tmp}/xsettingsd-\$\$.conf"
	cat << EOF_XSET >| "\${_xsettings_cfg}"
Net/ThemeName "adw-gtk3-dark"
Net/IconThemeName "${_icon_theme}"
Gtk/CursorThemeName "${_valid_theme}"
Gtk/CursorThemeSize 24
Gtk/FontName "${_ui_font}"
EOF_XSET
	xsettingsd -c "\${_xsettings_cfg}" > "/dev/null" 2>&1 &
fi

if [ "\${X11_NO_COMPOSITOR:-0}" != "1" ]; then
	if command -v picom > "/dev/null" 2>&1; then
		killall -0 picom 2> "/dev/null" || picom --backend glx --vsync -b > "/dev/null" 2>&1 || \
		killall -0 picom 2> "/dev/null" || picom --backend xrender --vsync -b > "/dev/null" 2>&1 || true
	elif command -v xcompmgr > "/dev/null" 2>&1; then
		killall -0 xcompmgr 2> "/dev/null" || xcompmgr -c -C -b > "/dev/null" 2>&1 || true
	fi
fi

if [ -n "${_tabbar_script}" ] && [ -f "${_tabbar_script}" ]; then
	env GDK_BACKEND=x11 XGUI_FONT="${_ui_font}" python3 "${_tabbar_script}" > "/dev/null" 2>&1 &
fi

case "${_target_wm}" in
	openbox)
		_ob_cfg="\${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-\$\$.xml"
		cat << 'XOB' >| "\${_ob_cfg}"
<?xml version="1.0"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>kiosk</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>no</keepBorder>
    <animateIconify>no</animateIconify>
    <font place="ActiveWindow"><name>${_ui_font}</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="InactiveWindow"><name>${_ui_font}</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="MenuHeader"><name>${_ui_font}</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="MenuItem"><name>${_ui_font}</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="ActiveOnScreenDisplay"><name>${_ui_font}</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="InactiveOnScreenDisplay"><name>${_ui_font}</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
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
    <context name="Root">
      <mousebind button="Middle" action="Press"><action name="ShowMenu"><menu>client-list-combined-menu</menu></action></mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="ToggleMaximize"/></mousebind>
    </context>
    <context name="Iconify">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Click"><action name="Iconify"/></mousebind>
    </context>
    <context name="Maximize">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Click"><action name="ToggleMaximize"/></mousebind>
    </context>
    <context name="Close">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Click"><action name="Close"/></mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Middle" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Right" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
  </mouse>
  <keyboard>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-Tab"><action name="NextWindow"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
  </keyboard>
  <applications>
    <application type="normal">
      <decor>no</decor>
      <shade>no</shade>
      <focus>yes</focus>
      <maximized>yes</maximized>
      <fullscreen>no</fullscreen>
    </application>
    <application type="dialog">
      <decor>yes</decor>
      <focus>yes</focus>
      <maximized>no</maximized>
    </application>
  </applications>
</openbox_config>
XOB
		openbox --config-file "\${_ob_cfg}" > "/dev/null" 2>&1 &
		;;
	cwm)
		cwm > "/dev/null" 2>&1 &
		;;
	dwm)
		dwm > "/dev/null" 2>&1 &
		;;
	fvwm)
		fvwm > "/dev/null" 2>&1 &
		;;
	twm)
		twm > "/dev/null" 2>&1 &
		;;
	matchbox|matchbox-window-manager)
		matchbox-window-manager -use_titlebar no > "/dev/null" 2>&1 &
		;;
	*)
		if command -v openbox > "/dev/null" 2>&1; then
			openbox > "/dev/null" 2>&1 &
		elif command -v matchbox-window-manager > "/dev/null" 2>&1; then
			matchbox-window-manager -use_titlebar no > "/dev/null" 2>&1 &
		elif command -v cwm > "/dev/null" 2>&1; then
			cwm > "/dev/null" 2>&1 &
		fi
		;;
esac

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
	_emacs_kiosk_bin="\$(command -v emacs-gtk+x11 2> "/dev/null" || command -v emacs-x11 2> "/dev/null" || command -v emacs-lucid 2> "/dev/null" || command -v emacs-gtk 2> "/dev/null" || command -v emacs-nw 2> "/dev/null" || command -v emacs 2> "/dev/null" || true)"
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
	rm -f "${_xinit_script}" "${XDG_RUNTIME_DIR:-/tmp}/openbox-gui-$$.xml" "${_tabbar_script}" 2> "/dev/null" || true
	[ "${_had_display}" -eq 0 ] && unset DISPLAY
	_freebsd_vt_bounce
	return "${_xinit_ret}"
}
alias graphical-launcher-x11="graphical_launcher_x11" xgui="graphical_launcher_x11"

graphical_launcher() {
	_dispatch_display_server "graphical-launcher" "$@"
}
alias graphical-launcher="graphical_launcher" gui="graphical_launcher"

### --------------------------------
### EMACS OS WINDOW MANAGERS
### --------------------------------
emacs_window_manager_wayland() {
	_sanitize_graphical_env

	local _flavor=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--lxqt)        _flavor="lxqt"; shift ;;
			--lxde)        _flavor="lxde"; shift ;;
			--budgie)      _flavor="budgie"; shift ;;
			--pantheon)    _flavor="pantheon"; shift ;;
			--deepin)      _flavor="deepin"; shift ;;
			--cosmic)      _flavor="cosmic"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	_wayland_session_env "${_flavor}"
	export EMACS_OS_MODE="wayland"

	local _ewm_emacs_bin="$(command -v emacs-pgtk 2> "/dev/null" || command -v emacs 2> "/dev/null" || true)"
	if [ -z "${_ewm_emacs_bin}" ]; then
		_ui_err "emacs não encontrado."
		unset EMACS_OS_MODE
		return 127
	fi

	local _ewm_so=""
	if [ -f "${HOME}/.local/lib/libewm_core.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm_core.so"
	elif [ -f "${HOME}/.local/lib/libewm.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm.so"
	fi

	if [ -n "${_ewm_so}" ]; then
		unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
		export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1
		local _bus_wrapper=""
		if command -v dbus-run-session > "/dev/null" 2>&1; then
			_bus_wrapper="dbus-run-session --"
		elif command -v dbus-launch > "/dev/null" 2>&1; then
			_bus_wrapper="dbus-launch --exit-with-session"
		fi
		export EWM_MODULE_PATH="${_ewm_so}"
		export EMACSLOADPATH="${HOME}/.local/share/emacs/site-lisp/ewm:${EMACSLOADPATH:-}:"
		export RUST_LOG="${RUST_LOG:-ewm=info,ewm_core::dbus_login1=error,ewm_core::xwayland::satellite=error,smithay=warn}"
		rm -f "${XDG_RUNTIME_DIR:-/tmp}/emacs/ewm" 2> "/dev/null" || true

		local _log_dir="$(_get_shell_log_dir)"
		local _ewm_log="${_log_dir}/ewm-wayland.log"
		unset WAYLAND_DISPLAY DISPLAY
		${_bus_wrapper:-command} "${_ewm_emacs_bin}" --fg-daemon=ewm -L "${HOME}/.local/share/emacs/site-lisp/ewm" -l ewm -f ewm-start-module "$@" >| "${_ewm_log}" 2>&1
		local _emacs_ret=$?

		if [ "${_emacs_ret}" -ne 0 ]; then
			_ui_err "EWM Wayland encerrou com erro (código ${_emacs_ret}). Log: ${_ewm_log}"
		fi
	else
		graphical_launcher_wayland emacs "$@"
	fi

	unset EMACS_OS_MODE
	_restore_tty_cursor 2> "/dev/null" || true
	_freebsd_vt_bounce
}
alias emacs-window-manager-wayland="emacs_window_manager_wayland" wewm="emacs_window_manager_wayland" wew="emacs_window_manager_wayland"

emacs_window_manager_x11() {
	_sanitize_graphical_env

	local _flavor=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-g|--gnome)    _flavor="gnome"; shift ;;
			-k|--kde)      _flavor="kde"; shift ;;
			-x|--xfce)     _flavor="xfce"; shift ;;
			-m|--mate)     _flavor="mate"; shift ;;
			-c|--cinnamon) _flavor="cinnamon"; shift ;;
			--lxqt)        _flavor="lxqt"; shift ;;
			--lxde)        _flavor="lxde"; shift ;;
			--budgie)      _flavor="budgie"; shift ;;
			--pantheon)    _flavor="pantheon"; shift ;;
			--deepin)      _flavor="deepin"; shift ;;
			--cosmic)      _flavor="cosmic"; shift ;;
			--)            shift; break ;;
			*)             break ;;
		esac
	done

	export EMACS_OS_MODE="x11"
	export _X11_FLAVOR_OVERRIDE="${_flavor}"
	_setup_cursor_env "${_flavor}"

	local _emacs_bin="$(command -v emacs-gtk+x11 2> "/dev/null" || command -v emacs-x11 2> "/dev/null" || command -v emacs-lucid 2> "/dev/null" || command -v emacs-gtk 2> "/dev/null" || command -v emacs-nw 2> "/dev/null" || command -v emacs 2> "/dev/null" || true)"
	if [ -z "${_emacs_bin}" ]; then
		_ui_err "emacs não encontrado."
		unset _X11_FLAVOR_OVERRIDE EMACS_OS_MODE
		return 127
	fi

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	_exec_x11 "${_emacs_bin}" -mm "$@"
	unset _X11_FLAVOR_OVERRIDE EMACS_OS_MODE
	_restore_tty_cursor 2> "/dev/null" || true
	_freebsd_vt_bounce
}
alias emacs-window-manager-x11="emacs_window_manager_x11" xewm="emacs_window_manager_x11" xew="emacs_window_manager_x11" exwm="emacs_window_manager_x11" exw="emacs_window_manager_x11"

emacs_window_manager() {
	_dispatch_display_server "emacs-window-manager" "$@"
}
alias emacs-window-manager="emacs_window_manager" ewm="emacs_window_manager" ew="emacs_window_manager"
