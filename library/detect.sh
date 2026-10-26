### ================================
### CACHE ENGINE
### ================================

### --------------------------------
### Cache Directory & Environment
### --------------------------------
_SHELL_CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/.universal_shell_cache_${USER:-${LOGNAME:-$(id -un 2> "/dev/null" || echo "user")}}"
_SHELL_CACHE_FILE="${_SHELL_CACHE_DIR}/cache.env"

[ -f "${_SHELL_CACHE_FILE}" ] && . "${_SHELL_CACHE_FILE}" 2> "/dev/null"

if [ -z "${_DETECTED_SHELL:-}" ]; then
	if [ -n "${ZSH_VERSION:-}" ]; then _DETECTED_SHELL="zsh"
	elif [ -n "${BASH_VERSION:-}" ]; then _DETECTED_SHELL="bash"
	elif [ -n "${KSH_VERSION:-}" ]; then _DETECTED_SHELL="ksh"
	elif [ -n "${FISH_VERSION:-}" ]; then _DETECTED_SHELL="fish"
	elif [ -n "${NU_VERSION:-}" ]; then _DETECTED_SHELL="nu"
	fi
fi

### --------------------------------
### Cache Read
### --------------------------------
_cache_read() {
	local _file="${_SHELL_CACHE_DIR}/${1}"
	if [ -f "${_file}" ]; then
		local _value
		read -r _value < "${_file}" 2> "/dev/null"
		echo "${_value}"
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
	[ -d "${_SHELL_CACHE_DIR}" ] && command rm -rf "${_SHELL_CACHE_DIR}" 2> "/dev/null" || true
	unset _DETECTED_OS _DETECTED_SHELL _DETECTED_ENABLED_SHELL _DETECTED_DISTRO _DETECTED_DISTRO_FAMILY \
		_DETECTED_DISTRO_ICON _DETECTED_DESKTOP_ENV _DETECTED_COLOR_SCHEME _DETECTED_GTK_THEME \
		_DETECTED_QT_THEME _DETECTED_QT_PLATFORM_THEME _DETECTED_EZA \
		_DETECTED_BAT _DETECTED_RG _DETECTED_FD _DETECTED_ZOXIDE _DETECTED_ESCALATOR \
		_DETECTED_KERNEL_RELEASE _DETECTED_XCURSOR_THEME _DETECTED_XCURSOR_SIZE 2> "/dev/null" || true
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
		Linux*)                        _DETECTED_OS="linux" ;;
		FreeBSD*)                      _DETECTED_OS="freebsd" ;;
		DragonFly*)                    _DETECTED_OS="dragonfly" ;;
		OpenBSD*)                      _DETECTED_OS="openbsd" ;;
		NetBSD*)                       _DETECTED_OS="netbsd" ;;
		SunOS*)                        _DETECTED_OS="illumos" ;;
		Darwin*)                       _DETECTED_OS="macos" ;;
		MINGW*|CYGWIN*|MSYS*|Windows*) _DETECTED_OS="windows" ;;
		*)                             _DETECTED_OS="unknown" ;;
	esac
	_cache_write "os" "${_DETECTED_OS}"
	echo "${_DETECTED_OS}"
}

### --------------------------------
### Detect WSL
### --------------------------------
_is_wsl() {
	[ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ] && return 0
	if [ -r "/proc/version" ]; then
		local _proc_version
		read -r _proc_version < "/proc/version" 2> "/dev/null"
		case "${_proc_version}" in
			*[Mm]icrosoft*|*WSL*) return 0 ;;
		esac
	fi
	return 1
}

### --------------------------------
### Detect SSH / Remote Session
### --------------------------------
_is_ssh() {
	[ -n "${SSH_CLIENT:-}" ] || [ -n "${SSH_TTY:-}" ] || [ -n "${SSH_CONNECTION:-}" ]
}

