### ================================
### CACHE ENGINE
### ================================

### --------------------------------
### Cache Directory & Environment
### --------------------------------
_SHELL_CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/.universal_shell_cache_${USER:-$(id -un 2> "/dev/null" || echo "user")}"
_SHELL_CACHE_FILE="${_SHELL_CACHE_DIR}/cache.env"

[ -f "${_SHELL_CACHE_FILE}" ] && . "${_SHELL_CACHE_FILE}" 2> "/dev/null"

### --------------------------------
### Cache Read
### --------------------------------
_cache_read() {
	local _file="${_SHELL_CACHE_DIR}/${1}"
	if [ -f "${_file}" ]; then
		local _val
		read -r _val < "${_file}" 2> "/dev/null"
		echo "${_val}"
		return 0
	fi
	return 1
}

### --------------------------------
### Cache Write
### --------------------------------
_cache_write() {
	[ -d "${_SHELL_CACHE_DIR}" ] || command mkdir -p "${_SHELL_CACHE_DIR}" 2> "/dev/null" || return 1
	[ -f "${_SHELL_CACHE_FILE}" ] || command touch "${_SHELL_CACHE_FILE}" 2> "/dev/null" || true
	echo "${2}" >| "${_SHELL_CACHE_DIR}/${1}" 2> "/dev/null"
	_var_name="_DETECTED_$(echo "${1}" | tr '[:lower:]' '[:upper:]')"
	echo "${_var_name}=\"${2}\"" >> "${_SHELL_CACHE_FILE}" 2> "/dev/null" || true
	eval "${_var_name}=\"\${2}\"" 2> "/dev/null" || true
	unset _var_name
}


### --------------------------------
### Cache Clean
### --------------------------------
_cache_clean() {
	if [ -d "${_SHELL_CACHE_DIR}" ]; then
		command rm -rf "${_SHELL_CACHE_DIR}" 2> "/dev/null" || true
	fi
	unset _DETECTED_OS _DETECTED_SHELL _DETECTED_ENABLED_SHELL _DETECTED_DISTRO _DETECTED_DISTRO_FAMILY \
		_DETECTED_DESKTOP_ENV _DETECTED_COLOR_SCHEME _DETECTED_GTK_THEME \
		_DETECTED_QT_THEME _DETECTED_QT_PLATFORM_THEME _DETECTED_EZA \
		_DETECTED_BAT _DETECTED_RG _DETECTED_FD _DETECTED_ESCALATOR \
		_DETECTED_KERNEL_RELEASE 2> "/dev/null" || true
}


### ================================
### SHELL DETECTION
### ================================

### --------------------------------
### Detect OS
### --------------------------------
_detect_os() {
	[ -n "${_DETECTED_OS+x}" ] && echo "${_DETECTED_OS}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/os" ]; then
		_DETECTED_OS="$(_cache_read "os")"
		echo "${_DETECTED_OS}"
		return 0
	fi

	case "$(uname -s)" in
		Linux*)               _DETECTED_OS="linux" ;;
		FreeBSD*)             _DETECTED_OS="freebsd" ;;
		Darwin*)              _DETECTED_OS="macos" ;;
		MINGW*|CYGWIN*|MSYS*) _DETECTED_OS="windows" ;;
		*)                    _DETECTED_OS="unknown" ;;
	esac
	_cache_write "os" "${_DETECTED_OS}"
	echo "${_DETECTED_OS}"
}

