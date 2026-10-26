# ----------------------------------------------------------------
# Library: Desktop Environment, Theme & CLI Binary Detection
# ----------------------------------------------------------------

### --------------------------------
### Detect Desktop Environment
### --------------------------------
_detect_desktop_environment() {
	[ -n "${_DETECTED_DESKTOP_ENV+x}" ] && echo "${_DETECTED_DESKTOP_ENV}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/desktop_env" ]; then
		_DETECTED_DESKTOP_ENV="$(_cache_read "desktop_env")"
		echo "${_DETECTED_DESKTOP_ENV}"
		return 0
	fi

	local _desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION}}"
	case "${_desktop}" in
		*[Kk][Dd][Ee]*|*[Pp]lasma*)                                            _DETECTED_DESKTOP_ENV="kde" ;;
		*[Gg][Nn][Oo][Mm][Ee]*)                                                _DETECTED_DESKTOP_ENV="gnome" ;;
		*[Xx][Ff][Cc][Ee]*)                                                    _DETECTED_DESKTOP_ENV="xfce" ;;
		*[Cc][Ii][Nn][Nn][Aa][Mm][Oo][Nn]*)                                    _DETECTED_DESKTOP_ENV="cinnamon" ;;
		*[Mm][Aa][Tt][Ee]*)                                                    _DETECTED_DESKTOP_ENV="mate" ;;
		*[Cc][Oo][Ss][Mm][Ii][Cc]*)                                            _DETECTED_DESKTOP_ENV="cosmic" ;;
		*[Ll][Xx][Qq][Tt]*)                                                    _DETECTED_DESKTOP_ENV="lxqt" ;;
		*[Ss][Ww][Aa][Yy]*)                                                    _DETECTED_DESKTOP_ENV="sway" ;;
		*[Hh][Yy][Pp][Rr][Ll][Aa][Nn][Dd]*)                                    _DETECTED_DESKTOP_ENV="hyprland" ;;
		*[Ii]3*|*[Bb][Ss][Pp][Ww][Mm]*|*[Rr][Ii][Vv][Ee][Rr]*|*[Dd][Ww][Mm]*) _DETECTED_DESKTOP_ENV="wm" ;;
		*)                                                                     _DETECTED_DESKTOP_ENV="unknown" ;;
	esac
	_cache_write "desktop_env" "${_DETECTED_DESKTOP_ENV}"
	echo "${_DETECTED_DESKTOP_ENV}"
}

### --------------------------------
### Detect Color Scheme
### --------------------------------
_detect_color_scheme() {
	[ -n "${_DETECTED_COLOR_SCHEME+x}" ] && echo "${_DETECTED_COLOR_SCHEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/color_scheme" ]; then
		_DETECTED_COLOR_SCHEME="$(_cache_read "color_scheme")"
		echo "${_DETECTED_COLOR_SCHEME}"
		return 0
	fi

	_DETECTED_COLOR_SCHEME="dark"
	if command -v gdbus > "/dev/null" 2>&1; then
		local _portal_scheme
		_portal_scheme="$(gdbus call --session --dest org.freedesktop.portal.Desktop \
			--object-path /org/freedesktop/portal/desktop \
			--method org.freedesktop.portal.Settings.Read \
			"org.freedesktop.appearance" "color-scheme" 2> "/dev/null")"
		case "${_portal_scheme}" in
			*uint32\ 1*) _DETECTED_COLOR_SCHEME="dark" ;;
			*uint32\ 2*) _DETECTED_COLOR_SCHEME="light" ;;
		esac
	elif command -v gsettings > "/dev/null" 2>&1; then
		local _gnome_scheme
		_gnome_scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2> "/dev/null")"
		case "${_gnome_scheme}" in
			*prefer-dark*)  _DETECTED_COLOR_SCHEME="dark" ;;
			*prefer-light*) _DETECTED_COLOR_SCHEME="light" ;;
		esac
	elif command -v kreadconfig6 > "/dev/null" 2>&1; then
		local _kde_scheme
		_kde_scheme="$(kreadconfig6 --group General --key ColorScheme 2> "/dev/null")"
		case "${_kde_scheme}" in
			*[Dd]ark*)  _DETECTED_COLOR_SCHEME="dark" ;;
			*[Ll]ight*) _DETECTED_COLOR_SCHEME="light" ;;
		esac
	elif command -v kreadconfig5 > "/dev/null" 2>&1; then
		local _kde_scheme5
		_kde_scheme5="$(kreadconfig5 --group General --key ColorScheme 2> "/dev/null")"
		case "${_kde_scheme5}" in
			*[Dd]ark*)  _DETECTED_COLOR_SCHEME="dark" ;;
			*[Ll]ight*) _DETECTED_COLOR_SCHEME="light" ;;
		esac
	elif [ -f "${HOME}/.config/kdeglobals" ]; then
		if grep -qi "ColorScheme=.*Dark" "${HOME}/.config/kdeglobals" 2> "/dev/null"; then
			_DETECTED_COLOR_SCHEME="dark"
		elif grep -qi "ColorScheme=.*Light" "${HOME}/.config/kdeglobals" 2> "/dev/null"; then
			_DETECTED_COLOR_SCHEME="light"
		fi
	fi

	_cache_write "color_scheme" "${_DETECTED_COLOR_SCHEME}"
	echo "${_DETECTED_COLOR_SCHEME}"
}

