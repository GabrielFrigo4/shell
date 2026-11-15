# ----------------------------------------------------------------
# Library: Ephemeral GUI Launchers & Emacs OS Window Managers
# ----------------------------------------------------------------

### --------------------------------
### EPHEMERAL GRAPHICAL LAUNCHERS
### --------------------------------
_kiosk_ensure_session() {
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

_kiosk_restore_ifs() {
	if [ "${1:-0}" -eq 1 ]; then
		IFS="${2:-}"
	else
		unset IFS
	fi
}

_kiosk_resolve_exec_bin() {
	local _keb_target="${1:-}"
	[ -z "${_keb_target}" ] && return 1
	case "${_keb_target}" in
		*/*)
			if [ -f "${_keb_target}" ] && [ -x "${_keb_target}" ]; then
				printf '%s\n' "${_keb_target}"
				return 0
			fi
			return 1
			;;
	esac
	[ -z "${PATH:-}" ] && return 1
	local _keb_rem="${PATH}:" _keb_dir=""
	while [ -n "${_keb_rem}" ]; do
		_keb_dir="${_keb_rem%%:*}"
		_keb_rem="${_keb_rem#*:}"
		[ -z "${_keb_dir}" ] && _keb_dir="."
		if [ -f "${_keb_dir}/${_keb_target}" ] && [ -x "${_keb_dir}/${_keb_target}" ]; then
			printf '%s\n' "${_keb_dir}/${_keb_target}"
			return 0
		fi
	done
	return 1
}

_kiosk_has_exec_bin() {
	_kiosk_resolve_exec_bin "${1:-}" > "/dev/null" 2>&1
}

_kiosk_has_forced_backend() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-w|--wm)
				[ "$#" -ge 2 ] || break
				case "$2" in
					sway|labwc|river|cage|hyprland|Hyprland|niri|wayfire|dwl|hikari|weston|ewm|openbox|cwm|dwm|fvwm3|fvwm|fluxbox|icewm|jwm|pekwm|twm|matchbox|matchbox-window-manager)
						return 0
						;;
				esac
				shift 2
				;;
			--wm=*)
				case "${1#--wm=}" in
					sway|labwc|river|cage|hyprland|Hyprland|niri|wayfire|dwl|hikari|weston|ewm|openbox|cwm|dwm|fvwm3|fvwm|fluxbox|icewm|jwm|pekwm|twm|matchbox|matchbox-window-manager)
						return 0
						;;
				esac
				shift
				;;
			--sway|--labwc|--river|--cage|--hyprland|--niri|--wayfire|--dwl|--hikari|--weston|--ewm|--openbox|--cwm|--dwm|--fvwm3|--fvwm|--fluxbox|--icewm|--jwm|--pekwm|--twm|--matchbox|--matchbox-window-manager)
				return 0
				;;
			--)
				break
				;;
			*)
				shift
				;;
		esac
	done
	return 1
}

_kiosk_exec_wayland_logged() {
	local _log_target="${1:-}"
	[ "$#" -ge 1 ] && shift
	[ -z "${_log_target}" ] && return 1
	local _exec_ret=0
	local _os_name="$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')"
	if [ "${_os_name}" = "freebsd" ] && _kiosk_has_exec_bin "ck-launch-session"; then
		local _ck_cmd="$(_session_cmd_file "$@")"
		if _kiosk_has_exec_bin "dbus-run-session"; then
			command dbus-run-session -- ck-launch-session "${_ck_cmd}" >> "${_log_target}" 2>&1
			_exec_ret=$?
		elif _kiosk_has_exec_bin "dbus-launch"; then
			command dbus-launch --exit-with-session ck-launch-session "${_ck_cmd}" >> "${_log_target}" 2>&1
			_exec_ret=$?
		else
			command ck-launch-session "${_ck_cmd}" >> "${_log_target}" 2>&1
			_exec_ret=$?
		fi
		rm -f "${_ck_cmd}" 2> "/dev/null" || true
	elif _kiosk_has_exec_bin "dbus-run-session"; then
		command dbus-run-session -- "$@" >> "${_log_target}" 2>&1
		_exec_ret=$?
	elif _kiosk_has_exec_bin "dbus-launch"; then
		command dbus-launch --exit-with-session "$@" >> "${_log_target}" 2>&1
		_exec_ret=$?
	else
		"$@" >> "${_log_target}" 2>&1
		_exec_ret=$?
	fi
	return "${_exec_ret}"
}

graphical_launcher_wayland() {
	_kiosk_ensure_session || return 1
	local _ifs_was_set=0 _saved_ifs=""
	if [ "${IFS+set}" = "set" ]; then
		_ifs_was_set=1
		_saved_ifs="${IFS}"
	fi
	unset EMACS_OS_MODE
	_sanitize_graphical_env

	local _flavor="" _selected_wm=""
	local _had_wayland=1
	[ -z "${WAYLAND_DISPLAY:-}" ] && _had_wayland=0
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-l|--list|--pipeline)
				_show_wm_pipeline "wayland"
				_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
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
			--sway|--labwc|--river|--cage|--hyprland|--niri|--wayfire|--dwl|--hikari|--weston)
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

	local _is_terminal=0
	_is_terminal_app "${_app}" && _is_terminal=1

	local _has_xwayland=0
	_kiosk_has_exec_bin "Xwayland" && _has_xwayland=1

	local _require_xwayland=0
	if [ "${_is_terminal}" -eq 0 ] && [ "${_has_xwayland}" -eq 0 ] && [ -z "${DISPLAY:-}" ]; then
		case "${_app##*/}" in
			xterm|urxvt|rxvt) _require_xwayland=1 ;;
			*)
				local _app_path=""
				_app_path="$(_kiosk_resolve_exec_bin "${_app}" || true)"
				if [ -n "${_app_path}" ] && [ -f "${_app_path}" ] && _kiosk_has_exec_bin "readelf"; then
					local _app_libs=""
					_app_libs="$(command readelf -d "${_app_path}" 2> "/dev/null" | command grep "(NEEDED)" || true)"
					if printf '%s\n' "${_app_libs}" | command grep -qi "libX11" > "/dev/null" 2>&1 && \
						! printf '%s\n' "${_app_libs}" | command grep -qiE "libwayland-client|libgtk-|libQt" > "/dev/null" 2>&1; then
						_require_xwayland=1
					fi
				fi
				;;
		esac
	fi

	local _target_wm=""
	local _prev_req_xwayland="${_WAYLAND_REQUIRE_XWAYLAND:-}"
	export _WAYLAND_REQUIRE_XWAYLAND="${_require_xwayland}"

	if [ -n "${_selected_wm}" ]; then
		if [ "${_selected_wm}" = "hyprland" ] || [ "${_selected_wm}" = "Hyprland" ]; then
			if _preflight_wayland "Hyprland"; then
				_target_wm="Hyprland"
			elif _preflight_wayland "hyprland"; then
				_target_wm="hyprland"
			fi
		elif _preflight_wayland "${_selected_wm}"; then
			_target_wm="${_selected_wm}"
		fi
		if [ -z "${_target_wm}" ]; then
			if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
				_ui_err "Compositor Wayland '${_selected_wm}' indisponível."
			fi
			if [ -n "${_prev_req_xwayland}" ]; then
				export _WAYLAND_REQUIRE_XWAYLAND="${_prev_req_xwayland}"
			else
				unset _WAYLAND_REQUIRE_XWAYLAND
			fi
			_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
			return 127
		fi
	else
		local _w_pipeline="$(_get_wayland_wm_pipeline) " _w_cand=""
		while [ -n "${_w_pipeline}" ]; do
			_w_cand="${_w_pipeline%% *}"
			_w_pipeline="${_w_pipeline#* }"
			[ -z "${_w_cand}" ] && continue
			if [ "${_w_cand}" = "hyprland" ]; then
				if _preflight_wayland "Hyprland"; then
					_target_wm="Hyprland"
					break
				elif _preflight_wayland "hyprland"; then
					_target_wm="hyprland"
					break
				fi
			elif _preflight_wayland "${_w_cand}"; then
				_target_wm="${_w_cand}"
				break
			fi
		done
		if [ -z "${_target_wm}" ]; then
			if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
				_ui_err "Nenhum compositor Wayland (sway, labwc, river, hyprland, niri, wayfire, dwl, hikari, weston, cage) disponível."
			fi
			if [ -n "${_prev_req_xwayland}" ]; then
				export _WAYLAND_REQUIRE_XWAYLAND="${_prev_req_xwayland}"
			else
				unset _WAYLAND_REQUIRE_XWAYLAND
			fi
			_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
			return 127
		fi
	fi

	if [ -n "${_prev_req_xwayland}" ]; then
		export _WAYLAND_REQUIRE_XWAYLAND="${_prev_req_xwayland}"
	else
		unset _WAYLAND_REQUIRE_XWAYLAND
	fi

	_wayland_session_env "${_flavor}"

	local _scheme="${_RESOLVED_COLOR_SCHEME:-dark}"
	local _hex_bg="1e1e22" _hex_panel="2b2b30" _hex_border="38383d" _hex_fg="ffffff" _hex_muted="9a9996"
	local _hex_accent="3584e4" _hex_urgent="e01b24"
	if [ "${_scheme}" = "light" ]; then
		_hex_bg="f6f5f4"
		_hex_panel="ffffff"
		_hex_border="cdc7c2"
		_hex_fg="241f31"
		_hex_muted="5e5c64"
	fi
	local _p_bg="#${_hex_bg}" _p_panel="#${_hex_panel}" _p_border="#${_hex_border}"
	local _p_fg="#${_hex_fg}" _p_muted="#${_hex_muted}" _p_accent="#${_hex_accent}" _p_urgent="#${_hex_urgent}"

	local _run_dir="${XDG_RUNTIME_DIR:-/tmp}"
	[ -d "${_run_dir}" ] && [ -w "${_run_dir}" ] || _run_dir="/tmp"
	local _wayland_runner="${_run_dir}/wayland-runner-$$.sh"
	local _wayland_entry="${_run_dir}/wayland-entry-$$.sh"
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
	[ -n "\${_emacs_wayland_bin}" ] && "\${_emacs_wayland_bin}" -mm "\$@"
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
if command -v labwc > "/dev/null" 2>&1 && [ -n "\${LABWC_PID:-}" ]; then
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
	chmod 0755 "${_wayland_runner}" 2> "/dev/null" || true

	local _quoted_entry=""
	_quoted_entry="$(_session_quote_args "${_wayland_runner}" "${_app}" "$@")"
	cat << EOF >| "${_wayland_entry}"
