# ----------------------------------------------------------------
# Library: Desktop Session, Display Server & Input Orchestration
# ----------------------------------------------------------------

### --------------------------------
### Console & Cursor Helpers
### --------------------------------
_enable_numlock_console() {
	if [ -t 0 ] || [ -c "/dev/tty" ]; then
		command -v setleds > "/dev/null" 2>&1 && setleds -D +num 2> "/dev/null" || true
		command -v kbdcontrol > "/dev/null" 2>&1 && kbdcontrol -l num 2> "/dev/null" || true
	fi
}

_setup_cursor_env() {
	export XCURSOR_PATH="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
	export WLR_NO_HARDWARE_CURSORS=1

	local _candidate="" _found_theme="" _p=""
	local _de_hint="${XDG_CURRENT_DESKTOP:-$(_detect_desktop_theme 2> "/dev/null" || true)}"
	local _primary_cursor="Adwaita" _secondary_cursor="breeze_cursors"
	case "${_de_hint}" in
		*[Kk][Dd][Ee]*|*[Pp]lasma*) _primary_cursor="breeze_cursors"; _secondary_cursor="Adwaita" ;;
	esac

	for _candidate in "${XCURSOR_THEME:-}" "${_primary_cursor}" "${_secondary_cursor}" "Bibata-Modern-Classic" "default"; do
		[ -z "${_candidate}" ] && continue
		for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
			if [ -d "${_p}/${_candidate}/cursors" ]; then
				_found_theme="${_candidate}"
				break 2
			fi
		done
	done

	[ -z "${_found_theme}" ] && _found_theme="default"
	local _target_size="${XCURSOR_SIZE:-24}"
	export XCURSOR_THEME="${_found_theme}" XCURSOR_SIZE="${_target_size}"

	mkdir -p "${HOME}/.icons/default" 2> "/dev/null" || true
	printf '[Icon Theme]\nInherits=%s\n' "${_found_theme}" >| "${HOME}/.icons/default/index.theme" 2> "/dev/null" || true

	if [ -n "${DISPLAY:-}" ] && command -v xrdb > "/dev/null" 2>&1; then
		printf "Xcursor.theme: %s\nXcursor.size: %s\n" "${_found_theme}" "${_target_size}" | xrdb -merge - 2> "/dev/null" || true
	fi
}

### --------------------------------
### Wayland & X11 Session Env
### --------------------------------
_wayland_session_env() {
	local _target_flavor="${1:-}"
	[ -z "${XDG_RUNTIME_DIR:-}" ] && export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
	[ ! -d "${XDG_RUNTIME_DIR}" ] && mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"

	export XKB_DEFAULT_LAYOUT="br" XKB_DEFAULT_MODEL="abnt2" XKB_DEFAULT_OPTIONS="numpad:mac"
	export WLR_KEYBOARD_REPEAT_DELAY=200 WLR_KEYBOARD_REPEAT_RATE=50
	export GDK_BACKEND="wayland,x11,*" CLUTTER_BACKEND="wayland" SDL_VIDEODRIVER="wayland"
	export MOZ_ENABLE_WAYLAND=1 ELECTRON_OZONE_PLATFORM_HINT="wayland"
	export GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DEBUG_COLOR_SCHEME="prefer-dark"

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	export GTK_THEME="$(_resolve_gtk_theme "${_theme_flavor}")"
	export QT_QPA_PLATFORM="wayland;xcb"
	case "${_theme_flavor}" in
		kde)
			export XDG_CURRENT_DESKTOP="KDE" QT_QPA_PLATFORMTHEME="kde" QT_STYLE_OVERRIDE="Breeze" XCURSOR_THEME="breeze_cursors"
			;;
		*)
			case "${_theme_flavor}" in
				cinnamon) export XDG_CURRENT_DESKTOP="X-Cinnamon" ;;
				mate)     export XDG_CURRENT_DESKTOP="MATE" ;;
				xfce)     export XDG_CURRENT_DESKTOP="XFCE" ;;
				*)        export XDG_CURRENT_DESKTOP="GNOME" ;;
			esac
			unset QT_STYLE_OVERRIDE 2> "/dev/null" || true
			if [ -f "${HOME}/.config/qt6ct/qt6ct.conf" ] || command -v qt6ct > "/dev/null" 2>&1; then
				export QT_QPA_PLATFORMTHEME="qt6ct"
			elif [ "${XDG_CURRENT_DESKTOP}" = "GNOME" ]; then
				export QT_QPA_PLATFORMTHEME="gnome"
			else
				export QT_QPA_PLATFORMTHEME="gtk3"
			fi
			export XCURSOR_THEME="Adwaita"
			;;
	esac

	_setup_cursor_env
	_enable_numlock_console
}