### --------------------------------
### Detect Desktop Theme Flavor
### --------------------------------
_detect_desktop_theme() {
	if [ -n "${1:-}" ]; then
		case "$1" in
			gnome|kde|xfce|mate|cinnamon|adwaita) echo "$1"; return 0 ;;
		esac
	fi

	if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
		case "$(printf '%s\n' "${XDG_CURRENT_DESKTOP}" | tr '[:upper:]' '[:lower:]')" in
			*gnome*)        echo "gnome"; return 0 ;;
			*kde*|*plasma*) echo "kde"; return 0 ;;
			*cinnamon*)     echo "cinnamon"; return 0 ;;
			*mate*)         echo "mate"; return 0 ;;
			*xfce*)         echo "xfce"; return 0 ;;
		esac
	fi

	if command -v pgrep > "/dev/null" 2>&1; then
		if pgrep -x plasmashell > "/dev/null" 2>&1 || pgrep -x kwin_wayland > "/dev/null" 2>&1 || pgrep -x kwin_x11 > "/dev/null" 2>&1; then
			echo "kde"; return 0
		elif pgrep -x gnome-shell > "/dev/null" 2>&1; then
			echo "gnome"; return 0
		elif pgrep -x cinnamon > "/dev/null" 2>&1; then
			echo "cinnamon"; return 0
		elif pgrep -x mate-session > "/dev/null" 2>&1; then
			echo "mate"; return 0
		elif pgrep -x xfce4-session > "/dev/null" 2>&1; then
			echo "xfce"; return 0
		fi
	fi

	if [ "${_DETECTED_OS-$(_detect_os)}" = "freebsd" ] && { command -v plasmashell > "/dev/null" 2>&1 || command -v startplasma-wayland > "/dev/null" 2>&1 || command -v startplasma-x11 > "/dev/null" 2>&1 || [ -d "/usr/local/share/plasma" ]; }; then
		echo "kde"
	elif command -v gnome-shell > "/dev/null" 2>&1; then
		echo "gnome"
	elif command -v startplasma-wayland > "/dev/null" 2>&1 || command -v plasmashell > "/dev/null" 2>&1 || command -v startplasma-x11 > "/dev/null" 2>&1 || [ -d "/usr/share/plasma" ] || [ -d "/usr/local/share/plasma" ]; then
		echo "kde"
	elif command -v cinnamon > "/dev/null" 2>&1 || [ -d "/usr/share/cinnamon" ] || [ -d "/usr/local/share/cinnamon" ]; then
		echo "cinnamon"
	elif command -v mate-session > "/dev/null" 2>&1 || [ -d "/usr/share/mate" ] || [ -d "/usr/local/share/mate" ]; then
		echo "mate"
	elif command -v xfce4-session > "/dev/null" 2>&1 || [ -d "/usr/share/xfce4" ] || [ -d "/usr/local/share/xfce4" ]; then
		echo "xfce"
	else
		echo "adwaita"
	fi
}

### --------------------------------
### Resolve & Detect GTK Theme
### --------------------------------
_resolve_gtk_theme() {
	local _flavor="${1:-$(_detect_desktop_theme)}"

	if [ "${_flavor}" = "gnome" ] || [ "${_flavor}" = "adwaita" ]; then
		if command -v gsettings > "/dev/null" 2>&1; then
			local _gset_theme=""
			_gset_theme="$(command gsettings get org.gnome.desktop.interface gtk-theme 2> "/dev/null" | tr -d "'" || true)"
			if [ -n "${_gset_theme}" ]; then
				case "${_gset_theme}" in
					Adwaita)
						if [ "$(_detect_color_scheme)" = "dark" ]; then
							_gset_theme="Adwaita-dark"
						fi
						;;
				esac
				if [ -d "/usr/share/themes/${_gset_theme}" ] || \
				   [ -d "/usr/local/share/themes/${_gset_theme}" ] || \
				   [ -d "${HOME}/.themes/${_gset_theme}" ] || \
				   [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/themes/${_gset_theme}" ]; then
					echo "${_gset_theme}"
					return 0
				fi
			fi
		fi
	fi

	local _candidates=""
	case "${_flavor}" in
		kde)      _candidates="Breeze-Dark Breeze:dark Breeze adw-gtk3-dark Adwaita-dark Adwaita:dark" ;;
		xfce)     _candidates="Greybird-dark Greybird adw-gtk3-dark Adwaita-dark Adwaita:dark" ;;
		cinnamon) _candidates="Mint-Y-Dark adw-gtk3-dark Adwaita-dark Adwaita:dark" ;;
		mate)     _candidates="Yaru-MATE-dark BlackMATE adw-gtk3-dark Adwaita-dark Adwaita:dark" ;;
		*)        _candidates="adw-gtk3-dark Yaru-dark Adwaita-dark Adwaita:dark Breeze-Dark Greybird-dark" ;;
	esac

	local _cand
	for _cand in ${_candidates}; do
		case "${_cand}" in
			*:dark)
				local _base_cand="${_cand%:dark}"
				if [ -d "/usr/share/themes/${_base_cand}" ] || [ -d "/usr/local/share/themes/${_base_cand}" ]; then
					echo "${_cand}"
					return 0
				fi
				;;
			*)
				if [ -d "/usr/share/themes/${_cand}" ] || \
				   [ -d "/usr/local/share/themes/${_cand}" ] || \
				   [ -d "${HOME}/.themes/${_cand}" ] || \
				   [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/themes/${_cand}" ]; then
					echo "${_cand}"
					return 0
				fi
				;;
		esac
	done

	if [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "/usr/local/share/themes/adw-gtk3-dark" ]; then
		echo "adw-gtk3-dark"
	elif [ -d "/usr/share/themes/Adwaita-dark" ] || [ -d "/usr/local/share/themes/Adwaita-dark" ]; then
		echo "Adwaita-dark"
	else
		echo "Adwaita:dark"
	fi
}

