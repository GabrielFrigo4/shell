# ----------------------------------------------------------------
# Library: Desktop Theme Context & Session Environment Propagation
# ----------------------------------------------------------------

export BREEZE_ADWAITA_ROOT_BG="#181b20"
export BREEZE_ADWAITA_BAR_BG="#1e222a"
export BREEZE_ADWAITA_SURFACE_BG="#2a2e38"
export BREEZE_ADWAITA_BORDER="#3b404d"
export BREEZE_ADWAITA_ACCENT="#3daee9"
export BREEZE_ADWAITA_ACCENT_FG="#ffffff"
export BREEZE_ADWAITA_ALERT="#e05263"

### ================================
### SESSION THEME PROPAGATION
### ================================
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
			_qt_theme="Breeze"
			[ "${_scheme}" = "light" ] && _gtk_theme="Breeze" || _gtk_theme="Breeze-Dark"
			;;
		lxqt)
			_qt_platform="lxqt"
			_qt_theme="Breeze"
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
	cat <<- EOF >| "${_env_dir}/10-theme.conf" 2> "/dev/null" || true
		QT_QPA_PLATFORMTHEME=${_qt_platform}
		SAL_USE_VCLPLUGIN=gtk3
	EOF

	local _xprofile="${HOME}/.xprofile"
	if [ ! -f "${_xprofile}" ]; then
		cat <<- EOF >| "${_xprofile}" 2> "/dev/null" || true
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