_x11_session_env() {
	local _target_flavor="${1:-}"
	unset WAYLAND_DISPLAY
	export XDG_SESSION_TYPE="x11" GDK_BACKEND="x11" QT_QPA_PLATFORM="xcb" SDL_VIDEODRIVER="x11" CLUTTER_BACKEND="x11"
	export XORG_RUN_AS_USER_OK=1 XKB_DEFAULT_LAYOUT="br" XKB_DEFAULT_MODEL="abnt2" XKB_DEFAULT_OPTIONS="numpad:mac"
	export GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DEBUG_COLOR_SCHEME="prefer-dark"

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	export GTK_THEME="$(_resolve_gtk_theme "${_theme_flavor}")"
	case "${_theme_flavor}" in
		kde)
			export XDG_CURRENT_DESKTOP="KDE" QT_QPA_PLATFORMTHEME="kde" QT_STYLE_OVERRIDE="Breeze" XCURSOR_THEME="breeze_cursors"
			;;
		*)
			case "${_theme_flavor}" in
				cinnamon) export XDG_CURRENT_DESKTOP="X-Cinnamon" ;;
				mate)     export XDG_CURRENT_DESKTOP="MATE" ;;
				xfce)     export XDG_CURRENT_DESKTOP="XFCE" ;;
				*)        export XDG_CURRENT_DESKTOP="GNOME" ;;
			esac
			unset QT_STYLE_OVERRIDE 2> "/dev/null" || true
			if [ -f "${HOME}/.config/qt6ct/qt6ct.conf" ] || command -v qt6ct > "/dev/null" 2>&1; then
				export QT_QPA_PLATFORMTHEME="qt6ct"
			else
				export QT_QPA_PLATFORMTHEME="gtk3"
			fi
			export XCURSOR_THEME="Adwaita"
			;;
	esac

	local _xres_target="${HOME}/.Xresources" _xres_src=""
	if [ -f "${HOME}/.local/share/profile/terminals/xterm/Xresources" ]; then
		_xres_src="${HOME}/.local/share/profile/terminals/xterm/Xresources"
	elif [ -f "${PROFILE_REPO_DIR:-}/terminals/xterm/Xresources" ]; then
		_xres_src="${PROFILE_REPO_DIR}/terminals/xterm/Xresources"
	fi
	if [ -n "${_xres_src}" ]; then
		if [ ! -f "${_xres_target}" ] || ! cmp -s "${_xres_src}" "${_xres_target}"; then
			cp -f "${_xres_src}" "${_xres_target}" 2> "/dev/null" || true
		fi
	fi

	_setup_cursor_env
	_enable_numlock_console
}

_freebsd_vt_bounce() {
	if [ "$(_detect_os)" = "freebsd" ]; then
		local _cur_tty="$(tty 2> "/dev/null" || true)"
		case "${_cur_tty}" in
			/dev/ttyv[0-9a-fA-F]*)
				local _hex="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/ttyv\([0-9a-fA-F]\{1,2\}\)$#\1#p')"
				if [ -n "${_hex}" ]; then
					local _vt_idx=$(( 0x${_hex} + 1 ))
					local _target_vt=1
					[ "${_vt_idx}" -eq 1 ] && _target_vt=2
					command vidcontrol -s "${_target_vt}" < "${_cur_tty}" 2> "/dev/null" || true
					command vidcontrol -s "${_vt_idx}" < "${_cur_tty}" 2> "/dev/null" || printf '\x1bc'
				fi
				;;
		esac
	fi
}

