# ----------------------------------------------------------------
# Library: Desktop Environment, Theme & CLI Binary Detection
# ----------------------------------------------------------------

### --------------------------------
### DETECT DESKTOP ENVIRONMENT
### --------------------------------
_detect_desktop_environment() {
	[ -n "${_DETECTED_DESKTOP_ENV+x}" ] && echo "${_DETECTED_DESKTOP_ENV}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/desktop_env" ]; then
		_DETECTED_DESKTOP_ENV="$(_cache_read "desktop_env")"
		echo "${_DETECTED_DESKTOP_ENV}"
		return 0
	fi

	local _desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
	case "$(printf '%s\n' "${_desktop}" | tr '[:upper:]' '[:lower:]')" in
		*kde*|*plasma*)                                   _DETECTED_DESKTOP_ENV="kde" ;;
		*gnome*)                                          _DETECTED_DESKTOP_ENV="gnome" ;;
		*mate*)                                           _DETECTED_DESKTOP_ENV="mate" ;;
		*cinnamon*)                                       _DETECTED_DESKTOP_ENV="cinnamon" ;;
		*xfce*)                                           _DETECTED_DESKTOP_ENV="xfce" ;;
		*lxqt*)                                           _DETECTED_DESKTOP_ENV="lxqt" ;;
		*lxde*)                                           _DETECTED_DESKTOP_ENV="lxde" ;;
		*budgie*)                                         _DETECTED_DESKTOP_ENV="budgie" ;;
		*pantheon*)                                       _DETECTED_DESKTOP_ENV="pantheon" ;;
		*deepin*|*dde*)                                   _DETECTED_DESKTOP_ENV="deepin" ;;
		*cosmic*)                                         _DETECTED_DESKTOP_ENV="cosmic" ;;
		*sway*)                                           _DETECTED_DESKTOP_ENV="sway" ;;
		*hyprland*)                                       _DETECTED_DESKTOP_ENV="hyprland" ;;
		*river*)                                          _DETECTED_DESKTOP_ENV="river" ;;
		*labwc*)                                          _DETECTED_DESKTOP_ENV="labwc" ;;
		*cage*)                                           _DETECTED_DESKTOP_ENV="cage" ;;
		*niri*)                                           _DETECTED_DESKTOP_ENV="niri" ;;
		*wayfire*)                                        _DETECTED_DESKTOP_ENV="wayfire" ;;
		*dwl*)                                            _DETECTED_DESKTOP_ENV="dwl" ;;
		*hikari*)                                         _DETECTED_DESKTOP_ENV="hikari" ;;
		*weston*)                                         _DETECTED_DESKTOP_ENV="weston" ;;
		*openbox*)                                        _DETECTED_DESKTOP_ENV="openbox" ;;
		*cwm*)                                            _DETECTED_DESKTOP_ENV="cwm" ;;
		*fluxbox*)                                        _DETECTED_DESKTOP_ENV="fluxbox" ;;
		*icewm*)                                          _DETECTED_DESKTOP_ENV="icewm" ;;
		*jwm*)                                            _DETECTED_DESKTOP_ENV="jwm" ;;
		*pekwm*)                                          _DETECTED_DESKTOP_ENV="pekwm" ;;
		*twm*)                                            _DETECTED_DESKTOP_ENV="twm" ;;
		*matchbox*)                                       _DETECTED_DESKTOP_ENV="matchbox" ;;
		*i3*|*bspwm*|*dwm*|*fvwm*|*xmonad*|*qtile*|*wm*)   _DETECTED_DESKTOP_ENV="wm" ;;
		*)                                                _DETECTED_DESKTOP_ENV="" ;;
	esac

	if [ -z "${_DETECTED_DESKTOP_ENV}" ] && command -v pgrep > "/dev/null" 2>&1; then
		if pgrep -x plasmashell > "/dev/null" 2>&1 || pgrep -x kwin_wayland > "/dev/null" 2>&1 || pgrep -x kwin_x11 > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="kde"
		elif pgrep -x gnome-shell > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="gnome"
		elif pgrep -x mate-session > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="mate"
		elif pgrep -x cinnamon > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="cinnamon"
		elif pgrep -x xfce4-session > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="xfce"
		elif pgrep -x lxqt-session > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="lxqt"
		elif pgrep -x lxsession > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="lxde"
		elif pgrep -x budgie-wm > "/dev/null" 2>&1 || pgrep -x budgie-panel > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="budgie"
		elif pgrep -x gala > "/dev/null" 2>&1 || pgrep -x wingpanel > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="pantheon"
		elif pgrep -x dde-desktop > "/dev/null" 2>&1 || pgrep -x deepin-wm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="deepin"
		elif pgrep -x cosmic-comp > "/dev/null" 2>&1 || pgrep -x cosmic-session > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="cosmic"
		elif pgrep -x sway > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="sway"
		elif pgrep -x Hyprland > "/dev/null" 2>&1 || pgrep -x hyprland > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="hyprland"
		elif pgrep -x river > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="river"
		elif pgrep -x labwc > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="labwc"
		elif pgrep -x cage > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="cage"
		elif pgrep -x niri > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="niri"
		elif pgrep -x wayfire > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="wayfire"
		elif pgrep -x dwl > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="dwl"
		elif pgrep -x hikari > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="hikari"
		elif pgrep -x weston > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="weston"
		elif pgrep -x openbox > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="openbox"
		elif pgrep -x cwm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="cwm"
		elif pgrep -x dwm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="dwm"
		elif pgrep -x fvwm3 > "/dev/null" 2>&1 || pgrep -x fvwm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="fvwm"
		elif pgrep -x fluxbox > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="fluxbox"
		elif pgrep -x icewm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="icewm"
		elif pgrep -x jwm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="jwm"
		elif pgrep -x pekwm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="pekwm"
		elif pgrep -x twm > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="twm"
		elif pgrep -x matchbox-window-manager > "/dev/null" 2>&1; then
			_DETECTED_DESKTOP_ENV="matchbox"
		fi
	fi

	[ -z "${_DETECTED_DESKTOP_ENV}" ] && _DETECTED_DESKTOP_ENV="unknown"
	_cache_write "desktop_env" "${_DETECTED_DESKTOP_ENV}"
	echo "${_DETECTED_DESKTOP_ENV}"
}

