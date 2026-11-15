# ----------------------------------------------------------------
# Environment: Common Desktop & Login Session Theme Propagation
# ----------------------------------------------------------------

### ================================
### DESKTOP ENVIRONMENT DETECTION
### ================================
_ses_raw_de="${_DETECTED_DESKTOP_ENV:-${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}}"
_ses_is_kde=0
if [ "${KDE_FULL_SESSION:-}" = "true" ]; then
	_ses_is_kde=1
else
	case "${_ses_raw_de}" in
		*[Kk][Dd][Ee]*|*[Pp][Ll][Aa][Ss][Mm][Aa]*) _ses_is_kde=1 ;;
	esac
fi
if [ "${_ses_is_kde}" -eq 0 ] && [ -z "${_ses_raw_de}" ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && command -v pgrep > "/dev/null" 2>&1; then
	if pgrep -x plasmashell > "/dev/null" 2>&1 || pgrep -x kwin_wayland > "/dev/null" 2>&1 || pgrep -x kwin_x11 > "/dev/null" 2>&1; then
		_ses_is_kde=1
	fi
fi

### ================================
### GRAPHICAL TOOLKIT THEME EXPORTS
### ================================
if [ "${_ses_is_kde}" -eq 1 ]; then
	export GTK_THEME="Breeze-Dark"
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	export QT_QPA_PLATFORMTHEME="kde"
	export QT_STYLE_OVERRIDE="Breeze-Dark"
else
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	if [ -z "${GTK_THEME:-}" ]; then
		_ses_gtk_ini="${XDG_CONFIG_HOME:-${HOME}/.config}/gtk-3.0/settings.ini"
		if [ -r "${_ses_gtk_ini}" ]; then
			_ses_ini=""
			while IFS='=' read -r _ses_key _ses_val || [ -n "${_ses_key}" ]; do
				while :; do
					case "${_ses_key}" in
						" "*|"	"*) _ses_key="${_ses_key#?}" ;;
						*" "|*"	") _ses_key="${_ses_key%?}" ;;
						*) break ;;
					esac
				done
				if [ "${_ses_key}" = "gtk-theme-name" ]; then
					_ses_cr="$(printf '\r')"
					while :; do
						case "${_ses_val}" in
							" "*|"	"*) _ses_val="${_ses_val#?}" ;;
							*" "|*"	"|*"${_ses_cr}") _ses_val="${_ses_val%?}" ;;
							*) break ;;
						esac
					done
					_ses_ini="${_ses_val}"
					unset _ses_cr
					break
				fi
			done < "${_ses_gtk_ini}"
			[ -n "${_ses_ini}" ] && export GTK_THEME="${_ses_ini}"
			unset _ses_ini _ses_key _ses_val
		fi
		unset _ses_gtk_ini
		[ -z "${GTK_THEME:-}" ] && export GTK_THEME="adw-gtk3-dark"
	fi
fi
export SAL_USE_VCLPLUGIN="gtk3"
unset _ses_raw_de _ses_is_kde

### ================================
### PYTHON PERFORMANCE CACHE
### ================================
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"
[ -d "${PYTHONPYCACHEPREFIX}" ] || { mkdir -p "${PYTHONPYCACHEPREFIX}" && chmod 0700 "${PYTHONPYCACHEPREFIX}"; } 2> "/dev/null" || true
