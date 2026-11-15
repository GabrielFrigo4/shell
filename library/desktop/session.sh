# ----------------------------------------------------------------
# Library: Desktop Session, Display Server & Input Orchestration
# ----------------------------------------------------------------

### --------------------------------
### GRAPHICAL HELPERS
### --------------------------------
_sanitize_graphical_env() {
	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST _IS_RAW_TTY_CACHED
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1
}

_get_shell_log_dir() {
	local _log_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/shell/logs"
	[ -d "${_log_dir}" ] || mkdir -p "${_log_dir}" 2> "/dev/null" || true
	printf '%s\n' "${_log_dir}"
}

_resolve_graphical_app() {
	local _target="${1:-}" _candidate
	case "${_target}" in
		vscode|code|code-oss|codium)
			if ! command -v "${_target}" > "/dev/null" 2>&1; then
				for _candidate in code code-oss codium vscode; do
					if command -v "${_candidate}" > "/dev/null" 2>&1; then
						echo "${_candidate}"
						return 0
					fi
				done
			fi
			;;
		chrome|chromium|google-chrome)
			if ! command -v "${_target}" > "/dev/null" 2>&1; then
				for _candidate in chrome chromium google-chrome brave-browser brave; do
					if command -v "${_candidate}" > "/dev/null" 2>&1; then
						echo "${_candidate}"
						return 0
					fi
				done
			fi
			;;
	esac
	echo "${_target}"
}

_resolve_desktop_font() {
	local _target_flavor="${1:-}" _font
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
				for _font in "Adwaita Sans" "Cantarell"; do
					if fc-list : family 2> "/dev/null" | grep -qi "^${_font}$"; then
						printf '%s\n' "${_font}"
						return 0
					fi
				done
				;;
			pantheon)
				for _font in "Inter" "Open Sans" "Cantarell"; do
					if fc-list : family 2> "/dev/null" | grep -qi "^${_font}$"; then
						printf '%s\n' "${_font}"
						return 0
					fi
				done
				;;
			deepin)
				for _font in "Noto Sans" "Source Han Sans" "Cantarell"; do
					if fc-list : family 2> "/dev/null" | grep -qi "^${_font}$"; then
						printf '%s\n' "${_font}"
						return 0
					fi
				done
				;;
			cosmic)
				for _font in "Fira Sans" "Noto Sans"; do
					if fc-list : family 2> "/dev/null" | grep -qi "^${_font}$"; then
						printf '%s\n' "${_font}"
						return 0
					fi
				done
				;;
			mate|cinnamon|xfce|lxde)
				for _font in "Ubuntu" "DejaVu Sans"; do
					if fc-list : family 2> "/dev/null" | grep -qi "^${_font}$"; then
						printf '%s\n' "${_font}"
						return 0
					fi
				done
				;;
		esac
		for _font in "Adwaita Sans" "Cantarell" "Noto Sans" "Ubuntu" "DejaVu Sans"; do
			if fc-list : family 2> "/dev/null" | grep -qi "^${_font}$"; then
				printf '%s\n' "${_font}"
				return 0
			fi
		done
	fi
	printf '%s\n' "Sans"
}

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
			_cursor_theme="$(_resolve_cursor_theme "${_flavor}" 2> "/dev/null" || echo "breeze_cursors")"
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
				_cursor_theme="$(_resolve_cursor_theme "${_flavor}" 2> "/dev/null" || echo "breeze_cursors")"
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
			_cursor_theme="$(_resolve_cursor_theme kde 2> "/dev/null" || echo "breeze_cursors")"
		elif command -v mate-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v cinnamon-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v xfce4-session > "/dev/null" 2>&1; then
			_cursor_theme="Adwaita"
		elif command -v lxqt-session > "/dev/null" 2>&1; then
			_cursor_theme="$(_resolve_cursor_theme lxqt 2> "/dev/null" || echo "breeze_cursors")"
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
	if [ -z "${_cursor_theme}" ] && command -v _resolve_cursor_theme > "/dev/null" 2>&1; then
		_cursor_theme="$(_resolve_cursor_theme "${_flavor}" 2> "/dev/null" || true)"
	fi
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

	local _color_scheme="${2:-}"
	if [ -z "${_color_scheme}" ]; then
		if command -v _detect_color_scheme > "/dev/null" 2>&1; then
			_color_scheme="$(_detect_color_scheme "${_flavor}" 2> "/dev/null" || echo "dark")"
		else
			_color_scheme="dark"
		fi
	fi

	local _icon_theme=""
	if command -v _resolve_icon_theme > "/dev/null" 2>&1; then
		_icon_theme="$(_resolve_icon_theme "${_flavor}" "${_color_scheme}" 2> "/dev/null" || true)"
	fi
	if [ -z "${_icon_theme}" ]; then
		case "${_flavor}" in
			kde|plasma|lxqt)
				if [ "${_color_scheme}" = "light" ]; then
					_icon_theme="breeze"
				else
					_icon_theme="breeze-dark"
				fi
				;;
			pantheon) _icon_theme="elementary" ;;
			deepin)   _icon_theme="bloom" ;;
			cosmic)   _icon_theme="cosmic" ;;
			*)        _icon_theme="Adwaita" ;;
		esac
	fi

	mkdir -p "${HOME}/.icons/default" 2> "/dev/null" || true
	printf '[Icon Theme]\nInherits=%s\n' "${_valid_theme}" >| "${HOME}/.icons/default/index.theme" 2> "/dev/null" || true

	local _de_key="${_flavor:-$(_detect_desktop_theme 2> "/dev/null" || echo "gnome")}"
	case "${_de_key}" in
		kde|plasma)   _de_key="kde" ;;
		gnome)        _de_key="gnome" ;;
		cosmic)       _de_key="cosmic" ;;
		xfce)         _de_key="xfce" ;;
		mate)         _de_key="mate" ;;
		cinnamon)     _de_key="cinnamon" ;;
		lxqt)         _de_key="lxqt" ;;
		lxde)         _de_key="lxde" ;;
		budgie)       _de_key="budgie" ;;
		pantheon)     _de_key="pantheon" ;;
		deepin|dde)   _de_key="deepin" ;;
		*)            _de_key="gnome" ;;
	esac

	local _gtk_theme_val=""
	if command -v _resolve_gtk_theme > "/dev/null" 2>&1; then
		_gtk_theme_val="$(_resolve_gtk_theme "${_de_key}" "${_color_scheme}" 2> "/dev/null" || true)"
	fi
	if [ -z "${_gtk_theme_val}" ]; then
		if [ "${_de_key}" = "kde" ] || [ "${_de_key}" = "lxqt" ]; then
			[ "${_color_scheme}" = "light" ] && _gtk_theme_val="Breeze" || _gtk_theme_val="Breeze-Dark"
		else
			[ "${_color_scheme}" = "light" ] && _gtk_theme_val="adw-gtk3" || _gtk_theme_val="adw-gtk3-dark"
		fi
	fi

	local _prefer_dark=1
	[ "${_color_scheme}" = "light" ] && _prefer_dark=0

	_sync_gtk_settings_ini "${_de_key}" "${_gtk_theme_val}" "${_icon_theme}" "${_valid_theme}" "${_target_size}" "${_prefer_dark}"

	if [ -n "${DISPLAY:-}" ]; then
		if command -v xrdb > "/dev/null" 2>&1; then
			printf "Xcursor.theme: %s\nXcursor.size: %s\nXTerm*cursorBlink: always\nXTerm*cursorOnTime: 600\nXTerm*cursorOffTime: 600\n" "${_valid_theme}" "${_target_size}" | xrdb -merge - > "/dev/null" 2>&1 || true
		fi
		command -v xsetroot > "/dev/null" 2>&1 && xsetroot -cursor_name left_ptr > "/dev/null" 2>&1 || true
	fi
	if command -v gsettings > "/dev/null" 2>&1; then
		case "${_de_key}" in
			gnome|budgie|pantheon|mate|cinnamon|xfce|lxde)
				gsettings set org.gnome.desktop.interface cursor-theme "${_valid_theme}" > "/dev/null" 2>&1 || true
				gsettings set org.gnome.desktop.interface cursor-size "${_target_size}" > "/dev/null" 2>&1 || true
				gsettings set org.gnome.desktop.interface cursor-blink true > "/dev/null" 2>&1 || true
				gsettings set org.gnome.desktop.interface cursor-blink-time 1200 > "/dev/null" 2>&1 || true
				gsettings set org.gnome.desktop.interface icon-theme "${_icon_theme}" > "/dev/null" 2>&1 || true
				;;
		esac
	fi
}

_set_ini_key() {
	local _ini_file="$1" _key="$2" _val="$3"
	if grep -q "^${_key}=" "${_ini_file}" 2> "/dev/null"; then
		sed "s|^${_key}=.*|${_key}=${_val}|" "${_ini_file}" > "${_ini_file}.1" 2> "/dev/null" && mv -f "${_ini_file}.1" "${_ini_file}" 2> "/dev/null" || true
	else
		printf '%s=%s\n' "${_key}" "${_val}" >> "${_ini_file}" 2> "/dev/null" || true
	fi
}

_sync_gtk_settings_ini() {
	local _de_key="${1:-gnome}" _gtk_theme_val="${2:-adw-gtk3-dark}" _icon_theme="${3:-Adwaita}"
	local _valid_theme="${4:-Adwaita}" _target_size="${5:-24}" _prefer_dark="${6:-1}"
	local _cfg_base="${XDG_CONFIG_HOME:-${HOME}/.config}"
	local _data_base="${XDG_DATA_HOME:-${HOME}/.local/share}"
	local _gtk_ver _rt_dir _rt_file _cfg_tmp _symlink

	for _gtk_ver in gtk-3.0 gtk-4.0; do
		_rt_dir="${_data_base}/profile/runtime/${_gtk_ver}"
		mkdir -p "${_rt_dir}" 2> "/dev/null" || true
		_rt_file="${_rt_dir}/settings-${_de_key}.ini"
		_cfg_tmp="${_rt_file}.tmp.$$"
		if [ -f "${_rt_file}" ]; then
			cat "${_rt_file}" >| "${_cfg_tmp}" 2> "/dev/null" || true
		else
			printf '[Settings]\n' >| "${_cfg_tmp}" 2> "/dev/null" || true
		fi

		_set_ini_key "${_cfg_tmp}" "gtk-cursor-theme-name" "${_valid_theme}"
		_set_ini_key "${_cfg_tmp}" "gtk-cursor-theme-size" "${_target_size}"
		_set_ini_key "${_cfg_tmp}" "gtk-cursor-blink" "true"
		_set_ini_key "${_cfg_tmp}" "gtk-cursor-blink-time" "1200"
		_set_ini_key "${_cfg_tmp}" "gtk-icon-theme-name" "${_icon_theme}"
		_set_ini_key "${_cfg_tmp}" "gtk-theme-name" "${_gtk_theme_val}"
		_set_ini_key "${_cfg_tmp}" "gtk-application-prefer-dark-theme" "${_prefer_dark}"

		mv -f "${_cfg_tmp}" "${_rt_file}" 2> "/dev/null" || true
		rm -f "${_cfg_tmp}" "${_cfg_tmp}.1" 2> "/dev/null" || true

		_symlink="${_cfg_base}/${_gtk_ver}/settings.ini"
		mkdir -p "${_cfg_base}/${_gtk_ver}" 2> "/dev/null" || true
		rm -f "${_symlink}" 2> "/dev/null" || true
		ln -s "${_rt_file}" "${_symlink}" 2> "/dev/null" || cp -f "${_rt_file}" "${_symlink}" 2> "/dev/null" || true
	done
}

_strip_env_var_from_file() {
	local _target_file="$1" _var_name="$2"
	[ -f "${_target_file}" ] || return 0
	if grep -qE "^[[:space:]]*(export[[:space:]]+)?${_var_name}=" "${_target_file}" 2> "/dev/null"; then
		sed -E "/^[[:space:]]*(export[[:space:]]+)?${_var_name}=/d" "${_target_file}" >| "${_target_file}.tmp.$$" 2> "/dev/null" && \
			mv -f "${_target_file}.tmp.$$" "${_target_file}" 2> "/dev/null" || rm -f "${_target_file}.tmp.$$" 2> "/dev/null" || true
	fi
}

_upsert_export_in_file() {
	local _target_file="$1" _var_name="$2" _var_val="$3"
	[ -f "${_target_file}" ] || return 0
	if grep -q "^[[:space:]]*export ${_var_name}=" "${_target_file}" 2> "/dev/null"; then
		sed "s|^[[:space:]]*export ${_var_name}=.*|export ${_var_name}=\"${_var_val}\"|" "${_target_file}" >| "${_target_file}.tmp.$$" 2> "/dev/null" && \
			mv -f "${_target_file}.tmp.$$" "${_target_file}" 2> "/dev/null" || rm -f "${_target_file}.tmp.$$" 2> "/dev/null" || true
	elif ! grep -q "^[[:space:]]*${_var_name}=" "${_target_file}" 2> "/dev/null"; then
		printf 'export %s="%s"\n' "${_var_name}" "${_var_val}" >> "${_target_file}" 2> "/dev/null" || true
	fi
}

### --------------------------------
### SESSION THEME PROPAGATION
### --------------------------------
_propagate_session_theme_env() {
	local _flavor="${1:-$(_detect_desktop_theme 2> "/dev/null" || echo "gnome")}"
	local _scheme="dark"
	if command -v _detect_color_scheme > "/dev/null" 2>&1; then
		_scheme="$(_detect_color_scheme "${_flavor}" 2> "/dev/null" || echo "dark")"
	fi

	local _gtk_theme="adw-gtk3-dark" _qt_theme="" _qt_platform="kde"
	if command -v _resolve_gtk_theme > "/dev/null" 2>&1; then
		_gtk_theme="$(_resolve_gtk_theme "${_flavor}" "${_scheme}" 2> "/dev/null" || echo "adw-gtk3-dark")"
	fi
	if command -v _detect_qt_theme > "/dev/null" 2>&1; then
		_qt_theme="$(_detect_qt_theme 2> "/dev/null" || echo "")"
	fi
	case "${_flavor}" in
		kde|plasma)
			_qt_platform="kde"
			[ "${_scheme}" = "light" ] && _qt_theme="Breeze" || _qt_theme="Breeze-Dark"
			[ "${_scheme}" = "light" ] && _gtk_theme="Breeze" || _gtk_theme="Breeze-Dark"
			;;
		lxqt)
			_qt_platform="lxqt"
			[ "${_scheme}" = "light" ] && _qt_theme="Breeze" || _qt_theme="Breeze-Dark"
			[ "${_scheme}" = "light" ] && _gtk_theme="Breeze" || _gtk_theme="Breeze-Dark"
			;;
		*)
			if command -v _detect_qt_platform_theme > "/dev/null" 2>&1; then
				_qt_platform="$(_detect_qt_platform_theme 2> "/dev/null" || echo "qt6ct")"
			fi
			[ -z "${_qt_platform}" ] && _qt_platform="qt6ct"
			;;
	esac

	local _env_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d"
	mkdir -p "${_env_dir}" 2> "/dev/null" || true
	rm -f "${_env_dir}/gtk-dark.conf" 2> "/dev/null" || true
	cat <<- EOF >| "${_env_dir}/10-theme.conf"
		QT_QPA_PLATFORMTHEME=${_qt_platform}
		SAL_USE_VCLPLUGIN=gtk3
	EOF

	local _xprofile="${HOME}/.xprofile"
	if [ ! -f "${_xprofile}" ]; then
		cat <<- EOF >| "${_xprofile}"
			#!/usr/bin/env sh
			export QT_QPA_PLATFORMTHEME="${_qt_platform}"
			export SAL_USE_VCLPLUGIN="gtk3"
		EOF
		chmod 0755 "${_xprofile}" 2> "/dev/null" || true
	else
		_strip_env_var_from_file "${_xprofile}" "GTK_THEME"
		_strip_env_var_from_file "${_xprofile}" "GTK_APPLICATION_PREFER_DARK_THEME"
		_strip_env_var_from_file "${_xprofile}" "QT_STYLE_OVERRIDE"
		_upsert_export_in_file "${_xprofile}" "QT_QPA_PLATFORMTHEME" "${_qt_platform}"
		_upsert_export_in_file "${_xprofile}" "SAL_USE_VCLPLUGIN" "gtk3"
	fi

	local _rc_file
	for _rc_file in "${HOME}/.profile" "${HOME}/.zshenv"; do
		[ -f "${_rc_file}" ] || continue
		_strip_env_var_from_file "${_rc_file}" "GTK_THEME"
		_strip_env_var_from_file "${_rc_file}" "GTK_APPLICATION_PREFER_DARK_THEME"
		_strip_env_var_from_file "${_rc_file}" "QT_STYLE_OVERRIDE"
		_upsert_export_in_file "${_rc_file}" "QT_QPA_PLATFORMTHEME" "${_qt_platform}"
		_upsert_export_in_file "${_rc_file}" "SAL_USE_VCLPLUGIN" "gtk3"
	done

	if command -v gsettings > "/dev/null" 2>&1; then
		case "${_flavor}" in
			gnome|budgie|pantheon|adwaita)
				gsettings set org.gnome.desktop.interface gtk-theme "${_gtk_theme}" > "/dev/null" 2>&1 || true
				;;
		esac
	fi

	local _bin_wrapper=""
	if [ -n "${SHELL_REPO_DIR:-}" ] && [ -x "${SHELL_REPO_DIR}/.scripts/emacs-client" ]; then
		_bin_wrapper="${SHELL_REPO_DIR}/.scripts/emacs-client"
	elif [ -x "${HOME}/.local/share/shell/.scripts/emacs-client" ]; then
		_bin_wrapper="${HOME}/.local/share/shell/.scripts/emacs-client"
	elif [ -x "/usr/local/share/shell/.scripts/emacs-client" ]; then
		_bin_wrapper="/usr/local/share/shell/.scripts/emacs-client"
	fi
	if [ -n "${_bin_wrapper}" ]; then
		mkdir -p "${HOME}/.local/bin" 2> "/dev/null" || true
		if [ ! -e "${HOME}/.local/bin/emacs-client" ] || [ -L "${HOME}/.local/bin/emacs-client" ]; then
			ln -sf "${_bin_wrapper}" "${HOME}/.local/bin/emacs-client" 2> "/dev/null" || true
		fi
	fi
}

