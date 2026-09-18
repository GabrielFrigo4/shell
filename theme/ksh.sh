### ================================
### KORN SHELL APPEARANCE
### ================================

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"

_ksh_prompt() {
	_setup_colors

	local _pwd="${PWD:-$(command pwd)}"
	if [ "${_pwd}" = "${HOME}" ]; then
		_pwd="~"
	elif [ "${_pwd}" = "/" ]; then
		_pwd="/"
	else
		_pwd="${_pwd##*/}"
		[ -z "${_pwd}" ] && _pwd="/"
	fi

	local _sh_name="ksh"
	local _branch _is_dirty
	_git_branch

	local _user="${USER:-${LOGNAME:-$(command id -un 2> "/dev/null" || echo "user")}}"
	local _u_color="${_theme_color_green}"
	local _term_color="${_theme_color_blue}"
	local _sym="\$"
	local _sym_color="${_theme_color_cyan}"
	if [ "${EUID:-$(id -u 2> "/dev/null")}" -eq 0 ]; then
		_u_color="${_theme_color_red}"
		_term_color="${_theme_color_red}"
		_sym="#"
		_sym_color="${_theme_color_red}"
	fi

	local _host="${HOSTNAME%%.*}"
	[ -z "${_host}" ] && _host="$(command uname -n 2> "/dev/null" | command cut -d. -f1)"

	local _os_icon="${PROMPT_OS_ICON:-🐡 }"
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_KERNEL_RELEASE:-$(uname -r 2> "/dev/null" || echo "OpenBSD")}}"
	_os_name="${_os_name%%-*}"

	local _os_color="${_theme_color_yellow}"
	case "${PROMPT_OS_COLOR:-yellow}" in
		red)    _os_color="${_theme_color_red}" ;;
		blue)   _os_color="${_theme_color_blue}" ;;
		yellow) _os_color="${_theme_color_yellow}" ;;
		*)      _os_color="${_theme_color_yellow}" ;;
	esac

	local _mode="pty"
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		_mode="tty"
	fi

	local _style="${PROMPT_STYLE:-pill}"
	case "${_style}" in
		micro|pill) ;;
		multi) [ "${_mode}" = "tty" ] && _style="pill" ;;
		*) _style="pill" ;;
	esac

	local _base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
	if [ "${_mode}_${_style}" != "${_LOADED_PROMPT_STYLE_KSH:-}" ]; then
		if [ -f "${_base_dir}/theme/styles/${_mode}/${_style}.sh" ]; then
			. "${_base_dir}/theme/styles/${_mode}/${_style}.sh"
			_LOADED_PROMPT_STYLE_KSH="${_mode}_${_style}"
		fi
	fi

	if command -v _theme_render > "/dev/null" 2>&1; then
		_theme_render
	fi
	printf "%s" "${PS1:-}"
}

export PS1='$(_ksh_prompt)'
