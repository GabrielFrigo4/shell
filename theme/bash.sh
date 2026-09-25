### ================================
### BOURNE AGAIN SHELL APPEARANCE
### ================================

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"

_update_prompt() {
	_setup_colors

	local _user="${USER:-$(command id -un)}"
	local _host="${HOSTNAME%%.*}"
	[ -z "${_host}" ] && _host="$(command uname -n 2> "/dev/null" | command cut -d. -f1)"

	local _pwd="${PWD:-$(command pwd)}"
	if [ "${_pwd}" = "${HOME}" ]; then
		_pwd="~"
	elif [ "${_pwd}" = "/" ]; then
		_pwd="/"
	else
		_pwd="${_pwd##*/}"
		[ -z "${_pwd}" ] && _pwd="/"
	fi

	local _shell_name="bash"
	local _os_icon="${PROMPT_OS_ICON:- }"
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_KERNEL_RELEASE:-$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "Linux")}}"
	_os_name="${_os_name%%-*}"

	local _mode="pty"
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		_mode="tty"
	fi

	local _style="${PROMPT_STYLE:-multi}"
	[ "${_mode}" = "tty" ] && _style="${PROMPT_STYLE:-pill}"
	case "${_style}" in
		micro|pill) ;;
		multi) [ "${_mode}" = "tty" ] && _style="pill" ;;
		*) _style="pill" ;;
	esac

	local _os_color
	case "${PROMPT_OS_COLOR:-blue}" in
		red)  _os_color="${_theme_color_red}" ;;
		blue) _os_color="${_theme_color_blue}" ;;
		*)    _os_color="${_theme_color_blue}" ;;
	esac

	local _user_color="${_theme_color_green}" _user_icon_color="${_theme_color_blue}" _prompt_symbol="\$" _prompt_symbol_color="${_theme_color_cyan}" _terminal_color="${_theme_color_blue}"
	if [ "${EUID:-$(id -u)}" -eq 0 ]; then
		_user_icon_color="${_theme_color_red}"
		if [ "${_mode}" = "tty" ]; then
			_user_color="${_theme_color_red}"
			_terminal_color="${_theme_color_red}"
		else
			_user_color="${_theme_color_magenta}"
		fi
		_prompt_symbol="#"
		_prompt_symbol_color="${_theme_color_red}"
	fi

	local _branch _is_dirty
	_git_branch

	local _base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
	if [ "${_mode}_${_style}" != "${_LOADED_PROMPT_STYLE_BASH:-}" ]; then
		if [ -f "${_base_dir}/theme/styles/${_mode}/${_style}.sh" ]; then
			. "${_base_dir}/theme/styles/${_mode}/${_style}.sh"
			_LOADED_PROMPT_STYLE_BASH="${_mode}_${_style}"
		fi
	fi

	if command -v _theme_render > "/dev/null" 2>&1; then
		_theme_render
	fi
}

case "${PROMPT_COMMAND:-}" in
	*_update_prompt*) ;;
	*) PROMPT_COMMAND="_update_prompt${PROMPT_COMMAND:+; }${PROMPT_COMMAND:-}" ;;
esac