### --------------------------------
### WAYLAND & X11 SESSION ENV
### --------------------------------
_apply_common_theme_exports() {
	local _theme_flavor="$1" _color_scheme="$2" _is_full_de="${3:-0}"
	export _RESOLVED_THEME_FLAVOR="${_theme_flavor}"
	export _RESOLVED_COLOR_SCHEME="${_color_scheme}"
	export SAL_USE_VCLPLUGIN="gtk3"

	local _gtk_theme=""
	if command -v _resolve_gtk_theme > "/dev/null" 2>&1; then
		_gtk_theme="$(_resolve_gtk_theme "${_theme_flavor}" "${_color_scheme}" 2> "/dev/null" || true)"
	fi
	if [ -z "${_gtk_theme}" ]; then
		if [ "${_theme_flavor}" = "kde" ] || [ "${_theme_flavor}" = "lxqt" ]; then
			[ "${_color_scheme}" = "light" ] && _gtk_theme="Breeze" || _gtk_theme="Breeze-Dark"
		else
			[ "${_color_scheme}" = "light" ] && _gtk_theme="adw-gtk3" || _gtk_theme="adw-gtk3-dark"
		fi
	fi

	local _icon_theme="Adwaita"
	if command -v _resolve_icon_theme > "/dev/null" 2>&1; then
		_icon_theme="$(_resolve_icon_theme "${_theme_flavor}" "${_color_scheme}" 2> "/dev/null" || echo "Adwaita")"
	fi
	export _RESOLVED_ICON_THEME="${_icon_theme}"

	if [ "${_is_full_de}" -eq 1 ]; then
		unset GTK_THEME GTK_APPLICATION_PREFER_DARK_THEME ADW_DEBUG_COLOR_SCHEME QT_STYLE_OVERRIDE 2> "/dev/null" || true
	else
		export GTK_THEME="${_gtk_theme}"
		if [ "${_color_scheme}" = "light" ]; then
			export GTK_APPLICATION_PREFER_DARK_THEME=0 ADW_DEBUG_COLOR_SCHEME="default"
		else
			export GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DEBUG_COLOR_SCHEME="prefer-dark"
		fi
	fi

	case "${_theme_flavor}" in
		kde|plasma)
			export XDG_CURRENT_DESKTOP="KDE" DESKTOP_SESSION="${DESKTOP_SESSION:-kde}" QT_QPA_PLATFORMTHEME="kde"
			if [ "${_is_full_de}" -eq 0 ]; then
				[ "${_color_scheme}" = "light" ] && export QT_STYLE_OVERRIDE="Breeze" || export QT_STYLE_OVERRIDE="Breeze-Dark"
			fi
			;;
		lxqt)
			export XDG_CURRENT_DESKTOP="LXQt" DESKTOP_SESSION="${DESKTOP_SESSION:-lxqt}" QT_QPA_PLATFORMTHEME="lxqt"
			[ "${_is_full_de}" -eq 0 ] && export QT_STYLE_OVERRIDE="Breeze"
			;;
		cosmic)
			export XDG_CURRENT_DESKTOP="COSMIC" DESKTOP_SESSION="${DESKTOP_SESSION:-cosmic}" QT_QPA_PLATFORMTHEME="cosmic"
			;;
		budgie)
			export XDG_CURRENT_DESKTOP="Budgie:GNOME" DESKTOP_SESSION="${DESKTOP_SESSION:-budgie}" QT_QPA_PLATFORMTHEME="qt6ct"
			;;
		pantheon)
			export XDG_CURRENT_DESKTOP="Pantheon" DESKTOP_SESSION="${DESKTOP_SESSION:-pantheon}" QT_QPA_PLATFORMTHEME="qt6ct"
			;;
		deepin)
			export XDG_CURRENT_DESKTOP="DDE" DESKTOP_SESSION="${DESKTOP_SESSION:-deepin}" QT_QPA_PLATFORMTHEME="deepin"
			;;
		*)
			case "${_theme_flavor}" in
				cinnamon) export XDG_CURRENT_DESKTOP="X-Cinnamon" DESKTOP_SESSION="${DESKTOP_SESSION:-cinnamon}" ;;
				mate)     export XDG_CURRENT_DESKTOP="MATE" DESKTOP_SESSION="${DESKTOP_SESSION:-mate}" ;;
				xfce)     export XDG_CURRENT_DESKTOP="XFCE" DESKTOP_SESSION="${DESKTOP_SESSION:-xfce}" ;;
				lxde)     export XDG_CURRENT_DESKTOP="LXDE" DESKTOP_SESSION="${DESKTOP_SESSION:-lxde}" ;;
				*)        export XDG_CURRENT_DESKTOP="GNOME" DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}" ;;
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
	export DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}"
}

_wayland_session_env() {
	local _target_flavor="${1:-}" _is_full_de="${2:-0}"
	[ -z "${XDG_RUNTIME_DIR:-}" ] && export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
	[ ! -d "${XDG_RUNTIME_DIR}" ] && mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"

	unset DISPLAY XAUTHORITY 2> "/dev/null" || true
	export XDG_SESSION_TYPE="wayland"
	export XKB_DEFAULT_LAYOUT="br" XKB_DEFAULT_MODEL="abnt2" XKB_DEFAULT_OPTIONS="numpad:mac"
	export WLR_KEYBOARD_REPEAT_DELAY=200 WLR_KEYBOARD_REPEAT_RATE=50
	export GDK_BACKEND="wayland,x11" CLUTTER_BACKEND="wayland" SDL_VIDEODRIVER="wayland"
	export MOZ_ENABLE_WAYLAND=1 ELECTRON_OZONE_PLATFORM_HINT="auto"
	export QT_QPA_PLATFORM="wayland;xcb"

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	local _color_scheme="dark"
	if command -v _detect_color_scheme > "/dev/null" 2>&1; then
		_color_scheme="$(_detect_color_scheme "${_theme_flavor}" 2> "/dev/null" || echo "dark")"
	fi

	_apply_common_theme_exports "${_theme_flavor}" "${_color_scheme}" "${_is_full_de}"
	_setup_cursor_env "${_theme_flavor}" "${_color_scheme}"
	_propagate_session_theme_env "${_theme_flavor}"
	_enable_numlock_console
}

_x11_session_env() {
	local _target_flavor="${1:-}" _is_full_de="${2:-0}"
	unset WAYLAND_DISPLAY 2> "/dev/null" || true
	export XDG_SESSION_TYPE="x11" GDK_BACKEND="x11" QT_QPA_PLATFORM="xcb" SDL_VIDEODRIVER="x11" CLUTTER_BACKEND="x11"
	export XORG_RUN_AS_USER_OK=1 XKB_DEFAULT_LAYOUT="br" XKB_DEFAULT_MODEL="abnt2" XKB_DEFAULT_OPTIONS="numpad:mac"
	export vblank_mode=3 __GL_SYNC_TO_VBLANK=1

	local _theme_flavor="$(_detect_desktop_theme "${_target_flavor}")"
	local _color_scheme="dark"
	if command -v _detect_color_scheme > "/dev/null" 2>&1; then
		_color_scheme="$(_detect_color_scheme "${_theme_flavor}" 2> "/dev/null" || echo "dark")"
	fi

	_apply_common_theme_exports "${_theme_flavor}" "${_color_scheme}" "${_is_full_de}"

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

	_setup_cursor_env "${_theme_flavor}" "${_color_scheme}"
	_propagate_session_theme_env "${_theme_flavor}"
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
					command vidcontrol -s "${_vt_idx}" < "${_cur_tty}" 2> "/dev/null" || echo -n $'\ec'
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
	printf '#!/usr/bin/env sh\nrm -f "$0"\nexec %s\n' "$(_session_quote_args "$@")" >| "${_file}"
	chmod 0700 "${_file}"
	printf '%s\n' "${_file}"
}

### --------------------------------
### PREFLIGHT & XORG DIAGNOSTICS
### --------------------------------
_has_exec_bin() {
	local _bin="$1" _old_ifs _p
	[ -z "${_bin}" ] && return 1
	case "${_bin}" in
		/*) [ -x "${_bin}" ] && [ ! -d "${_bin}" ] && return 0 || return 1 ;;
	esac
	_old_ifs="${IFS}"
	IFS=":"
	for _p in ${PATH:-}; do
		[ -z "${_p}" ] && _p="."
		if [ -x "${_p}/${_bin}" ] && [ ! -d "${_p}/${_bin}" ]; then
			IFS="${_old_ifs}"
			return 0
		fi
	done
	IFS="${_old_ifs}"
	return 1
}

_has_drm_card() {
	local _dri
	for _dri in /dev/dri/card*; do
		[ -c "${_dri}" ] && return 0
	done
	return 1
}

_is_full_de_cmd() {
	local _cmd="${1##*/}"
	case "${_cmd}" in
		startplasma-wayland|plasma-wayland-session|startplasma-x11|startkde|gnome-session|gnome-shell|startxfce4|xfce4-session|mate-session|cinnamon-session|cinnamon-session-wayland|startlxqt|lxqt-wayland-session|startlxqt-wayland|lxqt-session|startlxde|lxsession|budgie-desktop|pantheon-session|startdde|dde-session|cosmic-session|start-cosmic)
			return 0
			;;
	esac
	return 1
}

_preflight_wayland() {
	local _bin="${1:-}"
	_has_exec_bin "${_bin}" || return 127
	if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WLR_BACKENDS:-}" ] && [ "${SHELL_ALLOW_NO_DRM:-0}" != "1" ]; then
		case "$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')" in
			linux|freebsd)
				_has_drm_card || return 127
				;;
		esac
	fi
	if [ "${_WAYLAND_REQUIRE_XWAYLAND:-0}" = "1" ] && [ -z "${DISPLAY:-}" ]; then
		_has_exec_bin "Xwayland" || return 127
	fi
	return 0
}

_x11_driver_preflight() {
	local _log_target="${1:-}"
	[ "$(_detect_os)" = "freebsd" ] || return 0
	_has_drm_card && return 0
	if [ -n "${_log_target}" ]; then
		printf 'WARNING: /dev/dri/card* ausente: Xorg usará fallback scfb (verifique kld_list i915kms/amdgpu).\n' >> "${_log_target}" 2> "/dev/null" || true
	fi
}

### --------------------------------
### GRAPHICAL SESSION LAUNCHERS
### --------------------------------
_exec_wayland() {
	_preflight_wayland "${1:-}" || return 127
	_sanitize_graphical_env
	local _log_dir="$(_get_shell_log_dir)"
	local _log_file="${_log_dir}/wayland-session.log"
	local _ret=0
	local _is_full_de=0

	if [ "${_SESSION_IS_FULL_DE:-0}" = "1" ] || _is_full_de_cmd "${1:-}"; then
		_is_full_de=1
		_wayland_session_env "${_WAYLAND_FLAVOR_OVERRIDE:-}" 1
	fi

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	if [ "${_is_full_de}" -eq 1 ]; then
		unset GTK_THEME GTK_APPLICATION_PREFER_DARK_THEME ADW_DEBUG_COLOR_SCHEME QT_STYLE_OVERRIDE 2> "/dev/null" || true
	fi

	if command -v gnome-keyring-daemon > "/dev/null" 2>&1; then
		eval "$(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2>> "${_log_file}")" > "/dev/null" 2>&1 || true
		[ -n "${SSH_AUTH_SOCK:-}" ] && export SSH_AUTH_SOCK
		if command -v dbus-update-activation-environment > "/dev/null" 2>&1; then
			dbus-update-activation-environment --systemd SSH_AUTH_SOCK DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP >> "${_log_file}" 2>&1 || \
			dbus-update-activation-environment SSH_AUTH_SOCK DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP >> "${_log_file}" 2>&1 || true
		fi
	fi

	if [ "$(_detect_os)" = "freebsd" ]; then
		if command -v ck-launch-session > "/dev/null" 2>&1; then
			local _ck_cmd="$(_session_cmd_file "$@")"
			if command -v dbus-run-session > "/dev/null" 2>&1; then
				dbus-run-session -- ck-launch-session "${_ck_cmd}" >> "${_log_file}" 2>&1
				_ret=$?
			elif command -v dbus-launch > "/dev/null" 2>&1; then
				dbus-launch --exit-with-session ck-launch-session "${_ck_cmd}" >> "${_log_file}" 2>&1
				_ret=$?
			else
				ck-launch-session "${_ck_cmd}" >> "${_log_file}" 2>&1
				_ret=$?
			fi
		elif command -v dbus-run-session > "/dev/null" 2>&1; then
			dbus-run-session -- "$@" >> "${_log_file}" 2>&1
			_ret=$?
		elif command -v dbus-launch > "/dev/null" 2>&1; then
			dbus-launch --exit-with-session "$@" >> "${_log_file}" 2>&1
			_ret=$?
		else
			"$@" >> "${_log_file}" 2>&1
			_ret=$?
		fi
	else
		if command -v dbus-run-session > "/dev/null" 2>&1; then
			dbus-run-session -- "$@" >> "${_log_file}" 2>&1
			_ret=$?
		elif command -v dbus-launch > "/dev/null" 2>&1; then
			dbus-launch --exit-with-session "$@" >> "${_log_file}" 2>&1
			_ret=$?
		else
			"$@" >> "${_log_file}" 2>&1
			_ret=$?
		fi
	fi

	_freebsd_vt_bounce > "/dev/null" 2>&1
	[ "${_ret}" -eq 127 ] && _ret=1

	if [ "${_ret}" -ne 0 ]; then
		_ui_err "Sessão Wayland encerrou com erro (código ${_ret}). Log: ${_log_file}"
		return "${_ret}"
	fi
	return 0
}