_detect_gtk_theme() {
	[ -n "${_DETECTED_GTK_THEME:-}" ] && echo "${_DETECTED_GTK_THEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/gtk_theme" ]; then
		_DETECTED_GTK_THEME="$(_cache_read "gtk_theme")"
		if [ -n "${_DETECTED_GTK_THEME}" ]; then
			echo "${_DETECTED_GTK_THEME}"
			return 0
		fi
	fi

	local _desktop_env="$(_detect_desktop_environment)"
	[ "${_desktop_env}" = "unknown" ] && _desktop_env="$(_detect_desktop_theme)"
	_DETECTED_GTK_THEME="$(_resolve_gtk_theme "${_desktop_env}")"
	_cache_write "gtk_theme" "${_DETECTED_GTK_THEME}"
	echo "${_DETECTED_GTK_THEME}"
}

### --------------------------------
### Detect Qt Theme & Platform
### --------------------------------
_detect_qt_theme() {
	[ -n "${_DETECTED_QT_THEME+x}" ] && echo "${_DETECTED_QT_THEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/qt_theme" ]; then
		_DETECTED_QT_THEME="$(_cache_read "qt_theme")"
		echo "${_DETECTED_QT_THEME}"
		return 0
	fi

	local _desktop_env="$(_detect_desktop_environment)"
	[ "${_desktop_env}" = "unknown" ] && _desktop_env="$(_detect_desktop_theme)"
	local _color_scheme="$(_detect_color_scheme)"

	if [ "${_desktop_env}" = "kde" ]; then
		if [ "${_color_scheme}" = "dark" ]; then
			_DETECTED_QT_THEME="Breeze-Dark"
		else
			_DETECTED_QT_THEME="Breeze"
		fi
	else
		_DETECTED_QT_THEME=""
	fi
	_cache_write "qt_theme" "${_DETECTED_QT_THEME}"
	echo "${_DETECTED_QT_THEME}"
}

_detect_qt_platform_theme() {
	[ -n "${_DETECTED_QT_PLATFORM_THEME+x}" ] && echo "${_DETECTED_QT_PLATFORM_THEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/qt_platform_theme" ]; then
		_DETECTED_QT_PLATFORM_THEME="$(_cache_read "qt_platform_theme")"
		echo "${_DETECTED_QT_PLATFORM_THEME}"
		return 0
	fi

	local _desktop_env="$(_detect_desktop_environment)"
	[ "${_desktop_env}" = "unknown" ] && _desktop_env="$(_detect_desktop_theme)"

	case "${_desktop_env}" in
		kde)
			_DETECTED_QT_PLATFORM_THEME="xdgdesktopportal"
			;;
		gnome|sway|hyprland)
			if command -v qt6ct > "/dev/null" 2>&1; then
				_DETECTED_QT_PLATFORM_THEME="qt6ct"
			elif command -v qt5ct > "/dev/null" 2>&1; then
				_DETECTED_QT_PLATFORM_THEME="qt5ct"
			else
				_DETECTED_QT_PLATFORM_THEME="xdgdesktopportal"
			fi
			;;
		xfce|mate|cinnamon)
			_DETECTED_QT_PLATFORM_THEME="gtk3"
			;;
		*)
			if command -v qt6ct > "/dev/null" 2>&1; then
				_DETECTED_QT_PLATFORM_THEME="qt6ct"
			elif command -v qt5ct > "/dev/null" 2>&1; then
				_DETECTED_QT_PLATFORM_THEME="qt5ct"
			else
				_DETECTED_QT_PLATFORM_THEME=""
			fi
			;;
	esac
	_cache_write "qt_platform_theme" "${_DETECTED_QT_PLATFORM_THEME}"
	echo "${_DETECTED_QT_PLATFORM_THEME}"
}

### --------------------------------
### Detect Modern CLI Binaries
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