#!/usr/bin/env sh
exec ${_quoted_entry}
EOF
	chmod 0755 "${_wayland_entry}" 2> "/dev/null" || true

	if [ "${_app}" = "foot" ] || [ "${_is_terminal}" -eq 1 ]; then
		local _foot_target="${HOME}/.config/foot/foot.ini"
		local _foot_src=""
		if [ -f "${HOME}/.local/share/profile/terminals/foot/foot.ini" ]; then
			_foot_src="${HOME}/.local/share/profile/terminals/foot/foot.ini"
		elif [ -f "${PROFILE_REPO_DIR:-}/terminals/foot/foot.ini" ]; then
			_foot_src="${PROFILE_REPO_DIR}/terminals/foot/foot.ini"
		fi
		if [ -n "${_foot_src}" ]; then
			mkdir -p "${HOME}/.config/foot" 2> "/dev/null" || true
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

	local _cur_theme="${XCURSOR_THEME:-Adwaita}"
	local _cur_size="${XCURSOR_SIZE:-24}"
	local _ui_font="$(_resolve_desktop_font "${_flavor}")"
	local _log_dir="$(_get_shell_log_dir)"
	local _log_file="${_log_dir}/wayland-kiosk.log"
	local _ret=0
	local _xwayland_sway="disable"
	local _xwayland_ini="false"
	if [ "${_has_xwayland}" -eq 1 ]; then
		_xwayland_sway="enable"
		_xwayland_ini="true"
	fi

	mkdir -p "${_log_dir}" 2> "/dev/null" || true
	: >| "${_log_file}" 2> "/dev/null" || true

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	local _resolved_wm="$(_kiosk_resolve_exec_bin "${_target_wm}" || printf '%s' "${_target_wm}")"

	case "${_target_wm}" in
		sway)
			local _sway_cfg="${_run_dir}/sway-gui-$$.conf"
			local _tabwatch="${_run_dir}/wgui-tabwatch-$$.sh"
			cat << 'EOF' >| "${_tabwatch}"
#!/usr/bin/env sh
while :; do
	_count=$(swaymsg -t get_tree 2> "/dev/null" | grep -c '"pid":' || true)
	if [ "${_count:-0}" -ge 2 ]; then
		swaymsg "[workspace=__focused__] layout tabbed, border normal 2" > "/dev/null" 2>&1 || true
	else
		swaymsg "[workspace=__focused__] layout tabbed, border pixel 2" > "/dev/null" 2>&1 || true
	fi
	sleep 1
done
EOF
			chmod 0755 "${_tabwatch}" 2> "/dev/null" || true

			cat << EOF >| "${_sway_cfg}"
font pango:${_ui_font} Bold 10
titlebar_padding 10 4
default_border pixel 2
default_floating_border pixel 2
titlebar_border_thickness 0
gaps inner 0
gaps outer 0
workspace_layout tabbed
hide_edge_borders smart
popup_during_fullscreen smart
client.focused ${_p_accent} ${_p_panel} ${_p_fg} ${_p_accent} ${_p_accent}
client.focused_inactive ${_p_border} ${_p_bg} ${_p_muted} ${_p_border} ${_p_border}
client.unfocused ${_p_border} ${_p_bg} ${_p_muted} ${_p_border} ${_p_border}
client.urgent ${_p_urgent} ${_p_panel} #ffffff ${_p_urgent} ${_p_urgent}
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
xwayland ${_xwayland_sway}
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
exec "${_wayland_entry}"
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -c "${_sway_cfg}"
			_ret=$?
			rm -f "${_sway_cfg}" "${_tabwatch}" 2> "/dev/null" || true
			;;
		labwc)
			local _labwc_dir="${_run_dir}/labwc-gui-$$"
			mkdir -p "${_labwc_dir}" 2> "/dev/null" || true
			cat << EOF >| "${_labwc_dir}/themerc"
window.active.title.bg.color: ${_p_panel}
window.active.label.text.color: ${_p_fg}
window.inactive.title.bg.color: ${_p_bg}
window.inactive.label.text.color: ${_p_muted}
border.width: 2
border.color: ${_p_border}
window.active.border.color: ${_p_accent}
window.inactive.border.color: ${_p_border}
menu.border.width: 1
menu.border.color: ${_p_border}
menu.items.bg.color: ${_p_bg}
menu.items.text.color: ${_p_fg}
menu.items.active.bg.color: ${_p_accent}
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
    <border.width>2</border.width>
    <border.color>${_p_border}</border.color>
    <font place="ActiveWindow"><name>${_ui_font}</name><size>10</size><weight>Bold</weight></font>
    <font place="InactiveWindow"><name>${_ui_font}</name><size>10</size><weight>Normal</weight></font>
  </theme>
  <keyboard>
    <repeatRate>50</repeatRate>
    <repeatDelay>200</repeatDelay>
    <numlock>on</numlock>
    <keybind key="W-Return"><action name="Execute" command="foot -o dpi-aware=no"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-m"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
    <keybind key="W-S-q"><action name="Exit"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
  </keyboard>
  <mouse>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="ToggleMaximize"/></mousebind>
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
    <windowRule identifier="*">
      <action name="Maximize"/>
    </windowRule>
  </windowRules>
</labwc_config>
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -C "${_labwc_dir}" -s "${_wayland_entry}"
			_ret=$?
			rm -rf "${_labwc_dir}" 2> "/dev/null" || true
			;;
		river)
			local _river_init="${_run_dir}/river-gui-$$.sh"
			cat << EOF >| "${_river_init}"
#!/usr/bin/env sh
riverctl background-color 0x${_hex_bg}
riverctl border-width 2
riverctl border-color-focused 0x${_hex_accent}
riverctl border-color-unfocused 0x${_hex_border}
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
riverctl map normal Alt Tab focus-view next
riverctl map normal Super Tab focus-view next
riverctl map normal Super F toggle-fullscreen
riverctl map normal Super Q spawn "riverctl exit"
"${_wayland_entry}" &
EOF
			chmod 0755 "${_river_init}" 2> "/dev/null" || true
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -c "${_river_init}"
			_ret=$?
			rm -f "${_river_init}" 2> "/dev/null" || true
			;;
		hyprland|Hyprland)
			local _hypr_cfg="${_run_dir}/hyprland-gui-$$.conf"
			cat << EOF >| "${_hypr_cfg}"