_is_terminal_app() {
	local _target="${1:-}"
	[ -z "${_target}" ] && return 0

	local _base="${_target##*/}"
	local _bin_path=""
	if [ -f "${_target}" ] && [ -x "${_target}" ]; then
		_bin_path="${_target}"
	else
		_bin_path="$(command -v "${_base}" 2> "/dev/null" || true)"
	fi
	[ -z "${_bin_path}" ] && return 0

	local _xdg_dir _desktop_file
	for _xdg_dir in /usr/share/applications /usr/local/share/applications "${XDG_DATA_HOME:-${HOME}/.local/share}/applications" /var/lib/flatpak/exports/share/applications; do
		[ -d "${_xdg_dir}" ] || continue
		for _desktop_file in "${_xdg_dir}/${_base}.desktop" "${_xdg_dir}/"*".${_base}.desktop"; do
			[ -f "${_desktop_file}" ] || continue
			if command grep -q -E "^Exec=([^ ]*/|)${_base}( |$)" "${_desktop_file}" 2> "/dev/null"; then
				if command grep -q "^Terminal=true" "${_desktop_file}" 2> "/dev/null"; then
					return 0
				elif command grep -q "^Type=Application" "${_desktop_file}" 2> "/dev/null"; then
					return 1
				fi
			fi
		done
	done

	if command -v realpath > "/dev/null" 2>&1; then
		_bin_path="$(command realpath "${_bin_path}" 2> "/dev/null" || echo "${_bin_path}")"
	elif command -v readlink > "/dev/null" 2>&1; then
		_bin_path="$(command readlink -f "${_bin_path}" 2> "/dev/null" || echo "${_bin_path}")"
	fi

	if [ -f "${_bin_path}" ] && command -v readelf > "/dev/null" 2>&1; then
		local _needed_libs
		_needed_libs="$(command readelf -d "${_bin_path}" 2> "/dev/null" | command grep "(NEEDED)" | command sed -n 's/.*\[\(lib[^]]*\)\].*/\1/p' || true)"
		if [ -n "${_needed_libs}" ]; then
			if printf '%s\n' "${_needed_libs}" | command grep -qiE "libwayland-client|libX11|libxcb|libgtk|libgdk|libQt|libfltk|libwx|libFOX|libglfw|libSDL|libraylib|libsfml|liballegro|libGL\.|libEGL\.|libGLES|libvulkan" > "/dev/null" 2>&1; then
				return 1
			fi
			return 0
		fi
	fi

	if [ -f "${_bin_path}" ]; then
		case "$(command head -n 1 "${_bin_path}" 2> "/dev/null" || true)" in
			"#!"*sh*) return 0 ;;
			"#!"*python*|"#!"*node*|"#!"*ruby*|"#!"*perl*)
				command grep -q -E "(tkinter|PyQt|PySide|gi\.repository\.Gtk|pygame|wx)" "${_bin_path}" 2> "/dev/null" && return 1
				return 0
				;;
		esac
	fi
	return 0
}

### --------------------------------
### Session Command Quoting
### --------------------------------
# ck-launch-session rejects any dash-prefixed argument (including the
# ones meant for its child), so its command line must be option-free.
_session_quote_args() {
	local _arg _line=""
	for _arg in "$@"; do
		_line="${_line} '$(printf '%s' "${_arg}" | sed "s/'/'\\\\''/g")'"
	done
	printf '%s\n' "${_line# }"
}

_session_cmd_file() {
	local _file="${XDG_RUNTIME_DIR:-/tmp}/session-cmd-$$.sh"
	printf '#!/bin/sh\nrm -f "$0"\nexec %s\n' "$(_session_quote_args "$@")" > "${_file}"
	chmod 0700 "${_file}"
	printf '%s\n' "${_file}"
}

### --------------------------------
### Xorg Diagnostics
### --------------------------------
_filter_xorg_noise() {
	command grep -v -E '^> |XKEYBOARD keymap compiler|Errors from xkbcomp are not fatal|^scfb trace:|^[[:space:]]*$' 2> "/dev/null" || true
}

_x11_driver_preflight() {
	[ "$(_detect_os)" = "freebsd" ] || return 0
	[ -c "/dev/dri/card0" ] && return 0
	_ui_warn "/dev/dri/card0 ausente: Xorg usará o fallback scfb (sem aceleração). Verifique kld_list (i915kms/amdgpu)."
}