### --------------------------------
### Detect Shell
### --------------------------------
_detect_shell() {
	local _pid="$$"
	local _os="$(_detect_os)"
	local _name

	_name="$(command ps -p "${_pid}" -o comm= 2> "/dev/null" | command sed 's/^-//')"

	if [ -z "${_name}" ] && [ -r "/proc/${_pid}/comm" ]; then
		read -r _name < "/proc/${_pid}/comm" 2> "/dev/null"
		_name="${_name#-}"
	fi

	if [ -z "${_name}" ]; then
		if [ "${_os}" = "windows" ]; then
			_name="$(command ps 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $8}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
		else
			_name="$(command ps -o pid,comm 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $2}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
		fi
	fi

	if [ "${_name}" = "sudo" ] || [ "${_name}" = "doas" ] || [ "${_name}" = "su" ]; then
		local _gpid="$(command ps -p "${_pid}" -o ppid= 2> "/dev/null" | command tr -d ' ')"
		if [ -z "${_gpid}" ]; then
			if [ "${_os}" = "windows" ]; then
				_gpid="$(command ps 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $2}')"
			else
				_gpid="$(command ps -o pid,ppid 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $2}')"
			fi
		fi
		_name="$(command ps -p "${_gpid}" -o comm= 2> "/dev/null" | command sed 's/^-//')"
		if [ -z "${_name}" ] && [ -r "/proc/${_gpid}/comm" ]; then
			read -r _name < "/proc/${_gpid}/comm" 2> "/dev/null"
			_name="${_name#-}"
		fi
		if [ -z "${_name}" ]; then
			if [ "${_os}" = "windows" ]; then
				_name="$(command ps 2> "/dev/null" | command awk -v pid="${_gpid}" '$1 == pid {print $8}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
			else
				_name="$(command ps -o pid,comm 2> "/dev/null" | command awk -v pid="${_gpid}" '$1 == pid {print $2}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
			fi
		fi
	fi

	case "${_name}" in
		zsh*|*zsh)         echo "zsh"; return 0 ;;
		bash*|*bash)       echo "bash"; return 0 ;;
		dash*|*dash)       echo "dash"; return 0 ;;
		busybox*|*busybox) echo "busybox"; return 0 ;;
		ksh*|*ksh)         echo "ksh"; return 0 ;;
		fish*|*fish)       echo "fish"; return 0 ;;
		sh*|*sh)           echo "sh"; return 0 ;;
	esac

	local _arg0="${0##*/}"
	_arg0="${_arg0#-}"
	case "${_arg0}" in
		zsh*|*zsh)         echo "zsh"; return 0 ;;
		bash*|*bash)       echo "bash"; return 0 ;;
		dash*|*dash)       echo "dash"; return 0 ;;
		busybox*|*busybox) echo "busybox"; return 0 ;;
		ksh*|*ksh)         echo "ksh"; return 0 ;;
		fish*|*fish)       echo "fish"; return 0 ;;
		sh*|*sh)           echo "sh"; return 0 ;;
	esac

	[ -z "${_name}" ] && _name="$(command basename "${SHELL:-sh}")"

	echo "${_name##*/}"
}

### --------------------------------
### Detect Enabled Shell
### --------------------------------
_detect_enabled_shell() {
	local _target="${1:-path}"
	local _cur=""

	case "${_target}" in
		--preferred|-p|preferred)
			_cur=""
			;;
		*)
			_cur="$(_detect_shell)"
			case "${_cur}" in
				dash|fish) _cur="" ;;
			esac
			;;
	esac

	local _bin
	_bin="$( { [ -n "${_cur}" ] && command -v "${_cur}" 2> "/dev/null"; } || \
		command -v zsh 2> "/dev/null" || \
		command -v bash 2> "/dev/null" || \
		command -v sh 2> "/dev/null")"

	case "${_target}" in
		--name|-n|name) echo "${_bin##*/}" ;;
		*)              echo "${_bin}" ;;
	esac
}

### --------------------------------
### Detect Distro
### --------------------------------
_detect_distro() {
	[ -n "${_DETECTED_DISTRO+x}" ] && echo "${_DETECTED_DISTRO}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/distro" ]; then
		_DETECTED_DISTRO="$(_cache_read "distro")"
		echo "${_DETECTED_DISTRO}"
		return 0
	fi

	if [ -f "/etc/os-release" ]; then
		local _id="$(. /etc/os-release && echo "${ID}")"
		_DETECTED_DISTRO="${_id:-unknown}"
	elif [ -f "/etc/arch-release" ]; then
		_DETECTED_DISTRO="arch"
	elif [ -f "/etc/debian_version" ]; then
		_DETECTED_DISTRO="debian"
	else
		_DETECTED_DISTRO="unknown"
	fi
	_cache_write "distro" "${_DETECTED_DISTRO}"
	echo "${_DETECTED_DISTRO}"
}