### --------------------------------
### DETECT COLOR SCHEME
### --------------------------------
_detect_color_scheme() {
	local _flavor="${1:-$(_detect_desktop_theme 2> "/dev/null" || echo "")}"
	local _scheme=""
	local _cfg_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"
	local _c=""

	if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v gdbus > "/dev/null" 2>&1; then
		local _portal_scheme
		_portal_scheme="$(gdbus call --session --dest org.freedesktop.portal.Desktop \
			--object-path /org/freedesktop/portal/desktop \
			--method org.freedesktop.portal.Settings.Read \
			"org.freedesktop.appearance" "color-scheme" 2> "/dev/null" || true)"
		case "${_portal_scheme}" in
			*uint32\ 1*) _scheme="dark" ;;
			*uint32\ 2*) _scheme="light" ;;
		esac
	fi

	if [ -z "${_scheme}" ] && { [ "${_flavor}" = "kde" ] || [ "${_flavor}" = "lxqt" ] || [ -z "${_flavor}" ]; }; then
		local _kde_scheme="" _kde_laf=""
		if command -v kreadconfig6 > "/dev/null" 2>&1; then
			_kde_scheme="$(kreadconfig6 --group General --key ColorScheme 2> "/dev/null" || true)"
			_kde_laf="$(kreadconfig6 --group KDE --key LookAndFeelPackage 2> "/dev/null" || true)"
		elif command -v kreadconfig5 > "/dev/null" 2>&1; then
			_kde_scheme="$(kreadconfig5 --group General --key ColorScheme 2> "/dev/null" || true)"
			_kde_laf="$(kreadconfig5 --group KDE --key LookAndFeelPackage 2> "/dev/null" || true)"
		fi
		if [ -z "${_kde_scheme}" ] && [ -f "${_cfg_dir}/kdeglobals" ]; then
			_kde_scheme="$(sed -n 's/^[Cc]olor[Ss]cheme=//p' "${_cfg_dir}/kdeglobals" 2> "/dev/null" | head -n 1)"
			_kde_laf="$(sed -n 's/^[Ll]ook[Aa]nd[Ff]eel[Pp]ackage=//p' "${_cfg_dir}/kdeglobals" 2> "/dev/null" | head -n 1)"
		fi
		case "${_kde_scheme}" in
			*[Dd]ark*)  _scheme="dark" ;;
			*[Ll]ight*|Breeze|breeze|BreezeClassic) _scheme="light" ;;
		esac
		if [ -z "${_scheme}" ] && [ -n "${_kde_laf}" ]; then
			case "${_kde_laf}" in
				*breezedark*|*[Dd]ark*) _scheme="dark" ;;
				org.kde.breeze.desktop|*[Ll]ight*) _scheme="light" ;;
			esac
		fi
	fi

	if [ -z "${_scheme}" ] && [ "${_flavor}" = "cosmic" ] && [ -f "${_cfg_dir}/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark" ]; then
		case "$(cat "${_cfg_dir}/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark" 2> "/dev/null" || true)" in
			true)  _scheme="dark" ;;
			false) _scheme="light" ;;
		esac
	fi

	if [ -z "${_scheme}" ] && [ "${_flavor}" = "xfce" ] && command -v xfconf-query > "/dev/null" 2>&1; then
		local _xfce_theme
		_xfce_theme="$(xfconf-query -c xsettings -p /Net/ThemeName 2> "/dev/null" || true)"
		case "${_xfce_theme}" in
			*[Dd]ark*) _scheme="dark" ;;
			?*)        _scheme="light" ;;
		esac
	fi

	if [ -z "${_scheme}" ] && command -v gsettings > "/dev/null" 2>&1; then
		local _gnome_scheme="" _gnome_gtk=""
		_gnome_scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2> "/dev/null" || true)"
		case "${_gnome_scheme}" in
			*prefer-dark*)            _scheme="dark" ;;
			*prefer-light*|*default*) _scheme="light" ;;
		esac
		if [ -z "${_scheme}" ] && [ "${_flavor}" = "cinnamon" ]; then
			_gnome_gtk="$(gsettings get org.cinnamon.desktop.interface gtk-theme 2> "/dev/null" | tr -d "'" || true)"
			case "${_gnome_gtk}" in
				*[Dd]ark*) _scheme="dark" ;;
				?*)        _scheme="light" ;;
			esac
		elif [ -z "${_scheme}" ] && [ "${_flavor}" = "mate" ]; then
			_gnome_gtk="$(gsettings get org.mate.interface gtk-theme 2> "/dev/null" | tr -d "'" || true)"
			case "${_gnome_gtk}" in
				*[Dd]ark*) _scheme="dark" ;;
				?*)        _scheme="light" ;;
			esac
		fi
	fi

	if [ -z "${_scheme}" ]; then
		if [ -f "${_cfg_dir}/kdeglobals" ]; then
			if grep -qiE "^ColorScheme=.*Dark|^LookAndFeelPackage=.*[Dd]ark" "${_cfg_dir}/kdeglobals" 2> "/dev/null"; then
				_scheme="dark"
			elif grep -qiE "^ColorScheme=.*(Light|Breeze$)|^LookAndFeelPackage=org\.kde\.breeze\.desktop" "${_cfg_dir}/kdeglobals" 2> "/dev/null"; then
				_scheme="light"
			fi
		fi
	fi

	[ -z "${_scheme}" ] && _scheme="dark"
	_DETECTED_COLOR_SCHEME="${_scheme}"
	echo "${_scheme}"
}

