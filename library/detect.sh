### ================================
### SHELL DETECTION
### ================================

### --------------------------------
### Detect OS
### --------------------------------
_detect_os() {
	case "$(uname -s)" in
		Linux*)               echo "linux" ;;
		FreeBSD*)             echo "freebsd" ;;
		Darwin*)              echo "macos" ;;
		MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
		*)                    echo "unknown" ;;
	esac
}

### --------------------------------
### Detect Shell
### --------------------------------
_detect_shell() {
	local _pid="$$"
	local _os="$(_detect_os)"
	local _name

	_name="$(command ps -p "${_pid}" -o comm= 2> "/dev/null" | command sed 's/^-//')"

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
		if [ -z "${_name}" ]; then
			if [ "${_os}" = "windows" ]; then
				_name="$(command ps 2> "/dev/null" | command awk -v pid="${_gpid}" '$1 == pid {print $8}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
			else
				_name="$(command ps -o pid,comm 2> "/dev/null" | command awk -v pid="${_gpid}" '$1 == pid {print $2}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
			fi
		fi
	fi

	[ -z "${_name}" ] && _name="$(command basename "${SHELL}")"

	echo "${_name##*/}"
}

### --------------------------------
### Detect Distro
### --------------------------------
_detect_distro() {
	if [ -f "/etc/os-release" ]; then
		local _id="$(. /etc/os-release && echo "${ID}")"
		echo "${_id:-unknown}"
	elif [ -f "/etc/arch-release" ]; then
		echo "arch"
	elif [ -f "/etc/debian_version" ]; then
		echo "debian"
	else
		echo "unknown"
	fi
}

### --------------------------------
### Detect Distro Family
### --------------------------------
_detect_distro_family() {
	local _id="$(_detect_distro)"
	local _like=""
	[ -f "/etc/os-release" ] && _like="$(. /etc/os-release && echo "${ID_LIKE}")"

	case "${_id}" in
		arch|manjaro|endeavouros)             echo "arch" ;;
		debian|ubuntu|linuxmint|pop|raspbian) echo "debian" ;;
		fedora|rhel|centos|rocky|alma)        echo "fedora" ;;
		opensuse*|sles)                       echo "suse" ;;
		void)                                 echo "void" ;;
		alpine)                               echo "alpine" ;;
		gentoo|funtoo|calculate)              echo "gentoo" ;;
		nixos)                                echo "nixos" ;;
		*)
			case "${_like}" in
				*arch*)            echo "arch" ;;
				*debian*|*ubuntu*) echo "debian" ;;
				*fedora*|*rhel*)   echo "fedora" ;;
				*suse*)            echo "suse" ;;
				*gentoo*)          echo "gentoo" ;;
				*)                 echo "unknown" ;;
			esac
			;;
	esac
}

### --------------------------------
### Detect Desktop Environment
### --------------------------------
_detect_desktop_environment() {
	local _desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION}}"
	case "${_desktop}" in
		*[Kk][Dd][Ee]*|*[Pp]lasma*)                                          echo "kde" ;;
		*[Gg][Nn][Oo][Mm][Ee]*)                                              echo "gnome" ;;
		*[Xx][Ff][Cc][Ee]*)                                                  echo "xfce" ;;
		*[Cc][Ii][Nn][Nn][Aa][Mm][Oo][Nn]*)                                  echo "cinnamon" ;;
		*[Mm][Aa][Tt][Ee]*)                                                  echo "mate" ;;
		*[Cc][Oo][Ss][Mm][Ii][Cc]*)                                          echo "cosmic" ;;
		*[Ll][Xx][Qq][Tt]*)                                                  echo "lxqt" ;;
		*[Ss][Ww][Aa][Yy]*)                                                  echo "sway" ;;
		*[Hh][Yy][Pp][Rr][Ll][Aa][Nn][Dd]*)                                  echo "hyprland" ;;
		*[Ii]3*|*[Bb][Ss][Pp][Ww][Mm]*|*[Rr][Ii][Vv][Ee][Rr]*|*[Dd][Ww][Mm]*) echo "wm" ;;
		*)                                                                   echo "unknown" ;;
	esac
}

### --------------------------------
### Detect Color Scheme (dark/light)
### --------------------------------
_detect_color_scheme() {
	if command -v gdbus > "/dev/null" 2>&1; then
		local _portal
		_portal="$(gdbus call --session --dest org.freedesktop.portal.Desktop \
			--object-path /org/freedesktop/portal/desktop \
			--method org.freedesktop.portal.Settings.Read \
			"org.freedesktop.appearance" "color-scheme" 2> "/dev/null")"
		case "${_portal}" in
			*uint32\ 1*) echo "dark"; return 0 ;;
			*uint32\ 2*) echo "light"; return 0 ;;
		esac
	fi

	if command -v gsettings > "/dev/null" 2>&1; then
		local _gnome_scheme
		_gnome_scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2> "/dev/null")"
		case "${_gnome_scheme}" in
			*prefer-dark*)  echo "dark"; return 0 ;;
			*prefer-light*) echo "light"; return 0 ;;
		esac
	fi

	if command -v kreadconfig6 > "/dev/null" 2>&1; then
		local _kde_scheme
		_kde_scheme="$(kreadconfig6 --group General --key ColorScheme 2> "/dev/null")"
		case "${_kde_scheme}" in
			*[Dd]ark*)  echo "dark"; return 0 ;;
			*[Ll]ight*) echo "light"; return 0 ;;
		esac
	elif command -v kreadconfig5 > "/dev/null" 2>&1; then
		local _kde_scheme5
		_kde_scheme5="$(kreadconfig5 --group General --key ColorScheme 2> "/dev/null")"
		case "${_kde_scheme5}" in
			*[Dd]ark*)  echo "dark"; return 0 ;;
			*[Ll]ight*) echo "light"; return 0 ;;
		esac
	elif [ -f "${HOME}/.config/kdeglobals" ]; then
		if grep -qi "ColorScheme=.*Dark" "${HOME}/.config/kdeglobals" 2> "/dev/null"; then
			echo "dark"; return 0
		elif grep -qi "ColorScheme=.*Light" "${HOME}/.config/kdeglobals" 2> "/dev/null"; then
			echo "light"; return 0
		fi
	fi

	echo "dark"
}