### --------------------------------
### Detect Distro Family
### --------------------------------
_detect_distro_family() {
	[ -n "${_DETECTED_DISTRO_FAMILY+x}" ] && echo "${_DETECTED_DISTRO_FAMILY}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/distro_family" ]; then
		_DETECTED_DISTRO_FAMILY="$(_cache_read "distro_family")"
		echo "${_DETECTED_DISTRO_FAMILY}"
		return 0
	fi

	local _id="$(_detect_distro)"
	local _like=""
	[ -f "/etc/os-release" ] && _like="$(. /etc/os-release && echo "${ID_LIKE}")"

	case "${_id}" in
		arch|manjaro|endeavouros)             _DETECTED_DISTRO_FAMILY="arch" ;;
		debian|ubuntu|linuxmint|pop|raspbian) _DETECTED_DISTRO_FAMILY="debian" ;;
		fedora|rhel|centos|rocky|alma)        _DETECTED_DISTRO_FAMILY="fedora" ;;
		opensuse*|sles)                       _DETECTED_DISTRO_FAMILY="suse" ;;
		void)                                 _DETECTED_DISTRO_FAMILY="void" ;;
		alpine)                               _DETECTED_DISTRO_FAMILY="alpine" ;;
		gentoo|funtoo|calculate)              _DETECTED_DISTRO_FAMILY="gentoo" ;;
		nixos)                                _DETECTED_DISTRO_FAMILY="nixos" ;;
		*)
			case "${_like}" in
				*arch*)            _DETECTED_DISTRO_FAMILY="arch" ;;
				*debian*|*ubuntu*) _DETECTED_DISTRO_FAMILY="debian" ;;
				*fedora*|*rhel*)   _DETECTED_DISTRO_FAMILY="fedora" ;;
				*suse*)            _DETECTED_DISTRO_FAMILY="suse" ;;
				*gentoo*)          _DETECTED_DISTRO_FAMILY="gentoo" ;;
				*)                 _DETECTED_DISTRO_FAMILY="unknown" ;;
			esac
			;;
	esac
	_cache_write "distro_family" "${_DETECTED_DISTRO_FAMILY}"
	echo "${_DETECTED_DISTRO_FAMILY}"
}

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
		local _portal
		_portal="$(gdbus call --session --dest org.freedesktop.portal.Desktop \
			--object-path /org/freedesktop/portal/desktop \
			--method org.freedesktop.portal.Settings.Read \
			"org.freedesktop.appearance" "color-scheme" 2> "/dev/null")"
		case "${_portal}" in
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
### Detect GTK Theme
### --------------------------------
_detect_gtk_theme() {
	[ -n "${_DETECTED_GTK_THEME+x}" ] && echo "${_DETECTED_GTK_THEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/gtk_theme" ]; then
		_DETECTED_GTK_THEME="$(_cache_read "gtk_theme")"
		echo "${_DETECTED_GTK_THEME}"
		return 0
	fi

	local _desktop_env="$(_detect_desktop_environment)"
	local _color_scheme="$(_detect_color_scheme)"

	case "${_desktop_env}" in
		kde)
			if [ "${_color_scheme}" = "dark" ]; then
				_DETECTED_GTK_THEME="Breeze-Dark"
			else
				_DETECTED_GTK_THEME="Breeze"
			fi
			;;
		gnome)
			_DETECTED_GTK_THEME=""
			;;
		*)
			if [ "${_color_scheme}" = "dark" ]; then
				if [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "${HOME}/.themes/adw-gtk3-dark" ]; then
					_DETECTED_GTK_THEME="adw-gtk3-dark"
				else
					_DETECTED_GTK_THEME="Adwaita:dark"
				fi
			else
				if [ -d "/usr/share/themes/adw-gtk3" ] || [ -d "${HOME}/.themes/adw-gtk3" ]; then
					_DETECTED_GTK_THEME="adw-gtk3"
				else
					_DETECTED_GTK_THEME="Adwaita"
				fi
			fi
			;;
	esac
	_cache_write "gtk_theme" "${_DETECTED_GTK_THEME}"
	echo "${_DETECTED_GTK_THEME}"
}

### --------------------------------
### Detect Qt Theme
### --------------------------------
_detect_qt_theme() {
	[ -n "${_DETECTED_QT_THEME+x}" ] && echo "${_DETECTED_QT_THEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/qt_theme" ]; then
		_DETECTED_QT_THEME="$(_cache_read "qt_theme")"
		echo "${_DETECTED_QT_THEME}"
		return 0
	fi

	local _desktop_env="$(_detect_desktop_environment)"
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

### --------------------------------
### Detect Qt Platform Theme
### --------------------------------
_detect_qt_platform_theme() {
	[ -n "${_DETECTED_QT_PLATFORM_THEME+x}" ] && echo "${_DETECTED_QT_PLATFORM_THEME}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/qt_platform_theme" ]; then
		_DETECTED_QT_PLATFORM_THEME="$(_cache_read "qt_platform_theme")"
		echo "${_DETECTED_QT_PLATFORM_THEME}"
		return 0
	fi

	local _desktop_env="$(_detect_desktop_environment)"

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
### Detect Eza/Exa Binary
### --------------------------------
_detect_eza() {
	[ -n "${_DETECTED_EZA+x}" ] && echo "${_DETECTED_EZA}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/eza" ]; then
		_DETECTED_EZA="$(_cache_read "eza")"
		echo "${_DETECTED_EZA}"
		return 0
	fi

	if command -v eza > "/dev/null" 2>&1; then
		_DETECTED_EZA="eza"
	elif command -v exa > "/dev/null" 2>&1; then
		_DETECTED_EZA="exa"
	elif [ -x "${HOME}/.cargo/bin/eza" ]; then
		_DETECTED_EZA="${HOME}/.cargo/bin/eza"
	elif [ -x "${HOME}/.cargo/bin/exa" ]; then
		_DETECTED_EZA="${HOME}/.cargo/bin/exa"
	else
		_DETECTED_EZA=""
	fi
	_cache_write "eza" "${_DETECTED_EZA}"
	echo "${_DETECTED_EZA}"
}