_resolve_vt_arg() {
	local _cur_tty="${1:-$(tty 2> "/dev/null" || true)}" _hex _num
	case "${_cur_tty}" in
		/dev/ttyv[0-9a-fA-F]*|/dev/ttyC[0-9a-fA-F]*|/dev/ttyE[0-9a-fA-F]*)
			_hex="$(printf '%s\n' "${_cur_tty}" | sed -n 's#.*/tty[vCE]\([0-9a-fA-F]\{1,2\}\)$#\1#p')"
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
	{ _has_exec_bin "startx" || _has_exec_bin "xinit"; } || return 127
	{ _has_exec_bin "Xorg" || _has_exec_bin "X"; } || return 127
	if [ "$#" -gt 0 ]; then
		_has_exec_bin "$1" || return 127
	fi

	local _is_full_de=0
	if [ "${_X11_SESSION_IS_FULL_DE:-0}" = "1" ] || { [ "$#" -gt 0 ] && _is_full_de_cmd "$1"; }; then
		_is_full_de=1
	fi

	local _had_display=1
	[ -z "${DISPLAY:-}" ] && _had_display=0

	unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
	export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1

	local _display="$(_resolve_free_display)"
	export DISPLAY="${_display}"
	_x11_session_env "${_X11_FLAVOR_OVERRIDE:-}" "${_is_full_de}"

	local _log_dir="$(_get_shell_log_dir)"
	local _persistent_log="${_log_dir}/xorg-session.log"
	rm -f "${_persistent_log}" 2> "/dev/null" || true
	_x11_driver_preflight "${_persistent_log}"

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

	local _theme_flavor="${_RESOLVED_THEME_FLAVOR:-$(_detect_desktop_theme "${_X11_FLAVOR_OVERRIDE:-}")}"
	local _color_scheme="${_RESOLVED_COLOR_SCHEME:-$(_detect_color_scheme "${_theme_flavor}" 2> "/dev/null" || echo "dark")}"
	local _ui_font="$(_resolve_desktop_font "${_theme_flavor}")"
	local _valid_theme="${XCURSOR_THEME:-Adwaita}"
	local _icon_theme="${_RESOLVED_ICON_THEME:-Adwaita}"
	local _gtk_theme="${GTK_THEME:-}"
	if [ -z "${_gtk_theme}" ] && command -v _resolve_gtk_theme > "/dev/null" 2>&1; then
		_gtk_theme="$(_resolve_gtk_theme "${_theme_flavor}" "${_color_scheme}" 2> "/dev/null" || true)"
	fi
	if [ -z "${_gtk_theme}" ]; then
		[ "${_color_scheme}" = "light" ] && _gtk_theme="adw-gtk3" || _gtk_theme="adw-gtk3-dark"
	fi

	local _prefer_dark=1 _adw_scheme="prefer-dark" _root_bg="#1e1e22"
	if [ "${_color_scheme}" = "light" ]; then
		_prefer_dark=0
		_adw_scheme="default"
		_root_bg="#f6f5f4"
	fi

	local _bg_cmd="${_X11_SESSION_BG_CMD:-}"
	local _vt_arg="$(_resolve_vt_arg)"
	local _xinit_script="${XDG_RUNTIME_DIR:-/tmp}/xinit-session-$$.sh"
	cat << EOF >| "${_xinit_script}"
#!/usr/bin/env sh
unset DBUS_SESSION_BUS_ADDRESS SYSTEMD_EXEC_PID MANAGERPID
export MOZ_DBUS_REMOTE=0 MOZ_NO_REMOTE=1
export EMACS_OS_MODE="${EMACS_OS_MODE:-}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-GNOME}"
export DESKTOP_SESSION="${DESKTOP_SESSION:-gnome}"
export SAL_USE_VCLPLUGIN="gtk3"
export vblank_mode=3
export __GL_SYNC_TO_VBLANK=1
EOF

	if [ "${_is_full_de}" -eq 1 ]; then
		cat << 'EOF' >> "${_xinit_script}"
unset GTK_THEME GTK_APPLICATION_PREFER_DARK_THEME ADW_DEBUG_COLOR_SCHEME QT_STYLE_OVERRIDE 2> "/dev/null" || true
EOF
	else
		cat << EOF >> "${_xinit_script}"
export GTK_THEME="${_gtk_theme}"
export GTK_APPLICATION_PREFER_DARK_THEME=${_prefer_dark}
export ADW_DEBUG_COLOR_SCHEME="${_adw_scheme}"
${QT_STYLE_OVERRIDE:+export QT_STYLE_OVERRIDE="${QT_STYLE_OVERRIDE}"}
EOF
	fi

	cat << EOF >> "${_xinit_script}"
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
export vblank_mode=3
export __GL_SYNC_TO_VBLANK=1
export QT_QPA_PLATFORMTHEME="\${QT_QPA_PLATFORMTHEME:-qt6ct}"
export XCURSOR_THEME="\${XCURSOR_THEME}"
export XCURSOR_SIZE="\${XCURSOR_SIZE:-24}"
EOF

	if [ "${_is_full_de}" -eq 1 ]; then
		cat << 'EOF' >> "${_xinit_script}"
unset GTK_THEME GTK_APPLICATION_PREFER_DARK_THEME ADW_DEBUG_COLOR_SCHEME QT_STYLE_OVERRIDE 2> "/dev/null" || true
EOF
	else
		cat << EOF >> "${_xinit_script}"
export GTK_THEME="${_gtk_theme}"
export GTK_APPLICATION_PREFER_DARK_THEME=${_prefer_dark}
export ADW_DEBUG_COLOR_SCHEME="${_adw_scheme}"
${QT_STYLE_OVERRIDE:+export QT_STYLE_OVERRIDE="${QT_STYLE_OVERRIDE}"}
EOF
	fi

	cat << EOF >> "${_xinit_script}"
if [ -f "\${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "\${HOME}/.Xresources" > "/dev/null" 2>&1 || true
fi
if command -v xrdb > "/dev/null" 2>&1; then
	printf "Xcursor.theme: %s\nXcursor.size: %s\n" "\${XCURSOR_THEME}" "\${XCURSOR_SIZE}" | xrdb -merge - > "/dev/null" 2>&1 || true
fi
if command -v xsetroot > "/dev/null" 2>&1; then
	xsetroot -solid "${_root_bg}" -cursor_name left_ptr > "/dev/null" 2>&1 || true
fi

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
	eval "\$(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2> "/dev/null")" > "/dev/null" 2>&1 || true
	[ -n "\${SSH_AUTH_SOCK:-}" ] && export SSH_AUTH_SOCK
	if command -v dbus-update-activation-environment > "/dev/null" 2>&1; then
		dbus-update-activation-environment --systemd SSH_AUTH_SOCK DISPLAY XDG_CURRENT_DESKTOP > "/dev/null" 2>&1 || \
		dbus-update-activation-environment SSH_AUTH_SOCK DISPLAY XDG_CURRENT_DESKTOP > "/dev/null" 2>&1 || true
	fi
fi

if command -v xrandr > "/dev/null" 2>&1; then
	for _out in \$(xrandr 2> "/dev/null" | grep " connected" | cut -d ' ' -f1); do
		xrandr --output "\${_out}" --set "TearFree" "on" > "/dev/null" 2>&1 || true
	done
fi

_xset_pid=""
_bg_pid=""
_cleanup_x11_helpers() {
	[ -n "\${_bg_pid}" ] && kill "\${_bg_pid}" 2> "/dev/null" || true
	[ -n "\${_xset_pid}" ] && kill "\${_xset_pid}" 2> "/dev/null" || true
}
trap '_cleanup_x11_helpers' EXIT TERM INT
EOF

	if [ "${_is_full_de}" -eq 0 ]; then
		cat << EOF >> "${_xinit_script}"
if command -v xsettingsd > "/dev/null" 2>&1; then
	_xsettings_cfg="\${XDG_RUNTIME_DIR:-/tmp}/xsettingsd-\$\$.conf"
	cat << EOF_XSET >| "\${_xsettings_cfg}"
Net/ThemeName "${_gtk_theme}"
Net/IconThemeName "${_icon_theme}"
Gtk/CursorThemeName "${_valid_theme}"
Gtk/CursorThemeSize \${XCURSOR_SIZE}
Gtk/FontName "${_ui_font} 11"
Gtk/ApplicationPreferDarkTheme ${_prefer_dark}
EOF_XSET
	xsettingsd -c "\${_xsettings_cfg}" > "${_log_dir}/xsettingsd.log" 2>&1 &
	_xset_pid=\$!
fi

if [ "\${X11_NO_COMPOSITOR:-0}" != "1" ]; then
	if command -v picom > "/dev/null" 2>&1; then
		if ! { pgrep -x picom > "/dev/null" 2>&1 || pkill -0 -x picom > "/dev/null" 2>&1; }; then
			_picom_log_flag=""
			picom --help 2> "/dev/null" | grep -q -- "--log-file" && _picom_log_flag="--log-file"
			if [ -n "\${_picom_log_flag}" ]; then
				picom --backend glx --vsync --no-use-damage -b "\${_picom_log_flag}" "${_log_dir}/picom.log" > "${_log_dir}/picom.log" 2>&1 || \
					picom --backend xrender --vsync --no-use-damage -b "\${_picom_log_flag}" "${_log_dir}/picom.log" > "${_log_dir}/picom.log" 2>&1 || true
			else
				picom --backend glx --vsync --no-use-damage -b > "${_log_dir}/picom.log" 2>&1 || \
					picom --backend xrender --vsync --no-use-damage -b > "${_log_dir}/picom.log" 2>&1 || true
			fi
		fi
	elif command -v xcompmgr > "/dev/null" 2>&1; then
		{ pgrep -x xcompmgr > "/dev/null" 2>&1 || pkill -0 -x xcompmgr > "/dev/null" 2>&1; } || \
			xcompmgr -c -C -b > "${_log_dir}/xcompmgr.log" 2>&1 || true
	fi
fi
EOF
	fi

	if [ -n "${_bg_cmd}" ]; then
		cat << EOF >> "${_xinit_script}"
( sleep 0.25; ${_bg_cmd} ) > "${_log_dir}/wwm-bar.log" 2>&1 &
_bg_pid=\$!
EOF
	fi

	cat << EOF >> "${_xinit_script}"
eval "${_session_cmd}"
_wm_ret=\$?
_cleanup_x11_helpers
exit "\${_wm_ret}"
EOF
	chmod 0755 "${_xinit_script}"

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
		command xinit "${_xinit_script}" -- "${_display}" ${_vt_arg} ${_auth_args} >> "${_persistent_log}" 2>&1
		_xinit_ret=$?
	elif command -v startx > "/dev/null" 2>&1; then
		command startx "${_xinit_script}" -- "${_display}" ${_vt_arg} >> "${_persistent_log}" 2>&1
		_xinit_ret=$?
	else
		command xinit "${_xinit_script}" -- "${_display}" ${_vt_arg} >> "${_persistent_log}" 2>&1
		_xinit_ret=$?
	fi
	rm -f "${_server_auth}" "${_xinit_script}" "${XDG_RUNTIME_DIR:-/tmp}/xsettingsd-"*.conf 2> "/dev/null" || true
	command -v xauth > "/dev/null" 2>&1 && command xauth -q remove "${_display}" 2> "/dev/null" || true

	[ "${_xinit_ret}" -eq 127 ] && _xinit_ret=1
	if [ "${_xinit_ret}" -ne 0 ]; then
		_ui_err "Sessão Xorg encerrou com erro (código ${_xinit_ret}). Log: ${_persistent_log}"
	fi

	[ "${_had_display}" -eq 0 ] && unset DISPLAY
	_freebsd_vt_bounce > "/dev/null" 2>&1
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
		_has_exec_bin "${_compositor}" && return 0
	done
	return 1
}

_has_x11() {
	[ -n "${DISPLAY:-}" ] && return 0
	local _xbin _session_dir
	for _xbin in Xorg X xinit startx; do
		_has_exec_bin "${_xbin}" && return 0
	done
	for _session_dir in /usr/share/xsessions /usr/local/share/xsessions /usr/X11R7/share/xsessions /usr/X11R6/share/xsessions "${XDG_DATA_HOME:-${HOME}/.local/share}/xsessions"; do
		if [ -d "${_session_dir}" ] && [ -n "$(command ls -A "${_session_dir}" 2> "/dev/null")" ]; then
			return 0
		fi
	done
	return 1
}

_dispatch_display_server() {
	local _base_target="${1:-}"
	[ "$#" -ge 1 ] && shift

	local _arg
	for _arg in "$@"; do
		case "${_arg}" in
			-l|--list|--pipeline)
				_show_wm_pipeline "all"
				return 0
				;;
		esac
	done

	local _forced_backend=""
	for _arg in "$@"; do
		case "${_arg}" in
			--sway|--labwc|--river|--cage|--hyprland|--niri|--wayfire|--dwl|--hikari|--weston|--ewm)
				_forced_backend="wayland"
				;;
			--openbox|--cwm|--dwm|--fvwm3|--fvwm|--fluxbox|--icewm|--jwm|--pekwm|--twm|--matchbox|--matchbox-window-manager)
				_forced_backend="x11"
				;;
		esac
	done

	local _idx=1
	while [ "${_idx}" -le "$#" ]; do
		eval "_curr=\${${_idx}}"
		case "${_curr}" in
			-w|--wm)
				_next_idx=$(( _idx + 1 ))
				if [ "${_next_idx}" -le "$#" ]; then
					eval "_val=\${${_next_idx}}"
					case "${_val}" in
						sway|labwc|river|cage|hyprland|niri|wayfire|dwl|hikari|weston|ewm)
							_forced_backend="wayland"
							;;
						openbox|cwm|dwm|fvwm3|fvwm|fluxbox|icewm|jwm|pekwm|twm|matchbox|matchbox-window-manager)
							_forced_backend="x11"
							;;
					esac
				fi
				;;
			--wm=*)
				_val="${_curr#--wm=}"
				case "${_val}" in
					sway|labwc|river|cage|hyprland|niri|wayfire|dwl|hikari|weston|ewm)
						_forced_backend="wayland"
						;;
					openbox|cwm|dwm|fvwm3|fvwm|fluxbox|icewm|jwm|pekwm|twm|matchbox|matchbox-window-manager)
						_forced_backend="x11"
						;;
				esac
				;;
		esac
		_idx=$(( _idx + 1 ))
	done

	local _fn=""
	case "${_base_target}" in
		window-manager|window_manager)             _fn="window_manager" ;;
		graphical-launcher|graphical_launcher)     _fn="graphical_launcher" ;;
		desktop-session|desktop_session)           _fn="desktop_session" ;;
		start-session|start_session)               _fn="start_session" ;;
		emacs-window-manager|emacs_window_manager) _fn="emacs_window_manager" ;;
		*) _fn="$(printf '%s' "${_base_target}" | tr '-' '_')" ;;
	esac

	if [ "${_forced_backend}" = "wayland" ]; then
		"${_fn}_wayland" "$@"
		return $?
	elif [ "${_forced_backend}" = "x11" ]; then
		"${_fn}_x11" "$@"
		return $?
	fi

	local _disp_ret=127
	if _has_wayland && command -v "${_fn}_wayland" > "/dev/null" 2>&1; then
		"${_fn}_wayland" "$@"
		_disp_ret=$?
		[ "${_disp_ret}" -ne 127 ] && return "${_disp_ret}"
	fi
	if _has_x11 && command -v "${_fn}_x11" > "/dev/null" 2>&1; then
		"${_fn}_x11" "$@"
		_disp_ret=$?
		[ "${_disp_ret}" -ne 127 ] && return "${_disp_ret}"
	fi
	if [ "${_disp_ret}" -eq 127 ]; then
		_ui_err "Nenhum backend gráfico suportado (Wayland ou X11) disponível para '${_base_target}'."
	fi
	return "${_disp_ret}"
}

_try_wayland() {
	local _bin _ret=127
	for _bin in "$@"; do
		_has_exec_bin "${_bin}" || continue
		if [ "${_bin}" = "gnome-session" ]; then
			export XDG_SESSION_TYPE="wayland"
			_exec_wayland gnome-session --session=gnome
			_ret=$?
		elif [ "${_bin}" = "gnome-shell" ]; then
			export XDG_SESSION_TYPE="wayland"
			_exec_wayland gnome-shell --wayland
			_ret=$?
		else
			_exec_wayland "${_bin}"
			_ret=$?
		fi
		[ "${_ret}" -ne 127 ] && return "${_ret}"
	done
	return 127
}