### --------------------------------
### Graphical Session Launchers
### --------------------------------
_exec_wayland() {
	if [ "$(_detect_os)" = "freebsd" ]; then
		if command -v ck-launch-session > "/dev/null" 2>&1; then
			local _ck_cmd="$(_session_cmd_file "$@")"
			command -v dbus-run-session > "/dev/null" 2>&1 && exec dbus-run-session -- ck-launch-session "${_ck_cmd}"
			command -v dbus-launch > "/dev/null" 2>&1 && exec dbus-launch --exit-with-session ck-launch-session "${_ck_cmd}"
			exec ck-launch-session "${_ck_cmd}"
		fi
		command -v dbus-run-session > "/dev/null" 2>&1 && exec dbus-run-session -- "$@"
		exec "$@"
	fi
	if [ -S "/run/user/$(id -u)/bus" ]; then
		export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
		exec "$@"
	fi
	command -v dbus-run-session > "/dev/null" 2>&1 && exec dbus-run-session "$@"
	command -v dbus-launch > "/dev/null" 2>&1 && exec dbus-launch --exit-with-session "$@"
	exec "$@"
}

_resolve_vt_arg() {
	local _cur_tty="${1:-$(tty 2> "/dev/null" || true)}" _hex _num
	case "${_cur_tty}" in
		/dev/ttyv[0-9a-fA-F]*|/dev/ttyC[0-9a-fA-F]*)
			_hex="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/tty[vC]\([0-9a-fA-F]\{1,2\}\)$#\1#p')"
			[ -n "${_hex}" ] && echo "vt$(( 0x${_hex} + 1 ))"
			;;
		/dev/tty[0-9]*)
			_num="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/tty\([0-9]\{1,3\}\)$#\1#p')"
			[ -n "${_num}" ] && echo "vt${_num}"
			;;
	esac
}

_resolve_free_display() {
	local _d=0
	while true; do
		if [ ! -e "/tmp/.X${_d}-lock" ] && [ ! -S "/tmp/.X11-unix/X${_d}" ]; then
			if ! { [ -r "/proc/net/unix" ] && command grep -q "/tmp/.X11-unix/X${_d}" "/proc/net/unix" 2> "/dev/null"; }; then
				echo ":${_d}"
				return 0
			fi
		fi
		_d=$((_d + 1))
	done
}