### ================================
### DESKTOP THEME CONTEXT
### ================================
_desktop_apply_theme_context() {
	local _gui_raw_de _gui_is_full_de _gui_uid _gui_proc _gtk_theme _qt_style _qt_platform
	local _theme_env_dir _theme_stamp _default_cursor_paths _cursor_theme _cursor_size
	local _user_id _cursor_candidate _icon_dir
	if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
		_gui_raw_de="${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}}"
		_gui_is_full_de=0
		if [ "${KDE_FULL_SESSION:-}" = "true" ]; then
			_gui_is_full_de=1
		elif [ -n "${_gui_raw_de}" ]; then
			case "$(printf '%s' "${_gui_raw_de}" | tr '[:upper:]' '[:lower:]')" in
				*kde*|*plasma*|*gnome*|*ubuntu*|*unity*|*zorin*|*xfce*|*mate*|*cinnamon*|*cosmic*|*budgie*|*pantheon*|*lxqt*|*lxde*|*deepin*|*dde*)
					_gui_is_full_de=1
					;;
			esac
		elif command -v pgrep > "/dev/null" 2>&1; then
			case "$(uname -s 2> "/dev/null")" in
				MINGW*|MSYS*|CYGWIN*) _gui_uid="$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")" ;;
				*) _gui_uid="$(id -u 2> "/dev/null" || id -un 2> "/dev/null" || printf '%s' "${USER:-}")" ;;
			esac
			for _gui_proc in plasmashell kwin_wayland kwin_x11 gnome-shell xfce4-session mate-session cinnamon cosmic-comp cosmic-session budgie-wm budgie-panel gala wingpanel lxqt-session lxsession dde-desktop deepin-wm; do
				if [ -n "${_gui_uid}" ] && pgrep -u "${_gui_uid}" -x "${_gui_proc}" > "/dev/null" 2>&1; then
					_gui_is_full_de=1
					break
				fi
			done
		fi

		if [ "${_gui_is_full_de}" -eq 0 ]; then
			if [ -z "${GTK_THEME:-}" ]; then
				if [ -n "${_DETECTED_GTK_THEME:-}" ]; then
					export GTK_THEME="${_DETECTED_GTK_THEME}"
				elif [ -z "${_DETECTED_GTK_THEME+x}" ] && command -v _detect_gtk_theme > "/dev/null" 2>&1; then
					_gtk_theme="$(_detect_gtk_theme)"
					[ -n "${_gtk_theme}" ] && export GTK_THEME="${_gtk_theme}"
				fi
			fi

			if [ -z "${QT_STYLE_OVERRIDE:-}" ]; then
				if [ -n "${_DETECTED_QT_THEME:-}" ]; then
					export QT_STYLE_OVERRIDE="${_DETECTED_QT_THEME}"
				elif [ -z "${_DETECTED_QT_THEME+x}" ] && command -v _detect_qt_theme > "/dev/null" 2>&1; then
					_qt_style="$(_detect_qt_theme)"
					[ -n "${_qt_style}" ] && export QT_STYLE_OVERRIDE="${_qt_style}"
				fi
			fi
		fi

		if [ -z "${QT_QPA_PLATFORMTHEME:-}" ]; then
			if [ -n "${_DETECTED_QT_PLATFORM_THEME:-}" ]; then
				export QT_QPA_PLATFORMTHEME="${_DETECTED_QT_PLATFORM_THEME}"
			elif [ -z "${_DETECTED_QT_PLATFORM_THEME+x}" ] && command -v _detect_qt_platform_theme > "/dev/null" 2>&1; then
				_qt_platform="$(_detect_qt_platform_theme)"
				[ -n "${_qt_platform}" ] && export QT_QPA_PLATFORMTHEME="${_qt_platform}"
			fi
		fi

		export ELECTRON_OZONE_PLATFORM_HINT="auto"
		export _JAVA_AWT_WM_NONREPARENTING=1
		export SAL_USE_VCLPLUGIN="gtk3"

		_theme_env_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d"
		_theme_stamp="${_SHELL_CACHE_DIR:-}/session_theme_propagated_${_DETECTED_DESKTOP_ENV:-default}"
		if { [ -z "${_SHELL_CACHE_DIR:-}" ] || [ ! -f "${_theme_stamp}" ] || [ ! -f "${_theme_env_dir}/10-theme.conf" ]; } && command -v _propagate_session_theme_env > "/dev/null" 2>&1; then
			_propagate_session_theme_env
			if [ -n "${_SHELL_CACHE_DIR:-}" ]; then
				[ -d "${_SHELL_CACHE_DIR}" ] || command mkdir -p "${_SHELL_CACHE_DIR}" 2> "/dev/null" || true
				: >| "${_theme_stamp}" 2> "/dev/null" || true
			fi
		fi

		_default_cursor_paths="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons"
		case ":${XCURSOR_PATH:-}:" in
			*":/usr/local/share/icons:"*) ;;
			*) export XCURSOR_PATH="${XCURSOR_PATH:+${XCURSOR_PATH}:}${_default_cursor_paths}" ;;
		esac

		if [ -z "${XCURSOR_THEME:-}" ] || [ -z "${XCURSOR_SIZE:-}" ]; then
			if [ -n "${_DETECTED_CURSOR_THEME:-}" ] && [ -n "${_DETECTED_CURSOR_SIZE:-}" ]; then
				[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_DETECTED_CURSOR_THEME}"
				[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_DETECTED_CURSOR_SIZE}"
			else
				_cursor_theme=""
				_cursor_size="${XCURSOR_SIZE:-24}"

				_user_id=""
				if [ -z "${_DETECTED_DESKTOP_ENV:-}" ] && [ -z "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}" ] && command -v pgrep > "/dev/null" 2>&1; then
					case "$(uname -s 2> "/dev/null")" in
						MINGW*|MSYS*|CYGWIN*) _user_id="$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")" ;;
						*) _user_id="$(id -u 2> "/dev/null" || printf '1000')" ;;
					esac
				fi
				if [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x plasmashell > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x kwin_wayland > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x kwin_x11 > "/dev/null" 2>&1; }; then
					if [ -f "${HOME}/.config/kcminputrc" ]; then
						_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
						_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
				elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x gnome-shell > "/dev/null" 2>&1; then
					if command -v gsettings > "/dev/null" 2>&1; then
						_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
						_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x mate-session > "/dev/null" 2>&1; then
					if command -v gsettings > "/dev/null" 2>&1; then
						_cursor_theme="$(gsettings get org.mate.peripherals-mouse cursor-theme 2> "/dev/null" | tr -d "'\"")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x cinnamon > "/dev/null" 2>&1; then
					if command -v gsettings > "/dev/null" 2>&1; then
						_cursor_theme="$(gsettings get org.cinnamon.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x xfce4-session > "/dev/null" 2>&1; then
					_cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x lxqt-session > "/dev/null" 2>&1; then
					_cursor_theme="breeze_cursors"
				elif [ -n "${_user_id}" ] && pgrep -u "${_user_id}" -x lxsession > "/dev/null" 2>&1; then
					_cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x budgie-wm > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x budgie-panel > "/dev/null" 2>&1; }; then
					if command -v gsettings > "/dev/null" 2>&1; then
						_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
						_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x gala > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x wingpanel > "/dev/null" 2>&1; }; then
					if command -v gsettings > "/dev/null" 2>&1; then
						_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
						_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
					fi
					[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x dde-desktop > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x deepin-wm > "/dev/null" 2>&1; }; then
					_cursor_theme="Adwaita"
				elif [ -n "${_user_id}" ] && { pgrep -u "${_user_id}" -x cosmic-comp > "/dev/null" 2>&1 || pgrep -u "${_user_id}" -x cosmic-session > "/dev/null" 2>&1; }; then
					_cursor_theme="Adwaita"
				elif [ -n "${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}" ]; then
					case "$(printf '%s\n' "${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}" | tr '[:upper:]' '[:lower:]')" in
						*kde*|*plasma*)
							if [ -f "${HOME}/.config/kcminputrc" ]; then
								_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
								_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
							fi
							[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
							;;
						*gnome*)
							if command -v gsettings > "/dev/null" 2>&1; then
								_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
								_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
							fi
							[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
							;;
						*mate*)         _cursor_theme="Adwaita" ;;
						*cinnamon*)     _cursor_theme="Adwaita" ;;
						*xfce*)         _cursor_theme="Adwaita" ;;
						*lxqt*)         _cursor_theme="breeze_cursors" ;;
						*lxde*)         _cursor_theme="Adwaita" ;;
						*budgie*)       _cursor_theme="Adwaita" ;;
						*pantheon*)     _cursor_theme="Adwaita" ;;
						*deepin*|*dde*) _cursor_theme="Adwaita" ;;
						*cosmic*)       _cursor_theme="Adwaita" ;;
					esac
				fi

				if [ -z "${_cursor_theme}" ]; then
					if command -v plasmashell > "/dev/null" 2>&1 || command -v startplasma-wayland > "/dev/null" 2>&1 || command -v startplasma-x11 > "/dev/null" 2>&1 || [ -d "/usr/share/plasma" ] || [ -d "/usr/local/share/plasma" ]; then
						if [ -f "${HOME}/.config/kcminputrc" ]; then
							_cursor_theme="$(awk -F= '/^[[:space:]]*cursorTheme[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
							_cursor_size="$(awk -F= '/^[[:space:]]*cursorSize[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/kcminputrc" 2> "/dev/null")"
						fi
						[ -z "${_cursor_theme}" ] && _cursor_theme="breeze_cursors"
					elif command -v gnome-shell > "/dev/null" 2>&1 || command -v gnome-session > "/dev/null" 2>&1 || [ -d "/usr/share/gnome-shell" ] || [ -d "/usr/local/share/gnome-shell" ]; then
						if command -v gsettings > "/dev/null" 2>&1; then
							_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'\"")"
							_cursor_size="$(gsettings get org.gnome.desktop.interface cursor-size 2> "/dev/null" | tr -d "'\"")"
						fi
						[ -z "${_cursor_theme}" ] && _cursor_theme="Adwaita"
					elif command -v mate-session > "/dev/null" 2>&1 || [ -d "/usr/share/mate" ] || [ -d "/usr/local/share/mate" ]; then
						_cursor_theme="Adwaita"
					elif command -v cinnamon > "/dev/null" 2>&1 || command -v cinnamon-session > "/dev/null" 2>&1 || [ -d "/usr/share/cinnamon" ] || [ -d "/usr/local/share/cinnamon" ]; then
						_cursor_theme="Adwaita"
					elif command -v xfce4-session > "/dev/null" 2>&1 || [ -d "/usr/share/xfce4" ] || [ -d "/usr/local/share/xfce4" ]; then
						_cursor_theme="Adwaita"
					elif command -v lxqt-session > "/dev/null" 2>&1 || [ -d "/usr/share/lxqt" ] || [ -d "/usr/local/share/lxqt" ]; then
						_cursor_theme="breeze_cursors"
					elif command -v lxsession > "/dev/null" 2>&1 || command -v startlxde > "/dev/null" 2>&1 || [ -d "/usr/share/lxde" ] || [ -d "/usr/local/share/lxde" ]; then
						_cursor_theme="Adwaita"
					elif command -v budgie-desktop > "/dev/null" 2>&1 || command -v budgie-wm > "/dev/null" 2>&1 || [ -d "/usr/share/budgie-desktop" ] || [ -d "/usr/local/share/budgie-desktop" ]; then
						_cursor_theme="Adwaita"
					elif command -v gala > "/dev/null" 2>&1 || command -v wingpanel > "/dev/null" 2>&1 || [ -d "/usr/share/pantheon" ] || [ -d "/usr/local/share/pantheon" ]; then
						_cursor_theme="Adwaita"
					elif command -v dde-desktop > "/dev/null" 2>&1 || command -v dde-session > "/dev/null" 2>&1 || [ -d "/usr/share/dde" ] || [ -d "/usr/local/share/dde" ]; then
						_cursor_theme="Adwaita"
					elif command -v cosmic-session > "/dev/null" 2>&1 || command -v cosmic-comp > "/dev/null" 2>&1 || [ -d "/usr/share/cosmic" ] || [ -d "/usr/local/share/cosmic" ]; then
						_cursor_theme="Adwaita"
					fi
				fi

				if [ -z "${_cursor_theme}" ]; then
					for _cursor_candidate in Adwaita breeze_cursors Bibata-Modern-Classic DMZ-White default; do
						for _icon_dir in "${HOME}/.local/share/icons" "${HOME}/.icons" "/usr/local/share/icons" "/usr/share/icons"; do
							if [ -d "${_icon_dir}/${_cursor_candidate}/cursors" ]; then
								_cursor_theme="${_cursor_candidate}"
								break 2
							fi
						done
					done
				fi

				[ -z "${_cursor_theme}" ] && _cursor_theme="default"
				[ -z "${_cursor_size}" ] && _cursor_size="24"
				if command -v _cache_write > "/dev/null" 2>&1; then
					_cache_write "cursor_theme" "${_cursor_theme}"
					_cache_write "cursor_size" "${_cursor_size}"
				fi
				[ -z "${XCURSOR_THEME:-}" ] && export XCURSOR_THEME="${_cursor_theme}"
				[ -z "${XCURSOR_SIZE:-}" ] && export XCURSOR_SIZE="${_cursor_size}"
			fi
		fi
	fi
}
