### ================================
### Z SHELL APPEARANCE
### ================================

setopt PROMPT_SUBST

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"
unset _base_dir

_update_prompt() {
	_setup_colors

	local _user="${USERNAME:-${USER:-${LOGNAME:-$(command id -un 2> "/dev/null" || echo "user")}}}"
	local _host="${(%):-%m}"
	local _pwd="${(%):-%c}"
	local _shell_name="zsh"
	local _os_icon="${PROMPT_OS_ICON:-${_DETECTED_DISTRO_ICON:- }}"
	if [ -z "${PROMPT_OS_NAME:-}" ] && [ -z "${_DETECTED_DISTRO_VERSION:-}" ] && [ -z "${_THEME_FALLBACK_OS_NAME:-}" ]; then
		_THEME_FALLBACK_OS_NAME="$(_detect_distro_version 2> "/dev/null" || _detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || uname -s 2> "/dev/null" || echo "UNIX")"
	fi
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_DISTRO_VERSION:-${_THEME_FALLBACK_OS_NAME:-UNIX}}}"
	_os_name="${_os_name%%[-+~_]*}"
	if [ -z "${_DETECTED_KERNEL_RELEASE:-}" ] && [ -z "${_THEME_FALLBACK_KERNEL+x}" ]; then
		_THEME_FALLBACK_KERNEL="$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "")"
	fi
	local _kernel_release="${_DETECTED_KERNEL_RELEASE:-${_THEME_FALLBACK_KERNEL:-}}"
	_kernel_release="${_kernel_release%%[-+~_]*}"
	if [ -z "${PROMPT_OS_TYPE:-}" ] && [ -z "${_DETECTED_OS:-}" ] && [ -z "${_THEME_FALLBACK_OS_TYPE:-}" ]; then
		_THEME_FALLBACK_OS_TYPE="$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]' || echo "unix")"
	fi
	local _os_type="${PROMPT_OS_TYPE:-${_DETECTED_OS:-${_THEME_FALLBACK_OS_TYPE:-unix}}}"

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
		red)     _os_color="${_theme_color_red}" ;;
		green)   _os_color="${_theme_color_green}" ;;
		yellow)  _os_color="${_theme_color_yellow}" ;;
		blue)    _os_color="${_theme_color_blue}" ;;
		magenta) _os_color="${_theme_color_magenta}" ;;
		cyan)    _os_color="${_theme_color_cyan}" ;;
		white)   _os_color="${_theme_color_white}" ;;
		*)       _os_color="${_theme_color_blue}" ;;
	esac

	local _user_color="${_theme_color_green}" _user_icon_color="${_theme_color_blue}" _prompt_symbol="\$" _prompt_symbol_color="${_theme_color_cyan}" _terminal_color="${_theme_color_blue}"
	if [ "${EUID:-$(command id -u 2> "/dev/null" || echo 1000)}" -eq 0 ]; then
		_user="root"
		_user_icon_color="${_theme_color_red}"
		_terminal_color="${_theme_color_red}"
		if [ "${_mode}" = "tty" ]; then
			_user_color="${_theme_color_red}"
		else
			_user_color="${_theme_color_magenta}"
		fi
		_prompt_symbol="#"
		_prompt_symbol_color="${_theme_color_red}"
	fi

	local _branch _is_dirty
	_git_branch

	typeset -g _theme_ps1_pwd _theme_ps1_branch _theme_ps1_user _theme_ps1_host _theme_ps1_os_name _theme_ps1_os_icon _theme_ps1_kernel
	if [[ -o promptsubst ]]; then
		_theme_ps1_pwd="${_pwd//\%/%%}"
		_pwd='${_theme_ps1_pwd}'
		if [ -n "${_branch}" ]; then
			_theme_ps1_branch="${_branch//\%/%%}"
			_branch='${_theme_ps1_branch}'
		else
			_theme_ps1_branch=""
		fi
		_theme_ps1_user="${_user//\%/%%}"
		_user='${_theme_ps1_user}'
		_theme_ps1_host="${_host//\%/%%}"
		_host='${_theme_ps1_host}'
		_theme_ps1_os_name="${_os_name//\%/%%}"
		_os_name='${_theme_ps1_os_name}'
		_theme_ps1_os_icon="${_os_icon//\%/%%}"
		_os_icon='${_theme_ps1_os_icon}'
		if [ -n "${_kernel_release}" ]; then
			_theme_ps1_kernel="${_kernel_release//\%/%%}"
			_kernel_release='${_theme_ps1_kernel}'
		else
			_theme_ps1_kernel=""
		fi
	else
		_pwd="${_pwd//\%/%%}"
		_branch="${_branch//\%/%%}"
		_user="${_user//\%/%%}"
		_host="${_host//\%/%%}"
		_os_name="${_os_name//\%/%%}"
		_os_icon="${_os_icon//\%/%%}"
		_kernel_release="${_kernel_release//\%/%%}"
	fi

	local _base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
	if [ "${_mode}_${_style}" != "${_LOADED_PROMPT_STYLE_ZSH:-}" ]; then
		if [ -f "${_base_dir}/theme/styles/${_mode}/${_style}.sh" ]; then
			. "${_base_dir}/theme/styles/${_mode}/${_style}.sh"
			_LOADED_PROMPT_STYLE_ZSH="${_mode}_${_style}"
		fi
	fi

	if command -v _theme_render > "/dev/null" 2>&1; then
		_theme_render
	fi

	if [ -t 1 ]; then
		if [ "${_mode}" = "tty" ]; then
			[ "${TERM:-}" = "linux" ] && [ "${_os_type}" = "linux" ] && echo -n $'\e%G\e[?16;238;0c'
		else
			echo -n $'\e[1 q'
		fi
	fi
}

autoload -Uz add-zsh-hook 2> "/dev/null" || true
if typeset -f add-zsh-hook > "/dev/null" 2>&1; then
	add-zsh-hook precmd _update_prompt
else
	precmd_functions+=(_update_prompt)
fi

if [ -t 1 ]; then
	_update_prompt
fi
