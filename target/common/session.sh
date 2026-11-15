# ----------------------------------------------------------------
# Environment: Common Desktop & Login Session Theme Propagation
# ----------------------------------------------------------------

### ================================
### DESKTOP ENVIRONMENT DETECTION
### ================================
_ses_raw_de="${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}}"
_ses_lower_de="$(printf '%s' "${_ses_raw_de}" | tr '[:upper:]' '[:lower:]')"
_ses_is_kde=0
_ses_is_full_de=0
if [ "${KDE_FULL_SESSION:-}" = "true" ]; then
	_ses_is_kde=1
	_ses_is_full_de=1
elif [ -n "${_ses_lower_de}" ]; then
	case "${_ses_lower_de}" in
		*kde*|*plasma*)
			_ses_is_kde=1
			_ses_is_full_de=1
			;;
		*gnome*|*ubuntu*|*unity*|*zorin*|*xfce*|*mate*|*cinnamon*|*cosmic*|*budgie*|*pantheon*|*lxqt*|*lxde*|*deepin*|*dde*)
			_ses_is_full_de=1
			;;
	esac
fi
if [ "${_ses_is_full_de}" -eq 0 ] && [ -z "${_ses_raw_de}" ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && command -v pgrep > "/dev/null" 2>&1; then
	_ses_uid=""
	case "$(uname -s 2> "/dev/null")" in
		MINGW*|MSYS*|CYGWIN*) _ses_uid="$(id -un 2> "/dev/null" || printf '%s' "${USER:-}")" ;;
		*) _ses_uid="$(id -u 2> "/dev/null" || id -un 2> "/dev/null" || printf '%s' "${USER:-}")" ;;
	esac
	if [ -n "${_ses_uid}" ]; then
		if pgrep -u "${_ses_uid}" -x plasmashell > "/dev/null" 2>&1 || pgrep -u "${_ses_uid}" -x kwin_wayland > "/dev/null" 2>&1 || pgrep -u "${_ses_uid}" -x kwin_x11 > "/dev/null" 2>&1; then
			_ses_is_kde=1
			_ses_is_full_de=1
		else
			for _ses_proc in gnome-shell xfce4-session mate-session cinnamon cosmic-comp cosmic-session budgie-wm budgie-panel gala wingpanel lxqt-session lxsession dde-desktop deepin-wm; do
				if pgrep -u "${_ses_uid}" -x "${_ses_proc}" > "/dev/null" 2>&1; then
					_ses_is_full_de=1
					break
				fi
			done
			unset _ses_proc
		fi
	fi
	unset _ses_uid
fi

### ================================
### GRAPHICAL TOOLKIT THEME EXPORTS
### ================================
if [ "${_ses_is_full_de}" -eq 1 ]; then
	if [ "${_ses_is_kde}" -eq 1 ] && [ -z "${QT_QPA_PLATFORMTHEME:-}" ]; then
		export QT_QPA_PLATFORMTHEME="kde"
	fi
else
	if [ -z "${GTK_THEME:-}" ]; then
		if [ -n "${_DETECTED_GTK_THEME:-}" ]; then
			export GTK_THEME="${_DETECTED_GTK_THEME}"
		else
			_ses_gtk_ini="${XDG_CONFIG_HOME:-${HOME}/.config}/gtk-3.0/settings.ini"
			if [ -r "${_ses_gtk_ini}" ]; then
				_ses_ini=""
				_ses_cr=$'\r'
				[ "${#_ses_cr}" -eq 1 ] || _ses_cr="$(printf '\r')"
				while IFS='=' read -r _ses_key _ses_val || [ -n "${_ses_key}" ]; do
					while :; do
						case "${_ses_key}" in
							" "*|"	"*) _ses_key="${_ses_key#?}" ;;
							*" "|*"	") _ses_key="${_ses_key%?}" ;;
							*) break ;;
						esac
					done
					if [ "${_ses_key}" = "gtk-theme-name" ]; then
						while :; do
							case "${_ses_val}" in
								" "*|"	"*) _ses_val="${_ses_val#?}" ;;
								*" "|*"	"|*"${_ses_cr}") _ses_val="${_ses_val%?}" ;;
								*) break ;;
							esac
						done
						_ses_ini="${_ses_val}"
						break
					fi
				done < "${_ses_gtk_ini}"
				[ -n "${_ses_ini}" ] && export GTK_THEME="${_ses_ini}"
				unset _ses_ini _ses_key _ses_val _ses_cr
			fi
			unset _ses_gtk_ini
			[ -z "${GTK_THEME:-}" ] && export GTK_THEME="adw-gtk3-dark"
		fi
	fi
fi
export SAL_USE_VCLPLUGIN="gtk3"
unset _ses_raw_de _ses_lower_de _ses_is_kde _ses_is_full_de

### ================================
### PYTHON PERFORMANCE CACHE
### ================================
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"
[ -d "${PYTHONPYCACHEPREFIX}" ] || { mkdir -p "${PYTHONPYCACHEPREFIX}" && chmod 0700 "${PYTHONPYCACHEPREFIX}"; } 2> "/dev/null" || true