### --------------------------------
### DETECT DESKTOP THEME FLAVOR
### --------------------------------
_detect_desktop_theme() {
	if [ -n "${1:-}" ]; then
		case "$1" in
			kde|gnome|mate|cinnamon|xfce|lxqt|lxde|budgie|pantheon|deepin|cosmic|adwaita) echo "$1"; return 0 ;;
		esac
	fi

	local _desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
	if [ -n "${_desktop}" ]; then
		case "$(printf '%s\n' "${_desktop}" | tr '[:upper:]' '[:lower:]')" in
			*kde*|*plasma*)         echo "kde"; return 0 ;;
			*gnome*)                echo "gnome"; return 0 ;;
			*mate*)                 echo "mate"; return 0 ;;
			*cinnamon*)             echo "cinnamon"; return 0 ;;
			*xfce*)                 echo "xfce"; return 0 ;;
			*lxqt*)                 echo "lxqt"; return 0 ;;
			*lxde*)                 echo "lxde"; return 0 ;;
			*budgie*)               echo "budgie"; return 0 ;;
			*pantheon*)             echo "pantheon"; return 0 ;;
			*deepin*|*dde*)         echo "deepin"; return 0 ;;
			*cosmic*)               echo "cosmic"; return 0 ;;
		esac
	fi

	if command -v pgrep > "/dev/null" 2>&1; then
		if pgrep -x plasmashell > "/dev/null" 2>&1 || pgrep -x kwin_wayland > "/dev/null" 2>&1 || pgrep -x kwin_x11 > "/dev/null" 2>&1; then
			echo "kde"; return 0
		elif pgrep -x gnome-shell > "/dev/null" 2>&1; then
			echo "gnome"; return 0
		elif pgrep -x mate-session > "/dev/null" 2>&1; then
			echo "mate"; return 0
		elif pgrep -x cinnamon > "/dev/null" 2>&1; then
			echo "cinnamon"; return 0
		elif pgrep -x xfce4-session > "/dev/null" 2>&1; then
			echo "xfce"; return 0
		elif pgrep -x lxqt-session > "/dev/null" 2>&1; then
			echo "lxqt"; return 0
		elif pgrep -x lxsession > "/dev/null" 2>&1; then
			echo "lxde"; return 0
		elif pgrep -x budgie-wm > "/dev/null" 2>&1 || pgrep -x budgie-panel > "/dev/null" 2>&1; then
			echo "budgie"; return 0
		elif pgrep -x gala > "/dev/null" 2>&1 || pgrep -x wingpanel > "/dev/null" 2>&1; then
			echo "pantheon"; return 0
		elif pgrep -x dde-desktop > "/dev/null" 2>&1 || pgrep -x deepin-wm > "/dev/null" 2>&1; then
			echo "deepin"; return 0
		elif pgrep -x cosmic-comp > "/dev/null" 2>&1 || pgrep -x cosmic-session > "/dev/null" 2>&1; then
			echo "cosmic"; return 0
		fi
	fi

	if command -v plasmashell > "/dev/null" 2>&1 || command -v startplasma-wayland > "/dev/null" 2>&1 || command -v startplasma-x11 > "/dev/null" 2>&1 || [ -d "/usr/share/plasma" ] || [ -d "/usr/local/share/plasma" ]; then
		echo "kde"
	elif command -v gnome-shell > "/dev/null" 2>&1 || command -v gnome-session > "/dev/null" 2>&1 || [ -d "/usr/share/gnome-shell" ] || [ -d "/usr/local/share/gnome-shell" ]; then
		echo "gnome"
	elif command -v mate-session > "/dev/null" 2>&1 || [ -d "/usr/share/mate" ] || [ -d "/usr/local/share/mate" ]; then
		echo "mate"
	elif command -v cinnamon > "/dev/null" 2>&1 || command -v cinnamon-session > "/dev/null" 2>&1 || [ -d "/usr/share/cinnamon" ] || [ -d "/usr/local/share/cinnamon" ]; then
		echo "cinnamon"
	elif command -v xfce4-session > "/dev/null" 2>&1 || [ -d "/usr/share/xfce4" ] || [ -d "/usr/local/share/xfce4" ]; then
		echo "xfce"
	elif command -v lxqt-session > "/dev/null" 2>&1 || [ -d "/usr/share/lxqt" ] || [ -d "/usr/local/share/lxqt" ]; then
		echo "lxqt"
	elif command -v lxsession > "/dev/null" 2>&1 || command -v startlxde > "/dev/null" 2>&1 || [ -d "/usr/share/lxde" ] || [ -d "/usr/local/share/lxde" ]; then
		echo "lxde"
	elif command -v budgie-desktop > "/dev/null" 2>&1 || command -v budgie-wm > "/dev/null" 2>&1 || [ -d "/usr/share/budgie-desktop" ] || [ -d "/usr/local/share/budgie-desktop" ]; then
		echo "budgie"
	elif command -v gala > "/dev/null" 2>&1 || command -v wingpanel > "/dev/null" 2>&1 || [ -d "/usr/share/pantheon" ] || [ -d "/usr/local/share/pantheon" ]; then
		echo "pantheon"
	elif command -v dde-desktop > "/dev/null" 2>&1 || command -v dde-session > "/dev/null" 2>&1 || [ -d "/usr/share/dde" ] || [ -d "/usr/local/share/dde" ]; then
		echo "deepin"
	elif command -v cosmic-session > "/dev/null" 2>&1 || command -v cosmic-comp > "/dev/null" 2>&1 || [ -d "/usr/share/cosmic" ] || [ -d "/usr/local/share/cosmic" ]; then
		echo "cosmic"
	else
		echo "adwaita"
	fi
}