### --------------------------------
### Detect Shell
### --------------------------------
_detect_shell() {
	[ -n "${_DETECTED_SHELL:-}" ] && echo "${_DETECTED_SHELL}" && return 0

	local _name=""
	local _pid="$$"
	local _os="$(_detect_os)"

	if [ -r "/proc/${_pid}/comm" ]; then
		read -r _name < "/proc/${_pid}/comm" 2> "/dev/null"
		_name="${_name#-}"
	fi

	if [ -z "${_name}" ]; then
		if [ -n "${ZSH_VERSION:-}" ]; then _name="zsh"
		elif [ -n "${BASH_VERSION:-}" ]; then _name="bash"
		elif [ -n "${KSH_VERSION:-}" ]; then _name="ksh"
		elif [ -n "${FISH_VERSION:-}" ]; then _name="fish"
		elif [ -n "${NU_VERSION:-}" ]; then _name="nu"
		elif [ -n "${YASH_VERSION:-}" ]; then _name="yash"
		elif [ -n "${NETBSD_SHELL:-}" ]; then _name="sh"
		fi
	fi

	if [ -z "${_name}" ]; then
		local _invoked_name="${0##*/}"
		_invoked_name="${_invoked_name#-}"
		case "${_invoked_name}" in
			*zsh*)                       _name="zsh" ;;
			*bash*)                      _name="bash" ;;
			*dash*)                      _name="dash" ;;
			*busybox*|*ash*|*hush*)      _name="busybox" ;;
			*ksh*|*mksh*|*pdksh*|*oksh*) _name="ksh" ;;
			*fish*)                      _name="fish" ;;
			*tcsh*)                      _name="tcsh" ;;
			*csh*)                       _name="csh" ;;
			*yash*)                      _name="yash" ;;
			*nu*)                        _name="nu" ;;
			*sh*)                        _name="sh" ;;
		esac
	fi

	if [ -z "${_name}" ]; then
		if [ "${_os}" = "windows" ]; then
			_name="$(command ps 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $8}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
		else
			_name="$(command ps -p "${_pid}" -o comm= 2> "/dev/null" | command sed 's/^-//')"
			[ -z "${_name}" ] && _name="$(command ps -o pid,comm 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $2}' | command awk -F'/' '{print $NF}' | command sed 's/^-//; s/\.exe$//')"
		fi
	fi

	if [ "${_name}" = "sudo" ] || [ "${_name}" = "doas" ] || [ "${_name}" = "su" ]; then
		local _parent_pid="$(command ps -p "${_pid}" -o ppid= 2> "/dev/null" | command tr -d ' ')"
		if [ -z "${_parent_pid}" ]; then
			_parent_pid="$(command ps -o pid,ppid 2> "/dev/null" | command awk -v pid="${_pid}" '$1 == pid {print $2}')"
		fi
		if [ -n "${_parent_pid}" ] && [ -r "/proc/${_parent_pid}/comm" ]; then
			read -r _name < "/proc/${_parent_pid}/comm" 2> "/dev/null"
			_name="${_name#-}"
		fi
		[ -z "${_name}" ] && _name="$(command ps -p "${_parent_pid}" -o comm= 2> "/dev/null" | command sed 's/^-//')"
	fi

	case "${_name}" in
		zsh*|*zsh)         _DETECTED_SHELL="zsh" ;;
		bash*|*bash)       _DETECTED_SHELL="bash" ;;
		dash*|*dash)       _DETECTED_SHELL="dash" ;;
		busybox*|*busybox) _DETECTED_SHELL="busybox" ;;
		ksh*|*ksh)         _DETECTED_SHELL="ksh" ;;
		fish*|*fish)       _DETECTED_SHELL="fish" ;;
		sh*|*sh)           _DETECTED_SHELL="sh" ;;
		ash*|*ash)         _DETECTED_SHELL="ash" ;;
		tcsh*|*tcsh)       _DETECTED_SHELL="tcsh" ;;
		csh*|*csh)         _DETECTED_SHELL="csh" ;;
		yash*|*yash)       _DETECTED_SHELL="yash" ;;
		nu*|*nu)           _DETECTED_SHELL="nu" ;;
		*)                 _DETECTED_SHELL="${_name:-sh}" ;;
	esac

	[ -z "${_DETECTED_SHELL}" ] && _DETECTED_SHELL="$(command basename "${SHELL:-sh}")"
	_DETECTED_SHELL="${_DETECTED_SHELL##*/}"
	echo "${_DETECTED_SHELL}"
}