### --------------------------------
### Detect GTK Theme
### --------------------------------
_detect_gtk_theme() {
	local _desktop_env="$(_detect_desktop_environment)"
	local _color_scheme="$(_detect_color_scheme)"

	case "${_desktop_env}" in
		kde)
			if [ "${_color_scheme}" = "dark" ]; then
				echo "Breeze-Dark"
			else
				echo "Breeze"
			fi
			;;
		gnome)
			echo ""
			;;
		*)
			if [ "${_color_scheme}" = "dark" ]; then
				if [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "${HOME}/.themes/adw-gtk3-dark" ]; then
					echo "adw-gtk3-dark"
				else
					echo "Adwaita:dark"
				fi
			else
				if [ -d "/usr/share/themes/adw-gtk3" ] || [ -d "${HOME}/.themes/adw-gtk3" ]; then
					echo "adw-gtk3"
				else
					echo "Adwaita"
				fi
			fi
			;;
	esac
}

### --------------------------------
### Detect Qt Theme
### --------------------------------
_detect_qt_theme() {
	local _desktop_env="$(_detect_desktop_environment)"
	local _color_scheme="$(_detect_color_scheme)"

	if [ "${_desktop_env}" = "kde" ]; then
		if [ "${_color_scheme}" = "dark" ]; then
			echo "Breeze-Dark"
		else
			echo "Breeze"
		fi
	else
		echo ""
	fi
}

### --------------------------------
### Detect Qt Platform Theme
### --------------------------------
_detect_qt_platform_theme() {
	local _desktop_env="$(_detect_desktop_environment)"

	case "${_desktop_env}" in
		kde)
			echo "xdgdesktopportal"
			;;
		gnome|sway|hyprland)
			if command -v qt6ct > "/dev/null" 2>&1; then
				echo "qt6ct"
			elif command -v qt5ct > "/dev/null" 2>&1; then
				echo "qt5ct"
			else
				echo "xdgdesktopportal"
			fi
			;;
		xfce|mate|cinnamon)
			echo "gtk3"
			;;
		*)
			if command -v qt6ct > "/dev/null" 2>&1; then
				echo "qt6ct"
			elif command -v qt5ct > "/dev/null" 2>&1; then
				echo "qt5ct"
			else
				echo ""
			fi
			;;
	esac
}

### --------------------------------
### Detect Eza/Exa Binary
### --------------------------------
_detect_eza() {
	if command -v eza > "/dev/null" 2>&1; then
		echo "eza"
	elif command -v exa > "/dev/null" 2>&1; then
		echo "exa"
	elif [ -x "${HOME}/.cargo/bin/eza" ]; then
		echo "${HOME}/.cargo/bin/eza"
	elif [ -x "${HOME}/.cargo/bin/exa" ]; then
		echo "${HOME}/.cargo/bin/exa"
	fi
}

### --------------------------------
### Detect Bat/Batcat Binary
### --------------------------------
_detect_bat() {
	if command -v bat > "/dev/null" 2>&1; then
		echo "bat"
	elif command -v batcat > "/dev/null" 2>&1; then
		echo "batcat"
	elif [ -x "${HOME}/.cargo/bin/bat" ]; then
		echo "${HOME}/.cargo/bin/bat"
	fi
}

### --------------------------------
### Detect Ripgrep Binary
### --------------------------------
_detect_rg() {
	if command -v rg > "/dev/null" 2>&1; then
		echo "rg"
	elif command -v ripgrep > "/dev/null" 2>&1; then
		echo "ripgrep"
	elif [ -x "${HOME}/.cargo/bin/rg" ]; then
		echo "${HOME}/.cargo/bin/rg"
	fi
}

### --------------------------------
### Detect Rust Fd-Find Binary
### --------------------------------
_detect_fd() {
	if command -v fd > "/dev/null" 2>&1; then
		echo "fd"
	elif command -v fdfind > "/dev/null" 2>&1; then
		echo "fdfind"
	elif command -v fd-find > "/dev/null" 2>&1; then
		echo "fd-find"
	elif [ -x "${HOME}/.cargo/bin/fd" ]; then
		echo "${HOME}/.cargo/bin/fd"
	fi
}

### --------------------------------
### Detect Privilege Escalator
### --------------------------------
_detect_privilege_escalator() {
	if [ "$(id -u)" -eq 0 ]; then
		echo "root"
	elif command -v doas > "/dev/null" 2>&1; then
		echo "doas"
	elif command -v sudo > "/dev/null" 2>&1; then
		echo "sudo"
	fi
}

### --------------------------------
### Detect Raw TTY (Console)
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