### --------------------------------
### RESOLVE & DETECT GTK THEME
### --------------------------------
_theme_dir_exists() {
	local _tname="$1"
	[ -n "${_tname}" ] || return 1
	[ -d "/usr/share/themes/${_tname}" ] || \
		[ -d "/usr/local/share/themes/${_tname}" ] || \
		[ -d "${HOME}/.themes/${_tname}" ] || \
		[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/themes/${_tname}" ]
}

_icon_dir_exists() {
	local _iname="$1"
	[ -n "${_iname}" ] || return 1
	[ -d "/usr/share/icons/${_iname}" ] || \
		[ -d "/usr/local/share/icons/${_iname}" ] || \
		[ -d "${HOME}/.icons/${_iname}" ] || \
		[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/icons/${_iname}" ]
}

_resolve_gtk_theme() {
	local _raw_flavor="${1:-$(_detect_desktop_theme)}"
	local _flavor="$(_detect_desktop_theme "${_raw_flavor}")"
	local _scheme="${2:-$(_detect_color_scheme "${_flavor}")}"

	if [ "${_flavor}" = "gnome" ] || [ "${_flavor}" = "budgie" ] || [ "${_flavor}" = "pantheon" ] || [ "${_flavor}" = "adwaita" ]; then
		if command -v gsettings > "/dev/null" 2>&1; then
			local _gset_theme=""
			_gset_theme="$(command gsettings get org.gnome.desktop.interface gtk-theme 2> "/dev/null" | tr -d "'" || true)"
			if [ -n "${_gset_theme}" ]; then
				case "${_gset_theme}" in
					adw-gtk3|adw-gtk3-dark|Adwaita|Adwaita-dark|Adwaita:dark)
						if [ "${_scheme}" = "light" ]; then
							if _theme_dir_exists "adw-gtk3"; then
								echo "adw-gtk3"
								return 0
							elif _theme_dir_exists "Adwaita"; then
								echo "Adwaita"
								return 0
							fi
						else
							if _theme_dir_exists "adw-gtk3-dark"; then
								echo "adw-gtk3-dark"
								return 0
							elif _theme_dir_exists "Adwaita-dark"; then
								echo "Adwaita-dark"
								return 0
							fi
						fi
						;;
					*)
						if [ "${_scheme}" = "light" ]; then
							case "${_gset_theme}" in
								*-dark|*-Dark)
									local _light_gset="${_gset_theme%-dark}"
									_light_gset="${_light_gset%-Dark}"
									if _theme_dir_exists "${_light_gset}"; then
										echo "${_light_gset}"
										return 0
									fi
									;;
								*)
									if _theme_dir_exists "${_gset_theme}"; then
										echo "${_gset_theme}"
										return 0
									fi
									;;
							esac
						else
							case "${_gset_theme}" in
								*-dark|*-Dark)
									if _theme_dir_exists "${_gset_theme}"; then
										echo "${_gset_theme}"
										return 0
									fi
									;;
								*)
									if _theme_dir_exists "${_gset_theme}-dark"; then
										echo "${_gset_theme}-dark"
										return 0
									elif _theme_dir_exists "${_gset_theme}-Dark"; then
										echo "${_gset_theme}-Dark"
										return 0
									elif _theme_dir_exists "${_gset_theme}"; then
										echo "${_gset_theme}"
										return 0
									fi
									;;
							esac
						fi
						;;
				esac
			fi
		fi
	fi

	case "${_flavor}" in
		kde)
			if [ "${_scheme}" = "light" ]; then
				echo "Breeze"
			else
				echo "Breeze-Dark"
			fi
			return 0
			;;
	esac

	local _candidates=""
	if [ "${_scheme}" = "light" ]; then
		case "${_flavor}" in
			xfce)     _candidates="Greybird adw-gtk3 Adwaita" ;;
			cinnamon) _candidates="Mint-Y adw-gtk3 Adwaita" ;;
			mate)     _candidates="Yaru-MATE TraditionalOk adw-gtk3 Adwaita" ;;
			lxqt)     _candidates="Breeze adw-gtk3 Adwaita Arc" ;;
			lxde)     _candidates="Clearlooks-Phenix Arc adw-gtk3 Adwaita Numix" ;;
			budgie)   _candidates="Materia Arc Yaru adw-gtk3 Adwaita" ;;
			pantheon) _candidates="io.elementary.stylesheet.blueberry adw-gtk3 Adwaita" ;;
			deepin)   _candidates="deepin adw-gtk3 Adwaita" ;;
			cosmic)   _candidates="cosmic adw-gtk3 Adwaita" ;;
			*)        _candidates="adw-gtk3 Adwaita Yaru Breeze Greybird" ;;
		esac
	else
		case "${_flavor}" in
			xfce)     _candidates="Greybird-dark adw-gtk3-dark Adwaita-dark Greybird" ;;
			cinnamon) _candidates="Mint-Y-Dark adw-gtk3-dark Adwaita-dark" ;;
			mate)     _candidates="Yaru-MATE-dark BlackMATE adw-gtk3-dark Adwaita-dark" ;;
			lxqt)     _candidates="Breeze-Dark adw-gtk3-dark Adwaita-dark Arc-Dark" ;;
			lxde)     _candidates="Clearlooks-Phenix Arc-Dark adw-gtk3-dark Adwaita-dark Numix" ;;
			budgie)   _candidates="Materia-dark Arc-Dark Yaru-dark adw-gtk3-dark Adwaita-dark" ;;
			pantheon) _candidates="io.elementary.stylesheet.blueberry-dark io.elementary.stylesheet.blueberry adw-gtk3-dark Adwaita-dark" ;;
			deepin)   _candidates="deepin-dark deepin adw-gtk3-dark Adwaita-dark" ;;
			cosmic)   _candidates="cosmic-dark cosmic adw-gtk3-dark Adwaita-dark" ;;
			*)        _candidates="adw-gtk3-dark Yaru-dark Adwaita-dark Breeze-Dark Greybird-dark" ;;
		esac
	fi

	local _cand
	for _cand in ${_candidates}; do
		if _theme_dir_exists "${_cand}"; then
			echo "${_cand}"
			return 0
		fi
	done

	if [ "${_scheme}" = "light" ]; then
		if _theme_dir_exists "adw-gtk3"; then
			echo "adw-gtk3"
		else
			echo "Adwaita"
		fi
	else
		if _theme_dir_exists "adw-gtk3-dark"; then
			echo "adw-gtk3-dark"
		elif _theme_dir_exists "Adwaita-dark"; then
			echo "Adwaita-dark"
		else
			echo "Adwaita"
		fi
	fi
}

