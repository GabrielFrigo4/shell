# ----------------------------------------------------------------
# Library: Desktop Session, Display Server & Input Orchestration
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
### CONSOLE & CURSOR HELPERS
### --------------------------------
_enable_numlock_console() {
	if [ -t 0 ] || [ -c "/dev/tty" ]; then
		command -v setleds > "/dev/null" 2>&1 && setleds -D +num 2> "/dev/null" || true
		command -v kbdcontrol > "/dev/null" 2>&1 && kbdcontrol -l num 2> "/dev/null" || true
	fi
}

_setup_cursor_env() {
	local _flavor="${1:-}"
	export XCURSOR_PATH="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
	export WLR_NO_HARDWARE_CURSORS=1

	local _cursor_theme="" _target_size="${XCURSOR_SIZE:-24}"
	case "${_flavor}" in
		kde|plasma|lxqt)
			_cursor_theme="breeze_cursors"
			;;
		gnome|budgie)
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			;;
		pantheon)
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="elementary"
			;;
		deepin)
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get com.deepin.dde.dock cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="bloom"
			;;
		cosmic)
			_cursor_theme="cosmic"
			;;
		mate)
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.mate.peripherals-mouse cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			if [ -z "${_cursor_theme}" ]; then
				for _c in mate Mate Adwaita; do
					for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
						if [ -d "${_p}/${_c}/cursors" ]; then
							_cursor_theme="${_c}"
							break 2
						fi
					done
				done
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			;;
		cinnamon)
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.cinnamon.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			if [ -z "${_cursor_theme}" ]; then
				for _c in Bibata-Modern-Classic DMZ-White Adwaita; do
					for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
						if [ -d "${_p}/${_c}/cursors" ]; then
							_cursor_theme="${_c}"
							break 2
						fi
					done
				done
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
			;;
		xfce|lxde)
			_cursor_theme="Adwaita"
			;;
	esac

	if [ -z "${_cursor_theme}" ]; then
		local _uid="$(id -u 2> "/dev/null" || echo 1000)"
		if pgrep -u "${_uid}" -x gnome-shell > "/dev/null" 2>&1; then
			_flavor="gnome"
		elif pgrep -u "${_uid}" -x plasmashell > "/dev/null" 2>&1; then
			_flavor="kde"
		elif pgrep -u "${_uid}" -x mate-session > "/dev/null" 2>&1; then
			_flavor="mate"
		elif pgrep -u "${_uid}" -x cinnamon > "/dev/null" 2>&1; then
			_flavor="cinnamon"
		elif pgrep -u "${_uid}" -x xfce4-session > "/dev/null" 2>&1; then
			_flavor="xfce"
		elif pgrep -u "${_uid}" -x lxqt-session > "/dev/null" 2>&1; then
			_flavor="lxqt"
		elif pgrep -u "${_uid}" -x lxsession > "/dev/null" 2>&1; then
			_flavor="lxde"
		elif pgrep -u "${_uid}" -x budgie-daemon > "/dev/null" 2>&1; then
			_flavor="budgie"
		elif pgrep -u "${_uid}" -x io.elementary.wingpanel > "/dev/null" 2>&1; then
			_flavor="pantheon"
		elif pgrep -u "${_uid}" -x dde-desktop > "/dev/null" 2>&1; then
			_flavor="deepin"
		elif pgrep -u "${_uid}" -x cosmic-comp > "/dev/null" 2>&1; then
			_flavor="cosmic"
		elif [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
			case "${XDG_CURRENT_DESKTOP}" in
				*GNOME*|*gnome*)        _flavor="gnome" ;;
				*KDE*|*kde*|*Plasma*)   _flavor="kde" ;;
				*MATE*|*mate*)          _flavor="mate" ;;
				*Cinnamon*|*cinnamon*)  _flavor="cinnamon" ;;
				*XFCE*|*xfce*)          _flavor="xfce" ;;
				*LXQt*|*lxqt*)          _flavor="lxqt" ;;
				*LXDE*|*lxde*)          _flavor="lxde" ;;
				*Budgie*|*budgie*)      _flavor="budgie" ;;
				*Pantheon*|*pantheon*)  _flavor="pantheon" ;;
				*Deepin*|*deepin*|*DDE*) _flavor="deepin" ;;
				*COSMIC*|*cosmic*)      _flavor="cosmic" ;;
			esac
		fi

		case "${_flavor}" in
			kde|lxqt)
				_cursor_theme="breeze_cursors"
				;;
			gnome|budgie)
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				;;
			pantheon)
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="elementary"
				;;
			deepin)
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get com.deepin.dde.dock cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="bloom"
				;;
			cosmic)
				_cursor_theme="cosmic"
				;;
			mate)
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.mate.peripherals-mouse cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				;;
			cinnamon)
				if command -v gsettings > "/dev/null" 2>&1; then
					_cursor_theme="$(gsettings get org.cinnamon.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
				fi
				[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				;;
			xfce|lxde)
				_cursor_theme="Adwaita"
				;;
		esac
	fi

	if [ -z "${_cursor_theme}" ]; then
		if command -v gnome-shell > "/dev/null" 2>&1; then
			if command -v gsettings > "/dev/null" 2>&1; then
				_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
			fi
			[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
		elif command -v plasmashell > "/dev/null" 2>&1 || command -v startplasma-wayland > "/dev/null" 2>&1 || command -v startplasma-x11 > "/dev/null" 2>&1; then
			_cursor_theme="breeze_cursors"
		elif command -v mate-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v cinnamon-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v xfce4-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v lxqt-session > "/dev/null" 2>&1; then
			_cursor_theme="breeze_cursors"
		elif command -v lxsession > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v budgie-desktop > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v pantheon-session > "/dev/null" 2>&1 || command -v io.elementary.wingpanel > "/dev/null" 2>&1; then
			_cursor_theme="elementary"
		elif command -v startdde > "/dev/null" 2>&1 || command -v dde-session > "/dev/null" 2>&1; then
			_cursor_theme="bloom"
		elif command -v cosmic-session > "/dev/null" 2>&1 || command -v cosmic-comp > "/dev/null" 2>&1; then
			_cursor_theme="cosmic"
		fi
	fi

	local _valid_theme=""
	if [ -n "${_cursor_theme}" ]; then
		for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
			if [ -d "${_p}/${_cursor_theme}/cursors" ]; then
				_valid_theme="${_cursor_theme}"
				break
			fi
		done
	fi

	if [ -z "${_valid_theme}" ]; then
		for _c in "Adwaita" "Bibata-Modern-Classic" "breeze_cursors" "elementary" "bloom" "cosmic" "DMZ-White" "default"; do
			for _p in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
				if [ -d "${_p}/${_c}/cursors" ]; then
					_valid_theme="${_c}"
					break 2
				fi
			done
		done
	fi
	[ -z "${_valid_theme}" ] && _valid_theme="default"

	export XCURSOR_THEME="${_valid_theme}" XCURSOR_SIZE="${_target_size}"

	mkdir -p "${HOME}/.icons/default" 2> "/dev/null" || true
	printf '[Icon Theme]\nInherits=%s\n' "${_valid_theme}" >| "${HOME}/.icons/default/index.theme" 2> "/dev/null" || true

	for _gtk_cfg in "${HOME}/.config/gtk-3.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"; do
		_gtk_dir="$(dirname "${_gtk_cfg}")"
		[ -d "${_gtk_dir}" ] || mkdir -p "${_gtk_dir}" 2> "/dev/null" || true
		if [ ! -f "${_gtk_cfg}" ]; then
			printf '[Settings]\ngtk-cursor-theme-name=%s\ngtk-cursor-blink=true\ngtk-cursor-blink-time=1200\n' "${_valid_theme}" >| "${_gtk_cfg}" 2> "/dev/null" || true
		else
			_cfg_tmp="${_gtk_cfg}.tmp.$$"
			cat "${_gtk_cfg}" >| "${_cfg_tmp}" 2> "/dev/null" || true
			if grep -q "^gtk-cursor-theme-name=" "${_cfg_tmp}" 2> "/dev/null"; then
				sed "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=${_valid_theme}/" "${_cfg_tmp}" > "${_cfg_tmp}.1" 2> "/dev/null" && mv -f "${_cfg_tmp}.1" "${_cfg_tmp}" 2> "/dev/null" || true
			else
				printf 'gtk-cursor-theme-name=%s\n' "${_valid_theme}" >> "${_cfg_tmp}" 2> "/dev/null" || true
			fi
			if grep -q "^gtk-cursor-blink=" "${_cfg_tmp}" 2> "/dev/null"; then
				sed "s/^gtk-cursor-blink=.*/gtk-cursor-blink=true/" "${_cfg_tmp}" > "${_cfg_tmp}.1" 2> "/dev/null" && mv -f "${_cfg_tmp}.1" "${_cfg_tmp}" 2> "/dev/null" || true
			else
				printf 'gtk-cursor-blink=true\n' >> "${_cfg_tmp}" 2> "/dev/null" || true
			fi
			if grep -q "^gtk-cursor-blink-time=" "${_cfg_tmp}" 2> "/dev/null"; then
				sed "s/^gtk-cursor-blink-time=.*/gtk-cursor-blink-time=1200/" "${_cfg_tmp}" > "${_cfg_tmp}.1" 2> "/dev/null" && mv -f "${_cfg_tmp}.1" "${_cfg_tmp}" 2> "/dev/null" || true
			else
				printf 'gtk-cursor-blink-time=1200\n' >> "${_cfg_tmp}" 2> "/dev/null" || true
			fi
			cat "${_cfg_tmp}" >| "${_gtk_cfg}" 2> "/dev/null" || true
			rm -f "${_cfg_tmp}" "${_cfg_tmp}.1" 2> "/dev/null" || true
		fi
	done

	if [ -n "${DISPLAY:-}" ]; then
		if command -v xrdb > "/dev/null" 2>&1; then
			printf "Xcursor.theme: %s\nXcursor.size: %s\nXTerm*cursorBlink: always\nXTerm*cursorOnTime: 600\nXTerm*cursorOffTime: 600\n" "${_valid_theme}" "${_target_size}" | xrdb -merge - 2> "/dev/null" || true
		fi
		command -v xsetroot > "/dev/null" 2>&1 && xsetroot -cursor_name left_ptr 2> "/dev/null" || true
	fi
	if command -v gsettings > "/dev/null" 2>&1; then
		gsettings set org.gnome.desktop.interface cursor-theme "${_valid_theme}" > "/dev/null" 2>&1 || true
		gsettings set org.gnome.desktop.interface cursor-size "${_target_size}" > "/dev/null" 2>&1 || true
		gsettings set org.gnome.desktop.interface cursor-blink true > "/dev/null" 2>&1 || true
		gsettings set org.gnome.desktop.interface cursor-blink-time 1200 > "/dev/null" 2>&1 || true
	fi
}