monitor=,preferred,auto,1
general {
    border_size = 2
    gaps_in = 0
    gaps_out = 0
    col.active_border = rgb(${_hex_accent})
    col.inactive_border = rgb(${_hex_border})
}
decoration {
    rounding = 0
    drop_shadow = false
}
misc {
    disable_hyprland_logo = true
    background_color = rgb(${_hex_bg})
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
bind = ALT, Tab, cyclenext
bind = SUPER, Tab, cyclenext
bind = SUPER, Q, killactive
bind = SUPER SHIFT, Q, exit
exec-once = "${_wayland_entry}"
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" --config "${_hypr_cfg}"
			_ret=$?
			rm -f "${_hypr_cfg}" 2> "/dev/null" || true
			;;
		niri)
			local _niri_cfg="${_run_dir}/niri-gui-$$.kdl"
			cat << EOF >| "${_niri_cfg}"
prefer-no-csd
layout {
    border {
        width 2
        active-color "${_p_accent}"
        inactive-color "${_p_border}"
    }
}
binds {
    Mod+Tab { focus-window-or-workspace-down; }
    Alt+Tab { focus-window-or-workspace-down; }
    Mod+Q { close-window; }
    Mod+Shift+Q { quit; }
}
spawn-at-startup "${_wayland_entry}"
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" --config "${_niri_cfg}"
			_ret=$?
			rm -f "${_niri_cfg}" 2> "/dev/null" || true
			;;
		wayfire)
			local _wf_cfg="${_run_dir}/wayfire-gui-$$.ini"
			cat << EOF >| "${_wf_cfg}"
[core]
plugins = command vswitch place autostart
xwayland = ${_xwayland_ini}
[autostart]
app = ${_wayland_entry}
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -c "${_wf_cfg}"
			_ret=$?
			rm -f "${_wf_cfg}" 2> "/dev/null" || true
			;;
		dwl)
			local _dwl_startup="${_run_dir}/dwl-gui-$$.sh"
			cat << EOF >| "${_dwl_startup}"
#!/usr/bin/env sh
exec "${_wayland_entry}"
EOF
			chmod 0755 "${_dwl_startup}" 2> "/dev/null" || true
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -s "${_dwl_startup}"
			_ret=$?
			rm -f "${_dwl_startup}" 2> "/dev/null" || true
			;;
		hikari)
			local _hikari_cfg="${_run_dir}/hikari-gui-$$.conf"
			cat << EOF >| "${_hikari_cfg}"
ui {
  border = 2
  gap = 0
  active = 0x${_hex_accent}
  inactive = 0x${_hex_border}
}
actions {
  quit-app = "${_wayland_entry}"
}
bindings {
  keyboard {
    "L+q" = view-quit
    "LS+q" = quit
  }
}
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -c "${_hikari_cfg}" -a "${_wayland_entry}"
			_ret=$?
			rm -f "${_hikari_cfg}" 2> "/dev/null" || true
			;;
		weston)
			local _weston_cfg="${_run_dir}/weston-gui-$$.ini"
			cat << EOF >| "${_weston_cfg}"
[core]
xwayland=${_xwayland_ini}
[shell]
background-color=0xff${_hex_bg}
panel-position=none
[keyboard]
keymap_layout=br
keymap_model=abnt2
repeat-delay=200
repeat-rate=50
[autostart]
path=${_wayland_entry}
EOF
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" --config="${_weston_cfg}"
			_ret=$?
			rm -f "${_weston_cfg}" 2> "/dev/null" || true
			;;
		cage)
			_kiosk_exec_wayland_logged "${_log_file}" "${_resolved_wm}" -s -- "${_wayland_entry}"
			_ret=$?
			;;
	esac

	[ "${_ret}" -eq 127 ] && _ret=1
	rm -f "${_wayland_runner}" "${_wayland_entry}" 2> "/dev/null" || true
	[ "${_had_wayland}" -eq 0 ] && unset WAYLAND_DISPLAY
	_freebsd_vt_bounce > "/dev/null" 2>&1 || true
	_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"

	if [ "${_ret}" -ne 0 ]; then
		_ui_err "Lançador Wayland encerrou com erro (código ${_ret}). Log: ${_log_file}"
		return "${_ret}"
	fi
	return 0
}
alias graphical-launcher-wayland="graphical_launcher_wayland" wgui="graphical_launcher_wayland"

graphical_launcher_x11() {
	_kiosk_ensure_session || return 1
	local _ifs_was_set=0 _saved_ifs=""
	if [ "${IFS+set}" = "set" ]; then
		_ifs_was_set=1
		_saved_ifs="${IFS}"
	fi
	unset EMACS_OS_MODE
	_sanitize_graphical_env

	local _flavor="" _selected_wm=""
	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	while [ "$#" -gt 0 ]; do
		case "$1" in
			-l|--list|--pipeline)
				_show_wm_pipeline "x11"
				_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
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
			--openbox|--cwm|--dwm|--fvwm3|--fvwm|--fluxbox|--icewm|--jwm|--pekwm|--twm)
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

	{ _kiosk_has_exec_bin "xinit" || _kiosk_has_exec_bin "startx"; } || {
		if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
			_ui_err "xinit ou startx não encontrado para lançador Xorg."
		fi
		_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
		return 127
	}
	{ _kiosk_has_exec_bin "Xorg" || _kiosk_has_exec_bin "X"; } || {
		if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
			_ui_err "Servidor Xorg não encontrado."
		fi
		_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
		return 127
	}

	local _target_wm=""
	if [ -n "${_selected_wm}" ]; then
		if [ "${_selected_wm}" = "fvwm" ] || [ "${_selected_wm}" = "fvwm3" ]; then
			if _kiosk_has_exec_bin "${_selected_wm}"; then
				_target_wm="${_selected_wm}"
			elif _kiosk_has_exec_bin "fvwm3"; then
				_target_wm="fvwm3"
			elif _kiosk_has_exec_bin "fvwm"; then
				_target_wm="fvwm"
			fi
		elif [ "${_selected_wm}" = "matchbox" ] || [ "${_selected_wm}" = "matchbox-window-manager" ]; then
			if _kiosk_has_exec_bin "matchbox-window-manager"; then
				_target_wm="matchbox-window-manager"
			elif _kiosk_has_exec_bin "matchbox"; then
				_target_wm="matchbox"
			fi
		elif _kiosk_has_exec_bin "${_selected_wm}"; then
			_target_wm="${_selected_wm}"
		fi
		if [ -z "${_target_wm}" ]; then
			if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
				_ui_err "Gerenciador X11 '${_selected_wm}' não está instalado."
			fi
			_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
			return 127
		fi
	else
		local _x_pipeline="$(_get_x11_wm_pipeline) " _x_cand=""
		while [ -n "${_x_pipeline}" ]; do
			_x_cand="${_x_pipeline%% *}"
			_x_pipeline="${_x_pipeline#* }"
			[ -z "${_x_cand}" ] && continue
			if _kiosk_has_exec_bin "${_x_cand}"; then
				_target_wm="${_x_cand}"
				break
			fi
		done
	fi

	local _raw_app="${1:-xterm}"
	[ "$#" -ge 1 ] && shift
	local _app="$(_resolve_graphical_app "${_raw_app}")"

	local _log_dir="$(_get_shell_log_dir)"
	local _persistent_kiosk_log="${_log_dir}/xorg-kiosk.log"
	mkdir -p "${_log_dir}" 2> "/dev/null" || true
	: >| "${_persistent_kiosk_log}" 2> "/dev/null" || true

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	local _display="$(_resolve_free_display)"
	export DISPLAY="${_display}"
	_x11_session_env "${_flavor}"
	_x11_driver_preflight "${_persistent_kiosk_log}"

	local _scheme="${_RESOLVED_COLOR_SCHEME:-dark}"
	local _prefer_dark="${GTK_APPLICATION_PREFER_DARK_THEME:-1}"
	local _valid_theme="${XCURSOR_THEME:-Adwaita}"
	local _cur_size="${XCURSOR_SIZE:-24}"
	local _icon_theme="${_RESOLVED_ICON_THEME:-Adwaita}"
	local _ui_font="$(_resolve_desktop_font "${_flavor}")"
	local _gtk_theme="${GTK_THEME:-adw-gtk3-dark}"

	local _p_bg="#1e1e22" _p_panel="#2b2b30" _p_border="#38383d" _p_fg="#ffffff" _p_muted="#9a9996"
	local _p_menu_bg="#242428" _p_hover="#5e5c64" _p_accent="#3584e4" _p_urgent="#e01b24"
	if [ "${_scheme}" = "light" ]; then
		_p_bg="#f6f5f4"
		_p_panel="#ffffff"
		_p_border="#cdc7c2"
		_p_fg="#241f31"
		_p_muted="#5e5c64"
		_p_menu_bg="#ffffff"
		_p_hover="#77767b"
	fi

	local _kiosk_theme_dir="${HOME}/.local/share/themes/kiosk/openbox-3"
	mkdir -p "${_kiosk_theme_dir}" 2> "/dev/null" || true
	cat << OTM >| "${_kiosk_theme_dir}/themerc"
