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