### --------------------------------
### Detect Bat/Batcat Binary
### --------------------------------
_detect_bat() {
	[ -n "${_DETECTED_BAT+x}" ] && echo "${_DETECTED_BAT}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/bat" ]; then
		_DETECTED_BAT="$(_cache_read "bat")"
		echo "${_DETECTED_BAT}"
		return 0
	fi

	if command -v bat > "/dev/null" 2>&1; then
		_DETECTED_BAT="bat"
	elif command -v batcat > "/dev/null" 2>&1; then
		_DETECTED_BAT="batcat"
	elif [ -x "${HOME}/.cargo/bin/bat" ]; then
		_DETECTED_BAT="${HOME}/.cargo/bin/bat"
	else
		_DETECTED_BAT=""
	fi
	_cache_write "bat" "${_DETECTED_BAT}"
	echo "${_DETECTED_BAT}"
}

### --------------------------------
### Detect Ripgrep Binary
### --------------------------------
_detect_rg() {
	[ -n "${_DETECTED_RG+x}" ] && echo "${_DETECTED_RG}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/rg" ]; then
		_DETECTED_RG="$(_cache_read "rg")"
		echo "${_DETECTED_RG}"
		return 0
	fi

	if command -v rg > "/dev/null" 2>&1; then
		_DETECTED_RG="rg"
	elif command -v ripgrep > "/dev/null" 2>&1; then
		_DETECTED_RG="ripgrep"
	elif [ -x "${HOME}/.cargo/bin/rg" ]; then
		_DETECTED_RG="${HOME}/.cargo/bin/rg"
	else
		_DETECTED_RG=""
	fi
	_cache_write "rg" "${_DETECTED_RG}"
	echo "${_DETECTED_RG}"
}

### --------------------------------
### Detect Rust Fd-Find Binary
### --------------------------------
_detect_fd() {
	[ -n "${_DETECTED_FD+x}" ] && echo "${_DETECTED_FD}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/fd" ]; then
		_DETECTED_FD="$(_cache_read "fd")"
		echo "${_DETECTED_FD}"
		return 0
	fi

	if command -v fd > "/dev/null" 2>&1; then
		_DETECTED_FD="fd"
	elif command -v fdfind > "/dev/null" 2>&1; then
		_DETECTED_FD="fdfind"
	elif command -v fd-find > "/dev/null" 2>&1; then
		_DETECTED_FD="fd-find"
	elif [ -x "${HOME}/.cargo/bin/fd" ]; then
		_DETECTED_FD="${HOME}/.cargo/bin/fd"
	else
		_DETECTED_FD=""
	fi
	_cache_write "fd" "${_DETECTED_FD}"
	echo "${_DETECTED_FD}"
}

### --------------------------------
### Detect Privilege Escalator
### --------------------------------
_detect_privilege_escalator() {
	[ -n "${_DETECTED_ESCALATOR+x}" ] && echo "${_DETECTED_ESCALATOR}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/escalator" ]; then
		_DETECTED_ESCALATOR="$(_cache_read "escalator")"
		echo "${_DETECTED_ESCALATOR}"
		return 0
	fi

	if [ "$(id -u)" -eq 0 ]; then
		_DETECTED_ESCALATOR="root"
	elif command -v doas > "/dev/null" 2>&1; then
		_DETECTED_ESCALATOR="doas"
	elif command -v sudo > "/dev/null" 2>&1; then
		_DETECTED_ESCALATOR="sudo"
	else
		_DETECTED_ESCALATOR=""
	fi
	_cache_write "escalator" "${_DETECTED_ESCALATOR}"
	echo "${_DETECTED_ESCALATOR}"
}

### --------------------------------
### Detect Raw TTY
### --------------------------------
_is_raw_tty() {
	case "${TERM}" in
		linux|dumb|vt100|cons25*) return 0 ;;
	esac

	case "$(command tty 2> "/dev/null")" in
		/dev/tty[0-9]*|/dev/ttyv*|/dev/ttyS*|/dev/console) return 0 ;;
		*) return 1 ;;
	esac
}

### --------------------------------
### Detect Kernel Release
### --------------------------------
_detect_kernel_release() {
	[ -n "${_DETECTED_KERNEL_RELEASE+x}" ] && echo "${_DETECTED_KERNEL_RELEASE}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/kernel_release" ]; then
		_DETECTED_KERNEL_RELEASE="$(_cache_read "kernel_release")"
		echo "${_DETECTED_KERNEL_RELEASE}"
		return 0
	fi

	_DETECTED_KERNEL_RELEASE="$(uname -r)"
	_cache_write "kernel_release" "${_DETECTED_KERNEL_RELEASE}"
	echo "${_DETECTED_KERNEL_RELEASE}"
}
