### ================================
### SHELL DETECTION
### ================================

### --------------------------------
### Detect OS
### --------------------------------
detect_os() {
	case "$(uname -s)" in
		Linux*)               echo "linux" ;;
		FreeBSD*)             echo "freebsd" ;;
		MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
		*)                    echo "unknown" ;;
	esac
}

### --------------------------------
### Detect Shell
### --------------------------------
detect_shell() {
	local _pid="$$"
	local _os="$(detect_os)"
	local _name

	_name="$(command ps -p "${_pid}" -o comm= 2> "/dev/null" | command sed 's/^-//')"

	if [ -z "${_name}" ]; then
		if [ "${_os}" = "windows" ]; then
			_name="$(command ps 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $8}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
		else
			_name="$(command ps -o pid,comm 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $2}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
		fi
	fi

	if [ "${_name}" = "sudo" ] || [ "${_name}" = "su" ]; then
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
detect_distro() {
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
detect_distro_family() {
	local _id="$(detect_distro)"
	local _like=""
	[ -f "/etc/os-release" ] && _like="$(. /etc/os-release && echo "${ID_LIKE}")"

	case "${_id}" in
		arch|manjaro|endeavouros)             echo "arch" ;;
		debian|ubuntu|linuxmint|pop|raspbian) echo "debian" ;;
		fedora|rhel|centos|rocky|alma)        echo "fedora" ;;
		opensuse*|sles)                       echo "suse" ;;
		void)                                 echo "void" ;;
		alpine)                               echo "alpine" ;;
		*)
			case "${_like}" in
				*arch*)            echo "arch" ;;
				*debian*|*ubuntu*) echo "debian" ;;
				*fedora*|*rhel*)   echo "fedora" ;;
				*suse*)            echo "suse" ;;
				*)                 echo "unknown" ;;
			esac
			;;
	esac
}

### --------------------------------
### Detect Desktop Environment
### --------------------------------
detect_desktop_environment() {
	local _desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION}}"
	case "${_desktop}" in
		*[Kk][Dd][Ee]*|*[Pp]lasma*)         echo "kde" ;;
		*[Gg][Nn][Oo][Mm][Ee]*)             echo "gnome" ;;
		*[Xx][Ff][Cc][Ee]*)                 echo "xfce" ;;
		*[Cc][Ii][Nn][Nn][Aa][Mm][Oo][Nn]*) echo "cinnamon" ;;
		*[Mm][Aa][Tt][Ee]*)                 echo "mate" ;;
		*[Ss][Ww][Aa][Yy]*)                 echo "sway" ;;
		*[Hh][Yy][Pp][Rr][Ll][Aa][Nn][Dd]*) echo "hyprland" ;;
		*)                                  echo "unknown" ;;
	esac
}

### --------------------------------
### Detect Color Scheme (dark/light)
### --------------------------------
detect_color_scheme() {
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
detect_gtk_theme() {
	local _desktop_env="$(detect_desktop_environment)"
	local _color_scheme="$(detect_color_scheme)"

	if [ "${_color_scheme}" = "dark" ]; then
		case "${_desktop_env}" in
			kde) echo "Breeze-Dark" ;;
			*)   echo "Adwaita:dark" ;;
		esac
	else
		case "${_desktop_env}" in
			kde) echo "Breeze" ;;
			*)   echo "Adwaita" ;;
		esac
	fi
}

### --------------------------------
### Detect Qt Theme
### --------------------------------
detect_qt_theme() {
	local _desktop_env="$(detect_desktop_environment)"
	local _color_scheme="$(detect_color_scheme)"

	if [ "${_color_scheme}" = "dark" ]; then
		case "${_desktop_env}" in
			kde) echo "Breeze-Dark" ;;
			*)   echo "Adwaita-Dark" ;;
		esac
	else
		case "${_desktop_env}" in
			kde) echo "Breeze" ;;
			*)   echo "Adwaita" ;;
		esac
	fi
}