### --------------------------------
### WAYLAND & X11 SESSION ENV
### --------------------------------
_wayland_session_env() {
	local _target_flavor="${1:-}"
	[ -z "${XDG_RUNTIME_DIR:-}" ] && export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
	[ ! -d "${XDG_RUNTIME_DIR}" ] && mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"

	export XKB_DEFAULT_LAYOUT="br" XKB_DEFAULT_MODEL="abnt2" XKB_DEFAULT_OPTIONS="numpad:mac"
	export WLR_KEYBOARD_REPEAT_DELAY=200 WLR_KEYBOARD_REPEAT_RATE=50
	export GDK_BACKEND="wayland,x11,*" CLUTTER_BACKEND="wayland" SDL_VIDEODRIVER="wayland"
	export MOZ_ENABLE_WAYLAND=1 ELECTRON_OZONE_PLATFORM_HINT="auto"
	export GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DEBUG_COLOR_SCHEME="prefer-dark"

	if [ -z "${GTK_THEME:-}" ] && [ -r "${HOME}/.config/gtk-3.0/settings.ini" ]; then
		local _ini_gtk="$(grep -E '^[[:space:]]*gtk-theme-name[[:space:]]*=' "${HOME}/.config/gtk-3.0/settings.ini" 2> "/dev/null" | head -n 1 | cut -d= -f2- | tr -d ' "' || true)"
		[ -n "${_ini_gtk}" ] && export GTK_THEME="${_ini_gtk}"
	fi

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	[ -z "${GTK_THEME:-}" ] && export GTK_THEME="$(_resolve_gtk_theme "${_theme_flavor}")"
	[ -z "${GTK_THEME:-}" ] && export GTK_THEME="Breeze-Dark:dark"
	export QT_QPA_PLATFORM="wayland;xcb"
	case "${_theme_flavor}" in
		kde|plasma)
			export XDG_CURRENT_DESKTOP="KDE" QT_QPA_PLATFORMTHEME="kde" QT_STYLE_OVERRIDE="Breeze"
			;;
		lxqt)
			export XDG_CURRENT_DESKTOP="LXQt" QT_QPA_PLATFORMTHEME="lxqt" QT_STYLE_OVERRIDE="Breeze"
			;;
		cosmic)
			export XDG_CURRENT_DESKTOP="COSMIC" QT_QPA_PLATFORMTHEME="cosmic"
			;;
		budgie)
			export XDG_CURRENT_DESKTOP="Budgie:GNOME" QT_QPA_PLATFORMTHEME="qt6ct"
			;;
		pantheon)
			export XDG_CURRENT_DESKTOP="Pantheon" QT_QPA_PLATFORMTHEME="qt6ct"
			;;
		deepin)
			export XDG_CURRENT_DESKTOP="DDE" QT_QPA_PLATFORMTHEME="deepin"
			;;
		*)
			case "${_theme_flavor}" in
				cinnamon) export XDG_CURRENT_DESKTOP="X-Cinnamon" ;;
				mate)     export XDG_CURRENT_DESKTOP="MATE" ;;
				xfce)     export XDG_CURRENT_DESKTOP="XFCE" ;;
				lxde)     export XDG_CURRENT_DESKTOP="LXDE" ;;
				*)        export XDG_CURRENT_DESKTOP="GNOME" ;;
			esac
			unset QT_STYLE_OVERRIDE 2> "/dev/null" || true
			if [ -f "${HOME}/.config/qt6ct/qt6ct.conf" ] || command -v qt6ct > "/dev/null" 2>&1; then
				export QT_QPA_PLATFORMTHEME="qt6ct"
			elif [ "${XDG_CURRENT_DESKTOP}" = "GNOME" ]; then
				export QT_QPA_PLATFORMTHEME="gnome"
			else
				export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
			fi
			;;
	esac

	_setup_cursor_env "${_target_flavor}"
	_enable_numlock_console
}