_try_xorg() {
	local _bin _ret=127 _resolved=""
	for _bin in "$@"; do
		_has_exec_bin "${_bin}" || continue
		_resolved="$(command -v "${_bin}")"
		if [ "${_bin}" = "gnome-session" ]; then
			_exec_x11 "${_resolved}" --session=gnome-xorg
			_ret=$?
		else
			_exec_x11 "${_resolved}"
			_ret=$?
		fi
		[ "${_ret}" -ne 127 ] && return "${_ret}"
	done
	return 127
}

_start_wayland() {
	case "${1:-}" in
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
	{ _has_exec_bin "startx" || _has_exec_bin "xinit"; } || return 127
	{ _has_exec_bin "Xorg" || _has_exec_bin "X"; } || return 127
	case "${1:-}" in
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
		fvwm3|fvwm) _try_xorg fvwm3 fvwm ;;
		cwm)        _try_xorg cwm ;;
		dwm)        _try_xorg dwm ;;
		fluxbox)    _try_xorg startfluxbox fluxbox ;;
		icewm)      _try_xorg icewm-session icewm ;;
		jwm)        _try_xorg jwm ;;
		pekwm)      _try_xorg pekwm ;;
		twm)        _try_xorg twm ;;
		matchbox|matchbox-window-manager) _try_xorg matchbox-window-manager ;;
		"")
			if [ -f "${HOME}/.xinitrc" ] || [ -f "${HOME}/.xsession" ] || [ -f "${HOME}/.Xclients" ]; then
				_exec_x11
				return $?
			fi
			local _xret=127
			_try_xorg startplasma-x11 startxfce4 gnome-session mate-session cinnamon-session startlxqt startlxde budgie-desktop pantheon-session startdde cosmic-session openbox-session openbox fvwm3 fvwm
			_xret=$?
			[ "${_xret}" -ne 127 ] && return "${_xret}"
			_exec_x11
			return $?
			;;
		*) _try_xorg "${1}" ;;
	esac
}

start_session() {
	_sanitize_graphical_env
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
	local _ret=127
	local _WAYLAND_FLAVOR_OVERRIDE="${_env}"
	local _X11_FLAVOR_OVERRIDE="${_env}"
	case "${_type}" in
		way|wayland)
			_start_wayland "${_env}"
			_ret=$?
			[ "${_ret}" -eq 127 ] && { _ui_err "Nenhum compositor Wayland '${_env:-detectado}' encontrado."; return 127; }
			return "${_ret}"
			;;
		xorg|x11)
			_start_xorg "${_env}"
			_ret=$?
			[ "${_ret}" -eq 127 ] && { _ui_err "Nenhum ambiente Xorg '${_env:-detectado}' encontrado."; return 127; }
			return "${_ret}"
			;;
		"")
			_start_wayland "${_env}"
			_ret=$?
			if [ "${_ret}" -eq 127 ]; then
				_start_xorg "${_env}"
				_ret=$?
				[ "${_ret}" -eq 127 ] && { _ui_err "Nenhum ambiente gráfico encontrado."; return 127; }
			fi
			return "${_ret}"
			;;
		*)
			_WAYLAND_FLAVOR_OVERRIDE="${_type}"
			_X11_FLAVOR_OVERRIDE="${_type}"
			_start_wayland "${_type}"
			_ret=$?
			if [ "${_ret}" -eq 127 ]; then
				_start_xorg "${_type}"
				_ret=$?
				[ "${_ret}" -eq 127 ] && { _ui_err "Ambiente '${_type}' não encontrado."; return 127; }
			fi
			return "${_ret}"
			;;
	esac
}
alias start-session="start_session"

desktop_session_wayland() { start_session way "$@"; }
alias desktop-session-wayland="desktop_session_wayland" way="desktop_session_wayland" wayland="desktop_session_wayland" start-way="desktop_session_wayland" start-wayland="desktop_session_wayland"

desktop_session_x11() { start_session xorg "$@"; }
alias desktop-session-x11="desktop_session_x11" xorg="desktop_session_x11" x11="desktop_session_x11" start-xorg="desktop_session_x11" start-x11="desktop_session_x11"