_resolve_icon_theme() {
	local _raw_flavor="${1:-$(_detect_desktop_theme)}"
	local _flavor="$(_detect_desktop_theme "${_raw_flavor}")"
	local _scheme="${2:-$(_detect_color_scheme "${_flavor}")}"

	if [ "${_flavor}" = "gnome" ] || [ "${_flavor}" = "budgie" ] || [ "${_flavor}" = "pantheon" ] || [ "${_flavor}" = "adwaita" ]; then
		if command -v gsettings > "/dev/null" 2>&1; then
			local _gset_icon=""
			_gset_icon="$(command gsettings get org.gnome.desktop.interface icon-theme 2> "/dev/null" | tr -d "'" || true)"
			if [ -n "${_gset_icon}" ] && _icon_dir_exists "${_gset_icon}"; then
				echo "${_gset_icon}"
				return 0
			fi
		fi
	fi

	local _candidates=""
	case "${_flavor}" in
		kde|lxqt)
			if [ "${_scheme}" = "light" ]; then
				_candidates="breeze breeze-dark Adwaita"
			else
				_candidates="breeze-dark breeze Adwaita"
			fi
			;;
		xfce)
			if [ "${_scheme}" = "light" ]; then
				_candidates="elementary-xfce Tango Adwaita"
			else
				_candidates="elementary-xfce-dark elementary-xfce Adwaita"
			fi
			;;
		cinnamon)
			if [ "${_scheme}" = "light" ]; then
				_candidates="Mint-Y Adwaita"
			else
				_candidates="Mint-Y-Dark Mint-Y Adwaita"
			fi
			;;
		mate)
			if [ "${_scheme}" = "light" ]; then
				_candidates="Yaru-MATE MATE Adwaita"
			else
				_candidates="Yaru-MATE-dark MATE Adwaita"
			fi
			;;
		*)
			if [ "${_scheme}" = "light" ]; then
				_candidates="Adwaita Papirus Yaru breeze hicolor"
			else
				_candidates="Adwaita Papirus-Dark Yaru breeze-dark hicolor"
			fi
			;;
	esac

	local _cand
	for _cand in ${_candidates}; do
		if _icon_dir_exists "${_cand}"; then
			echo "${_cand}"
			return 0
		fi
	done

	case "${_flavor}" in
		kde|lxqt)
			if [ "${_scheme}" = "light" ]; then
				echo "breeze"
			else
				echo "breeze-dark"
			fi
			;;
		*) echo "Adwaita" ;;
	esac
}