### --------------------------------
### Detect Enabled Shell
### --------------------------------
_detect_enabled_shell() {
	local _target="${1:-path}"
	local _shell_binary=""
	local _chsh_shell=""
	local _user="${USER:-$(id -un 2> "/dev/null" || true)}"

	if [ -n "${_user}" ] && command -v getent > "/dev/null" 2>&1; then
		_chsh_shell="$(getent passwd "${_user}" 2> "/dev/null" | cut -d: -f7)"
	fi
	[ -z "${_chsh_shell}" ] && [ -n "${SHELL:-}" ] && _chsh_shell="${SHELL}"

	if [ -n "${_chsh_shell}" ] && [ -x "${_chsh_shell}" ]; then
		case "${_chsh_shell##*/}" in
			dash|fish|csh|tcsh|nu|nologin|false) ;;
			sh)
				case "$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" || true)" in
					freebsd|FreeBSD) _shell_binary="${_chsh_shell}" ;;
				esac
				;;
			zsh|bash|ksh) _shell_binary="${_chsh_shell}" ;;
		esac
	fi

	[ -z "${_shell_binary}" ] && _shell_binary="$(command -v zsh 2> "/dev/null" || true)"
	[ -z "${_shell_binary}" ] && _shell_binary="$(command -v bash 2> "/dev/null" || true)"
	[ -z "${_shell_binary}" ] && _shell_binary="$(command -v ksh 2> "/dev/null" || true)"
	if [ -z "${_shell_binary}" ]; then
		local _sh_bin="$(command -v sh 2> "/dev/null" || true)"
		if [ -n "${_sh_bin}" ]; then
			local _real_sh="${_sh_bin}"
			[ -L "${_sh_bin}" ] && _real_sh="$(readlink -f "${_sh_bin}" 2> "/dev/null" || echo "${_sh_bin}")"
			case "${_real_sh##*/}" in
				dash) ;;
				*)    _shell_binary="${_sh_bin}" ;;
			esac
		fi
	fi
	[ -z "${_shell_binary}" ] && _shell_binary="${SHELL:-/bin/sh}"

	case "${_target}" in
		--name|-n|name) echo "${_shell_binary##*/}" ;;
		*)              echo "${_shell_binary}" ;;
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
		local _os_id="$(. /etc/os-release && echo "${ID}")"
		if [ "${_os_id}" = "ubuntu" ]; then
			case "$(. /etc/os-release && echo "${NAME:-} ${PRETTY_NAME:-}")" in
				*[Kk]ubuntu*) _os_id="kubuntu" ;;
				*[Xx]ubuntu*) _os_id="xubuntu" ;;
				*[Ll]ubuntu*) _os_id="lubuntu" ;;
			esac
		fi
		_DETECTED_DISTRO="${_os_id:-unknown}"
	elif [ -f "/etc/arch-release" ]; then _DETECTED_DISTRO="arch"
	elif [ -f "/etc/devuan_version" ]; then _DETECTED_DISTRO="devuan"
	elif [ -f "/etc/oracle-release" ]; then _DETECTED_DISTRO="ol"
	elif [ -f "/etc/debian_version" ]; then _DETECTED_DISTRO="debian"
	elif [ -f "/etc/ghostbsd-version" ] || [ -f "/usr/local/etc/ghostbsd-version" ]; then _DETECTED_DISTRO="ghostbsd"
	elif [ -f "/etc/nomadbsd-version" ]; then _DETECTED_DISTRO="nomadbsd"
	elif [ -f "/etc/release" ]; then
		case "$(command cat /etc/release 2> "/dev/null")" in
			*OmniOS*)      _DETECTED_DISTRO="omnios" ;;
			*SmartOS*)     _DETECTED_DISTRO="smartos" ;;
			*OpenIndiana*) _DETECTED_DISTRO="openindiana" ;;
			*)             _DETECTED_DISTRO="illumos" ;;
		esac
	else
		case "$(uname -s)" in
			OpenBSD*)   _DETECTED_DISTRO="openbsd" ;;
			NetBSD*)    _DETECTED_DISTRO="netbsd" ;;
			FreeBSD*)   _DETECTED_DISTRO="freebsd" ;;
			DragonFly*) _DETECTED_DISTRO="dragonfly" ;;
			SunOS*)     _DETECTED_DISTRO="illumos" ;;
			Darwin*)    _DETECTED_DISTRO="macos" ;;
			*)          _DETECTED_DISTRO="unknown" ;;
		esac
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

	local _distro_id="$(_detect_distro)"
	local _distro_like=""
	[ -f "/etc/os-release" ] && _distro_like="$(. /etc/os-release && echo "${ID_LIKE}")"

	case "${_distro_id}" in
		arch|manjaro|endeavouros|garuda|cachyos|artix)          _DETECTED_DISTRO_FAMILY="arch" ;;
		debian|devuan|ubuntu|kubuntu|xubuntu|lubuntu|linuxmint|pop|raspbian|kali|parrot|tails|mx|zorin|elementary|neon) _DETECTED_DISTRO_FAMILY="debian" ;;
		fedora|rhel|centos|rocky|alma*|nobara|ol|amzn|azurelinux|mariner|qubes) _DETECTED_DISTRO_FAMILY="fedora" ;;
		opensuse*|sles)                       _DETECTED_DISTRO_FAMILY="suse" ;;
		void)                                 _DETECTED_DISTRO_FAMILY="void" ;;
		alpine)                               _DETECTED_DISTRO_FAMILY="alpine" ;;
		gentoo|funtoo|calculate)              _DETECTED_DISTRO_FAMILY="gentoo" ;;
		nixos)                                _DETECTED_DISTRO_FAMILY="nixos" ;;
		solus)                                _DETECTED_DISTRO_FAMILY="solus" ;;
		slackware)                            _DETECTED_DISTRO_FAMILY="slackware" ;;
		guix)                                 _DETECTED_DISTRO_FAMILY="guix" ;;
		openwrt)                                           _DETECTED_DISTRO_FAMILY="embedded" ;;
		freebsd|ghostbsd|nomadbsd|dragonfly|openbsd|netbsd) _DETECTED_DISTRO_FAMILY="bsd" ;;
		omnios|smartos|openindiana|illumos)                _DETECTED_DISTRO_FAMILY="illumos" ;;
		macos)                                _DETECTED_DISTRO_FAMILY="darwin" ;;
		*)
			case "${_distro_like}" in
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
### Detect Distro Icon
### --------------------------------
_detect_distro_icon() {
	[ -n "${_DETECTED_DISTRO_ICON+x}" ] && echo "${_DETECTED_DISTRO_ICON}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/distro_icon" ]; then
		_DETECTED_DISTRO_ICON="$(_cache_read "distro_icon")"
		echo "${_DETECTED_DISTRO_ICON}"
		return 0
	fi

	local _distro="$(_detect_distro)"
	case "${_distro}" in
		fedora)                             _DETECTED_DISTRO_ICON=" " ;;
		arch)                               _DETECTED_DISTRO_ICON=" " ;;
		manjaro)                            _DETECTED_DISTRO_ICON=" " ;;
		endeavouros)                        _DETECTED_DISTRO_ICON=" " ;;
		garuda)                             _DETECTED_DISTRO_ICON="󰛓 " ;;
		cachyos)                            _DETECTED_DISTRO_ICON=" " ;;
		artix)                              _DETECTED_DISTRO_ICON=" " ;;
		debian)                             _DETECTED_DISTRO_ICON=" " ;;
		devuan)                             _DETECTED_DISTRO_ICON=" " ;;
		ubuntu)                             _DETECTED_DISTRO_ICON=" " ;;
		kubuntu)                            _DETECTED_DISTRO_ICON=" " ;;
		xubuntu)                            _DETECTED_DISTRO_ICON=" " ;;
		lubuntu)                            _DETECTED_DISTRO_ICON=" " ;;
		linuxmint|mint)                     _DETECTED_DISTRO_ICON=" " ;;
		pop)                                _DETECTED_DISTRO_ICON=" " ;;
		kali)                               _DETECTED_DISTRO_ICON=" " ;;
		parrot)                             _DETECTED_DISTRO_ICON=" " ;;
		tails)                              _DETECTED_DISTRO_ICON=" " ;;
		mx)                                 _DETECTED_DISTRO_ICON=" " ;;
		zorin)                              _DETECTED_DISTRO_ICON=" " ;;
		elementary)                         _DETECTED_DISTRO_ICON=" " ;;
		neon)                               _DETECTED_DISTRO_ICON=" " ;;
		nobara)                             _DETECTED_DISTRO_ICON=" " ;;
		solus)                              _DETECTED_DISTRO_ICON=" " ;;
		slackware)                          _DETECTED_DISTRO_ICON=" " ;;
		raspbian)                           _DETECTED_DISTRO_ICON=" " ;;
		rocky)                              _DETECTED_DISTRO_ICON=" " ;;
		alma|almalinux)                     _DETECTED_DISTRO_ICON=" " ;;
		centos)                             _DETECTED_DISTRO_ICON=" " ;;
		rhel)                               _DETECTED_DISTRO_ICON=" " ;;
		ol|oracle)                          _DETECTED_DISTRO_ICON="󰌷 " ;;
		azurelinux|mariner)                 _DETECTED_DISTRO_ICON="󰠅 " ;;
		amzn|amazon)                        _DETECTED_DISTRO_ICON=" " ;;
		qubes)                              _DETECTED_DISTRO_ICON=" " ;;
		guix)                               _DETECTED_DISTRO_ICON=" " ;;
		openwrt)                            _DETECTED_DISTRO_ICON=" " ;;
		puppy)                              _DETECTED_DISTRO_ICON=" " ;;
		mageia)                             _DETECTED_DISTRO_ICON=" " ;;
		opensuse*|sles)                     _DETECTED_DISTRO_ICON=" " ;;
		void)                               _DETECTED_DISTRO_ICON=" " ;;
		alpine)                             _DETECTED_DISTRO_ICON=" " ;;
		gentoo)                             _DETECTED_DISTRO_ICON=" " ;;
		nixos)                              _DETECTED_DISTRO_ICON=" " ;;
		freebsd|ghostbsd|nomadbsd)          _DETECTED_DISTRO_ICON=" " ;;
		dragonfly)                          _DETECTED_DISTRO_ICON=" " ;;
		openbsd)                            _DETECTED_DISTRO_ICON=" " ;;
		netbsd)                             _DETECTED_DISTRO_ICON=" " ;;
		solaris|sunos)                      _DETECTED_DISTRO_ICON="󰖨 " ;;
		omnios|smartos|openindiana|illumos) _DETECTED_DISTRO_ICON=" " ;;
		macos)                              _DETECTED_DISTRO_ICON=" " ;;
		windows)                            _DETECTED_DISTRO_ICON=" " ;;
		*)
			case "$(_detect_os)" in
				linux) _DETECTED_DISTRO_ICON=" " ;; freebsd) _DETECTED_DISTRO_ICON=" " ;;
				dragonfly) _DETECTED_DISTRO_ICON=" " ;; openbsd) _DETECTED_DISTRO_ICON=" " ;;
				netbsd) _DETECTED_DISTRO_ICON=" " ;; solaris|sunos) _DETECTED_DISTRO_ICON="󰖨 " ;;
				illumos) _DETECTED_DISTRO_ICON=" " ;; macos) _DETECTED_DISTRO_ICON=" " ;;
				windows) _DETECTED_DISTRO_ICON=" " ;; *) _DETECTED_DISTRO_ICON=" " ;;
			esac
			;;
	esac
	_cache_write "distro_icon" "${_DETECTED_DISTRO_ICON}"
	echo "${_DETECTED_DISTRO_ICON}"
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

	if [ "$(id -u)" -eq 0 ]; then _DETECTED_ESCALATOR="root"
	elif command -v doas > "/dev/null" 2>&1; then _DETECTED_ESCALATOR="doas"
	elif command -v sudo > "/dev/null" 2>&1; then _DETECTED_ESCALATOR="sudo"
	else _DETECTED_ESCALATOR=""; fi
	_cache_write "escalator" "${_DETECTED_ESCALATOR}"
	echo "${_DETECTED_ESCALATOR}"
}