_x11_session_env() {
	local _target_flavor="${1:-}"
	unset WAYLAND_DISPLAY
	export XDG_SESSION_TYPE="x11" GDK_BACKEND="x11" QT_QPA_PLATFORM="xcb" SDL_VIDEODRIVER="x11" CLUTTER_BACKEND="x11"
	export XORG_RUN_AS_USER_OK=1 XKB_DEFAULT_LAYOUT="br" XKB_DEFAULT_MODEL="abnt2" XKB_DEFAULT_OPTIONS="numpad:mac"
	export GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DEBUG_COLOR_SCHEME="prefer-dark"

	if [ -z "${GTK_THEME:-}" ] && [ -r "${HOME}/.config/gtk-3.0/settings.ini" ]; then
		local _ini_gtk="$(grep -E '^[[:space:]]*gtk-theme-name[[:space:]]*=' "${HOME}/.config/gtk-3.0/settings.ini" 2> "/dev/null" | head -n 1 | cut -d= -f2- | tr -d ' "' || true)"
		[ -n "${_ini_gtk}" ] && export GTK_THEME="${_ini_gtk}"
	fi

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	[ -z "${GTK_THEME:-}" ] && export GTK_THEME="$(_resolve_gtk_theme "${_theme_flavor}")"
	[ -z "${GTK_THEME:-}" ] && export GTK_THEME="Breeze-Dark:dark"
	case "${_theme_flavor}" in
		kde|plasma)
			export XDG_CURRENT_DESKTOP="KDE" QT_QPA_PLATFORMTHEME="kde" QT_STYLE_OVERRIDE="Breeze"
			;;
		lxqt)
			export XDG_CURRENT_DESKTOP="LXQt" QT_QPA_PLATFORMTHEME="lxqt" QT_STYLE_OVERRIDE="Breeze"
			;;
		cosmic)
			export XDG_CURRENT_DESKTOP="COSMIC" QT_QPA_PLATFORMTHEME="cosmic"
			;;
		budgie)
			export XDG_CURRENT_DESKTOP="Budgie:GNOME" QT_QPA_PLATFORMTHEME="qt6ct"
			;;
		pantheon)
			export XDG_CURRENT_DESKTOP="Pantheon" QT_QPA_PLATFORMTHEME="qt6ct"
			;;
		deepin)
			export XDG_CURRENT_DESKTOP="DDE" QT_QPA_PLATFORMTHEME="deepin"
			;;
		*)
			case "${_theme_flavor}" in
				cinnamon) export XDG_CURRENT_DESKTOP="X-Cinnamon" ;;
				mate)     export XDG_CURRENT_DESKTOP="MATE" ;;
				xfce)     export XDG_CURRENT_DESKTOP="XFCE" ;;
				lxde)     export XDG_CURRENT_DESKTOP="LXDE" ;;
				*)        export XDG_CURRENT_DESKTOP="GNOME" ;;
			esac
			unset QT_STYLE_OVERRIDE 2> "/dev/null" || true
			if [ -f "${HOME}/.config/qt6ct/qt6ct.conf" ] || command -v qt6ct > "/dev/null" 2>&1; then
				export QT_QPA_PLATFORMTHEME="qt6ct"
			else
				export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
			fi
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

	_setup_cursor_env "${_target_flavor}"
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
	case "${_base}" in
		code*|vscode*|codium*|firefox*|chrome*|chromium*|google-chrome*|brave*|microsoft-edge*|vivaldi*|opera*|librewolf*|zen*|epiphany*|falkon*|qutebrowser*|electron*|emacs*|gimp*|inkscape*|blender*|libreoffice*|soffice*|onlyoffice*|desktopeditors*|vlc*|mpv*|celluloid*|wireshark*|kate*|geany*|zed*|antigravity*|kdeconnect*|thunderbird*|telegram*|discord*|vesktop*|slack*|spotify*|steam*|obs*|zathura*|evince*|papers*|okular*|pcmanfm*|thunar*|dolphin*|nautilus*|nemo*|caja*|pavucontrol*|pwvucontrol*|wezterm*|alacritty*|kitty*|foot*|xterm*|konsole*)
			return 1
			;;
	esac
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
			"#!"*sh*)
				if command grep -qiE "(chrome|chromium|firefox|code|electron|gtk|qt|x11|wayland)" "${_bin_path}" 2> "/dev/null"; then
					return 1
				fi
				return 0
				;;
			"#!"*python*|"#!"*node*|"#!"*ruby*|"#!"*perl*)
				command grep -q -E "(tkinter|PyQt|PySide|gi\.repository\.Gtk|pygame|wx)" "${_bin_path}" 2> "/dev/null" && return 1
				return 0
				;;
		esac
	fi
	return 0
}

### --------------------------------
### SESSION COMMAND QUOTING
### --------------------------------
_session_quote_args() {
	local _arg _line=""
	for _arg in "$@"; do
		_line="${_line} '$(printf '%s' "${_arg}" | sed "s/'/'\\\\''/g")'"
	done
	printf '%s\n' "${_line# }"
}

_session_cmd_file() {
	local _file="${XDG_RUNTIME_DIR:-/tmp}/session-cmd-$$.sh"
	printf '#!/bin/sh\nrm -f "$0"\nexec %s\n' "$(_session_quote_args "$@")" >| "${_file}"
	chmod 0700 "${_file}"
	printf '%s\n' "${_file}"
}