_resolve_cursor_theme() {
	local _raw_flavor="${1:-$(_detect_desktop_theme)}"
	local _flavor="$(_detect_desktop_theme "${_raw_flavor}")"
	local _cfg_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"
	local _c=""

	if [ "${_flavor}" = "kde" ] || [ "${_flavor}" = "lxqt" ]; then
		local _kde_cur=""
		if command -v kreadconfig6 > "/dev/null" 2>&1; then
			_kde_cur="$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2> "/dev/null" || true)"
		elif command -v kreadconfig5 > "/dev/null" 2>&1; then
			_kde_cur="$(kreadconfig5 --file kcminputrc --group Mouse --key cursorTheme 2> "/dev/null" || true)"
		fi
		if [ -z "${_kde_cur}" ] && [ -f "${_cfg_dir}/kcminputrc" ]; then
			_kde_cur="$(sed -n 's/^cursorTheme=//p' "${_cfg_dir}/kcminputrc" 2> "/dev/null" | head -n 1)"
		fi
		if [ -n "${_kde_cur}" ]; then
			echo "${_kde_cur}"
			return 0
		fi
	elif command -v gsettings > "/dev/null" 2>&1; then
		local _gset_cur=""
		_gset_cur="$(command gsettings get org.gnome.desktop.interface cursor-theme 2> "/dev/null" | tr -d "'" || true)"
		if [ -n "${_gset_cur}" ]; then
			echo "${_gset_cur}"
			return 0
		fi
	fi

	case "${_flavor}" in
		kde|lxqt)
			for _c in breeze_cursors Breeze_Snow Adwaita default; do
				_icon_dir_exists "${_c}" && echo "${_c}" && return 0
			done
			echo "breeze_cursors"
			;;
		*)
			for _c in Adwaita default DMZ-Black breeze_cursors; do
				_icon_dir_exists "${_c}" && echo "${_c}" && return 0
			done
			echo "Adwaita"
			;;
	esac
}

_detect_gtk_theme() {
	local _flavor="$(_detect_desktop_theme)"
	local _scheme="$(_detect_color_scheme "${_flavor}")"
	_DETECTED_GTK_THEME="$(_resolve_gtk_theme "${_flavor}" "${_scheme}")"
	echo "${_DETECTED_GTK_THEME}"
}

### --------------------------------
### DETECT QT THEME & PLATFORM
### --------------------------------
_detect_qt_theme() {
	local _flavor="$(_detect_desktop_theme)"
	local _color_scheme="$(_detect_color_scheme "${_flavor}")"

	case "${_flavor}" in
		kde|lxqt)
			if [ "${_color_scheme}" = "dark" ]; then
				_DETECTED_QT_THEME="Breeze-Dark"
			else
				_DETECTED_QT_THEME="Breeze"
			fi
			;;
		deepin)
			_DETECTED_QT_THEME="chameleon"
			;;
		*)
			_DETECTED_QT_THEME=""
			;;
	esac
	echo "${_DETECTED_QT_THEME}"
}

_detect_qt_platform_theme() {
	local _desktop_env="$(_detect_desktop_environment)"
	case "${_desktop_env}" in
		unknown|wm|sway|hyprland|river|labwc|cage|niri|wayfire|dwl|hikari|weston|openbox|cwm|dwm|fvwm|fluxbox|icewm|jwm|pekwm|twm|matchbox)
			_desktop_env="$(_detect_desktop_theme)"
			;;
	esac

	case "${_desktop_env}" in
		kde)
			_DETECTED_QT_PLATFORM_THEME="kde"
			;;
		lxqt)
			_DETECTED_QT_PLATFORM_THEME="lxqt"
			;;
		deepin)
			_DETECTED_QT_PLATFORM_THEME="deepin"
			;;
		xfce|mate|cinnamon|lxde)
			_DETECTED_QT_PLATFORM_THEME="gtk3"
			;;
		*)
			if command -v qt6ct > "/dev/null" 2>&1; then
				_DETECTED_QT_PLATFORM_THEME="qt6ct"
			elif command -v qt5ct > "/dev/null" 2>&1; then
				_DETECTED_QT_PLATFORM_THEME="qt5ct"
			elif [ "${_desktop_env}" = "gnome" ] || [ "${_desktop_env}" = "budgie" ] || [ "${_desktop_env}" = "pantheon" ] || [ "${_desktop_env}" = "cosmic" ]; then
				_DETECTED_QT_PLATFORM_THEME="xdgdesktopportal"
			else
				_DETECTED_QT_PLATFORM_THEME=""
			fi
			;;
	esac
	echo "${_DETECTED_QT_PLATFORM_THEME}"
}