### --------------------------------
### Detect Raw TTY
### --------------------------------
_is_raw_tty() {
	[ -n "${_IS_RAW_TTY_CACHED+x}" ] && return "${_IS_RAW_TTY_CACHED}"

	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _IS_RAW_TTY_CACHED=0; return 0 ;;
		*0*|*false*|*no*) _IS_RAW_TTY_CACHED=1; return 1 ;;
	esac

	case "$(command tty 2> "/dev/null")" in
		/dev/tty[0-9]*|/dev/ttyv*|/dev/ttyS*|/dev/ttyC*|/dev/ttyE*|/dev/console)
			_IS_RAW_TTY_CACHED=0; return 0 ;;
	esac

	case "${TERM:-}" in
		linux|dumb|vt100|cons25*|wvt25*) _IS_RAW_TTY_CACHED=0; return 0 ;;
	esac

	_IS_RAW_TTY_CACHED=1
	return 1
}

### --------------------------------
### Detect Kernel & Distro Version
### --------------------------------
_detect_kernel_release() {
	[ -n "${_DETECTED_KERNEL_RELEASE+x}" ] && echo "${_DETECTED_KERNEL_RELEASE}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/kernel_release" ]; then
		_DETECTED_KERNEL_RELEASE="$(_cache_read "kernel_release")"
		echo "${_DETECTED_KERNEL_RELEASE}"
		return 0
	fi
	[ -r "/proc/sys/kernel/osrelease" ] && read -r _DETECTED_KERNEL_RELEASE < "/proc/sys/kernel/osrelease" 2> "/dev/null"
	[ -z "${_DETECTED_KERNEL_RELEASE:-}" ] && _DETECTED_KERNEL_RELEASE="$(uname -r 2> "/dev/null" || echo "unknown")"
	_cache_write "kernel_release" "${_DETECTED_KERNEL_RELEASE}"
	echo "${_DETECTED_KERNEL_RELEASE}"
}