### --------------------------------
### XORG DIAGNOSTICS
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
### GRAPHICAL SESSION LAUNCHERS
### --------------------------------
_exec_wayland() {
	_sanitize_graphical_env
	local _log_dir="$(_get_shell_log_dir)"
	local _log_file="${_log_dir}/wayland-session.log"
	local _ret=0

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	if [ "$(_detect_os)" = "freebsd" ]; then
		if command -v ck-launch-session > "/dev/null" 2>&1; then
			local _ck_cmd="$(_session_cmd_file "$@")"
			if command -v dbus-run-session > "/dev/null" 2>&1; then
				dbus-run-session -- ck-launch-session "${_ck_cmd}" >| "${_log_file}" 2>&1
				_ret=$?
			elif command -v dbus-launch > "/dev/null" 2>&1; then
				dbus-launch --exit-with-session ck-launch-session "${_ck_cmd}" >| "${_log_file}" 2>&1
				_ret=$?
			else
				ck-launch-session "${_ck_cmd}" >| "${_log_file}" 2>&1
				_ret=$?
			fi
		elif command -v dbus-run-session > "/dev/null" 2>&1; then
			dbus-run-session -- "$@" >| "${_log_file}" 2>&1
			_ret=$?
		elif command -v dbus-launch > "/dev/null" 2>&1; then
			dbus-launch --exit-with-session "$@" >| "${_log_file}" 2>&1
			_ret=$?
		else
			"$@" >| "${_log_file}" 2>&1
			_ret=$?
		fi
	else
		if command -v dbus-run-session > "/dev/null" 2>&1; then
			dbus-run-session -- "$@" >| "${_log_file}" 2>&1
			_ret=$?
		elif command -v dbus-launch > "/dev/null" 2>&1; then
			dbus-launch --exit-with-session "$@" >| "${_log_file}" 2>&1
			_ret=$?
		else
			"$@" >| "${_log_file}" 2>&1
			_ret=$?
		fi
	fi

	_freebsd_vt_bounce

	if [ "${_ret}" -ne 0 ]; then
		_ui_err "Sessão Wayland encerrou com erro (código ${_ret}). Log: ${_log_file}"
		return "${_ret}"
	fi
	return 0
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
	_sanitize_graphical_env
	command -v startx > "/dev/null" 2>&1 || command -v xinit > "/dev/null" 2>&1 || return 1

	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

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
	cat << EOF >| "${_xinit_script}"
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1
export EMACS_OS_MODE="${EMACS_OS_MODE:-}"

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
export GTK_THEME="\${GTK_THEME:-Breeze-Dark:dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1
export QT_QPA_PLATFORMTHEME="\${QT_QPA_PLATFORMTHEME:-qt6ct}"
export XCURSOR_THEME="\${XCURSOR_THEME}"
export XCURSOR_SIZE="\${XCURSOR_SIZE:-24}"

if [ -f "\${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "\${HOME}/.Xresources" 2> "/dev/null" || true
fi
if command -v xrdb > "/dev/null" 2>&1; then
	printf "Xcursor.theme: %s\nXcursor.size: %s\n" "\${XCURSOR_THEME}" "\${XCURSOR_SIZE}" | xrdb -merge - 2> "/dev/null" || true
fi
if command -v xsetroot > "/dev/null" 2>&1; then
	xsetroot -solid "#16161e" -cursor_name left_ptr 2> "/dev/null" || true
fi

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

	local _log_dir="$(_get_shell_log_dir)"
	local _persistent_log="${_log_dir}/xorg-session.log"
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

	if [ "${_xinit_ret}" -ne 0 ] && [ -f "${_persistent_log}" ] && [ -s "${_persistent_log}" ]; then
		_ui_err "Sessão Xorg encerrou com erro (código ${_xinit_ret}). Log: ${_persistent_log}"
	fi

	[ "${_had_display}" -eq 0 ] && unset DISPLAY
	_freebsd_vt_bounce
	return "${_xinit_ret}"
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
		lxqt)          _try_wayland lxqt-wayland-session startlxqt-wayland ;;
		budgie)        _try_wayland budgie-desktop ;;
		pantheon)      _try_wayland pantheon-session io.elementary.wingpanel ;;
		deepin)        _try_wayland startdde dde-session ;;
		niri)          _try_wayland niri-session niri ;;
		river)         _try_wayland river ;;
		wayfire)       _try_wayland wayfire ;;
		labwc)         _try_wayland labwc ;;
		dwl)           _try_wayland dwl ;;
		hikari)        _try_wayland hikari ;;
		weston)        _try_wayland weston ;;
		"")            _try_wayland startplasma-wayland plasma-wayland-session gnome-session Hyprland hyprland sway cosmic-session start-cosmic lxqt-wayland-session startlxqt-wayland budgie-desktop pantheon-session startdde niri-session niri river wayfire labwc dwl hikari weston ;;
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
		budgie)     _try_xorg budgie-desktop ;;
		pantheon)   _try_xorg pantheon-session io.elementary.wingpanel ;;
		deepin)     _try_xorg startdde dde-session ;;
		cosmic)     _try_xorg start-cosmic cosmic-session ;;
		openbox)    _try_xorg openbox-session openbox ;;
		"")
			[ -f "${HOME}/.xinitrc" ] || [ -f "${HOME}/.xsession" ] || [ -f "${HOME}/.Xclients" ] && _exec_x11
			_try_xorg startplasma-x11 startxfce4 gnome-session mate-session cinnamon-session startlxqt startlxde budgie-desktop pantheon-session startdde cosmic-session openbox-session openbox
			_exec_x11
			;;
		*) _try_xorg "${1}" ;;
	esac
}

start-session() {
	_sanitize_graphical_env
	[ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ] && _ui_warn "Uma sessão gráfica já está ativa (${WAYLAND_DISPLAY:-${DISPLAY}})."
	local _type=""
	local _env=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
			way|wayland)   _type="way"; shift ;;
			xorg|x11)      _type="xorg"; shift ;;
			-g|--gnome)    _env="gnome"; shift ;;
			-k|--kde)      _env="kde"; shift ;;
			-x|--xfce)     _env="xfce"; shift ;;
			-m|--mate)     _env="mate"; shift ;;
			-c|--cinnamon) _env="cinnamon"; shift ;;
			--lxqt)        _env="lxqt"; shift ;;
			--lxde)        _env="lxde"; shift ;;
			--budgie)      _env="budgie"; shift ;;
			--pantheon)    _env="pantheon"; shift ;;
			--deepin)      _env="deepin"; shift ;;
			--cosmic)      _env="cosmic"; shift ;;
			--)            shift; break ;;
			*)
				if [ -z "${_type}" ]; then
					case "$1" in
						way*|xorg*|x11*) _type="$1" ;;
						*) _env="$1" ;;
					esac
				elif [ -z "${_env}" ]; then
					_env="$1"
				fi
				shift
				;;
		esac
	done
	case "${_type}" in
		way|wayland) _start_wayland "${_env}" || { _ui_err "Nenhum compositor Wayland '${_env:-detectado}' encontrado."; return 1; } ;;
		xorg|x11)    _start_xorg "${_env}" || { _ui_err "Nenhum ambiente Xorg '${_env:-detectado}' encontrado."; return 1; } ;;
		"")          _start_wayland "${_env}" || _start_xorg "${_env}" || { _ui_err "Nenhum ambiente gráfico encontrado."; return 1; } ;;
		*)           _start_wayland "${_type}" || _start_xorg "${_type}" || { _ui_err "Ambiente '${_type}' não encontrado."; return 1; } ;;
	esac
}

desktop-session-wayland() { start-session way "$@"; }
alias way="desktop-session-wayland" wayland="desktop-session-wayland" start-way="desktop-session-wayland" start-wayland="desktop-session-wayland"

desktop-session-x11() { start-session xorg "$@"; }
alias xorg="desktop-session-x11" x11="desktop-session-x11" start-xorg="desktop-session-x11" start-x11="desktop-session-x11"