border.width: 2
border.color: ${_p_border}
padding.width: 8
padding.height: 6
window.handle.width: 2
window.client.padding.width: 0

window.active.border.color: ${_p_accent}
window.active.title.bg: flat solid
window.active.title.bg.color: ${_p_panel}
window.active.label.bg: parentrelative
window.active.label.text.color: ${_p_fg}
window.active.handle.bg: flat solid
window.active.handle.bg.color: ${_p_panel}
window.active.grip.bg: flat solid
window.active.grip.bg.color: ${_p_accent}
window.active.button.unpressed.bg: parentrelative
window.active.button.unpressed.image.color: ${_p_fg}
window.active.button.pressed.bg: flat solid
window.active.button.pressed.bg.color: ${_p_accent}
window.active.button.pressed.image.color: #ffffff
window.active.button.hover.bg: flat solid
window.active.button.hover.bg.color: ${_p_accent}
window.active.button.hover.image.color: #ffffff
window.active.button.disabled.bg: parentrelative
window.active.button.disabled.image.color: ${_p_hover}
window.inactive.border.color: ${_p_border}
window.inactive.title.bg: flat solid
window.inactive.title.bg.color: ${_p_bg}
window.inactive.label.bg: parentrelative
window.inactive.label.text.color: ${_p_muted}
window.inactive.handle.bg: flat solid
window.inactive.handle.bg.color: ${_p_bg}
window.inactive.grip.bg: flat solid
window.inactive.grip.bg.color: ${_p_panel}
window.inactive.button.unpressed.bg: parentrelative
window.inactive.button.unpressed.image.color: ${_p_muted}
window.inactive.button.pressed.bg: flat solid
window.inactive.button.pressed.bg.color: ${_p_border}
window.inactive.button.pressed.image.color: ${_p_fg}
window.inactive.button.hover.bg: flat solid
window.inactive.button.hover.bg.color: ${_p_border}
window.inactive.button.hover.image.color: ${_p_fg}
window.inactive.button.disabled.bg: parentrelative
window.inactive.button.disabled.image.color: ${_p_hover}
osd.border.width: 2
osd.border.color: ${_p_accent}
osd.bg: flat solid
osd.bg.color: ${_p_panel}
osd.label.bg: parentrelative
osd.label.text.color: ${_p_fg}
osd.hilight.bg: flat solid
osd.hilight.bg.color: ${_p_accent}
osd.unhilight.bg: flat solid
osd.unhilight.bg.color: ${_p_bg}
osd.button.unpressed.bg: flat solid
osd.button.unpressed.bg.color: ${_p_bg}
osd.button.unpressed.text.color: ${_p_fg}
osd.button.unpressed.border.color: ${_p_border}
osd.button.pressed.bg: flat solid
osd.button.pressed.bg.color: ${_p_accent}
osd.button.pressed.text.color: #ffffff
osd.button.pressed.border.color: ${_p_accent}
osd.button.focused.bg: flat solid
osd.button.focused.bg.color: ${_p_accent}
osd.button.focused.text.color: #ffffff
osd.button.focused.border.color: ${_p_accent}
menu.border.width: 2
menu.border.color: ${_p_border}
menu.title.bg: flat solid
menu.title.bg.color: ${_p_bg}
menu.title.text.color: ${_p_accent}
menu.items.bg: flat solid
menu.items.bg.color: ${_p_menu_bg}
menu.items.text.color: ${_p_fg}
menu.items.disabled.text.color: ${_p_hover}
menu.items.active.bg: flat solid
menu.items.active.bg.color: ${_p_accent}
menu.items.active.text.color: #ffffff
menu.separator.color: ${_p_border}
OTM

	local _is_terminal=0
	_is_terminal_app "${_app}" && _is_terminal=1

	local _run_dir="${XDG_RUNTIME_DIR:-/tmp}"
	[ -d "${_run_dir}" ] && [ -w "${_run_dir}" ] || _run_dir="/tmp"
	local _tabbar_script=""
	if command -v python3 > "/dev/null" 2>&1 && python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' > "/dev/null" 2>&1; then
		_tabbar_script="${_run_dir}/xgui-tabbar-$$.py"
		cat << 'EOF_TABBAR' >| "${_tabbar_script}"
import os, sys, shutil, subprocess
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    from gi.repository import GdkX11
except Exception:
    GdkX11 = None

try:
    from gi.repository import Pango
except Exception:
    Pango = None

try:
    from Xlib import display, X, Xatom
    import Xlib.protocol.event
    HAS_XLIB = True
except Exception:
    display = None
    X = None
    Xatom = None
    Xlib = None
    HAS_XLIB = False

BAR_H = 32