_exec_x11() {
	command -v startx > "/dev/null" 2>&1 || command -v xinit > "/dev/null" 2>&1 || return 1

	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	local _display="$(_resolve_free_display)"
	export DISPLAY="${_display}"
	_x11_session_env "${_X11_FLAVOR_OVERRIDE:-}"

	_x11_driver_preflight

	local _session_cmd=""
	if [ "$#" -gt 0 ]; then
		_session_cmd="$(_session_quote_args "$@")"
	else
		local _rc
		for _rc in "${HOME}/.xinitrc" "${HOME}/.xsession" "${HOME}/.Xclients"; do
			[ -f "${_rc}" ] && { _session_cmd="$(_session_quote_args sh "${_rc}")"; break; }
		done
		[ -z "${_session_cmd}" ] && _session_cmd="'xterm'"
	fi

	local _vt_arg="$(_resolve_vt_arg)"
	local _xinit_script="${XDG_RUNTIME_DIR:-/tmp}/xinit-session-$$.sh"
	cat << EOF > "${_xinit_script}"
#!/bin/sh
if [ -z "\${ENVIRONMENT_SESSION_WRAPPED:-}" ]; then
	export ENVIRONMENT_SESSION_WRAPPED=1
	if [ -z "\${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}/bus" ]; then
		export DBUS_SESSION_BUS_ADDRESS="unix:path=\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}/bus"
	fi
	_ck=""
	[ "\$(uname -s)" = "FreeBSD" ] && command -v ck-launch-session > "/dev/null" 2>&1 && _ck="ck-launch-session"
	if [ -z "\${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
		command -v dbus-run-session > "/dev/null" 2>&1 && exec dbus-run-session -- \${_ck} "\$0"
		command -v dbus-launch > "/dev/null" 2>&1 && exec dbus-launch --exit-with-session \${_ck} "\$0"
	fi
	[ -n "\${_ck}" ] && exec ck-launch-session "\$0"
fi
unset ENVIRONMENT_SESSION_WRAPPED

export XDG_SESSION_TYPE="x11"
unset WAYLAND_DISPLAY
export GDK_BACKEND="x11"
export QT_QPA_PLATFORM="xcb"
export SDL_VIDEODRIVER="x11"
export CLUTTER_BACKEND="x11"
export GTK_THEME="${GTK_THEME:-Adwaita:dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1
export XCURSOR_THEME="${XCURSOR_THEME:-Adwaita}"
export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"

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

exec ${_session_cmd}
EOF
	chmod 0755 "${_xinit_script}"

	local _persistent_log="${HOME}/.local/state/environment/xorg-session.log"
	mkdir -p "${HOME}/.local/state/environment" 2> "/dev/null" || true
	rm -f "${_persistent_log}" 2> "/dev/null" || true
	local _server_auth="${XDG_RUNTIME_DIR:-/tmp}/.serverauth-session-$$"
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
		command xinit "${_xinit_script}" -- "${_display}" ${_vt_arg} ${_auth_args} >| "${_persistent_log}" 2>&1
		_xinit_ret=$?
	elif command -v startx > "/dev/null" 2>&1; then
		command startx "${_xinit_script}" -- "${_display}" ${_vt_arg} >| "${_persistent_log}" 2>&1
		_xinit_ret=$?
	else
		command xinit "${_xinit_script}" -- "${_display}" ${_vt_arg} >| "${_persistent_log}" 2>&1
		_xinit_ret=$?
	fi
	rm -f "${_server_auth}" "${_xinit_script}" 2> "/dev/null" || true
	command -v xauth > "/dev/null" 2>&1 && command xauth -q remove "${_display}" 2> "/dev/null" || true

	if [ -f "${_persistent_log}" ] && [ -s "${_persistent_log}" ]; then
		if [ "${_xinit_ret}" -ne 0 ]; then
			_ui_warn "Xorg encerrou com código ${_xinit_ret}. Diagnóstico:"
		else
			_ui_info "Log da sessão Xorg preservado em: ${_persistent_log}"
		fi
		_filter_xorg_noise < "${_persistent_log}" | command tail -n 15
	fi

	[ "${_had_display}" -eq 0 ] && unset DISPLAY
}

_has_wayland() {
	[ -n "${WAYLAND_DISPLAY:-}" ] && return 0

	local _session_dir
	for _session_dir in /usr/share/wayland-sessions /usr/local/share/wayland-sessions "${XDG_DATA_HOME:-${HOME}/.local/share}/wayland-sessions"; do
		if [ -d "${_session_dir}" ] && [ -n "$(command ls -A "${_session_dir}" 2> "/dev/null")" ]; then
			return 0
		fi
	done

	if [ -f "${HOME}/.local/lib/libewm_core.so" ] || [ -f "${HOME}/.local/lib/libewm.so" ]; then
		return 0
	fi

	local _compositor
	for _compositor in cage river labwc sway gnome-shell startplasma-wayland cosmic-session Hyprland hyprland niri wayfire dwl hikari weston ewm; do
		command -v "${_compositor}" > "/dev/null" 2>&1 && return 0
	done
	return 1
}

_has_x11() {
	[ -n "${DISPLAY:-}" ] && return 0
	for _xbin in Xorg X xinit startx; do
		command -v "${_xbin}" > "/dev/null" 2>&1 && return 0
	done
	local _session_dir
	for _session_dir in /usr/share/xsessions /usr/local/share/xsessions /usr/X11R6/share/xsessions "${XDG_DATA_HOME:-${HOME}/.local/share}/xsessions"; do
		if [ -d "${_session_dir}" ] && [ -n "$(command ls -A "${_session_dir}" 2> "/dev/null")" ]; then
			return 0
		fi
	done
	return 1
}

_dispatch_display_server() {
	local _base_target="${1:-}"
	[ "$#" -ge 1 ] && shift

	if _has_wayland && command -v "${_base_target}-wayland" > "/dev/null" 2>&1; then
		"${_base_target}-wayland" "$@"
	elif _has_x11 && command -v "${_base_target}-x11" > "/dev/null" 2>&1; then
		"${_base_target}-x11" "$@"
	else
		_ui_err "Nenhum backend gráfico suportado (Wayland ou X11) disponível para '${_base_target}'."
		return 127
	fi
}

_try_wayland() {
	local _bin
	for _bin in "$@"; do
		command -v "${_bin}" > "/dev/null" 2>&1 || continue
		if [ "${_bin}" = "gnome-session" ]; then
			export XDG_SESSION_TYPE="wayland"
			_exec_wayland gnome-session --session=gnome
		elif [ "${_bin}" = "gnome-shell" ]; then
			export XDG_SESSION_TYPE="wayland"
			_exec_wayland gnome-shell --wayland
		else
			_exec_wayland "${_bin}"
		fi
	done
	return 1
}

_try_xorg() {
	local _bin
	for _bin in "$@"; do
		command -v "${_bin}" > "/dev/null" 2>&1 || continue
		if [ "${_bin}" = "gnome-session" ]; then
			_exec_x11 "$(command -v gnome-session)" --session=gnome-xorg
		elif [ "${_bin}" = "qtile" ]; then
			_exec_x11 "$(command -v qtile)" start
		else
			_exec_x11 "$(command -v "${_bin}")"
		fi
	done
	return 1
}

_start_wayland() {
	case "${1}" in
		kde|plasma)    _try_wayland startplasma-wayland plasma-wayland-session ;;
		gnome)         _try_wayland gnome-session gnome-shell ;;
		hyprland|hypr) _try_wayland Hyprland hyprland ;;
		sway)          _try_wayland sway ;;
		cosmic)        _try_wayland cosmic-session start-cosmic ;;
		niri)          _try_wayland niri-session niri ;;
		river)         _try_wayland river ;;
		wayfire)       _try_wayland wayfire ;;
		labwc)         _try_wayland labwc ;;
		dwl)           _try_wayland dwl ;;
		hikari)        _try_wayland hikari ;;
		weston)        _try_wayland weston ;;
		"")            _try_wayland startplasma-wayland plasma-wayland-session gnome-session Hyprland hyprland sway cosmic-session start-cosmic niri-session niri river wayfire labwc dwl hikari weston ;;
		*)             _try_wayland "${1}" ;;
	esac
}