window-manager-wayland() {
	unset EMACS_OS_MODE
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
	if [ "$#" -gt 0 ]; then
		start-session way "$@"
		return $?
	fi
	_wayland_session_env "${_flavor}"

	local _cur_theme="${XCURSOR_THEME}"
	local _cur_size="${XCURSOR_SIZE:-24}"
	local _ui_font="$(_resolve_desktop_font "${_flavor}")"

	local _wm_term="foot -o dpi-aware=no"
	for _t in foot alacritty kitty xterm; do
		if command -v "${_t}" > "/dev/null" 2>&1; then
			[ "${_t}" = "foot" ] && _wm_term="foot -o dpi-aware=no" || _wm_term="${_t}"
			break
		fi
	done

	local _run_dir="${XDG_RUNTIME_DIR:-/tmp}"
	local _term_script="${_run_dir}/wwm-term-$$.sh"
	local _browser_script="${_run_dir}/wwm-browser-$$.sh"
	local _files_script="${_run_dir}/wwm-files-$$.sh"
	local _emacs_script="${_run_dir}/wwm-emacs-$$.sh"
	local _menu_script="${_run_dir}/wwm-menu-$$.sh"
	local _status_script="${_run_dir}/wwm-status-$$.sh"
	local _bar_script=""

	local _has_gtk3_bar=0
	if command -v python3 > "/dev/null" 2>&1 && python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' > "/dev/null" 2>&1; then
		_has_gtk3_bar=1
		_bar_script="${_run_dir}/wwm-bar-$$.py"
		cat << 'EOF_WBAR' >| "${_bar_script}"
import os, sys, subprocess, json, datetime
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

class WwmBar(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_wmclass("wwm-bar", "wwm-bar")
        self.set_title("wwm-bar")
        self.set_decorated(False)
        self.set_resizable(False)

        screen = Gdk.Screen.get_default()
        screen_w = screen.get_width() if screen else 1920
        self.set_default_size(screen_w, 32)
        self.set_size_request(screen_w, 32)

        self.last_ws_state = None
        self.managed_workspaces = {1}

        font_name = os.environ.get("WWM_FONT", "JetBrainsMono Nerd Font")

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
            font-size: 11px;
        }}
        button {{
            background-image: none;
            box-shadow: none;
            text-shadow: none;
            border-radius: 6px;
        }}
        button.app-btn {{
            background-color: #2b2b30;
            background-image: none;
            color: #e5e9f0;
            border: 1px solid #38383d;
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
        }}
        button.app-btn:hover {{
            background-color: #3584e4;
            background-image: none;
            color: #ffffff;
            border-color: #4a96ef;
        }}
        button.ws-inactive {{
            background-color: #242429;
            background-image: none;
            color: #9a9996;
            border: 1px solid #323238;
            border-radius: 6px;
            padding: 2px 8px;
            margin: 3px 2px;
            min-width: 24px;
            min-height: 22px;
        }}
        button.ws-inactive:hover {{
            background-color: #323238;
            background-image: none;
            color: #ffffff;
            border-color: #48484f;
        }}
        button.ws-active {{
            background-color: #3584e4;
            background-image: none;
            color: #ffffff;
            border: 1px solid #4a96ef;
            border-radius: 6px;
            padding: 2px 8px;
            margin: 3px 2px;
            min-width: 24px;
            min-height: 22px;
            font-weight: bold;
        }}
        button.ws-active:hover {{
            background-color: #4a96ef;
            background-image: none;
            color: #ffffff;
            border-color: #62a0ea;
        }}
        button.ws-ctrl-btn {{
            background-color: #2b2b30;
            background-image: none;
            color: #ffffff;
            border: 1px solid #38383d;
            border-radius: 6px;
            padding: 2px 7px;
            margin: 3px 2px;
            min-width: 22px;
            min-height: 22px;
            font-weight: bold;
        }}
        button.ws-ctrl-btn:hover {{
            background-color: #3584e4;
            background-image: none;
            border-color: #4a96ef;
        }}
        button.danger-btn {{
            background-color: #2b2b30;
            background-image: none;
            color: #f66151;
            border: 1px solid #4a2528;
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
        }}
        button.danger-btn:hover {{
            background-color: #e01b24;
            background-image: none;
            color: #ffffff;
            border-color: #f66151;
        }}
        label.clock-lbl {{
            color: #9a9996;
            font-size: 11px;
            margin: 0 10px;
        }}
        """
        css_provider.load_from_data(css.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.add(main_box)

        self.ws_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.pack_start(self.ws_box, False, False, 4)

        ws_ctrl_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        btn_add = Gtk.Button(label="+")
        btn_add.get_style_context().add_class("ws-ctrl-btn")
        btn_add.connect("clicked", self.on_add_ws)
        ws_ctrl_box.pack_start(btn_add, False, False, 0)

        btn_del = Gtk.Button(label="−")
        btn_del.get_style_context().add_class("ws-ctrl-btn")
        btn_del.connect("clicked", self.on_del_ws)
        ws_ctrl_box.pack_start(btn_del, False, False, 0)

        main_box.pack_start(ws_ctrl_box, False, False, 2)

        center_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.pack_start(center_box, True, True, 0)

        actions_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.pack_end(actions_box, False, False, 4)

        self.clock_lbl = Gtk.Label()
        self.clock_lbl.get_style_context().add_class("clock-lbl")
        actions_box.pack_end(self.clock_lbl, False, False, 0)

        btn_exit = Gtk.Button(label="Exit")
        btn_exit.get_style_context().add_class("danger-btn")
        btn_exit.connect("clicked", lambda b: subprocess.Popen(["swaymsg", "exit"]))
        actions_box.pack_end(btn_exit, False, False, 0)

        btn_close = Gtk.Button(label="Close")
        btn_close.get_style_context().add_class("danger-btn")
        btn_close.connect("clicked", lambda b: subprocess.Popen(["swaymsg", "kill"]))
        actions_box.pack_end(btn_close, False, False, 0)

        actions = [
            ("Menu", os.environ.get("WWM_MENU", "")),
            ("Emacs", os.environ.get("WWM_EMACS", "")),
            ("Files", os.environ.get("WWM_FILES", "")),
            ("Terminal", os.environ.get("WWM_TERM", "")),
            ("Web Browser", os.environ.get("WWM_BROWSER", "")),
        ]
        for name, cmd in actions:
            if not cmd:
                continue
            b = Gtk.Button(label=name)
            b.get_style_context().add_class("app-btn")
            b.connect("clicked", lambda widget, c=cmd: subprocess.Popen([c]))
            actions_box.pack_end(b, False, False, 0)

        self.update_workspaces()
        self.update_clock()
        GLib.timeout_add(250, self.update_workspaces)
        GLib.timeout_add(1000, self.update_clock)
        self.show_all()

    def update_clock(self):
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        self.clock_lbl.set_text(now)
        return True

    def on_add_ws(self, widget=None):
        used_nums = set()
        try:
            res = subprocess.run(["swaymsg", "-t", "get_workspaces"], capture_output=True, text=True)
            ws_list = json.loads(res.stdout)
            for ws in ws_list:
                num = ws.get("num")
                if num is not None:
                    used_nums.add(num)
        except Exception:
            pass
        all_existing = self.managed_workspaces.union(used_nums)
        next_num = (max(all_existing) + 1) if all_existing else 1
        self.managed_workspaces.add(next_num)
        subprocess.Popen(["swaymsg", "workspace", "number", str(next_num)])
        self.update_workspaces()

    def on_del_ws(self, widget=None):
        focused_num = 1
        used_nums = set()
        try:
            res = subprocess.run(["swaymsg", "-t", "get_workspaces"], capture_output=True, text=True)
            ws_list = json.loads(res.stdout)
            for ws in ws_list:
                num = ws.get("num")
                if num is not None:
                    used_nums.add(num)
                if ws.get("focused"):
                    focused_num = num
        except Exception:
            pass
        all_ws = sorted(list(self.managed_workspaces.union(used_nums)))
        if len(all_ws) > 1:
            remaining = [w for w in all_ws if w != focused_num]
            lower = [w for w in remaining if w < focused_num]
            target_num = max(lower) if lower else min(remaining)
            subprocess.run(
                ["swaymsg", f"[workspace=__focused__] move container to workspace number {target_num}"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            self.managed_workspaces.discard(focused_num)
            subprocess.Popen(["swaymsg", "workspace", "number", str(target_num)])
            self.update_workspaces()

    def update_workspaces(self):
        focused_num = 1
        used_nums = set()
        try:
            res = subprocess.run(["swaymsg", "-t", "get_workspaces"], capture_output=True, text=True)
            ws_list = json.loads(res.stdout)
            for ws in ws_list:
                num = ws.get("num")
                if num is not None:
                    used_nums.add(num)
                if ws.get("focused"):
                    focused_num = num
        except Exception:
            focused_num = 1
            used_nums = set([1])

        all_ws = sorted(list(self.managed_workspaces.union(used_nums)))
        current_state = (tuple(all_ws), focused_num)
        if current_state == self.last_ws_state:
            return True
        self.last_ws_state = current_state

        for child in self.ws_box.get_children():
            self.ws_box.remove(child)

        for num in all_ws:
            b = Gtk.Button(label=str(num))
            if num == focused_num:
                b.get_style_context().add_class("ws-active")
            else:
                b.get_style_context().add_class("ws-inactive")
            b.connect("clicked", lambda widget, n=num: subprocess.Popen(["swaymsg", "workspace", "number", str(n)]))
            self.ws_box.pack_start(b, False, False, 0)
        self.ws_box.show_all()
        return True

win = WwmBar()
Gtk.main()
EOF_WBAR
	fi

	cat << EOF >| "${_term_script}"
#!/bin/sh
exec ${_wm_term} "\$@"
EOF
	chmod 0755 "${_term_script}"

	cat << 'EOF' >| "${_browser_script}"
#!/bin/sh
for _b in firefox chromium google-chrome-stable google-chrome brave-browser; do
	if command -v "${_b}" > "/dev/null" 2>&1; then
		exec "${_b}" "$@"
	fi
done
EOF
	chmod 0755 "${_browser_script}"

	cat << EOF >| "${_files_script}"
#!/bin/sh
for _fm in nautilus dolphin thunar pcmanfm caja nemo; do
	if command -v "\${_fm}" > "/dev/null" 2>&1; then
		exec "\${_fm}" "\$@"
	fi
done
exec ${_wm_term} -e sh -c 'ls -la; exec sh'
EOF
	chmod 0755 "${_files_script}"

	cat << 'EOF' >| "${_emacs_script}"
#!/bin/sh
for _e in emacs-pgtk emacs; do
	if command -v "${_e}" > "/dev/null" 2>&1; then
		exec "${_e}" "$@"
	fi
done
EOF
	chmod 0755 "${_emacs_script}"

	cat << EOF >| "${_menu_script}"
#!/bin/sh
if command -v wofi > "/dev/null" 2>&1; then
	exec wofi --show drun
elif command -v fuzzel > "/dev/null" 2>&1; then
	exec fuzzel
elif command -v rofi > "/dev/null" 2>&1; then
	exec rofi -show drun
elif command -v bemenu-run > "/dev/null" 2>&1; then
	exec bemenu-run
else
	exec ${_wm_term}
fi
EOF
	chmod 0755 "${_menu_script}"

	cat << EOF >| "${_status_script}"
#!/bin/sh
_term="${_term_script}"
_browser="${_browser_script}"
_files="${_files_script}"
_emacs="${_emacs_script}"
_menu="${_menu_script}"

(
	printf '{"version":1,"click_events":true}\n[\n'
	while :; do
		_date_str="\$(date "+%Y-%m-%d %H:%M:%S")"
		printf '[{"name":"browser","full_text":" Web Browser ","background":"#2b2b30","color":"#ffffff","border":"#3584e4"},'
		printf '{"name":"term","full_text":" Terminal ","background":"#2b2b30","color":"#ffffff","border":"#3584e4"},'
		printf '{"name":"files","full_text":" Files ","background":"#2b2b30","color":"#ffffff","border":"#3584e4"},'
		printf '{"name":"emacs","full_text":" Emacs ","background":"#2b2b30","color":"#ffffff","border":"#3584e4"},'
		printf '{"name":"menu","full_text":" Menu ","background":"#2b2b30","color":"#ffffff","border":"#3584e4"},'
		printf '{"name":"close","full_text":" Close ","background":"#2b2b30","color":"#ffffff","border":"#e01b24"},'
		printf '{"name":"exit","full_text":" Exit ","background":"#2b2b30","color":"#ffffff","border":"#e01b24"},'
		printf '{"name":"time","full_text":" %s ","background":"#1e1e22","color":"#9a9996","border":"#38383d"}],\n' "\${_date_str}"
		sleep 1
	done
) &
_clock_pid=\$!
trap "kill \${_clock_pid} 2> \"/dev/null\" || true; exit" EXIT TERM INT

while IFS= read -r _click_line; do
	case "\${_click_line}" in
		*"\"name\""*"\"browser\""*) "\${_browser}" > "/dev/null" 2>&1 & ;;
		*"\"name\""*"\"term\""*)    "\${_term}" > "/dev/null" 2>&1 & ;;
		*"\"name\""*"\"files\""*)   "\${_files}" > "/dev/null" 2>&1 & ;;
		*"\"name\""*"\"emacs\""*)   "\${_emacs}" > "/dev/null" 2>&1 & ;;
		*"\"name\""*"\"menu\""*)    "\${_menu}" > "/dev/null" 2>&1 & ;;
		*"\"name\""*"\"close\""*)   swaymsg kill > "/dev/null" 2>&1 & ;;
		*"\"name\""*"\"exit\""*)    swaymsg exit > "/dev/null" 2>&1 & ;;
	esac
done
EOF
	chmod 0755 "${_status_script}"

	if command -v sway > "/dev/null" 2>&1; then
		local _sway_cfg="${_run_dir}/sway-wm-$$.conf"
		cat << EOF >| "${_sway_cfg}"
output * bg #1e1e22 solid_color
font pango:${_ui_font} Bold 10
titlebar_padding 10 6
default_border pixel 2
default_floating_border pixel 2
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
input type:keyboard {
    xkb_layout br
    xkb_model abnt2
    xkb_options numpad:mac
    repeat_delay 200
    repeat_rate 50
    xkb_numlock enabled
}
focus_follows_mouse yes
xwayland enable
bindsym Mod4+Return exec ${_term_script}
bindsym Ctrl+Mod1+t exec ${_term_script}
bindsym Mod4+b exec ${_browser_script}
bindsym Mod4+e exec ${_emacs_script}
bindsym Mod4+d exec ${_menu_script}
bindsym Mod4+1 workspace number 1
bindsym Mod4+2 workspace number 2
bindsym Mod4+3 workspace number 3
bindsym Mod4+4 workspace number 4
bindsym Mod4+5 workspace number 5
bindsym Mod4+6 workspace number 6
bindsym Mod4+7 workspace number 7
bindsym Mod4+8 workspace number 8
bindsym Mod4+9 workspace number 9
bindsym Mod4+Shift+1 move container to workspace number 1
bindsym Mod4+Shift+2 move container to workspace number 2
bindsym Mod4+Shift+3 move container to workspace number 3
bindsym Mod4+Shift+4 move container to workspace number 4
bindsym Mod4+Shift+5 move container to workspace number 5
bindsym Mod4+Shift+6 move container to workspace number 6
bindsym Mod4+Shift+7 move container to workspace number 7
bindsym Mod4+Shift+8 move container to workspace number 8
bindsym Mod4+Shift+9 move container to workspace number 9
bindsym Mod4+f fullscreen toggle
bindsym Mod4+Shift+space floating toggle
bindsym Mod4+Left focus left
bindsym Mod4+Down focus down
bindsym Mod4+Up focus up
bindsym Mod4+Right focus right
bindsym Mod1+Tab focus next
bindsym Mod4+Tab focus next
bindsym Mod4+q kill
bindsym Mod1+F4 kill
bindsym Mod4+Shift+q exec swaymsg exit
EOF
		if [ "${_has_gtk3_bar}" -eq 1 ]; then
			cat << EOF >> "${_sway_cfg}"
floating_minimum_size 1 x 1
gaps top 32
for_window [instance="wwm-bar"] floating enable, sticky enable, border none, resize set 100 ppt 32 px, move absolute position 0 0
exec env GDK_BACKEND=x11 WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" python3 "${_bar_script}"
EOF
		else
			cat << EOF >> "${_sway_cfg}"
bar {
    position bottom
    status_command "${_status_script}"
    font pango:${_ui_font} Bold 10
    colors {
        background #1e1e22
        statusline #ffffff
        separator #38383d
        focused_workspace #3584e4 #2b2b30 #ffffff
        inactive_workspace #1e1e22 #1e1e22 #9a9996
    }
}
EOF
		fi
		_exec_wayland sway -c "${_sway_cfg}"
		local _sway_ret=$?
		rm -f "${_sway_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
		return "${_sway_ret}"
	elif command -v labwc > "/dev/null" 2>&1; then
		local _labwc_dir="${XDG_RUNTIME_DIR:-/tmp}/labwc-wm-$$"
		mkdir -p "${_labwc_dir}"
		cat << 'EOF' >| "${_labwc_dir}/themerc"
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
		cat << 'EOF' >| "${_labwc_dir}/menu.xml"
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
		cat << EOF >| "${_labwc_dir}/rc.xml"
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
</labwc_config>
EOF
		_exec_wayland labwc -C "${_labwc_dir}"
		local _labwc_ret=$?
		rm -rf "${_labwc_dir}" 2> "/dev/null" || true
		return "${_labwc_ret}"
	elif command -v river > "/dev/null" 2>&1; then
		local _river_init="${XDG_RUNTIME_DIR:-/tmp}/river-wm-$$.sh"
		cat << EOF >| "${_river_init}"
#!/bin/sh
riverctl border-width 1
riverctl border-color-focused "0x7e9cd8"
riverctl border-color-unfocused "0x54546d"
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
riverctl map normal Super Return spawn "foot -o dpi-aware=no"
riverctl map normal Super Q close
riverctl map normal Super+Shift Q spawn "riverctl exit"
EOF
		chmod 0755 "${_river_init}"
		_exec_wayland river -c "${_river_init}"
		local _river_ret=$?
		rm -f "${_river_init}" 2> "/dev/null" || true
		return "${_river_ret}"
	elif command -v cage > "/dev/null" 2>&1; then
		_exec_wayland cage -s -- foot -o dpi-aware=no
	elif command -v emacs > "/dev/null" 2>&1 || [ -f "${HOME}/.local/lib/libewm_core.so" ] || [ -f "${HOME}/.local/lib/libewm.so" ]; then
		emacs-window-manager-wayland
	else
		desktop-session-wayland
	fi
}
alias wwm="window-manager-wayland"

window-manager-x11() {
	unset EMACS_OS_MODE
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
	if [ "$#" -gt 0 ]; then
		start-session xorg "$@"
		return $?
	fi
	_x11_session_env "${_flavor}"

	local _ui_font="$(_resolve_desktop_font "${_flavor}")"

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

	local _wm_x11_term="xterm"
	for _t in alacritty kitty xterm; do
		if command -v "${_t}" > "/dev/null" 2>&1; then
			_wm_x11_term="${_t}"
			break
		fi
	done

	local _run_dir="${XDG_RUNTIME_DIR:-/tmp}"
	local _term_script="${_run_dir}/xwm-term-$$.sh"
	local _browser_script="${_run_dir}/xwm-browser-$$.sh"
	local _files_script="${_run_dir}/xwm-files-$$.sh"
	local _emacs_script="${_run_dir}/xwm-emacs-$$.sh"

	cat << EOF >| "${_term_script}"
#!/bin/sh
exec ${_wm_x11_term} "\$@"
EOF
	chmod 0755 "${_term_script}"

	cat << 'EOF' >| "${_browser_script}"
#!/bin/sh
for _b in firefox chromium google-chrome-stable google-chrome brave-browser; do
	if command -v "${_b}" > "/dev/null" 2>&1; then
		exec "${_b}" "$@"
	fi
done
EOF
	chmod 0755 "${_browser_script}"

	cat << EOF >| "${_files_script}"
#!/bin/sh
for _fm in nautilus dolphin thunar pcmanfm caja nemo; do
	if command -v "\${_fm}" > "/dev/null" 2>&1; then
		exec "\${_fm}" "\$@"
	fi
done
exec ${_wm_x11_term} -e sh -c 'ls -la; exec sh'
EOF
	chmod 0755 "${_files_script}"

	cat << 'EOF' >| "${_emacs_script}"
#!/bin/sh
for _e in emacs-gtk+x11 emacs-gtk emacs emacs-lucid; do
	if command -v "${_e}" > "/dev/null" 2>&1; then
		exec "${_e}" "$@"
	fi
done
EOF
	chmod 0755 "${_emacs_script}"

	if command -v openbox > "/dev/null" 2>&1; then
		local _ob_menu_cfg="${_run_dir}/openbox-menu-$$.xml"
		local _ob_wm_cfg="${_run_dir}/openbox-wm-$$.xml"
		local _cat_dev="${_run_dir}/menu-cat-dev-$$.xml"
		local _cat_net="${_run_dir}/menu-cat-net-$$.xml"
		local _cat_office="${_run_dir}/menu-cat-office-$$.xml"
		local _cat_media="${_run_dir}/menu-cat-media-$$.xml"
		local _cat_sys="${_run_dir}/menu-cat-sys-$$.xml"
		: >| "${_cat_dev}"
		: >| "${_cat_net}"
		: >| "${_cat_office}"
		: >| "${_cat_media}"
		: >| "${_cat_sys}"

		awk '
			FNR == 1 {
				if (in_entry && !nodisplay && name != "" && exec_cmd != "") {
					print cat "\t" substr(name, 1, 24) "\t" exec_cmd;
				}
				in_entry = 0; name = ""; exec_cmd = ""; nodisplay = 0; cat = "sys";
			}
			/^\[Desktop Entry\]/ { in_entry = 1; next }
			/^\[/ && !/^\[Desktop Entry\]/ { in_entry = 0 }
			in_entry && /^Name=/ && name == "" { name = substr($0, 6) }
			in_entry && /^Exec=/ && exec_cmd == "" {
				exec_cmd = substr($0, 6);
				sub(/[[:space:]]+%[a-zA-Z]/, "", exec_cmd);
			}
			in_entry && /^Categories=/ {
				cats = substr($0, 12);
				if (cats ~ /Development|IDE|Building/) {
					cat = "dev";
				} else if (cats ~ /Network|WebBrowser|Email|Chat/) {
					cat = "net";
				} else if (cats ~ /Office|WordProcessor|Spreadsheet|Viewer/) {
					cat = "office";
				} else if (cats ~ /AudioVideo|Audio|Video|Graphics/) {
					cat = "media";
				} else {
					cat = "sys";
				}
			}
			in_entry && (/^NoDisplay=true/ || /^Hidden=true/) { nodisplay = 1 }
			END {
				if (in_entry && !nodisplay && name != "" && exec_cmd != "") {
					print cat "\t" substr(name, 1, 24) "\t" exec_cmd;
				}
			}
		' /usr/share/applications/*.desktop /usr/local/share/applications/*.desktop /var/lib/flatpak/exports/share/applications/*.desktop "${HOME}/.local/share/applications/"*.desktop 2> "/dev/null" \
		| sort -u -k2,2 \
		| while IFS="$(printf '\t')" read -r _app_cat _app_name _app_exec; do
			[ -z "${_app_name}" ] || [ -z "${_app_exec}" ] && continue
			_safe_name="$(printf '%s' "${_app_name}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
			_safe_exec="$(printf '%s' "${_app_exec}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
			_item="    <item label=\"${_safe_name}\"><action name=\"Execute\"><command>${_safe_exec}</command></action></item>"
			case "${_app_cat}" in
				dev)    printf '%s\n' "${_item}" >> "${_cat_dev}" ;;
				net)    printf '%s\n' "${_item}" >> "${_cat_net}" ;;
				office) printf '%s\n' "${_item}" >> "${_cat_office}" ;;
				media)  printf '%s\n' "${_item}" >> "${_cat_media}" ;;
				*)      printf '%s\n' "${_item}" >> "${_cat_sys}" ;;
			esac
		done

		cat << EOF >| "${_ob_menu_cfg}"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Universal Environment">
    <item label="Web Browser">
      <action name="Execute"><command>${_browser_script}</command></action>
    </item>
    <item label="Terminal">
      <action name="Execute"><command>${_term_script}</command></action>
    </item>
    <item label="Files">
      <action name="Execute"><command>${_files_script}</command></action>
    </item>
    <item label="Emacs">
      <action name="Execute"><command>${_emacs_script}</command></action>
    </item>
    <separator/>
    <menu id="cat-dev" label="Development">
$(cat "${_cat_dev}")
    </menu>
    <menu id="cat-net" label="Internet">
$(cat "${_cat_net}")
    </menu>
    <menu id="cat-office" label="Office">
$(cat "${_cat_office}")
    </menu>
    <menu id="cat-media" label="Media &amp; Graphics">
$(cat "${_cat_media}")
    </menu>
    <menu id="cat-sys" label="System &amp; Tools">
$(cat "${_cat_sys}")
    </menu>
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
		rm -f "${_cat_dev}" "${_cat_net}" "${_cat_office}" "${_cat_media}" "${_cat_sys}" 2> "/dev/null" || true

		cat << EOF >| "${_ob_wm_cfg}"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>kiosk</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>no</animateIconify>
    <font place="ActiveWindow"><name>${_ui_font}</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="InactiveWindow"><name>${_ui_font}</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="MenuHeader"><name>${_ui_font}</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="MenuItem"><name>${_ui_font}</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
    <font place="ActiveOnScreenDisplay"><name>${_ui_font}</name><size>10</size><weight>Bold</weight><slant>Normal</slant></font>
    <font place="InactiveOnScreenDisplay"><name>${_ui_font}</name><size>10</size><weight>Normal</weight><slant>Normal</slant></font>
  </theme>
  <mouse>
    <dragThreshold>1</dragThreshold>
    <doubleClickTime>500</doubleClickTime>
    <screenEdgeWarpTime>0</screenEdgeWarpTime>
    <screenEdgeWarpMouse>false</screenEdgeWarpMouse>
    <context name="Frame">
      <mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="A-Right" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="A-Right" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="ToggleMaximize"/></mousebind>
    </context>
    <context name="Top">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>top</edge></action></mousebind>
    </context>
    <context name="Bottom">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>bottom</edge></action></mousebind>
    </context>
    <context name="Left">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>left</edge></action></mousebind>
    </context>
    <context name="Right">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>right</edge></action></mousebind>
    </context>
    <context name="TLCorner">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="TRCorner">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="BLCorner">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="BRCorner">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="Handle">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"><edge>bottom</edge></action></mousebind>
    </context>
    <context name="BLGrip">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="BRGrip">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
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
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
  </mouse>
  <menu>
    <file>${_ob_menu_cfg}</file>
  </menu>
  <keyboard>
    <keybind key="W-Return"><action name="Execute"><command>${_term_script}</command></action></keybind>
    <keybind key="C-A-t"><action name="Execute"><command>${_term_script}</command></action></keybind>
    <keybind key="W-b"><action name="Execute"><command>${_browser_script}</command></action></keybind>
    <keybind key="W-e"><action name="Execute"><command>${_emacs_script}</command></action></keybind>
    <keybind key="W-f"><action name="Execute"><command>${_files_script}</command></action></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-S-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF
		_exec_x11 openbox --config-file "${_ob_wm_cfg}"
		local _ob_ret=$?
		rm -f "${_ob_menu_cfg}" "${_ob_wm_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" 2> "/dev/null" || true
		return "${_ob_ret}"
	elif command -v openbox-session > "/dev/null" 2>&1; then
		_exec_x11 openbox-session
	elif command -v cwm > "/dev/null" 2>&1; then
		local _cwm_cfg="${XDG_RUNTIME_DIR:-/tmp}/cwmrc-wm-$$"
		cat << EOF >| "${_cwm_cfg}"
color activeborder "#7e9cd8"
color inactiveborder "#1f1f28"
color menubg "#16161e"
color menufg "#dcd7ba"
bind-key 4-Return "${_wm_x11_term}"
bind-key CM-t "${_wm_x11_term}"
bind-key 4-b "${_wm_browser}"
bind-key 4-e "${_wm_emacs}"
bind-key 4-q window-close
bind-key M-F4 window-close
bind-key 4S-q quit
EOF
		_exec_x11 cwm -c "${_cwm_cfg}"
		local _cwm_ret=$?
		rm -f "${_cwm_cfg}" 2> "/dev/null" || true
		return "${_cwm_ret}"
	elif command -v matchbox-window-manager > "/dev/null" 2>&1; then
		_exec_x11 sh -c '(command -v xterm > "/dev/null" 2>&1 && xterm &); exec matchbox-window-manager'
	elif command -v emacs > "/dev/null" 2>&1; then
		emacs-window-manager-x11
	else
		desktop-session-x11
	fi
}
alias xwm="window-manager-x11"

window-manager() { _dispatch_display_server "window-manager" "$@"; }
alias wm="window-manager" win="window-manager" win-man="window-manager" window="window-manager"