_detect_distro_version() {
	[ -n "${_DETECTED_DISTRO_VERSION+x}" ] && echo "${_DETECTED_DISTRO_VERSION}" && return 0
	if [ -f "${_SHELL_CACHE_DIR}/distro_version" ]; then
		_DETECTED_DISTRO_VERSION="$(_cache_read "distro_version")"
		echo "${_DETECTED_DISTRO_VERSION}"
		return 0
	fi
	if [ -f "/etc/os-release" ]; then
		_DETECTED_DISTRO_VERSION="$(. /etc/os-release 2> "/dev/null" && echo "${VERSION_ID:-${BUILD_ID:-}}")"
	elif [ -f "/etc/debian_version" ]; then
		_DETECTED_DISTRO_VERSION="$(cat /etc/debian_version 2> "/dev/null")"
	fi
	if [ -z "${_DETECTED_DISTRO_VERSION:-}" ]; then
		case "$(_detect_distro)" in
			arch|void|gentoo)                 _DETECTED_DISTRO_VERSION="rolling" ;;
			freebsd|openbsd|netbsd|dragonfly) _DETECTED_DISTRO_VERSION="$(uname -r 2> "/dev/null" | cut -d'-' -f1)" ;;
			macos)                            _DETECTED_DISTRO_VERSION="$(sw_vers -productVersion 2> "/dev/null" || uname -r)" ;;
			*)                                _DETECTED_DISTRO_VERSION="$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "UNIX")" ;;
		esac
	fi
	_cache_write "distro_version" "${_DETECTED_DISTRO_VERSION}"
	echo "${_DETECTED_DISTRO_VERSION}"
}

if ! command -v _detect_eza > "/dev/null" 2>&1; then
	for _det_mod in "${SHELL_REPO_DIR:-}/library/detect-desktop.sh" "./library/detect-desktop.sh"; do
		if [ -f "${_det_mod}" ]; then
			. "${_det_mod}"
			break
		fi
	done
	unset _det_mod
fi