class XguiTabBar(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_accept_focus(False)
        self.set_focus_on_map(False)
        self.set_keep_above(True)
        self.set_title("xgui-tabbar")
        self.set_wmclass("xgui-tabbar", "xgui-tabbar")

        self.bar_h = BAR_H
        self.d = None
        self.screen_obj = None
        self.root = None
        self.wm_supports_struts = False

        if HAS_XLIB:
            try:
                self.d = display.Display()
                self.screen_obj = self.d.screen()
                self.root = self.screen_obj.root
                self.screen_w = self.screen_obj.width_in_pixels
                self.screen_h = self.screen_obj.height_in_pixels
            except Exception:
                self.d = None

        if self.d is None:
            gdk_screen = Gdk.Screen.get_default()
            self.screen_w = gdk_screen.get_width() if gdk_screen else 1920
            self.screen_h = gdk_screen.get_height() if gdk_screen else 1080
            if not shutil.which("wmctrl") and not shutil.which("xdotool"):
                sys.exit(0)

        self.set_default_size(self.screen_w, self.bar_h)
        self.set_size_request(self.screen_w, self.bar_h)
        self.move(0, 0)
        self.realize()

        self.self_xid = 0
        try:
            gdk_win = self.get_window()
            if gdk_win and hasattr(gdk_win, "get_xid"):
                self.self_xid = int(gdk_win.get_xid())
        except Exception:
            self.self_xid = 0

        self.self_xwin = None
        if self.d is not None:
            if self.self_xid:
                try:
                    self.self_xwin = self.d.create_resource_object("window", self.self_xid)
                except Exception:
                    self.self_xwin = None
            self.atom_net_supported = self.d.intern_atom("_NET_SUPPORTED")
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

            try:
                sup = self.root.get_full_property(self.atom_net_supported, Xatom.ATOM)
                if sup and sup.value:
                    sup_set = set(sup.value)
                    if self.atom_net_strut_partial in sup_set or self.atom_net_strut in sup_set:
                        self.wm_supports_struts = True
            except Exception:
                self.wm_supports_struts = False

        scheme = os.environ.get("XGUI_SCHEME", "dark").strip().lower()
        if scheme == "light":
            win_bg = "#f6f5f4"
            btn_bg = "#ffffff"
            border = "#cdc7c2"
            fg = "#241f31"
            muted = "#5e5c64"
            accent = "#3584e4"
            tab_active_bg = "#ffffff"
        else:
            win_bg = "#1e1e22"
            btn_bg = "#2b2b30"
            border = "#38383d"
            fg = "#ffffff"
            muted = "#9a9996"
            accent = "#3584e4"
            tab_active_bg = "#2b2b30"

        font_name = os.environ.get("XGUI_FONT", "JetBrainsMono Nerd Font")

        css_provider = Gtk.CssProvider()
        css = f"""
        window {{
            background-color: {win_bg};
            background-image: none;
            border-bottom: 1px solid {border};
            padding: 0;
            margin: 0;
        }}
        * {{
            font-family: "{font_name}", "JetBrainsMono Nerd Font", monospace;
            font-size: 11px;
        }}
        button {{
            background-image: none;
            box-shadow: none;
            text-shadow: none;
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
        }}
        button.inactive-tab {{
            background-color: {win_bg};
            background-image: none;
            color: {muted};
            border: 1px solid {border};
        }}
        button.inactive-tab:hover {{
            background-color: {btn_bg};
            background-image: none;
            color: {fg};
            border-color: {accent};
        }}
        button.active-tab {{
            background-color: {tab_active_bg};
            background-image: none;
            color: {fg};
            border: 1px solid {accent};
            border-top: 2px solid {accent};
            font-weight: bold;
        }}
        button.active-tab:hover {{
            background-color: {accent};
            background-image: none;
            color: #ffffff;
            border-color: {accent};
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
        self.positioned_single_wids = set()

        self.poll()
        GLib.timeout_add(200, self.poll)

    def _spawn(self, argv):
        try:
            subprocess.Popen(
                argv,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
                start_new_session=True,
            )
        except Exception:
            pass

    def set_struts(self, enable):
        if self.d is None or self.self_xwin is None:
            return
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
        if self.d is not None:
            try:
                ev = Xlib.protocol.event.ClientMessage(
                    window=xid,
                    client_type=self.atom_net_wm_state,
                    data=(32, [0, self.atom_max_vert, self.atom_max_horz, 1, 0])
                )
                self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
                self.d.sync()
                return
            except Exception:
                pass
        if shutil.which("wmctrl"):
            self._spawn(["wmctrl", "-i", "-r", str(xid), "-b", "remove,maximized_vert,maximized_horz"])

    def maximize_window(self, xid):
        if self.d is not None:
            try:
                ev = Xlib.protocol.event.ClientMessage(
                    window=xid,
                    client_type=self.atom_net_wm_state,
                    data=(32, [1, self.atom_max_vert, self.atom_max_horz, 1, 0])
                )
                self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
                self.d.sync()
                return
            except Exception:
                pass
        if shutil.which("wmctrl"):
            self._spawn(["wmctrl", "-i", "-r", str(xid), "-b", "add,maximized_vert,maximized_horz"])

    def maximize_to_bounds(self, xid, y, w, h, maximize_hint=True):
        self.unmaximize_window(xid)
        if self.d is not None:
            try:
                w_obj = self.d.create_resource_object("window", xid)
                w_obj.configure(x=0, y=y, width=w, height=h)
                self.d.sync()
            except Exception:
                pass
            if maximize_hint:
                self.maximize_window(xid)
            return
        if shutil.which("wmctrl"):
            if maximize_hint:
                self.maximize_window(xid)
            else:
                self._spawn(["wmctrl", "-i", "-r", str(xid), "-e", f"0,0,{y},{w},{h}"])
        elif shutil.which("xdotool"):
            self._spawn(["xdotool", "windowmove", str(xid), "0", str(y)])
            self._spawn(["xdotool", "windowsize", str(xid), str(w), str(h)])

    def activate_window(self, xid):
        if self.d is not None:
            try:
                ev = Xlib.protocol.event.ClientMessage(
                    window=xid,
                    client_type=self.atom_net_active,
                    data=(32, [1, X.CurrentTime, 0, 0, 0])
                )
                self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
                w_obj = self.d.create_resource_object("window", xid)
                w_obj.raise_window()
                self.d.sync()
                return
            except Exception:
                pass
        if shutil.which("wmctrl"):
            self._spawn(["wmctrl", "-i", "-a", str(xid)])
        elif shutil.which("xdotool"):
            self._spawn(["xdotool", "windowactivate", str(xid)])

    def get_title(self, xid):
        if self.d is not None:
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
        if shutil.which("xdotool"):
            try:
                res = subprocess.run(["xdotool", "getwindowname", str(xid)], capture_output=True, text=True)
                t = (res.stdout or "").strip()
                if t:
                    return t
            except Exception:
                pass
        return "Window"

    def is_normal(self, xid):
        if xid == self.self_xid:
            return False
        if self.d is None:
            return True
        try:
            xwin = self.d.create_resource_object("window", xid)
            attrs = xwin.get_attributes()
            if attrs and getattr(attrs, "override_redirect", False):
                return False
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

    def _list_windows_fallback(self):
        normal = []
        titles = {}
        active_xid = None
        if shutil.which("wmctrl"):
            try:
                res = subprocess.run(["wmctrl", "-l"], capture_output=True, text=True)
                for line in (res.stdout or "").splitlines():
                    parts = line.split(None, 3)
                    if len(parts) >= 4:
                        wid = int(parts[0], 16)
                        if wid == self.self_xid:
                            continue
                        normal.append(wid)
                        titles[wid] = parts[3].strip() or "Window"
            except Exception:
                pass
        elif shutil.which("xdotool"):
            try:
                res = subprocess.run(["xdotool", "search", "--onlyvisible", "--maxdepth", "2", "--name", ""], capture_output=True, text=True)
                for line in (res.stdout or "").splitlines():
                    s = line.strip()
                    if s.isdigit():
                        wid = int(s)
                        if wid != self.self_xid:
                            normal.append(wid)
            except Exception:
                pass
        if shutil.which("xdotool"):
            try:
                res = subprocess.run(["xdotool", "getactivewindow"], capture_output=True, text=True)
                s = (res.stdout or "").strip()
                if s.isdigit():
                    active_xid = int(s)
            except Exception:
                pass
        return normal, active_xid, titles

    def poll(self):
        titles_cache = {}
        all_xids = []
        active_xid = None

        if self.d is not None:
            try:
                prop = self.root.get_full_property(self.atom_net_client_list, Xatom.WINDOW)
                all_xids = list(prop.value) if prop and prop.value else []
            except Exception:
                all_xids = []
            try:
                act_prop = self.root.get_full_property(self.atom_net_active, Xatom.WINDOW)
                if act_prop and act_prop.value:
                    active_xid = act_prop.value[0]
            except Exception:
                active_xid = None

        if not all_xids:
            fb_xids, fb_active, titles_cache = self._list_windows_fallback()
            if fb_xids:
                all_xids = fb_xids
            elif self.d is not None:
                try:
                    tree = self.root.query_tree()
                    for child in tree.children:
                        cid = getattr(child, "id", None)
                        if not cid or cid == self.self_xid:
                            continue
                        attrs = child.get_attributes()
                        if attrs and attrs.map_state == X.IsViewable and not attrs.override_redirect:
                            all_xids.append(cid)
                except Exception:
                    pass
            if active_xid is None:
                active_xid = fb_active

        normal_windows = [x for x in all_xids if self.is_normal(x)]
        self.positioned_single_wids.intersection_update(normal_windows)

        if len(normal_windows) < 2:
            if self.is_bar_visible:
                self.hide()
                self.set_struts(False)
                self.is_bar_visible = False
                self.positioned_wids.clear()
                self.positioned_single_wids.clear()
                self.last_windows = []
                self.last_active = None
            for w in normal_windows:
                if w not in self.positioned_single_wids:
                    self.maximize_to_bounds(w, 0, self.screen_w, self.screen_h, maximize_hint=True)
                    self.positioned_single_wids.add(w)
            return True

        self.positioned_single_wids.clear()
        self.positioned_wids.intersection_update(normal_windows)

        if not self.is_bar_visible:
            self.set_struts(True)
            self.move(0, 0)
            self.resize(self.screen_w, self.bar_h)
            self.show_all()
            if self.self_xwin is not None:
                try:
                    self.self_xwin.raise_window()
                    self.d.sync()
                except Exception:
                    pass
            self.is_bar_visible = True

        for w in normal_windows:
            if w not in self.positioned_wids:
                self.maximize_to_bounds(w, self.bar_h, self.screen_w, self.screen_h - self.bar_h, maximize_hint=self.wm_supports_struts)
                self.positioned_wids.add(w)

        if normal_windows != self.last_windows or active_xid != self.last_active:
            self.last_windows = list(normal_windows)
            self.last_active = active_xid
            for child in self.box.get_children():
                self.box.remove(child)

            for w in normal_windows:
                title = titles_cache.get(w) or self.get_title(w)
                btn = Gtk.Button()
                lbl = Gtk.Label(label=title)
                if Pango is not None:
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


	local _sh="$(_detect_enabled_shell)"
	local _vt_arg="$(_resolve_vt_arg)"
	local _xinit_script="${_run_dir}/xinit-gui-$$.sh"
	cat << EOF >| "${_xinit_script}"
#!/usr/bin/env sh
unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1
export vblank_mode=3
export __GL_SYNC_TO_VBLANK=1
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-GNOME}"
export DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}"
export SAL_USE_VCLPLUGIN="gtk3"
export GTK_THEME="${_gtk_theme}"
export GTK_APPLICATION_PREFER_DARK_THEME="${_prefer_dark}"
export ADW_DEBUG_COLOR_SCHEME="${ADW_DEBUG_COLOR_SCHEME:-prefer-dark}"

if [ -z "\${ENVIRONMENT_SESSION_WRAPPED:-}" ]; then
	export ENVIRONMENT_SESSION_WRAPPED=1
	_ck=0
	[ "\$(uname -s)" = "FreeBSD" ] && command -v ck-launch-session > "/dev/null" 2>&1 && _ck=1
	if command -v dbus-run-session > "/dev/null" 2>&1; then
		if [ "\${_ck}" -eq 1 ]; then
			exec dbus-run-session -- ck-launch-session "\$0" "\$@"
		else
			exec dbus-run-session -- "\$0" "\$@"
		fi
	elif command -v dbus-launch > "/dev/null" 2>&1; then
		if [ "\${_ck}" -eq 1 ]; then
			exec dbus-launch --exit-with-session ck-launch-session "\$0" "\$@"
		else
			exec dbus-launch --exit-with-session "\$0" "\$@"
		fi
	elif [ "\${_ck}" -eq 1 ]; then
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
export vblank_mode=3
export __GL_SYNC_TO_VBLANK=1
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-GNOME}"
export DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}"
export SAL_USE_VCLPLUGIN="gtk3"
export GTK_CSD=0
export GTK_THEME="${_gtk_theme}"
export GTK_APPLICATION_PREFER_DARK_THEME="${_prefer_dark}"
export ADW_DEBUG_COLOR_SCHEME="${ADW_DEBUG_COLOR_SCHEME:-prefer-dark}"
export QT_QPA_PLATFORMTHEME="\${QT_QPA_PLATFORMTHEME:-qt6ct}"
export XCURSOR_THEME="${_valid_theme}"
export XCURSOR_SIZE="${_cur_size}"
export MOZ_GTK_TITLEBAR_DECORATION="system"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

if [ -f "\${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "\${HOME}/.Xresources" > "/dev/null" 2>&1 || true
fi
if command -v xrdb > "/dev/null" 2>&1; then
	printf "Xcursor.theme: %s\nXcursor.size: %s\n" "${_valid_theme}" "${_cur_size}" | xrdb -merge - > "/dev/null" 2>&1 || true
fi
command -v xsetroot > "/dev/null" 2>&1 && xsetroot -solid "${_p_bg}" -cursor_name left_ptr > "/dev/null" 2>&1 || true

if command -v setxkbmap > "/dev/null" 2>&1; then
	setxkbmap -model abnt2 -layout br -option numpad:mac > "/dev/null" 2>&1 || true
fi
if command -v xset > "/dev/null" 2>&1; then
	xset r rate 200 50 > "/dev/null" 2>&1 || true
	xset led named "Num Lock" > "/dev/null" 2>&1 || true
fi
if command -v numlockx > "/dev/null" 2>&1; then
	numlockx on > "/dev/null" 2>&1 || true
fi

if command -v gnome-keyring-daemon > "/dev/null" 2>&1; then
	eval "\$(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2>> "${_persistent_kiosk_log}")" > "/dev/null" 2>&1 || true
	[ -n "\${SSH_AUTH_SOCK:-}" ] && export SSH_AUTH_SOCK
	if command -v dbus-update-activation-environment > "/dev/null" 2>&1; then
		dbus-update-activation-environment --systemd SSH_AUTH_SOCK DISPLAY XDG_CURRENT_DESKTOP >> "${_persistent_kiosk_log}" 2>&1 || \
		dbus-update-activation-environment SSH_AUTH_SOCK DISPLAY XDG_CURRENT_DESKTOP >> "${_persistent_kiosk_log}" 2>&1 || true
	fi
fi

if command -v xrandr > "/dev/null" 2>&1; then
	xrandr 2> "/dev/null" | grep " connected" | cut -d ' ' -f1 | while IFS= read -r _out; do
		[ -n "\${_out}" ] && xrandr --output "\${_out}" --set "TearFree" "on" > "/dev/null" 2>&1 || true
	done
fi

if command -v xsettingsd > "/dev/null" 2>&1; then
	_xsettings_cfg="${_run_dir}/xsettingsd-gui-$$.conf"
	cat << EOF_XSET >| "\${_xsettings_cfg}"
Net/ThemeName "${_gtk_theme}"
Net/IconThemeName "${_icon_theme}"
Gtk/ApplicationPreferDarkTheme ${_prefer_dark}
Gtk/CursorThemeName "${_valid_theme}"
Gtk/CursorThemeSize ${_cur_size}
Gtk/FontName "${_ui_font}"
EOF_XSET
	xsettingsd -c "\${_xsettings_cfg}" >| "${_log_dir}/xsettingsd-kiosk.log" 2>&1 &
fi

if [ "\${X11_NO_COMPOSITOR:-0}" != "1" ]; then
	if command -v picom > "/dev/null" 2>&1; then
		: >| "${_log_dir}/picom-kiosk.log" 2> "/dev/null" || true
		{ pgrep -x picom > "/dev/null" 2>&1 || pkill -0 -x picom > "/dev/null" 2>&1; } || \
			picom --backend glx --vsync --no-use-damage -b --log-file "${_log_dir}/picom-kiosk.log" > "/dev/null" 2>&1 || \
			picom --backend xrender --vsync --no-use-damage -b --log-file "${_log_dir}/picom-kiosk.log" > "/dev/null" 2>&1 || true
	elif command -v xcompmgr > "/dev/null" 2>&1; then
		{ pgrep -x xcompmgr > "/dev/null" 2>&1 || pkill -0 -x xcompmgr > "/dev/null" 2>&1; } || \
			xcompmgr -c -C -b >| "${_log_dir}/xcompmgr-kiosk.log" 2>&1 || true
	fi
fi

if [ -n "${_tabbar_script}" ] && [ -f "${_tabbar_script}" ]; then
	env GDK_BACKEND=x11 XGUI_FONT="${_ui_font}" XGUI_SCHEME="${_scheme}" python3 "${_tabbar_script}" >| "${_log_dir}/xgui-tabbar.log" 2>&1 &
fi

_wm_log="${_log_dir}/xorg-wm-kiosk.log"
: >| "\${_wm_log}" 2> "/dev/null" || true
case "${_target_wm}" in
	openbox)
		_ob_cfg="${_run_dir}/openbox-gui-$$.xml"
		cat << XOB >| "\${_ob_cfg}"
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
		openbox --config-file "\${_ob_cfg}" >> "\${_wm_log}" 2>&1 &
		;;
	cwm)
		_cwm_cfg="${_run_dir}/cwm-gui-$$.conf"
		cat << CWM_EOF >| "\${_cwm_cfg}"
borderwidth 2
fontname "${_ui_font}:pixelsize=12:bold"
color activeborder "${_p_accent}"
color inactiveborder "${_p_border}"
color groupborder "${_p_accent}"
color urgencyborder "${_p_urgent}"
color menubg "${_p_bg}"
color menufg "${_p_fg}"
color font "${_p_fg}"
color selfont "#ffffff"
sticky yes
gap 0 0 0 0
ignore xgui-tabbar
autogroup 1 "xterm,XTerm"
autogroup 1 "emacs,Emacs"
bind-key M-Tab window-cycle
bind-key 4-Tab window-cycle
bind-key 4-m window-maximize
bind-key 4-q window-close
bind-key M-F4 window-close
bind-key 4S-q quit
CWM_EOF
		cwm -c "\${_cwm_cfg}" >> "\${_wm_log}" 2>&1 &
		;;
	dwm)
		dwm >> "\${_wm_log}" 2>&1 &
		;;
	fvwm3|fvwm)
		_fvwm_cfg="${_run_dir}/fvwm-gui-$$.cfg"
		cat << FVWM_EOF >| "\${_fvwm_cfg}"
EdgeThickness 0
Colorset 1 bg ${_p_bg}, fg ${_p_fg}
Colorset 2 bg ${_p_accent}, fg #ffffff
Style "*" NoTitle, BorderWidth 0, HandleWidth 0, Colorset 1, HilightColorset 2, Maximizable
Style "xgui-tabbar" NoTitle, BorderWidth 0, HandleWidth 0, StaysOnTop, Sticky, WindowListSkip, NeverFocus
Key Tab A M Next (CurrentPage, AcceptsFocus) Focus
Key Tab A 4 Next (CurrentPage, AcceptsFocus) Focus
Key q A 4 Close
Key F4 A M Close
FVWM_EOF
		${_target_wm} -f "\${_fvwm_cfg}" >> "\${_wm_log}" 2>&1 &
		;;
	fluxbox)
		_fb_dir="${_run_dir}/fluxbox-gui-$$"
		mkdir -p "\${_fb_dir}" 2> "/dev/null" || true
		cat << FB_KEYS >| "\${_fb_dir}/keys"
Mod1 Tab :NextWindow
Mod4 Tab :NextWindow
Mod4 q :Close
Mod1 F4 :Close
FB_KEYS
		cat << FB_INIT >| "\${_fb_dir}/init"
session.screen0.toolbar.visible: false
session.screen0.tabs.intitlebar: false
session.screen0.defaultDeco: NONE
session.screen0.maxDisableMove: false
session.keyFile: \${_fb_dir}/keys
FB_INIT
		fluxbox -rc "\${_fb_dir}/init" >> "\${_wm_log}" 2>&1 &
		;;
	icewm)
		_ice_dir="${_run_dir}/icewm-gui-$$"
		mkdir -p "\${_ice_dir}" 2> "/dev/null" || true
		cat << ICE_PREF >| "\${_ice_dir}/preferences"
ShowTaskBar=0
TaskBarShowWindows=0
BorderSizeX=0
BorderSizeY=0
TitleBarHeight=0
ColorActiveTitleBar="${_p_panel}"
ColorNormalTitleBar="${_p_bg}"
ColorActiveBorder="${_p_accent}"
ColorNormalBorder="${_p_border}"
ICE_PREF
		ICEWM_PRIVCFG="\${_ice_dir}" icewm >> "\${_wm_log}" 2>&1 &
		;;
	jwm)
		_jwm_cfg="${_run_dir}/jwm-gui-$$.rc"
		cat << JWM_RC >| "\${_jwm_cfg}"
<JWM>
  <Desktops width="1" height="1"/>
  <WindowStyle>
    <Width>0</Width>
    <Height>0</Height>
    <Active><Background>${_p_panel}</Background><Outline>${_p_accent}</Outline></Active>
    <Inactive><Background>${_p_bg}</Background><Outline>${_p_border}</Outline></Inactive>
  </WindowStyle>
  <Group><Option>maximized</Option><Option>noborder</Option><Option>notitle</Option></Group>
  <Key mask="A" key="Tab">next</Key>
  <Key mask="4" key="Tab">next</Key>
  <Key mask="4" key="q">close</Key>
  <Key mask="A" key="F4">close</Key>
</JWM>
JWM_RC
		jwm -f "\${_jwm_cfg}" >> "\${_wm_log}" 2>&1 &
		;;
	pekwm)
		_pek_cfg="${_run_dir}/pekwm-gui-$$.cfg"
		cat << PEK_CFG >| "\${_pek_cfg}"
Files {
    Keys = "~/.pekwm/keys"
    Mouse = "~/.pekwm/mouse"
    Menu = "~/.pekwm/menu"
    Start = "~/.pekwm/start"
    AutoProps = "~/.pekwm/autoproperties"
    Theme = "~/.pekwm/themes/default"
}
PEK_CFG
		pekwm --config "\${_pek_cfg}" >> "\${_wm_log}" 2>&1 &
		;;
	twm)
		twm >> "\${_wm_log}" 2>&1 &
		;;
	matchbox|matchbox-window-manager)
		matchbox-window-manager -use_titlebar no >> "\${_wm_log}" 2>&1 &
		;;
	*)
		if command -v openbox > "/dev/null" 2>&1; then
			openbox >> "\${_wm_log}" 2>&1 &
		elif command -v matchbox-window-manager > "/dev/null" 2>&1; then
			matchbox-window-manager -use_titlebar no >> "\${_wm_log}" 2>&1 &
		elif command -v cwm > "/dev/null" 2>&1; then
			cwm >> "\${_wm_log}" 2>&1 &
		elif command -v fvwm3 > "/dev/null" 2>&1; then
			fvwm3 >> "\${_wm_log}" 2>&1 &
		elif command -v fvwm > "/dev/null" 2>&1; then
			fvwm >> "\${_wm_log}" 2>&1 &
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
	[ -n "\${_emacs_kiosk_bin}" ] || exit 127
	exec "\${_emacs_kiosk_bin}" -mm "\$@"
else
	exec "\${_target_bin}" "\$@"
fi
EOF
	chmod 0755 "${_xinit_script}" 2> "/dev/null" || true

	local _server_auth="${_run_dir}/.serverauth-gui-$$"
	local _xinit_ret=0
	local _use_auth=0

	if _kiosk_has_exec_bin "xauth"; then
		( umask 0077; rm -f "${_server_auth}"; : >| "${_server_auth}"; [ -f "${HOME}/.Xauthority" ] || : >| "${HOME}/.Xauthority" ) 2> "/dev/null" || true
		local _cookie=""
		if _kiosk_has_exec_bin "mcookie"; then
			_cookie="$(command mcookie 2> "/dev/null" || true)"
		elif [ -r "/dev/urandom" ] && _kiosk_has_exec_bin "hexdump"; then
			_cookie="$(command dd if=/dev/urandom bs=16 count=1 2> "/dev/null" | command hexdump -e '16/1 "%02x"' 2> "/dev/null" || true)"
		elif [ -r "/dev/urandom" ] && _kiosk_has_exec_bin "od"; then
			_cookie="$(command dd if=/dev/urandom bs=16 count=1 2> "/dev/null" | command od -An -tx1 2> "/dev/null" | tr -d ' \n' || true)"
		fi
		if [ -n "${_cookie}" ]; then
			if command xauth -q -f "${_server_auth}" add "${_display}" . "${_cookie}" > "/dev/null" 2>&1; then
				command xauth -q add "${_display}" . "${_cookie}" > "/dev/null" 2>&1 || true
				_use_auth=1
			fi
		fi
	fi

	if _kiosk_has_exec_bin "xinit" && [ "${_use_auth}" -eq 1 ]; then
		if [ -n "${_vt_arg}" ]; then
			command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" "${_vt_arg}" "-auth" "${_server_auth}" >> "${_persistent_kiosk_log}" 2>&1
		else
			command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" "-auth" "${_server_auth}" >> "${_persistent_kiosk_log}" 2>&1
		fi
		_xinit_ret=$?
	elif _kiosk_has_exec_bin "startx"; then
		if [ -n "${_vt_arg}" ]; then
			command startx "${_xinit_script}" "${_app}" "$@" -- "${_display}" "${_vt_arg}" >> "${_persistent_kiosk_log}" 2>&1
		else
			command startx "${_xinit_script}" "${_app}" "$@" -- "${_display}" >> "${_persistent_kiosk_log}" 2>&1
		fi
		_xinit_ret=$?
	elif _kiosk_has_exec_bin "xinit"; then
		if [ -n "${_vt_arg}" ]; then
			command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" "${_vt_arg}" >> "${_persistent_kiosk_log}" 2>&1
		else
			command xinit "${_xinit_script}" "${_app}" "$@" -- "${_display}" >> "${_persistent_kiosk_log}" 2>&1
		fi
		_xinit_ret=$?
	else
		_xinit_ret=1
	fi
	[ "${_xinit_ret}" -eq 127 ] && _xinit_ret=1

	rm -f "${_server_auth}" "${_xinit_script}" "${_tabbar_script}" \
		"${_run_dir}/openbox-gui-$$.xml" "${_run_dir}/cwm-gui-$$.conf" \
		"${_run_dir}/fvwm-gui-$$.cfg" "${_run_dir}/jwm-gui-$$.rc" \
		"${_run_dir}/pekwm-gui-$$.cfg" "${_run_dir}/xsettingsd-gui-$$.conf" 2> "/dev/null" || true
	rm -rf "${_run_dir}/fluxbox-gui-$$" "${_run_dir}/icewm-gui-$$" 2> "/dev/null" || true
	_kiosk_has_exec_bin "xauth" && command xauth -q remove "${_display}" > "/dev/null" 2>&1 || true
	[ "${_had_display}" -eq 0 ] && unset DISPLAY
	_freebsd_vt_bounce > "/dev/null" 2>&1 || true
	_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"

	if [ "${_xinit_ret}" -ne 0 ] && [ "${_xinit_ret}" -ne 127 ]; then
		_ui_err "Lançador Xorg encerrou com erro (código ${_xinit_ret}). Log: ${_persistent_kiosk_log}"
	fi
	return "${_xinit_ret}"
}
alias graphical-launcher-x11="graphical_launcher_x11" xgui="graphical_launcher_x11"

graphical_launcher() {
	_kiosk_ensure_session || return 1
	local _ifs_was_set=0 _saved_ifs=""
	if [ "${IFS+set}" = "set" ]; then
		_ifs_was_set=1
		_saved_ifs="${IFS}"
	fi
	local _prev_probe="${_SHELL_DISPATCH_PROBE:-}"
	if ! _kiosk_has_forced_backend "$@"; then
		export _SHELL_DISPATCH_PROBE=1
	fi
	_dispatch_display_server "graphical-launcher" "$@"
	local _ret=$?
	if [ -n "${_prev_probe}" ]; then
		export _SHELL_DISPATCH_PROBE="${_prev_probe}"
	else
		unset _SHELL_DISPATCH_PROBE
	fi
	_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
	return "${_ret}"
}
alias graphical-launcher="graphical_launcher" gui="graphical_launcher"

### --------------------------------
### EMACS OS WINDOW MANAGERS
### --------------------------------
emacs_window_manager_wayland() {
	_kiosk_ensure_session || return 1
	local _ifs_was_set=0 _saved_ifs=""
	if [ "${IFS+set}" = "set" ]; then
		_ifs_was_set=1
		_saved_ifs="${IFS}"
	fi
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

	local _ewm_emacs_bin="$(_kiosk_resolve_exec_bin "emacs-pgtk" || _kiosk_resolve_exec_bin "emacs" || true)"
	if [ -z "${_ewm_emacs_bin}" ]; then
		if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
			_ui_err "emacs não encontrado."
		fi
		unset EMACS_OS_MODE
		_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
		return 127
	fi

	local _ewm_so=""
	if [ -f "${HOME}/.local/lib/libewm_core.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm_core.so"
	elif [ -f "${HOME}/.local/lib/libewm.so" ]; then
		_ewm_so="${HOME}/.local/lib/libewm.so"
	fi

	local _emacs_ret=0
	if [ -n "${_ewm_so}" ]; then
		if ! _preflight_wayland "${_ewm_emacs_bin}"; then
			if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
				_ui_err "Pré-requisitos Wayland (/dev/dri/card* ou compositor) indisponíveis para EWM."
			fi
			unset EMACS_OS_MODE
			_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
			return 127
		fi
		unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
		export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1
		export EWM_MODULE_PATH="${_ewm_so}"
		export EMACSLOADPATH="${HOME}/.local/share/emacs/site-lisp/ewm:${EMACSLOADPATH:-}:"
		export RUST_LOG="${RUST_LOG:-ewm=info,ewm_core::dbus_login1=error,ewm_core::xwayland::satellite=error,smithay=warn}"
		rm -f "${XDG_RUNTIME_DIR:-/tmp}/emacs/ewm" 2> "/dev/null" || true

		local _log_dir="$(_get_shell_log_dir)"
		local _ewm_log="${_log_dir}/ewm-wayland.log"
		mkdir -p "${_log_dir}" 2> "/dev/null" || true
		: >| "${_ewm_log}" 2> "/dev/null" || true
		unset WAYLAND_DISPLAY DISPLAY
		_kiosk_exec_wayland_logged "${_ewm_log}" "${_ewm_emacs_bin}" --fg-daemon=ewm -L "${HOME}/.local/share/emacs/site-lisp/ewm" -l ewm -f ewm-start-module "$@"
		_emacs_ret=$?
		[ "${_emacs_ret}" -eq 127 ] && _emacs_ret=1

		if [ "${_emacs_ret}" -ne 0 ]; then
			_ui_err "EWM Wayland encerrou com erro (código ${_emacs_ret}). Log: ${_ewm_log}"
		fi
	else
		if [ -n "${_flavor}" ]; then
			graphical_launcher_wayland "--${_flavor}" emacs "$@"
		else
			graphical_launcher_wayland emacs "$@"
		fi
		_emacs_ret=$?
	fi

	unset EMACS_OS_MODE
	_restore_tty_cursor > "/dev/null" 2>&1 || true
	_freebsd_vt_bounce > "/dev/null" 2>&1 || true
	_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
	return "${_emacs_ret}"
}
alias emacs-window-manager-wayland="emacs_window_manager_wayland" wewm="emacs_window_manager_wayland" wew="emacs_window_manager_wayland"

emacs_window_manager_x11() {
	_kiosk_ensure_session || return 1
	local _ifs_was_set=0 _saved_ifs=""
	if [ "${IFS+set}" = "set" ]; then
		_ifs_was_set=1
		_saved_ifs="${IFS}"
	fi
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

	{ _kiosk_has_exec_bin "xinit" || _kiosk_has_exec_bin "startx"; } || {
		if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
			_ui_err "xinit ou startx não encontrado para EWM Xorg."
		fi
		_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
		return 127
	}
	{ _kiosk_has_exec_bin "Xorg" || _kiosk_has_exec_bin "X"; } || {
		if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
			_ui_err "Servidor Xorg não encontrado para EWM."
		fi
		_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
		return 127
	}

	local _emacs_bin="$(_kiosk_resolve_exec_bin "emacs-gtk+x11" || _kiosk_resolve_exec_bin "emacs-x11" || _kiosk_resolve_exec_bin "emacs-lucid" || _kiosk_resolve_exec_bin "emacs-gtk" || _kiosk_resolve_exec_bin "emacs-nw" || _kiosk_resolve_exec_bin "emacs" || true)"
	if [ -z "${_emacs_bin}" ]; then
		if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
			_ui_err "emacs não encontrado."
		fi
		_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
		return 127
	fi

	export EMACS_OS_MODE="x11"
	export _X11_FLAVOR_OVERRIDE="${_flavor}"
	_setup_cursor_env "${_flavor}"

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	_exec_x11 "${_emacs_bin}" -mm "$@"
	local _ret=$?
	unset _X11_FLAVOR_OVERRIDE EMACS_OS_MODE
	_restore_tty_cursor > "/dev/null" 2>&1 || true
	_freebsd_vt_bounce > "/dev/null" 2>&1 || true
	_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
	return "${_ret}"
}
alias emacs-window-manager-x11="emacs_window_manager_x11" xewm="emacs_window_manager_x11" xew="emacs_window_manager_x11" exwm="emacs_window_manager_x11" exw="emacs_window_manager_x11"

emacs_window_manager() {
	_kiosk_ensure_session || return 1
	local _ifs_was_set=0 _saved_ifs=""
	if [ "${IFS+set}" = "set" ]; then
		_ifs_was_set=1
		_saved_ifs="${IFS}"
	fi
	local _prev_probe="${_SHELL_DISPATCH_PROBE:-}"
	if ! _kiosk_has_forced_backend "$@"; then
		export _SHELL_DISPATCH_PROBE=1
	fi
	_dispatch_display_server "emacs-window-manager" "$@"
	local _ret=$?
	if [ -n "${_prev_probe}" ]; then
		export _SHELL_DISPATCH_PROBE="${_prev_probe}"
	else
		unset _SHELL_DISPATCH_PROBE
	fi
	_kiosk_restore_ifs "${_ifs_was_set}" "${_saved_ifs}"
	return "${_ret}"
}
alias emacs-window-manager="emacs_window_manager" ewm="emacs_window_manager" ew="emacs_window_manager"
_SHELL_DESKTOP_KIOSK_LOADED=1