### --------------------------------
### DETECT MODERN CLI BINARIES
### --------------------------------
_detect_eza() {
	[ -n "${_DETECTED_EZA+x}" ] && echo "${_DETECTED_EZA}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/eza" ]; then
		_DETECTED_EZA="$(_cache_read "eza")"
		echo "${_DETECTED_EZA}"
		return 0
	fi
	if command -v eza > "/dev/null" 2>&1; then _DETECTED_EZA="eza"
	elif command -v exa > "/dev/null" 2>&1; then _DETECTED_EZA="exa"
	elif [ -x "${HOME}/.cargo/bin/eza" ]; then _DETECTED_EZA="${HOME}/.cargo/bin/eza"
	elif [ -x "${HOME}/.cargo/bin/exa" ]; then _DETECTED_EZA="${HOME}/.cargo/bin/exa"
	else _DETECTED_EZA=""; fi
	_cache_write "eza" "${_DETECTED_EZA}"
	echo "${_DETECTED_EZA}"
}

_detect_bat() {
	[ -n "${_DETECTED_BAT+x}" ] && echo "${_DETECTED_BAT}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/bat" ]; then
		_DETECTED_BAT="$(_cache_read "bat")"
		echo "${_DETECTED_BAT}"
		return 0
	fi
	if command -v bat > "/dev/null" 2>&1; then _DETECTED_BAT="bat"
	elif command -v batcat > "/dev/null" 2>&1; then _DETECTED_BAT="batcat"
	elif [ -x "${HOME}/.cargo/bin/bat" ]; then _DETECTED_BAT="${HOME}/.cargo/bin/bat"
	else _DETECTED_BAT=""; fi
	_cache_write "bat" "${_DETECTED_BAT}"
	echo "${_DETECTED_BAT}"
}

_detect_rg() {
	[ -n "${_DETECTED_RG+x}" ] && echo "${_DETECTED_RG}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/rg" ]; then
		_DETECTED_RG="$(_cache_read "rg")"
		echo "${_DETECTED_RG}"
		return 0
	fi
	if command -v rg > "/dev/null" 2>&1; then _DETECTED_RG="rg"
	elif command -v ripgrep > "/dev/null" 2>&1; then _DETECTED_RG="ripgrep"
	elif [ -x "${HOME}/.cargo/bin/rg" ]; then _DETECTED_RG="${HOME}/.cargo/bin/rg"
	else _DETECTED_RG=""; fi
	_cache_write "rg" "${_DETECTED_RG}"
	echo "${_DETECTED_RG}"
}

_detect_fd() {
	[ -n "${_DETECTED_FD+x}" ] && echo "${_DETECTED_FD}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/fd" ]; then
		_DETECTED_FD="$(_cache_read "fd")"
		echo "${_DETECTED_FD}"
		return 0
	fi
	if command -v fd > "/dev/null" 2>&1; then _DETECTED_FD="fd"
	elif command -v fdfind > "/dev/null" 2>&1; then _DETECTED_FD="fdfind"
	elif command -v fd-find > "/dev/null" 2>&1; then _DETECTED_FD="fd-find"
	elif [ -x "${HOME}/.cargo/bin/fd" ]; then _DETECTED_FD="${HOME}/.cargo/bin/fd"
	else _DETECTED_FD=""; fi
	_cache_write "fd" "${_DETECTED_FD}"
	echo "${_DETECTED_FD}"
}

_detect_dust() {
	[ -n "${_DETECTED_DUST+x}" ] && echo "${_DETECTED_DUST}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/dust" ]; then
		_DETECTED_DUST="$(_cache_read "dust")"
		echo "${_DETECTED_DUST}"
		return 0
	fi
	if command -v dust > "/dev/null" 2>&1; then _DETECTED_DUST="dust"
	elif [ -x "${HOME}/.cargo/bin/dust" ]; then _DETECTED_DUST="${HOME}/.cargo/bin/dust"
	else _DETECTED_DUST=""; fi
	_cache_write "dust" "${_DETECTED_DUST}"
	echo "${_DETECTED_DUST}"
}

_detect_procs() {
	[ -n "${_DETECTED_PROCS+x}" ] && echo "${_DETECTED_PROCS}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/procs" ]; then
		_DETECTED_PROCS="$(_cache_read "procs")"
		echo "${_DETECTED_PROCS}"
		return 0
	fi
	if command -v procs > "/dev/null" 2>&1; then _DETECTED_PROCS="procs"
	elif [ -x "${HOME}/.cargo/bin/procs" ]; then _DETECTED_PROCS="${HOME}/.cargo/bin/procs"
	else _DETECTED_PROCS=""; fi
	_cache_write "procs" "${_DETECTED_PROCS}"
	echo "${_DETECTED_PROCS}"
}