### --------------------------------
### DESKTOP MENU & BAR GENERATION
### --------------------------------
_generate_wwm_bar_script() {
	local _out_script="$1"
	cat << 'EOF_WBAR' >| "${_out_script}"
import os, sys, subprocess, json, datetime, shutil
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    from Xlib import display as xlib_display, X as xlib_X, Xatom as xlib_Xatom
    HAS_XLIB = True
except Exception:
    HAS_XLIB = False

BAR_H = 32

class WwmBar(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_wmclass("wwm-bar", "wwm-bar")
        self.set_title("wwm-bar")
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_accept_focus(False)
        self.set_focus_on_map(False)
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)

        screen = Gdk.Screen.get_default()
        self.screen_w = screen.get_width() if screen else 1920
        self.set_default_size(self.screen_w, BAR_H)
        self.set_size_request(self.screen_w, BAR_H)
        self.move(0, 0)

        self.has_sway = bool(os.environ.get("SWAYSOCK") and shutil.which("swaymsg"))
        self.has_hypr = bool(os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and shutil.which("hyprctl"))
        self.has_niri = bool(os.environ.get("NIRI_SOCKET") and shutil.which("niri"))
        self.is_x11 = bool(os.environ.get("DISPLAY") and not self.has_sway and not self.has_hypr and not self.has_niri)
        self.xdisp = None
        if HAS_XLIB and os.environ.get("DISPLAY"):
            try:
                self.xdisp = xlib_display.Display()
            except Exception:
                self.xdisp = None

        self.managed_workspaces = {1}
        self.current_fallback_ws = 1
        self.last_ws_state = None
        self.last_win_state = None
        self.realize()
        self.setup_struts()

        scheme = os.environ.get("WWM_SCHEME", "dark").strip().lower()
        if scheme == "light":
            win_bg = "#f6f5f4"
            btn_bg = "#ffffff"
            border = "#cdc7c2"
            fg = "#241f31"
            muted = "#5e5c64"
            accent = "#3584e4"
            danger = "#e01b24"
            tab_active_bg = "#ffffff"
        else:
            win_bg = "#1e1e22"
            btn_bg = "#2b2b30"
            border = "#38383d"
            fg = "#ffffff"
            muted = "#9a9996"
            accent = "#3584e4"
            danger = "#e01b24"
            tab_active_bg = "#2b2b30"

        font_name = os.environ.get("WWM_FONT", "JetBrainsMono Nerd Font")
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
        }}
        button.app-btn {{
            background-color: {btn_bg};
            background-image: none;
            color: {fg};
            border: 1px solid {border};
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
        }}
        button.app-btn:hover {{
            background-color: {accent};
            background-image: none;
            color: #ffffff;
            border-color: {accent};
        }}
        button.ws-inactive {{
            background-color: {win_bg};
            background-image: none;
            color: {muted};
            border: 1px solid {border};
            border-radius: 6px;
            padding: 2px 8px;
            margin: 3px 2px;
            min-width: 24px;
            min-height: 22px;
        }}
        button.ws-inactive:hover {{
            background-color: {btn_bg};
            background-image: none;
            color: {fg};
            border-color: {accent};
        }}
        button.ws-active {{
            background-color: {tab_active_bg};
            background-image: none;
            color: {fg};
            border: 1px solid {accent};
            border-radius: 6px;
            padding: 2px 8px;
            margin: 3px 2px;
            min-width: 24px;
            min-height: 22px;
            font-weight: bold;
        }}
        button.ws-active:hover {{
            background-color: {accent};
            background-image: none;
            color: #ffffff;
            border-color: {accent};
        }}
        button.ws-ctrl-btn {{
            background-color: {btn_bg};
            background-image: none;
            color: {fg};
            border: 1px solid {border};
            border-radius: 6px;
            padding: 2px 7px;
            margin: 3px 2px;
            min-width: 22px;
            min-height: 22px;
            font-weight: bold;
        }}
        button.ws-ctrl-btn:hover {{
            background-color: {accent};
            background-image: none;
            color: #ffffff;
            border-color: {accent};
        }}
        button.win-tab {{
            background-color: {win_bg};
            background-image: none;
            color: {muted};
            border: 1px solid {border};
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
        }}
        button.win-tab:hover {{
            background-color: {btn_bg};
            background-image: none;
            color: {fg};
            border-color: {accent};
        }}
        button.win-tab-active {{
            background-color: {tab_active_bg};
            background-image: none;
            color: {fg};
            border: 1px solid {accent};
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
            font-weight: bold;
        }}
        button.win-tab-active:hover {{
            background-color: {accent};
            background-image: none;
            color: #ffffff;
            border-color: {accent};
        }}
        button.danger-btn {{
            background-color: {btn_bg};
            background-image: none;
            color: {fg};
            border: 1px solid {border};
            border-radius: 6px;
            padding: 2px 10px;
            margin: 3px 2px;
            min-height: 22px;
        }}
        button.danger-btn:hover {{
            background-color: {danger};
            background-image: none;
            color: #ffffff;
            border-color: {danger};
        }}
        label.clock-lbl {{
            color: {muted};
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

        btn_del = Gtk.Button(label="-")
        btn_del.get_style_context().add_class("ws-ctrl-btn")
        btn_del.connect("clicked", self.on_del_ws)
        ws_ctrl_box.pack_start(btn_del, False, False, 0)
        main_box.pack_start(ws_ctrl_box, False, False, 2)

        center_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        scroll.set_shadow_type(Gtk.ShadowType.NONE)
        self.tabs_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        scroll.add(self.tabs_box)
        center_box.pack_start(scroll, True, True, 4)
        main_box.pack_start(center_box, True, True, 0)

        actions_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.pack_end(actions_box, False, False, 4)

        self.clock_lbl = Gtk.Label()
        self.clock_lbl.get_style_context().add_class("clock-lbl")
        actions_box.pack_end(self.clock_lbl, False, False, 0)

        btn_exit = Gtk.Button(label="Exit")
        btn_exit.get_style_context().add_class("danger-btn")
        btn_exit.connect("clicked", self.on_exit_session)
        actions_box.pack_end(btn_exit, False, False, 0)

        btn_close = Gtk.Button(label="Close")
        btn_close.get_style_context().add_class("danger-btn")
        btn_close.connect("clicked", self.on_close_app)
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
            b.connect("clicked", lambda widget, c=cmd: self.run_cmd(c))
            actions_box.pack_end(b, False, False, 0)

        self.refresh_tick()
        self.update_clock()
        GLib.timeout_add(250, self.refresh_tick)
        GLib.timeout_add(1000, self.update_clock)
        self.show_all()

    def _spawn(self, args, shell=False):
        try:
            subprocess.Popen(
                args,
                shell=shell,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
            )
        except Exception:
            pass

    def _self_xid(self):
        try:
            gdk_win = self.get_window()
            if gdk_win and hasattr(gdk_win, "get_xid"):
                return int(gdk_win.get_xid())
        except Exception:
            pass
        return 0

    def setup_struts(self):
        try:
            xid = self._self_xid()
            if xid and shutil.which("xprop"):
                sp = f"0, 0, {BAR_H}, 0, 0, 0, 0, 0, 0, {self.screen_w}, 0, 0"
                st = f"0, 0, {BAR_H}, 0"
                subprocess.run(
                    ["xprop", "-id", str(xid), "-f", "_NET_WM_STRUT_PARTIAL", "32c", "-set", "_NET_WM_STRUT_PARTIAL", sp],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                subprocess.run(
                    ["xprop", "-id", str(xid), "-f", "_NET_WM_STRUT", "32c", "-set", "_NET_WM_STRUT", st],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
        except Exception:
            pass

    def run_cmd(self, cmd):
        if not cmd:
            return
        if self.has_sway:
            self._spawn(["swaymsg", "exec", cmd])
        else:
            self._spawn(cmd, shell=True)

    def on_exit_session(self, widget=None):
        exit_cmd = os.environ.get("WWM_EXIT_CMD", "")
        if exit_cmd:
            self._spawn(exit_cmd, shell=True)
        elif self.has_sway:
            self._spawn(["swaymsg", "exit"])
        elif self.has_hypr:
            self._spawn(["hyprctl", "dispatch", "exit"])
        elif self.has_niri:
            self._spawn(["niri", "msg", "action", "quit", "--skip-confirmation"])
        elif os.environ.get("RIVER_SOCKET") and shutil.which("riverctl"):
            self._spawn(["riverctl", "exit"])
        elif os.environ.get("WWM_WM") == "labwc" and shutil.which("labwc"):
            self._spawn(["labwc", "--exit"])
        elif os.environ.get("WWM_WM") == "openbox" and shutil.which("openbox"):
            self._spawn(["openbox", "--exit"])
        elif os.environ.get("DISPLAY"):
            wm_hint = os.environ.get("WWM_WM", "")
            if wm_hint == "openbox" and shutil.which("openbox"):
                self._spawn(["openbox", "--exit"])
            elif wm_hint == "jwm" and shutil.which("jwm"):
                self._spawn(["jwm", "-exit"])
            elif wm_hint == "icewm" and shutil.which("pkill"):
                self._spawn(["pkill", "-TERM", "-x", "icewm"])
            elif wm_hint in ("fvwm3", "fvwm") and shutil.which("pkill"):
                self._spawn(["pkill", "-TERM", "-x", wm_hint])
            elif wm_hint and shutil.which("pkill"):
                self._spawn(["pkill", "-TERM", "-x", wm_hint])
            else:
                Gtk.main_quit()
        else:
            Gtk.main_quit()

    def get_target_app_con_id(self):
        try:
            res = subprocess.run(["swaymsg", "-t", "get_tree"], capture_output=True, text=True)
            root = json.loads(res.stdout)
        except Exception:
            return None

        def find_focused_workspace(node):
            if node.get("type") == "workspace":
                def has_focus(n):
                    if n.get("focused"):
                        return True
                    for c in n.get("nodes", []) + n.get("floating_nodes", []):
                        if has_focus(c):
                            return True
                    return False
                if has_focus(node):
                    return node
            for c in node.get("nodes", []) + node.get("floating_nodes", []):
                r = find_focused_workspace(c)
                if r:
                    return r
            return None

        ws = find_focused_workspace(root)
        if not ws:
            return None

        def collect_app_leaves(node):
            leaves = []
            children = node.get("nodes", []) + node.get("floating_nodes", [])
            name = str(node.get("name") or "")
            app_id = str(node.get("app_id") or "")
            win_props = node.get("window_properties") or {}
            instance = str(win_props.get("instance") or "")
            is_bar = (name == "wwm-bar" or app_id == "wwm-bar" or instance == "wwm-bar")
            if not children:
                if not is_bar and node.get("id") and node.get("type") != "workspace":
                    leaves.append(node)
            else:
                for c in children:
                    leaves.extend(collect_app_leaves(c))
            return leaves

        candidates = collect_app_leaves(ws)
        if not candidates:
            return None
        for c in candidates:
            if c.get("focused"):
                return c.get("id")
        ws_focus = ws.get("focus", [])
        for f_id in ws_focus:
            for c in candidates:
                if c.get("id") == f_id:
                    return f_id
        return candidates[0].get("id")

    def on_close_app(self, widget=None):
        if self.has_sway:
            target_id = self.get_target_app_con_id()
            if target_id is not None:
                self._spawn(["swaymsg", f"[con_id={target_id}] kill"])
        elif self.has_hypr:
            self._spawn(["hyprctl", "dispatch", "killactive"])
        elif self.has_niri:
            self._spawn(["niri", "msg", "action", "close-window"])
        elif os.environ.get("RIVER_SOCKET") and shutil.which("riverctl"):
            self._spawn(["riverctl", "close"])
        else:
            if shutil.which("xdotool"):
                try:
                    res = subprocess.run(["xdotool", "getactivewindow"], capture_output=True, text=True)
                    act_id = res.stdout.strip()
                    self_xid = str(self._self_xid() or "")
                    if act_id and act_id != self_xid:
                        self._spawn(["xdotool", "windowclose", act_id])
                        return
                except Exception:
                    pass
            if shutil.which("wmctrl"):
                self._spawn(["wmctrl", "-c", ":ACTIVE:"])
            elif shutil.which("wlrctl"):
                self._spawn(["wlrctl", "window", "close"])

    def update_clock(self):
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        self.clock_lbl.set_text(now)
        return True

    def get_workspaces_info(self):
        if self.has_sway:
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
                used_nums = {1}
            all_ws = sorted(list(self.managed_workspaces.union(used_nums)))
            return all_ws, focused_num

        if self.has_hypr:
            focused_num = 1
            used_nums = set()
            try:
                ws_res = subprocess.run(["hyprctl", "workspaces", "-j"], capture_output=True, text=True)
                act_res = subprocess.run(["hyprctl", "activeworkspace", "-j"], capture_output=True, text=True)
                for ws in json.loads(ws_res.stdout or "[]"):
                    wid = ws.get("id")
                    if isinstance(wid, int) and wid > 0:
                        used_nums.add(wid)
                act = json.loads(act_res.stdout or "{}")
                if isinstance(act.get("id"), int) and act.get("id") > 0:
                    focused_num = act["id"]
            except Exception:
                used_nums = {1}
            all_ws = sorted(list(self.managed_workspaces.union(used_nums)))
            return all_ws, focused_num

        if self.has_niri:
            focused_num = 1
            used_nums = set()
            try:
                res = subprocess.run(["niri", "msg", "-j", "workspaces"], capture_output=True, text=True)
                for ws in json.loads(res.stdout or "[]"):
                    idx = ws.get("idx")
                    if isinstance(idx, int) and idx > 0:
                        used_nums.add(idx)
                        if ws.get("is_focused"):
                            focused_num = idx
            except Exception:
                used_nums = {1}
            all_ws = sorted(list(self.managed_workspaces.union(used_nums)))
            return all_ws, focused_num

        if shutil.which("wmctrl"):
            try:
                res = subprocess.run(["wmctrl", "-d"], capture_output=True, text=True)
                lines = [l.strip() for l in res.stdout.strip().split("\n") if l.strip()]
                if lines:
                    all_ws = []
                    focused_num = 1
                    for l in lines:
                        parts = l.split()
                        idx = int(parts[0]) + 1
                        all_ws.append(idx)
                        if "*" in parts[1]:
                            focused_num = idx
                    return all_ws, focused_num
            except Exception:
                pass

        all_ws = sorted(list(self.managed_workspaces))
        return all_ws, self.current_fallback_ws

    def get_windows(self):
        windows = []
        if self.has_sway:
            try:
                res = subprocess.run(["swaymsg", "-t", "get_tree"], capture_output=True, text=True)
                root = json.loads(res.stdout or "{}")
                def find_focused_ws(node):
                    if node.get("type") == "workspace":
                        def has_focus(n):
                            if n.get("focused"):
                                return True
                            return any(has_focus(c) for c in n.get("nodes", []) + n.get("floating_nodes", []))
                        if has_focus(node):
                            return node
                    for c in node.get("nodes", []) + node.get("floating_nodes", []):
                        r = find_focused_ws(c)
                        if r:
                            return r
                    return None
                ws = find_focused_ws(root) or root
                def collect(node):
                    children = node.get("nodes", []) + node.get("floating_nodes", [])
                    name = str(node.get("name") or "")
                    app_id = str(node.get("app_id") or "")
                    win_props = node.get("window_properties") or {}
                    inst = str(win_props.get("instance") or "")
                    is_bar = (name == "wwm-bar" or app_id == "wwm-bar" or inst == "wwm-bar")
                    if not children:
                        if not is_bar and node.get("id") and node.get("type") not in ("workspace", "output", "root"):
                            title = name or app_id or win_props.get("class") or "Window"
                            windows.append((str(node.get("id")), title, bool(node.get("focused"))))
                    else:
                        for c in children:
                            collect(c)
                collect(ws)
            except Exception:
                pass
            return windows

        if self.has_hypr:
            try:
                c_res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
                a_res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
                active_addr = json.loads(a_res.stdout or "{}").get("address", "")
                for c in json.loads(c_res.stdout or "[]"):
                    cls = str(c.get("class") or "")
                    title = str(c.get("title") or cls or "Window")
                    if cls == "wwm-bar" or title == "wwm-bar":
                        continue
                    addr = c.get("address", "")
                    if addr:
                        windows.append((addr, title, addr == active_addr))
            except Exception:
                pass
            return windows

        if self.has_niri:
            try:
                res = subprocess.run(["niri", "msg", "-j", "windows"], capture_output=True, text=True)
                for w in json.loads(res.stdout or "[]"):
                    app_id = str(w.get("app_id") or "")
                    title = str(w.get("title") or app_id or "Window")
                    if app_id == "wwm-bar" or title == "wwm-bar":
                        continue
                    wid = w.get("id")
                    if wid is not None:
                        windows.append((str(wid), title, bool(w.get("is_focused"))))
            except Exception:
                pass
            return windows

        self_xid = self._self_xid()
        if self.xdisp is not None:
            try:
                root = self.xdisp.screen().root
                atom_client_list = self.xdisp.intern_atom("_NET_CLIENT_LIST")
                atom_active = self.xdisp.intern_atom("_NET_ACTIVE_WINDOW")
                atom_net_name = self.xdisp.intern_atom("_NET_WM_NAME")
                atom_utf8 = self.xdisp.intern_atom("UTF8_STRING")
                atom_wtype = self.xdisp.intern_atom("_NET_WM_WINDOW_TYPE")
                atom_dock = self.xdisp.intern_atom("_NET_WM_WINDOW_TYPE_DOCK")

                act_prop = root.get_full_property(atom_active, xlib_Xatom.WINDOW)
                active_wid = act_prop.value[0] if act_prop and act_prop.value else 0
                if not active_wid:
                    try:
                        focus_win = self.xdisp.get_input_focus().focus
                        if hasattr(focus_win, "id"):
                            active_wid = focus_win.id
                    except Exception:
                        pass

                prop = root.get_full_property(atom_client_list, xlib_Xatom.WINDOW)
                wids = list(prop.value) if prop and prop.value else []
                if not wids:
                    for child in root.query_tree().children:
                        try:
                            attrs = child.get_attributes()
                            if attrs.map_state == xlib_X.IsViewable and not attrs.override_redirect:
                                wids.append(child.id)
                        except Exception:
                            pass

                for wid in wids:
                    if wid == self_xid:
                        continue
                    try:
                        win = self.xdisp.create_resource_object("window", wid)
                        wtype = win.get_full_property(atom_wtype, xlib_Xatom.ATOM)
                        if wtype and atom_dock in wtype.value:
                            continue
                        wclass = win.get_wm_class()
                        if wclass and "wwm-bar" in wclass:
                            continue
                        title = ""
                        nprop = win.get_full_property(atom_net_name, atom_utf8)
                        if nprop and nprop.value:
                            raw = nprop.value
                            title = raw.decode("utf-8", "replace") if isinstance(raw, bytes) else str(raw)
                        if not title:
                            title = win.get_wm_name() or ""
                        if not title and wclass:
                            title = wclass[1] or wclass[0]
                        if title == "wwm-bar":
                            continue
                        windows.append((str(wid), title or f"Window {wid}", wid == active_wid))
                    except Exception:
                        continue
                if windows:
                    return windows
            except Exception:
                pass

        if shutil.which("wmctrl"):
            try:
                active_wid = 0
                if shutil.which("xprop"):
                    ap = subprocess.run(["xprop", "-root", "_NET_ACTIVE_WINDOW"], capture_output=True, text=True)
                    if "0x" in ap.stdout:
                        active_wid = int(ap.stdout.strip().split()[-1], 16)
                res = subprocess.run(["wmctrl", "-l"], capture_output=True, text=True)
                for line in res.stdout.splitlines():
                    parts = line.split(None, 3)
                    if len(parts) >= 3:
                        wid = int(parts[0], 16)
                        if wid == self_xid:
                            continue
                        title = parts[3] if len(parts) == 4 else "Window"
                        if title == "wwm-bar":
                            continue
                        windows.append((str(wid), title, wid == active_wid))
            except Exception:
                pass
            return windows

        if shutil.which("xdotool"):
            try:
                act_res = subprocess.run(["xdotool", "getactivewindow"], capture_output=True, text=True)
                active_str = act_res.stdout.strip()
                res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", ""], capture_output=True, text=True)
                for w_str in res.stdout.splitlines():
                    w_str = w_str.strip()
                    if not w_str or w_str == str(self_xid):
                        continue
                    n_res = subprocess.run(["xdotool", "getwindowname", w_str], capture_output=True, text=True)
                    title = n_res.stdout.strip()
                    if not title or title == "wwm-bar":
                        continue
                    windows.append((w_str, title, w_str == active_str))
            except Exception:
                pass
        return windows

    def focus_window(self, wid):
        if self.has_sway:
            self._spawn(["swaymsg", f"[con_id={wid}]", "focus"])
        elif self.has_hypr:
            self._spawn(["hyprctl", "dispatch", "focuswindow", f"address:{wid}"])
        elif self.has_niri:
            self._spawn(["niri", "msg", "action", "focus-window", "--id", str(wid)])
        else:
            focused = False
            if self.xdisp is not None:
                try:
                    from Xlib import protocol
                    xid = int(wid)
                    win = self.xdisp.create_resource_object("window", xid)
                    root = self.xdisp.screen().root
                    atom_active = self.xdisp.intern_atom("_NET_ACTIVE_WINDOW")
                    ev = protocol.event.ClientMessage(
                        window=win,
                        client_type=atom_active,
                        data=(32, [2, xlib_X.CurrentTime, 0, 0, 0])
                    )
                    root.send_event(ev, event_mask=xlib_X.SubstructureRedirectMask | xlib_X.SubstructureNotifyMask)
                    win.raise_window()
                    win.set_input_focus(xlib_X.RevertToPointerRoot, xlib_X.CurrentTime)
                    self.xdisp.flush()
                    focused = True
                except Exception:
                    pass
            if shutil.which("wmctrl"):
                self._spawn(["wmctrl", "-i", "-a", hex(int(wid))])
            elif not focused and shutil.which("xdotool"):
                self._spawn(["xdotool", "windowactivate", str(wid)])

    def switch_ws(self, num):
        if self.has_sway:
            self._spawn(["swaymsg", "workspace", "number", str(num)])
        elif self.has_hypr:
            self._spawn(["hyprctl", "dispatch", "workspace", str(num)])
        elif self.has_niri:
            self._spawn(["niri", "msg", "action", "focus-workspace", str(num)])
        elif shutil.which("wmctrl"):
            self._spawn(["wmctrl", "-s", str(num - 1)])
        elif shutil.which("xdotool"):
            self._spawn(["xdotool", "set_desktop", str(num - 1)])
        self.current_fallback_ws = num
        self.update_workspaces()

    def on_add_ws(self, widget=None):
        all_ws, focused_num = self.get_workspaces_info()
        next_num = (max(all_ws) + 1) if all_ws else 1
        self.managed_workspaces.add(next_num)
        self.switch_ws(next_num)

    def on_del_ws(self, widget=None):
        all_ws, focused_num = self.get_workspaces_info()
        if len(all_ws) > 1:
            remaining = [w for w in all_ws if w != focused_num]
            lower = [w for w in remaining if w < focused_num]
            target_num = max(lower) if lower else min(remaining)
            if self.has_sway:
                subprocess.run(
                    ["swaymsg", f"[workspace=__focused__] move container to workspace number {target_num}"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
            elif shutil.which("wmctrl"):
                subprocess.run(["wmctrl", "-n", str(len(remaining))], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.managed_workspaces.discard(focused_num)
            self.switch_ws(target_num)

    def update_workspaces(self):
        all_ws, focused_num = self.get_workspaces_info()
        current_state = (tuple(all_ws), focused_num)
        if current_state == self.last_ws_state:
            return
        self.last_ws_state = current_state

        for child in self.ws_box.get_children():
            self.ws_box.remove(child)

        for num in all_ws:
            b = Gtk.Button(label=str(num))
            if num == focused_num:
                b.get_style_context().add_class("ws-active")
            else:
                b.get_style_context().add_class("ws-inactive")
            b.connect("clicked", lambda widget, n=num: self.switch_ws(n))
            self.ws_box.pack_start(b, False, False, 0)
        self.ws_box.show_all()

    def update_windows(self):
        windows = self.get_windows()
        current_state = tuple((str(w), str(t), bool(f)) for w, t, f in windows)
        if current_state == self.last_win_state:
            return
        self.last_win_state = current_state

        for child in self.tabs_box.get_children():
            self.tabs_box.remove(child)

        for wid, title, is_active in windows:
            short = (title[:28] + "...") if len(title) > 31 else title
            b = Gtk.Button(label=short)
            b.set_tooltip_text(title)
            if is_active:
                b.get_style_context().add_class("win-tab-active")
            else:
                b.get_style_context().add_class("win-tab")
            b.connect("clicked", lambda widget, w=wid: self.focus_window(w))
            self.tabs_box.pack_start(b, False, False, 0)
        self.tabs_box.show_all()

    def refresh_tick(self):
        self.update_workspaces()
        self.update_windows()
        return True

win = WwmBar()
Gtk.main()
EOF_WBAR
	chmod 0755 "${_out_script}"
}

_generate_openbox_menu_xml() {
	local _out_menu="$1"
	local _b_cmd="$2"
	local _t_cmd="$3"
	local _f_cmd="$4"
	local _e_cmd="$5"
	local _w_term="$6"

	local _gen_ok=0
	if command -v python3 > "/dev/null" 2>&1; then
		python3 - "${_out_menu}" "${_b_cmd}" "${_t_cmd}" "${_f_cmd}" "${_e_cmd}" "${_w_term}" << 'EOF_PY_MENU' > "/dev/null" 2>&1
import os, sys, re, shlex, shutil

menu_file = sys.argv[1]
browser_cmd = sys.argv[2]
term_cmd = sys.argv[3]
files_cmd = sys.argv[4]
emacs_cmd = sys.argv[5]
wm_term = sys.argv[6] if len(sys.argv) > 6 else "xterm"

dirs = [
    os.path.expanduser("~/.local/share/applications"),
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    "/usr/local/share/applications",
    "/usr/share/applications"
]

def extract_bin(cmd):
    try:
        parts = shlex.split(cmd)
    except Exception:
        parts = cmd.split()
    if not parts:
        return None
    idx = 0
    if parts[0] == "env":
        idx = 1
        while idx < len(parts) and "=" in parts[idx]:
            idx += 1
    elif "=" in parts[0]:
        while idx < len(parts) and "=" in parts[idx]:
            idx += 1
    if idx < len(parts):
        return parts[idx]
    return None

def xml_escape(s):
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;")
             .replace("'", "&apos;"))

CATEGORIES = [
    ("cat-editors", "Editors", {"TextEditor", "IDE"}),
    ("cat-dev", "Development", {"Development", "Building", "Debugger", "RevisionControl", "Translation", "WebDevelopment"}),
    ("cat-net", "Internet", {"Network", "WebBrowser", "Email", "InstantMessaging", "Chat", "FileTransfer", "P2P", "RemoteAccess", "Feed"}),
    ("cat-office", "Office", {"Office", "WordProcessor", "Spreadsheet", "Presentation", "Database", "Publishing", "Viewer", "PDF", "Calendar", "ContactManagement"}),
    ("cat-graphics", "Graphics", {"Graphics", "2DGraphics", "3DGraphics", "VectorGraphics", "RasterGraphics", "Photography", "Scanning", "OCR"}),
    ("cat-media", "Media Player", {"AudioVideo", "Audio", "Video", "Player", "Recorder", "Midi", "Mixer", "Sequencer", "Tuner", "TV", "Music"}),
    ("cat-tools", "Tools", {"Utility", "Accessories", "Archiving", "Compression", "Calculator", "Clock", "FileTools", "TextTools", "Accessibility"}),
    ("cat-sys", "System", {"System", "Settings", "HardwareSettings", "DesktopSettings", "PackageManager", "TerminalEmulator", "FileManager", "Monitor", "Security"}),
]

cat_map = {c[0]: [] for c in CATEGORIES}
seen_files = set()
seen_names = set()

for d in dirs:
    if not os.path.isdir(d):
        continue
    for fname in sorted(os.listdir(d)):
        if not fname.endswith(".desktop"):
            continue
        if fname in seen_files:
            continue
        seen_files.add(fname)
        fpath = os.path.join(d, fname)

        in_entry = False
        data = {}
        try:
            with open(fpath, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("["):
                        in_entry = (line == "[Desktop Entry]")
                        continue
                    if not in_entry or "=" not in line or line.startswith("#"):
                        continue
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip()
                    if k not in data:
                        data[k] = v
        except Exception:
            continue

        if data.get("Type") != "Application":
            continue
        if data.get("NoDisplay", "false").lower() == "true":
            continue
        if data.get("Hidden", "false").lower() == "true":
            continue

        name = data.get("Name")
        exec_cmd = data.get("Exec")
        if not name or not exec_cmd:
            continue

        try_exec = data.get("TryExec")
        if try_exec and not shutil.which(try_exec):
            continue

        clean_exec = re.sub(r"%[a-zA-Z]", "", exec_cmd).strip()
        clean_exec = re.sub(r"@@[uUfF]?\s*@@?", "", clean_exec).strip()
        clean_exec = re.sub(r"\s+", " ", clean_exec)
        target_bin = extract_bin(clean_exec)
        if not target_bin or not shutil.which(target_bin):
            continue

        if target_bin == "emacsclient" or clean_exec.startswith("emacsclient"):
            clean_exec = emacs_cmd

        norm_name = name.strip()
        if norm_name.lower() in seen_names:
            continue
        seen_names.add(norm_name.lower())

        app_cats = set(c for c in data.get("Categories", "").split(";") if c)
        terminal = data.get("Terminal", "false").lower() == "true"

        assigned_cat = "cat-sys"
        for cat_id, _, cat_keys in CATEGORIES:
            if app_cats.intersection(cat_keys):
                assigned_cat = cat_id
                break

        cat_map[assigned_cat].append({
            "name": norm_name,
            "exec": clean_exec,
            "terminal": terminal
        })

lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<openbox_menu xmlns="http://openbox.org/3.4/menu">',
    '  <menu id="root-menu" label="Universal Environment">',
    '    <item label="Web Browser">',
    f'      <action name="Execute"><command>{xml_escape(browser_cmd)}</command></action>',
    '    </item>',
    '    <item label="Terminal">',
    f'      <action name="Execute"><command>{xml_escape(term_cmd)}</command></action>',
    '    </item>',
    '    <item label="Files">',
    f'      <action name="Execute"><command>{xml_escape(files_cmd)}</command></action>',
    '    </item>',
    '    <item label="Emacs">',
    f'      <action name="Execute"><command>{xml_escape(emacs_cmd)}</command></action>',
    '    </item>',
    '    <separator/>'
]

for cat_id, cat_title, _ in CATEGORIES:
    apps_in_cat = cat_map.get(cat_id, [])
    if not apps_in_cat:
        continue
    apps_in_cat.sort(key=lambda x: x["name"].lower())
    lines.append(f'    <menu id="{cat_id}" label="{cat_title}">')
    for a in apps_in_cat:
        s_name = xml_escape(a["name"][:36])
        raw_cmd = a["exec"]
        if a["terminal"]:
            esc_sh = raw_cmd.replace("'", "'\\''")
            full_cmd = f"{wm_term} -e sh -c '{esc_sh}'"
        else:
            esc_sh = raw_cmd.replace("'", "'\\''")
            full_cmd = f"sh -c '{esc_sh}'"
        s_cmd = xml_escape(full_cmd)
        lines.append(f'      <item label="{s_name}"><action name="Execute"><command>{s_cmd}</command></action></item>')
    lines.append('    </menu>')

lines.extend([
    '    <separator/>',
    '    <item label="Reconfigure">',
    '      <action name="Reconfigure"/>',
    '    </item>',
    '    <item label="Exit">',
    '      <action name="Exit"/>',
    '    </item>',
    '  </menu>',
    '</openbox_menu>'
])

with open(menu_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
EOF_PY_MENU
		[ $? -eq 0 ] && [ -s "${_out_menu}" ] && _gen_ok=1
	fi

	if [ "${_gen_ok}" -ne 1 ]; then
		local _cid _target_cat _tuple _t_key _rest _t_id _t_label _t_file _r_dir
		_r_dir="${XDG_RUNTIME_DIR:-/tmp}"
		for _cid in editors dev net office graphics media tools sys; do
			: >| "${_r_dir}/menu-cat-${_cid}-$$.xml"
		done
		for _app_dir in "${HOME}/.local/share/applications" "${HOME}/.local/share/flatpak/exports/share/applications" "/var/lib/flatpak/exports/share/applications" "/usr/local/share/applications" "/usr/share/applications"; do
			[ -d "${_app_dir}" ] || continue
			for _df in "${_app_dir}"/*.desktop; do
				[ -f "${_df}" ] || continue
				_d_name="$(grep -m 1 '^Name=' "${_df}" 2> "/dev/null" | cut -d= -f2- | tr -d '\r\n' || true)"
				_d_exec="$(grep -m 1 '^Exec=' "${_df}" 2> "/dev/null" | cut -d= -f2- | sed 's/[[:space:]]*%[a-zA-Z]//g' | tr -d '\r\n' || true)"
				[ -z "${_d_name}" ] || [ -z "${_d_exec}" ] && continue
				grep -q -E '^(NoDisplay|Hidden)=true' "${_df}" 2> "/dev/null" && continue
				case "${_d_exec}" in
					emacsclient*) _d_exec="${_e_cmd}" ;;
				esac
				_s_name="$(printf '%s' "${_d_name}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
				_s_exec="$(printf '%s' "${_d_exec}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
				_d_cat="$(grep -m 1 '^Categories=' "${_df}" 2> "/dev/null" | cut -d= -f2- | tr -d '\r\n' || true)"
				case "${_d_cat}" in
					*TextEditor*|*IDE*) _target_cat="editors" ;;
					*Development*|*Building*|*Debugger*|*RevisionControl*|*Translation*|*WebDevelopment*) _target_cat="dev" ;;
					*Network*|*WebBrowser*|*Email*|*InstantMessaging*|*Chat*|*FileTransfer*|*P2P*|*RemoteAccess*|*Feed*) _target_cat="net" ;;
					*Office*|*WordProcessor*|*Spreadsheet*|*Presentation*|*Database*|*Publishing*|*Viewer*|*PDF*|*Calendar*|*ContactManagement*) _target_cat="office" ;;
					*Graphics*|*2DGraphics*|*3DGraphics*|*VectorGraphics*|*RasterGraphics*|*Photography*|*Scanning*|*OCR*) _target_cat="graphics" ;;
					*AudioVideo*|*Audio*|*Video*|*Player*|*Recorder*|*Midi*|*Mixer*|*Sequencer*|*Tuner*|*TV*|*Music*) _target_cat="media" ;;
					*Utility*|*Accessories*|*Archiving*|*Compression*|*Calculator*|*Clock*|*FileTools*|*TextTools*|*Accessibility*) _target_cat="tools" ;;
					*) _target_cat="sys" ;;
				esac
				printf '      <item label="%s"><action name="Execute"><command>sh -c &apos;%s&apos;</command></action></item>\n' "${_s_name}" "${_s_exec}" >> "${_r_dir}/menu-cat-${_target_cat}-$$.xml"
			done
		done
		cat << EOF >| "${_out_menu}"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Universal Environment">
    <item label="Web Browser">
      <action name="Execute"><command>${_b_cmd}</command></action>
    </item>
    <item label="Terminal">
      <action name="Execute"><command>${_t_cmd}</command></action>
    </item>
    <item label="Files">
      <action name="Execute"><command>${_f_cmd}</command></action>
    </item>
    <item label="Emacs">
      <action name="Execute"><command>${_e_cmd}</command></action>
    </item>
    <separator/>
EOF
		for _tuple in "editors:cat-editors:Editors" "dev:cat-dev:Development" "net:cat-net:Internet" "office:cat-office:Office" "graphics:cat-graphics:Graphics" "media:cat-media:Media Player" "tools:cat-tools:Tools" "sys:cat-sys:System"; do
			_t_key="${_tuple%%:*}"
			_rest="${_tuple#*:}"
			_t_id="${_rest%%:*}"
			_t_label="${_rest#*:}"
			_t_file="${_r_dir}/menu-cat-${_t_key}-$$.xml"
			if [ -s "${_t_file}" ]; then
				printf '    <menu id="%s" label="%s">\n' "${_t_id}" "${_t_label}" >> "${_out_menu}"
				cat "${_t_file}" >> "${_out_menu}"
				printf '    </menu>\n' >> "${_out_menu}"
			fi
			rm -f "${_t_file}" 2> "/dev/null" || true
		done
		cat << EOF >> "${_out_menu}"
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
	fi
}

### --------------------------------
### WAYLAND WINDOW MANAGERS
### --------------------------------
window_manager_wayland() {
	unset EMACS_OS_MODE
	_sanitize_graphical_env
	local _flavor="" _selected_wm=""
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
			--sway|--labwc|--river|--cage|--hyprland|--niri|--wayfire|--dwl|--hikari|--weston|--ewm)
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

	if [ "$#" -gt 0 ]; then
		start-session way "$@"
		return $?
	fi

	if [ "${_selected_wm}" = "ewm" ]; then
		if [ -n "${_flavor}" ]; then
			emacs_window_manager_wayland "--${_flavor}"
		else
			emacs_window_manager_wayland
		fi
		return $?
	fi

	local _target_wm="${_selected_wm}"
	if [ -n "${_target_wm}" ]; then
		if [ "${_target_wm}" = "hyprland" ] && ! _has_exec_bin "hyprland" && _has_exec_bin "Hyprland"; then
			_target_wm="Hyprland"
		elif ! _has_exec_bin "${_target_wm}"; then
			if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
				_ui_err "Compositor Wayland '${_target_wm}' não está instalado."
			fi
			return 127
		fi
	else
		local _w_cand
		for _w_cand in $(_get_wayland_wm_pipeline); do
			if [ "${_w_cand}" = "hyprland" ] && ! _has_exec_bin "hyprland" && _has_exec_bin "Hyprland"; then
				if _preflight_wayland "Hyprland"; then
					_target_wm="Hyprland"
					break
				fi
			elif _preflight_wayland "${_w_cand}"; then
				_target_wm="${_w_cand}"
				break
			fi
		done
	fi
	[ -z "${_target_wm}" ] && return 127

	local _check_bin="${_target_wm}"
	_preflight_wayland "${_check_bin}" || return 127

	local _WAYLAND_FLAVOR_OVERRIDE="${_flavor}"
	_wayland_session_env "${_flavor}"

	local _scheme="${_RESOLVED_COLOR_SCHEME:-dark}"
	local _c_bg="#1e1e22" _c_panel="#2b2b30" _c_fg="#ffffff" _c_muted="#9a9996" _c_border="#38383d" _c_accent="#3584e4" _c_urgent="#e01b24"
	if [ "${_scheme}" = "light" ]; then
		_c_bg="#f6f5f4"
		_c_panel="#ffffff"
		_c_fg="#241f31"
		_c_muted="#5e5c64"
		_c_border="#cdc7c2"
	fi
	local _hex_bg="${_c_bg#\#}" _hex_border="${_c_border#\#}" _hex_accent="${_c_accent#\#}"

	local _cur_theme="${XCURSOR_THEME}"
	local _cur_size="${XCURSOR_SIZE:-24}"
	local _ui_font="$(_resolve_desktop_font "${_flavor}")"
	local _log_dir="$(_get_shell_log_dir)"

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
	local _bar_script="${_run_dir}/wwm-bar-$$.py"

	local _has_gtk3_bar=0
	if command -v python3 > "/dev/null" 2>&1 && python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' > "/dev/null" 2>&1; then
		_has_gtk3_bar=1
		_generate_wwm_bar_script "${_bar_script}"
	fi

	cat << EOF >| "${_term_script}"
#!/usr/bin/env sh
exec ${_wm_term} "\$@"
EOF
	chmod 0755 "${_term_script}"

	cat << 'EOF' >| "${_browser_script}"
#!/usr/bin/env sh
for _b in firefox chromium google-chrome-stable google-chrome brave-browser; do
	if command -v "${_b}" > "/dev/null" 2>&1; then
		exec "${_b}" "$@"
	fi
done
EOF
	chmod 0755 "${_browser_script}"

	cat << EOF >| "${_files_script}"
#!/usr/bin/env sh
for _fm in nautilus dolphin thunar pcmanfm caja nemo; do
	if command -v "\${_fm}" > "/dev/null" 2>&1; then
		exec "\${_fm}" "\$@"
	fi
done
exec ${_wm_term} -e sh -c 'ls -la; exec sh'
EOF
	chmod 0755 "${_files_script}"

	cat << 'EOF' >| "${_emacs_script}"
#!/usr/bin/env sh
export GDK_BACKEND="wayland"
for _e in emacs-pgtk emacs; do
	if command -v "${_e}" > "/dev/null" 2>&1; then
		exec "${_e}" "$@"
	fi
done
EOF
	chmod 0755 "${_emacs_script}"

	cat << EOF >| "${_menu_script}"
#!/usr/bin/env sh
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
#!/usr/bin/env sh
_term="${_term_script}"
_browser="${_browser_script}"
_files="${_files_script}"
_emacs="${_emacs_script}"
_menu="${_menu_script}"

(
	printf '{"version":1,"click_events":true}\n[\n'
	while :; do
		_date_str="\$(date "+%Y-%m-%d %H:%M:%S")"
		printf '[{"name":"browser","full_text":" Web Browser ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_accent}"},'
		printf '{"name":"term","full_text":" Terminal ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_accent}"},'
		printf '{"name":"files","full_text":" Files ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_accent}"},'
		printf '{"name":"emacs","full_text":" Emacs ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_accent}"},'
		printf '{"name":"menu","full_text":" Menu ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_accent}"},'
		printf '{"name":"close","full_text":" Close ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_urgent}"},'
		printf '{"name":"exit","full_text":" Exit ","background":"${_c_panel}","color":"${_c_fg}","border":"${_c_urgent}"},'
		printf '{"name":"time","full_text":" %s ","background":"${_c_bg}","color":"${_c_muted}","border":"${_c_border}"}],\n' "\${_date_str}"
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

	local _xwayland_line="xwayland disable" _bar_gdk="wayland"
	if _has_exec_bin "Xwayland"; then
		_xwayland_line="xwayland enable"
		_bar_gdk="x11"
	fi

	case "${_target_wm}" in
		sway)
			local _sway_cfg="${_run_dir}/sway-wm-$$.conf"
			cat << EOF >| "${_sway_cfg}"
output * bg ${_c_bg} solid_color
font pango:${_ui_font} Bold 10
workspace_layout tabbed
titlebar_padding 10 6
default_border pixel 2
default_floating_border pixel 2
client.focused ${_c_accent} ${_c_panel} ${_c_fg} ${_c_accent} ${_c_accent}
client.focused_inactive ${_c_border} ${_c_bg} ${_c_muted} ${_c_border} ${_c_border}
client.unfocused ${_c_border} ${_c_bg} ${_c_muted} ${_c_border} ${_c_border}
client.urgent ${_c_urgent} ${_c_panel} #ffffff ${_c_urgent} ${_c_urgent}
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
${_xwayland_line}
bindsym Mod4+Return exec ${_term_script}
bindsym Ctrl+Mod1+t exec ${_term_script}
bindsym Mod4+b exec ${_browser_script}
bindsym Mod4+e exec ${_emacs_script}
bindsym Mod4+f exec ${_files_script}
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
bindsym Mod4+Shift+f fullscreen toggle
bindsym F11 fullscreen toggle
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
no_focus [instance="wwm-bar"]
for_window [instance="wwm-bar"] floating enable, sticky enable, border none, resize set 100 ppt 32 px, move absolute position 0 0
exec sh -c 'env GDK_BACKEND=${_bar_gdk} WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" WWM_SCHEME="${_scheme}" WWM_WM="sway" python3 "${_bar_script}" > "${_log_dir}/wwm-bar.log" 2>&1'
EOF
			else
				cat << EOF >> "${_sway_cfg}"
bar {
    position bottom
    status_command "${_status_script}"
    font pango:${_ui_font} Bold 10
    colors {
        background ${_c_bg}
        statusline ${_c_fg}
        separator ${_c_border}
        focused_workspace ${_c_accent} ${_c_panel} ${_c_fg}
        inactive_workspace ${_c_bg} ${_c_bg} ${_c_muted}
    }
}
EOF
			fi
			_exec_wayland sway -c "${_sway_cfg}"
			local _ret=$?
			rm -f "${_sway_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		labwc)
			local _labwc_dir="${_run_dir}/labwc-wm-$$"
			mkdir -p "${_labwc_dir}"
			cat << EOF >| "${_labwc_dir}/themerc"
window.active.title.bg.color: ${_c_panel}
window.active.label.text.color: ${_c_fg}
window.inactive.title.bg.color: ${_c_bg}
window.inactive.label.text.color: ${_c_muted}
border.width: 2
border.color: ${_c_border}
window.active.border.color: ${_c_accent}
window.inactive.border.color: ${_c_border}
menu.border.width: 2
menu.border.color: ${_c_border}
menu.items.bg.color: ${_c_bg}
menu.items.text.color: ${_c_fg}
menu.items.active.bg.color: ${_c_accent}
menu.items.active.text.color: #ffffff
EOF
			_generate_openbox_menu_xml "${_labwc_dir}/menu.xml" "${_browser_script}" "${_term_script}" "${_files_script}" "${_emacs_script}" "${_wm_term}"
			cat << EOF >| "${_labwc_dir}/rc.xml"
<?xml version="1.0"?>
<labwc_config>
  <theme>
    <name>kiosk</name>
    <cornerRadius>0</cornerRadius>
    <border.width>2</border.width>
    <border.color>${_c_border}</border.color>
  </theme>
  <keyboard>
    <repeatRate>50</repeatRate>
    <repeatDelay>200</repeatDelay>
    <numlock>on</numlock>
    <keybind key="W-Return"><action name="Execute" command="${_term_script}"/></keybind>
    <keybind key="C-A-t"><action name="Execute" command="${_term_script}"/></keybind>
    <keybind key="W-b"><action name="Execute" command="${_browser_script}"/></keybind>
    <keybind key="W-e"><action name="Execute" command="${_emacs_script}"/></keybind>
    <keybind key="W-f"><action name="Execute" command="${_files_script}"/></keybind>
    <keybind key="W-m"><action name="ToggleMaximize"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
    <keybind key="W-S-q"><action name="Exit"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
  </keyboard>
  <windowRules>
    <windowRule identifier="wwm-bar" serverDecoration="no" skipTaskbar="yes"/>
  </windowRules>
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
</labwc_config>
EOF
			if [ "${_has_gtk3_bar}" -eq 1 ]; then
				cat << EOF >| "${_labwc_dir}/autostart"
#!/usr/bin/env sh
env GDK_BACKEND=${_bar_gdk} WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" WWM_SCHEME="${_scheme}" WWM_WM="labwc" python3 "${_bar_script}" > "${_log_dir}/wwm-bar.log" 2>&1 &
EOF
				chmod 0755 "${_labwc_dir}/autostart"
			fi
			_exec_wayland labwc -C "${_labwc_dir}"
			local _ret=$?
			rm -rf "${_labwc_dir}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		river)
			local _river_init="${_run_dir}/river-wm-$$.sh"
			cat << EOF >| "${_river_init}"
#!/usr/bin/env sh
riverctl border-width 2
riverctl border-color-focused "0x${_hex_accent}"
riverctl border-color-unfocused "0x${_hex_border}"
riverctl background-color "0x${_hex_bg}"
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
riverctl map normal Super Return spawn "${_term_script}"
riverctl map normal Control+Alt T spawn "${_term_script}"
riverctl map normal Super B spawn "${_browser_script}"
riverctl map normal Super E spawn "${_emacs_script}"
riverctl map normal Super F spawn "${_files_script}"
riverctl map normal Super Tab focus-view next
riverctl map normal Alt Tab focus-view next
riverctl map normal Super M toggle-fullscreen
riverctl map normal Super Q close
riverctl map normal Super+Shift Q spawn "riverctl exit"
EOF
			if [ "${_has_gtk3_bar}" -eq 1 ]; then
				cat << EOF >> "${_river_init}"
env GDK_BACKEND=${_bar_gdk} WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" WWM_SCHEME="${_scheme}" WWM_WM="river" python3 "${_bar_script}" > "${_log_dir}/wwm-bar.log" 2>&1 &
EOF
			fi
			chmod 0755 "${_river_init}"
			_exec_wayland river -c "${_river_init}"
			local _ret=$?
			rm -f "${_river_init}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		Hyprland|hyprland)
			local _hypr_cfg="${_run_dir}/hyprland-wm-$$.conf"
			cat << EOF >| "${_hypr_cfg}"
monitor=,preferred,auto,1
general {
    border_size = 2
    gaps_in = 2
    gaps_out = 4
    col.active_border = rgb(${_hex_accent})
    col.inactive_border = rgb(${_hex_border})
}
misc {
    disable_hyprland_logo = true
    background_color = rgb(${_hex_bg})
}
input {
    kb_layout = br
    kb_model = abnt2
    kb_options = numpad:mac
    repeat_rate = 50
    repeat_delay = 200
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}
bind = SUPER, Return, exec, ${_term_script}
bind = CTRL ALT, T, exec, ${_term_script}
bind = SUPER, B, exec, ${_browser_script}
bind = SUPER, E, exec, ${_emacs_script}
bind = SUPER, F, exec, ${_files_script}
bind = SUPER, D, exec, ${_menu_script}
bind = SUPER, Tab, cyclenext
bind = ALT, Tab, cyclenext
bind = SUPER, M, fullscreen, 1
bind = SUPER, Q, killactive
bind = SUPER SHIFT, Q, exit
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
EOF
			if [ "${_has_gtk3_bar}" -eq 1 ]; then
				cat << EOF >> "${_hypr_cfg}"
windowrulev2 = float, class:^(wwm-bar)$
windowrulev2 = pin, class:^(wwm-bar)$
windowrulev2 = noborder, class:^(wwm-bar)$
windowrulev2 = nofocus, class:^(wwm-bar)$
windowrulev2 = move 0 0, class:^(wwm-bar)$
exec-once = sh -c 'env GDK_BACKEND=${_bar_gdk} WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" WWM_SCHEME="${_scheme}" WWM_WM="hyprland" python3 "${_bar_script}" > "${_log_dir}/wwm-bar.log" 2>&1'
EOF
			fi
			_exec_wayland "${_target_wm}" --config "${_hypr_cfg}"
			local _ret=$?
			rm -f "${_hypr_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		niri)
			local _niri_cfg="${_run_dir}/niri-wm-$$.kdl"
			cat << EOF >| "${_niri_cfg}"
prefer-no-csd
layout {
    border {
        width 2
        active-color "${_c_accent}"
        inactive-color "${_c_border}"
    }
}
binds {
    Mod+Return { spawn "${_term_script}"; }
    Ctrl+Alt+T { spawn "${_term_script}"; }
    Mod+B { spawn "${_browser_script}"; }
    Mod+E { spawn "${_emacs_script}"; }
    Mod+F { spawn "${_files_script}"; }
    Mod+D { spawn "${_menu_script}"; }
    Mod+Q { close-window; }
    Mod+Shift+Q { quit; }
}
EOF
			if [ "${_has_gtk3_bar}" -eq 1 ]; then
				printf 'spawn-at-startup "sh" "-c" "env GDK_BACKEND=%s WWM_TERM=%s WWM_BROWSER=%s WWM_FILES=%s WWM_EMACS=%s WWM_MENU=%s WWM_FONT=%s WWM_SCHEME=%s WWM_WM=niri python3 %s > %s/wwm-bar.log 2>&1"\n' \
					"${_bar_gdk}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_ui_font}" "${_scheme}" "${_bar_script}" "${_log_dir}" >> "${_niri_cfg}"
			fi
			_exec_wayland niri --config "${_niri_cfg}"
			local _ret=$?
			rm -f "${_niri_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		wayfire)
			local _wf_cfg="${_run_dir}/wayfire-wm-$$.ini"
			cat << EOF >| "${_wf_cfg}"
[core]
plugins = autostart command wm-actions resize move grid
close_top_view = <super> KEY_Q
[command]
binding_term = <super> KEY_ENTER
command_term = ${_term_script}
binding_browser = <super> KEY_B
command_browser = ${_browser_script}
binding_emacs = <super> KEY_E
command_emacs = ${_emacs_script}
binding_files = <super> KEY_F
command_files = ${_files_script}
binding_menu = <super> KEY_D
command_menu = ${_menu_script}
EOF
			if [ "${_has_gtk3_bar}" -eq 1 ]; then
				cat << EOF >> "${_wf_cfg}"
[autostart]
bar = sh -c 'env GDK_BACKEND=${_bar_gdk} WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" WWM_SCHEME="${_scheme}" WWM_WM="wayfire" python3 "${_bar_script}" > "${_log_dir}/wwm-bar.log" 2>&1'
EOF
			fi
			_exec_wayland wayfire -c "${_wf_cfg}"
			local _ret=$?
			rm -f "${_wf_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		dwl)
			local _dwl_startup="${_run_dir}/dwl-startup-$$.sh"
			cat << EOF >| "${_dwl_startup}"
#!/usr/bin/env sh
if [ "${_has_gtk3_bar}" -eq 1 ]; then
	env GDK_BACKEND=${_bar_gdk} WWM_TERM="${_term_script}" WWM_BROWSER="${_browser_script}" WWM_FILES="${_files_script}" WWM_EMACS="${_emacs_script}" WWM_MENU="${_menu_script}" WWM_FONT="${_ui_font}" WWM_SCHEME="${_scheme}" WWM_WM="dwl" python3 "${_bar_script}" > "${_log_dir}/wwm-bar.log" 2>&1 &
fi
exec ${_wm_term}
EOF
			chmod 0755 "${_dwl_startup}"
			_exec_wayland dwl -s "${_dwl_startup}"
			local _ret=$?
			rm -f "${_dwl_startup}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		hikari)
			local _hikari_cfg="${_run_dir}/hikari-wm-$$.conf"
			cat << EOF >| "${_hikari_cfg}"
ui {
  border = 2
  gap = 4
  active = 0x${_hex_accent}
  inactive = 0x${_hex_border}
}
actions {
  terminal = "${_term_script}"
  browser = "${_browser_script}"
  emacs = "${_emacs_script}"
  files = "${_files_script}"
}
bindings {
  keyboard {
    "L+Return" = action-terminal
    "CA+t" = action-terminal
    "L+b" = action-browser
    "L+e" = action-emacs
    "L+f" = action-files
    "L+q" = view-quit
    "LS+q" = quit
  }
}
EOF
			_exec_wayland hikari -c "${_hikari_cfg}"
			local _ret=$?
			rm -f "${_hikari_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		weston)
			local _weston_cfg="${_run_dir}/weston-wm-$$.ini"
			cat << EOF >| "${_weston_cfg}"
[core]
xwayland=true
[shell]
background-color=0xff${_hex_bg}
panel-position=top
[keyboard]
keymap_layout=br
keymap_model=abnt2
repeat-delay=200
repeat-rate=50
[launcher]
path=${_term_script}
[launcher]
path=${_browser_script}
[launcher]
path=${_emacs_script}
EOF
			_exec_wayland weston --config="${_weston_cfg}"
			local _ret=$?
			rm -f "${_weston_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		cage)
			_exec_wayland cage -s -- ${_wm_term}
			local _ret=$?
			rm -f "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		*)
			rm -f "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_status_script}" "${_bar_script}" 2> "/dev/null" || true
			return 127
			;;
	esac
}
alias window-manager-wayland="window_manager_wayland" wwm="window_manager_wayland"

### --------------------------------
### X11 WINDOW MANAGERS
### --------------------------------
window_manager_x11() {
	unset EMACS_OS_MODE
	_sanitize_graphical_env
	local _flavor="" _selected_wm=""
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

	if [ "$#" -gt 0 ]; then
		start-session xorg "$@"
		return $?
	fi

	if [ "${_selected_wm}" = "ewm" ]; then
		if [ -n "${_flavor}" ]; then
			emacs_window_manager_x11 "--${_flavor}"
		else
			emacs_window_manager_x11
		fi
		return $?
	fi

	{ _has_exec_bin "startx" || _has_exec_bin "xinit"; } || return 127
	{ _has_exec_bin "Xorg" || _has_exec_bin "X"; } || return 127

	local _target_wm="${_selected_wm}" _fvwm_bin=""
	case "${_target_wm}" in
		fvwm3|fvwm)
			if [ "${_target_wm}" = "fvwm3" ] && _has_exec_bin "fvwm3"; then
				_fvwm_bin="$(command -v fvwm3)"
			elif _has_exec_bin "fvwm3"; then
				_fvwm_bin="$(command -v fvwm3)"
			elif _has_exec_bin "fvwm"; then
				_fvwm_bin="$(command -v fvwm)"
			fi
			if [ -z "${_fvwm_bin}" ]; then
				if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
					_ui_err "Gerenciador X11 '${_target_wm}' não está instalado."
				fi
				return 127
			fi
			_target_wm="${_fvwm_bin##*/}"
			;;
		matchbox)
			_target_wm="matchbox-window-manager"
			;;
	esac

	if [ -n "${_target_wm}" ]; then
		if [ "${_target_wm}" != "fvwm3" ] && [ "${_target_wm}" != "fvwm" ] && ! _has_exec_bin "${_target_wm}"; then
			if [ "${_SHELL_DISPATCH_PROBE:-0}" != "1" ]; then
				_ui_err "Gerenciador X11 '${_target_wm}' não está instalado."
			fi
			return 127
		fi
	else
		local _x_cand
		for _x_cand in $(_get_x11_wm_pipeline); do
			if _has_exec_bin "${_x_cand}"; then
				_target_wm="${_x_cand}"
				case "${_x_cand}" in
					fvwm3|fvwm) _fvwm_bin="$(command -v "${_x_cand}")" ;;
				esac
				break
			fi
		done
	fi
	[ -z "${_target_wm}" ] && return 127

	local _X11_FLAVOR_OVERRIDE="${_flavor}"
	_x11_session_env "${_flavor}"

	local _scheme="${_RESOLVED_COLOR_SCHEME:-dark}"
	local _c_bg="#1e1e22" _c_panel="#2b2b30" _c_menu_bg="#242428" _c_fg="#ffffff" _c_muted="#9a9996" _c_dis="#5e5c64" _c_border="#38383d" _c_accent="#3584e4" _c_urgent="#e01b24"
	if [ "${_scheme}" = "light" ]; then
		_c_bg="#f6f5f4"
		_c_panel="#ffffff"
		_c_menu_bg="#ffffff"
		_c_fg="#241f31"
		_c_muted="#5e5c64"
		_c_dis="#9a9996"
		_c_border="#cdc7c2"
	fi

	local _ui_font="$(_resolve_desktop_font "${_flavor}")"

	local _kiosk_theme_dir="${HOME}/.local/share/themes/kiosk/openbox-3"
	mkdir -p "${_kiosk_theme_dir}" 2> "/dev/null" || true
	cat << OTM >| "${_kiosk_theme_dir}/themerc"
border.width: 3
border.color: ${_c_border}
padding.width: 8
padding.height: 6
window.handle.width: 3
window.client.padding.width: 0

window.active.border.color: ${_c_accent}
window.active.title.bg: flat solid
window.active.title.bg.color: ${_c_panel}
window.active.label.bg: parentrelative
window.active.label.text.color: ${_c_fg}
window.active.handle.bg: flat solid
window.active.handle.bg.color: ${_c_panel}
window.active.grip.bg: flat solid
window.active.grip.bg.color: ${_c_accent}
window.active.button.unpressed.bg: parentrelative
window.active.button.unpressed.image.color: ${_c_fg}
window.active.button.pressed.bg: flat solid
window.active.button.pressed.bg.color: ${_c_accent}
window.active.button.pressed.image.color: #ffffff
window.active.button.hover.bg: flat solid
window.active.button.hover.bg.color: ${_c_accent}
window.active.button.hover.image.color: #ffffff
window.active.button.disabled.bg: parentrelative
window.active.button.disabled.image.color: ${_c_dis}
window.inactive.border.color: ${_c_border}
window.inactive.title.bg: flat solid
window.inactive.title.bg.color: ${_c_bg}
window.inactive.label.bg: parentrelative
window.inactive.label.text.color: ${_c_muted}
window.inactive.handle.bg: flat solid
window.inactive.handle.bg.color: ${_c_bg}
window.inactive.grip.bg: flat solid
window.inactive.grip.bg.color: ${_c_panel}
window.inactive.button.unpressed.bg: parentrelative
window.inactive.button.unpressed.image.color: ${_c_muted}
window.inactive.button.pressed.bg: flat solid
window.inactive.button.pressed.bg.color: ${_c_border}
window.inactive.button.pressed.image.color: ${_c_fg}
window.inactive.button.hover.bg: flat solid
window.inactive.button.hover.bg.color: ${_c_border}
window.inactive.button.hover.image.color: ${_c_fg}
window.inactive.button.disabled.bg: parentrelative
window.inactive.button.disabled.image.color: ${_c_dis}
osd.border.width: 2
osd.border.color: ${_c_accent}
osd.bg: flat solid
osd.bg.color: ${_c_panel}
osd.label.bg: parentrelative
osd.label.text.color: ${_c_fg}
osd.hilight.bg: flat solid
osd.hilight.bg.color: ${_c_accent}
osd.unhilight.bg: flat solid
osd.unhilight.bg.color: ${_c_bg}
osd.button.unpressed.bg: flat solid
osd.button.unpressed.bg.color: ${_c_bg}
osd.button.unpressed.text.color: ${_c_fg}
osd.button.unpressed.border.color: ${_c_border}
osd.button.pressed.bg: flat solid
osd.button.pressed.bg.color: ${_c_accent}
osd.button.pressed.text.color: #ffffff
osd.button.pressed.border.color: ${_c_accent}
osd.button.focused.bg: flat solid
osd.button.focused.bg.color: ${_c_accent}
osd.button.focused.text.color: #ffffff
osd.button.focused.border.color: ${_c_accent}
menu.border.width: 2
menu.border.color: ${_c_border}
menu.title.bg: flat solid
menu.title.bg.color: ${_c_bg}
menu.title.text.color: ${_c_accent}
menu.items.bg: flat solid
menu.items.bg.color: ${_c_menu_bg}
menu.items.text.color: ${_c_fg}
menu.items.disabled.text.color: ${_c_dis}
menu.items.active.bg: flat solid
menu.items.active.bg.color: ${_c_accent}
menu.items.active.text.color: #ffffff
menu.separator.color: ${_c_border}
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
	local _menu_script="${_run_dir}/xwm-menu-$$.sh"
	local _bar_script="${_run_dir}/xwm-bar-$$.py"

	local _has_gtk3_bar=0
	if command -v python3 > "/dev/null" 2>&1 && python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' > "/dev/null" 2>&1; then
		_has_gtk3_bar=1
		_generate_wwm_bar_script "${_bar_script}"
	fi

	cat << EOF >| "${_term_script}"
#!/usr/bin/env sh
exec ${_wm_x11_term} "\$@"
EOF
	chmod 0755 "${_term_script}"

	cat << 'EOF' >| "${_browser_script}"
#!/usr/bin/env sh
for _b in firefox chromium google-chrome-stable google-chrome brave-browser; do
	if command -v "${_b}" > "/dev/null" 2>&1; then
		exec "${_b}" "$@"
	fi
done
EOF
	chmod 0755 "${_browser_script}"

	cat << EOF >| "${_files_script}"
#!/usr/bin/env sh
for _fm in nautilus dolphin thunar pcmanfm caja nemo; do
	if command -v "\${_fm}" > "/dev/null" 2>&1; then
		exec "\${_fm}" "\$@"
	fi
done
exec ${_wm_x11_term} -e sh -c 'ls -la; exec sh'
EOF
	chmod 0755 "${_files_script}"

	cat << 'EOF' >| "${_emacs_script}"
#!/usr/bin/env sh
for _e in emacs-gtk+x11 emacs-x11 emacs-lucid emacs-gtk emacs-nw emacs; do
	if command -v "${_e}" > "/dev/null" 2>&1; then
		exec "${_e}" "$@"
	fi
done
EOF
	chmod 0755 "${_emacs_script}"

	cat << EOF >| "${_menu_script}"
#!/usr/bin/env sh
if command -v rofi > "/dev/null" 2>&1; then
	exec rofi -show drun
elif command -v dmenu_run > "/dev/null" 2>&1; then
	exec dmenu_run
else
	exec ${_wm_x11_term}
fi
EOF
	chmod 0755 "${_menu_script}"

	local _X11_SESSION_BG_CMD=""
	if [ "${_has_gtk3_bar}" -eq 1 ]; then
		_X11_SESSION_BG_CMD="exec env GDK_BACKEND=x11 WWM_TERM=\"${_term_script}\" WWM_BROWSER=\"${_browser_script}\" WWM_FILES=\"${_files_script}\" WWM_EMACS=\"${_emacs_script}\" WWM_MENU=\"${_menu_script}\" WWM_FONT=\"${_ui_font}\" WWM_SCHEME=\"${_scheme}\" WWM_WM=\"${_target_wm}\" python3 \"${_bar_script}\""
	fi

	local _ret=0
	case "${_target_wm}" in
		openbox)
			local _ob_menu_cfg="${_run_dir}/openbox-menu-$$.xml"
			local _ob_wm_cfg="${_run_dir}/openbox-wm-$$.xml"
			_generate_openbox_menu_xml "${_ob_menu_cfg}" "${_browser_script}" "${_term_script}" "${_files_script}" "${_emacs_script}" "${_wm_x11_term}"
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
  <margins>
    <top>32</top>
    <bottom>0</bottom>
    <left>0</left>
    <right>0</right>
  </margins>
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
      <mousebind button="Middle" action="Press">
        <action name="ShowMenu"><menu>client-list-combined-menu</menu></action>
      </mousebind>
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
    <keybind key="W-m"><action name="ToggleMaximize"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-S-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF
			_exec_x11 openbox --config-file "${_ob_wm_cfg}"
			_ret=$?
			rm -f "${_ob_menu_cfg}" "${_ob_wm_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		cwm)
			local _cwm_cfg="${_run_dir}/cwmrc-wm-$$"
			cat << EOF >| "${_cwm_cfg}"
borderwidth 2
color activeborder "${_c_accent}"
color inactiveborder "${_c_border}"
color groupborder "${_c_accent}"
color urgencyborder "${_c_urgent}"
color menubg "${_c_bg}"
color menufg "${_c_fg}"
color font "${_c_fg}"
color selfont "#ffffff"
fontname "${_ui_font}:size=10"
gap 32 0 0 0
ignore wwm-bar
sticky yes
autogroup 1 "xterm,XTerm"
autogroup 1 "emacs,Emacs"
bind-key 4-Return "${_term_script}"
bind-key CM-t "${_term_script}"
bind-key 4-b "${_browser_script}"
bind-key 4-e "${_emacs_script}"
bind-key 4-f "${_files_script}"
bind-key 4-m window-maximize
bind-key M-Tab window-cycle
bind-key 4-Tab window-cycle
bind-key 4-q window-close
bind-key M-F4 window-close
bind-key 4S-q quit
EOF
			_exec_x11 cwm -c "${_cwm_cfg}"
			_ret=$?
			rm -f "${_cwm_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		fvwm3|fvwm)
			local _fvwm_cfg="${_run_dir}/fvwm-wm-$$.conf"
			cat << EOF >| "${_fvwm_cfg}"
EwmhBaseStruts 0 0 32 0
Style * BorderWidth 2, HandleWidth 2
Style * HilightBorderColor ${_c_accent}, BorderColor ${_c_border}
Style * HilightFore ${_c_fg}, HilightBack ${_c_panel}
Style * ForeColor ${_c_muted}, BackColor ${_c_bg}
Style * Font "xft:${_ui_font}:size=10:bold"
Style "wwm-bar" !Title, !Borders, !Handles, Sticky, WindowListSkip, CirculateSkip, StaysOnTop
Key Return A 4 Exec exec ${_term_script}
Key b A 4 Exec exec ${_browser_script}
Key e A 4 Exec exec ${_emacs_script}
Key f A 4 Exec exec ${_files_script}
Key m A 4 Maximize 100 100
Key Tab A 4 Next (AcceptsFocus) Focus
Key Tab A M Next (AcceptsFocus) Focus
Key q A 4 Close
Key F4 A M Close
Key q A 4S Quit
EOF
			_exec_x11 "${_fvwm_bin}" -f "${_fvwm_cfg}"
			_ret=$?
			rm -f "${_fvwm_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		fluxbox)
			local _fb_dir="${_run_dir}/fluxbox-wm-$$"
			mkdir -p "${_fb_dir}"
			cat << EOF >| "${_fb_dir}/keys"
Mod4 Return :Exec ${_term_script}
Control Mod1 t :Exec ${_term_script}
Mod4 b :Exec ${_browser_script}
Mod4 e :Exec ${_emacs_script}
Mod4 f :Exec ${_files_script}
Mod4 m :Maximize
Mod1 Tab :NextWindow
Mod4 Tab :NextWindow
Mod4 q :Close
Mod1 F4 :Close
Mod4 Shift q :Exit
EOF
			cat << EOF >| "${_fb_dir}/overlay"
background: solid
background.color: ${_c_bg}
window.borderWidth: 2
window.borderColor: ${_c_border}
window.title.focus.color: ${_c_panel}
window.title.unfocus.color: ${_c_bg}
window.label.focus.textColor: ${_c_fg}
window.label.unfocus.textColor: ${_c_muted}
window.frame.focusColor: ${_c_accent}
window.frame.unfocusColor: ${_c_border}
EOF
			cat << EOF >| "${_fb_dir}/init"
session.screen0.toolbar.visible: false
session.screen0.struts: 0,0,32,0
session.keyFile: ${_fb_dir}/keys
session.styleOverlay: ${_fb_dir}/overlay
EOF
			_exec_x11 fluxbox -rc "${_fb_dir}/init"
			_ret=$?
			rm -rf "${_fb_dir}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		icewm)
			local _ice_dir="${_run_dir}/icewm-wm-$$"
			mkdir -p "${_ice_dir}"
			cat << EOF >| "${_ice_dir}/preferences"
ShowTaskBar=0
BorderSizeX=2
BorderSizeY=2
DesktopBackgroundColor="${_c_bg}"
ColorActiveTitleBar="${_c_panel}"
ColorNormalTitleBar="${_c_bg}"
ColorActiveTitleBarText="${_c_fg}"
ColorNormalTitleBarText="${_c_muted}"
ColorActiveBorder="${_c_accent}"
ColorNormalBorder="${_c_border}"
EOF
			cat << EOF >| "${_ice_dir}/keys"
key "Super+Return" ${_term_script}
key "Ctrl+Alt+t" ${_term_script}
key "Super+b" ${_browser_script}
key "Super+e" ${_emacs_script}
key "Super+f" ${_files_script}
EOF
			cat << 'EOF' >| "${_ice_dir}/winoptions"
wwm-bar.ignoreTaskBar: 1
wwm-bar.dTitleBar: 0
wwm-bar.dBorder: 0
wwm-bar.allWorkspaces: 1
EOF
			ICEWM_PRIVCFG="${_ice_dir}" _exec_x11 icewm -c "${_ice_dir}/preferences"
			_ret=$?
			rm -rf "${_ice_dir}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		jwm)
			local _jwm_cfg="${_run_dir}/jwm-wm-$$.xml"
			cat << EOF >| "${_jwm_cfg}"
<?xml version="1.0"?>
<JWM>
  <Desktops width="1" height="1">
    <Background type="solid">${_c_bg}</Background>
  </Desktops>
  <WindowStyle>
    <Font>${_ui_font}-10:bold</Font>
    <Width>2</Width>
    <Height>22</Height>
    <Foreground>${_c_muted}</Foreground>
    <Background>${_c_bg}</Background>
    <Outline>${_c_border}</Outline>
    <Active>
      <Foreground>${_c_fg}</Foreground>
      <Background>${_c_panel}</Background>
      <Outline>${_c_accent}</Outline>
    </Active>
  </WindowStyle>
  <Group>
    <Name>wwm-bar</Name>
    <Option>nolist</Option>
    <Option>noborder</Option>
    <Option>notitle</Option>
    <Option>sticky</Option>
    <Option>layer:above</Option>
  </Group>
  <Key mask="4" key="Return">exec:${_term_script}</Key>
  <Key mask="CA" key="t">exec:${_term_script}</Key>
  <Key mask="4" key="b">exec:${_browser_script}</Key>
  <Key mask="4" key="e">exec:${_emacs_script}</Key>
  <Key mask="4" key="f">exec:${_files_script}</Key>
  <Key mask="4" key="m">maximize</Key>
  <Key mask="A" key="Tab">next</Key>
  <Key mask="4" key="Tab">next</Key>
  <Key mask="4" key="q">close</Key>
  <Key mask="A" key="F4">close</Key>
  <Key mask="4S" key="q">exit</Key>
</JWM>
EOF
			_exec_x11 jwm -f "${_jwm_cfg}"
			_ret=$?
			rm -f "${_jwm_cfg}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		pekwm)
			local _pekwm_dir="${_run_dir}/pekwm-wm-$$"
			mkdir -p "${_pekwm_dir}"
			cat << EOF >| "${_pekwm_dir}/config"
Files {
    Keys = "${_pekwm_dir}/keys"
    AutoProps = "${_pekwm_dir}/autoproperties"
}
Screen {
    EdgeSize = "2"
    EdgeIndent = "True"
}
EOF
			cat << EOF >| "${_pekwm_dir}/keys"
Global {
    KeyPress = "Mod4 Return" { Actions = "Exec ${_term_script}" }
    KeyPress = "Ctrl Mod1 t" { Actions = "Exec ${_term_script}" }
    KeyPress = "Mod4 b" { Actions = "Exec ${_browser_script}" }
    KeyPress = "Mod4 e" { Actions = "Exec ${_emacs_script}" }
    KeyPress = "Mod4 f" { Actions = "Exec ${_files_script}" }
    KeyPress = "Mod4 m" { Actions = "Toggle Maximized True True" }
    KeyPress = "Mod1 Tab" { Actions = "NextFrame EndRaise" }
    KeyPress = "Mod4 Tab" { Actions = "NextFrame EndRaise" }
    KeyPress = "Mod4 q" { Actions = "Close" }
    KeyPress = "Mod4 Shift q" { Actions = "Exit" }
}
EOF
			cat << 'EOF' >| "${_pekwm_dir}/autoproperties"
Property = "wwm-bar,wwm-bar" {
    Titlebar = "False";
    Border = "False";
    Sticky = "True";
    Skip = "Taskbar FocusToggle";
    Layer = "AboveDock";
}
EOF
			_exec_x11 pekwm --config "${_pekwm_dir}/config"
			_ret=$?
			rm -rf "${_pekwm_dir}" "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		dwm|twm)
			_exec_x11 "${_target_wm}"
			_ret=$?
			rm -f "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		matchbox|matchbox-window-manager)
			_exec_x11 sh -c '(command -v xterm > "/dev/null" 2>&1 && xterm &); exec matchbox-window-manager'
			_ret=$?
			rm -f "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return "${_ret}"
			;;
		*)
			rm -f "${_term_script}" "${_browser_script}" "${_files_script}" "${_emacs_script}" "${_menu_script}" "${_bar_script}" 2> "/dev/null" || true
			return 127
			;;
	esac
}
alias window-manager-x11="window_manager_x11" xwm="window_manager_x11"

### --------------------------------
### WINDOW MANAGER ENTRYPOINT
### --------------------------------
window_manager() {
	local _prev_probe="${_SHELL_DISPATCH_PROBE:-}"
	export _SHELL_DISPATCH_PROBE=1
	_dispatch_display_server "window-manager" "$@"
	local _ret=$?
	if [ -n "${_prev_probe}" ]; then
		export _SHELL_DISPATCH_PROBE="${_prev_probe}"
	else
		unset _SHELL_DISPATCH_PROBE
	fi
	return "${_ret}"
}
alias window-manager="window_manager" wm="window_manager" win="window_manager" win-man="window_manager" window="window_manager"
_SHELL_DESKTOP_SESSION_LOADED=1