_start_xorg() {
	command -v startx > "/dev/null" 2>&1 || command -v xinit > "/dev/null" 2>&1 || return 1
	case "${1}" in
		kde|plasma) _try_xorg startplasma-x11 startkde ;;
		gnome)      _try_xorg gnome-session ;;
		xfce|xfce4) _try_xorg startxfce4 ;;
		mate)       _try_xorg mate-session ;;
		cinnamon)   _try_xorg cinnamon-session ;;
		lxqt)       _try_xorg startlxqt ;;
		lxde)       _try_xorg startlxde ;;
		i3)         _try_xorg i3 ;;
		bspwm)      _try_xorg bspwm ;;
		awesome)    _try_xorg awesome ;;
		openbox)    _try_xorg openbox-session openbox ;;
		dwm)        _try_xorg dwm ;;
		xmonad)     _try_xorg xmonad ;;
		qtile)      _try_xorg qtile ;;
		fluxbox)    _try_xorg startfluxbox fluxbox ;;
		"")
			[ -f "${HOME}/.xinitrc" ] || [ -f "${HOME}/.xsession" ] || [ -f "${HOME}/.Xclients" ] && _exec_x11
			_try_xorg startplasma-x11 startxfce4 gnome-session mate-session cinnamon-session startlxqt startlxde i3 bspwm awesome openbox-session dwm xmonad qtile startfluxbox
			_exec_x11
			;;
		*) _try_xorg "${1}" ;;
	esac
}

start-session() {
	[ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ] && _ui_warn "Uma sessão gráfica já está ativa (${WAYLAND_DISPLAY:-${DISPLAY}})."
	local _type="${1}"
	local _env="${2}"
	case "${_type}" in
		way|wayland) _start_wayland "${_env}" || { _ui_err "Nenhum compositor Wayland '${_env:-detectado}' encontrado."; return 1; } ;;
		xorg|x11)    _start_xorg "${_env}" || { _ui_err "Nenhum ambiente Xorg '${_env:-detectado}' encontrado."; return 1; } ;;
		"")          _start_wayland "" || _start_xorg "" || { _ui_err "Nenhum ambiente gráfico encontrado."; return 1; } ;;
		*)           _start_wayland "${_type}" || _start_xorg "${_type}" || { _ui_err "Ambiente '${_type}' não encontrado."; return 1; } ;;
	esac
}

window-manager-wayland() { start-session way "$@"; }
alias wwm="window-manager-wayland" way="window-manager-wayland" wayland="window-manager-wayland" start-way="window-manager-wayland" start-wayland="window-manager-wayland"

window-manager-x11() { start-session xorg "$@"; }
alias xwm="window-manager-x11" xorg="window-manager-x11" x11="window-manager-x11" start-xorg="window-manager-x11" start-x11="window-manager-x11"

window-manager() { _dispatch_display_server "window-manager" "$@"; }
alias wm="window-manager" win="window-manager" win-man="window-manager" window="window-manager"