_detect_bottom() {
	[ -n "${_DETECTED_BOTTOM+x}" ] && echo "${_DETECTED_BOTTOM}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/bottom" ]; then
		_DETECTED_BOTTOM="$(_cache_read "bottom")"
		echo "${_DETECTED_BOTTOM}"
		return 0
	fi
	if command -v btm > "/dev/null" 2>&1; then _DETECTED_BOTTOM="btm"
	elif command -v bottom > "/dev/null" 2>&1; then _DETECTED_BOTTOM="bottom"
	elif [ -x "${HOME}/.cargo/bin/btm" ]; then _DETECTED_BOTTOM="${HOME}/.cargo/bin/btm"
	else _DETECTED_BOTTOM=""; fi
	_cache_write "bottom" "${_DETECTED_BOTTOM}"
	echo "${_DETECTED_BOTTOM}"
}

_detect_zoxide() {
	[ -n "${_DETECTED_ZOXIDE+x}" ] && echo "${_DETECTED_ZOXIDE}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/zoxide" ]; then
		_DETECTED_ZOXIDE="$(_cache_read "zoxide")"
		echo "${_DETECTED_ZOXIDE}"
		return 0
	fi
	if command -v zoxide > "/dev/null" 2>&1; then _DETECTED_ZOXIDE="zoxide"
	elif [ -x "${HOME}/.cargo/bin/zoxide" ]; then _DETECTED_ZOXIDE="${HOME}/.cargo/bin/zoxide"
	elif [ -x "/usr/local/bin/zoxide" ]; then _DETECTED_ZOXIDE="/usr/local/bin/zoxide"
	else _DETECTED_ZOXIDE=""; fi
	_cache_write "zoxide" "${_DETECTED_ZOXIDE}"
	echo "${_DETECTED_ZOXIDE}"
}

### --------------------------------
### WINDOW MANAGER PIPELINES
### --------------------------------
_get_x11_wm_pipeline() {
	local _os="${1:-${_DETECTED_OS-$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}}"
	case "${_os}" in
		openbsd)
			printf '%s\n' "openbox cwm dwm fvwm3 fvwm fluxbox icewm jwm pekwm twm matchbox-window-manager"
			;;
		*)
			printf '%s\n' "openbox cwm dwm fvwm3 fvwm fluxbox icewm jwm pekwm twm matchbox-window-manager"
			;;
	esac
}

_get_wayland_wm_pipeline() {
	printf '%s\n' "sway labwc river hyprland niri wayfire dwl hikari weston cage"
}

_show_wm_pipeline() {
	local _target="${1:-all}"
	local _os="${_DETECTED_OS-$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}"

	if [ "${_target}" = "wayland" ] || [ "${_target}" = "all" ]; then
		_ui_banner "PIPELINE WAYLAND (${_os})"
		local _w_pipeline="$(_get_wayland_wm_pipeline)"
		local _primary_w="" _w_wm _w_bin
		for _w_wm in ${_w_pipeline}; do
			if command -v "${_w_wm}" > "/dev/null" 2>&1; then
				_primary_w="${_w_wm}"
				break
			fi
		done
		_ui_step "Ordem de compositores Wayland:"
		for _w_wm in ${_w_pipeline}; do
			if command -v "${_w_wm}" > "/dev/null" 2>&1; then
				_w_bin="$(command -v "${_w_wm}")"
				if [ "${_w_wm}" = "${_primary_w}" ]; then
					_ui_ok "${_w_wm} -> ${_w_bin} [SELECIONADO]"
				else
					_ui_ok "${_w_wm} -> ${_w_bin}"
				fi
			else
				_ui_warn "${_w_wm} (ausente)"
			fi
		done
		if [ -z "${_primary_w}" ]; then
			_ui_warn "Nenhum compositor Wayland disponível no sistema."
		fi
	fi

	if [ "${_target}" = "x11" ] || [ "${_target}" = "all" ]; then
		_ui_banner "PIPELINE X11 (${_os})"
		local _x_pipeline="$(_get_x11_wm_pipeline "${_os}")"
		local _primary_x="" _x_wm _x_bin
		for _x_wm in ${_x_pipeline}; do
			if command -v "${_x_wm}" > "/dev/null" 2>&1; then
				_primary_x="${_x_wm}"
				break
			fi
		done
		_ui_step "Ordem de gerenciadores X11:"
		for _x_wm in ${_x_pipeline}; do
			if command -v "${_x_wm}" > "/dev/null" 2>&1; then
				_x_bin="$(command -v "${_x_wm}")"
				if [ "${_x_wm}" = "${_primary_x}" ]; then
					_ui_ok "${_x_wm} -> ${_x_bin} [SELECIONADO]"
				else
					_ui_ok "${_x_wm} -> ${_x_bin}"
				fi
			else
				_ui_warn "${_x_wm} (ausente)"
			fi
		done
		if [ -z "${_primary_x}" ]; then
			_ui_warn "Nenhum gerenciador X11 disponível no sistema."
		fi
	fi
}
