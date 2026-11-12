# ----------------------------------------------------------------
# Environment: Common Desktop & Login Session Theme Propagation
# ----------------------------------------------------------------

### ================================
### DESKTOP ENVIRONMENT DETECTION
### ================================
_ses_raw_de="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}"
_ses_is_kde=0
case "$(printf '%s\n' "${_ses_raw_de}" | tr '[:upper:]' '[:lower:]')" in
	*kde*|*plasma*) _ses_is_kde=1 ;;
esac
if [ "${_ses_is_kde}" -eq 0 ] && command -v pgrep > "/dev/null" 2>&1; then
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
		if [ -r "${HOME}/.config/gtk-3.0/settings.ini" ]; then
			_ses_ini="$(awk -F= '/^[[:space:]]*gtk-theme-name[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "${HOME}/.config/gtk-3.0/settings.ini" 2> "/dev/null" | head -n 1)"
			[ -n "${_ses_ini}" ] && export GTK_THEME="${_ses_ini}"
			unset _ses_ini
		fi
		[ -z "${GTK_THEME:-}" ] && export GTK_THEME="adw-gtk3-dark"
	fi
fi
export SAL_USE_VCLPLUGIN="gtk3"
unset _ses_raw_de _ses_is_kde
