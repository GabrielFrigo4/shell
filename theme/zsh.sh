### ================================
### Z SHELL APPEARANCE
### ================================

setopt PROMPT_SUBST

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"

_update_prompt() {
	_setup_colors

	local _user="${USER:-$(command id -un)}"
	local _host="${(%):-%m}"
	local _pwd="${(%):-%c}"
	local _sh_name="zsh"
	local _os_icon="${PROMPT_OS_ICON:- }"
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_KERNEL_RELEASE:-$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "Linux")}}"
	_os_name="${_os_name%%-*}"

	local _os_color
	case "${PROMPT_OS_COLOR:-blue}" in
		red)  _os_color="${_c_red}" ;;
		blue) _os_color="${_c_blue}" ;;
		*)    _os_color="${_c_blue}" ;;
	esac

	local _u_color="${_c_green}" _sym="\$" _sym_color="${_c_cyan}" _term_color="${_c_blue}"
	if [ "${EUID:-$(id -u)}" -eq 0 ]; then
		_u_color="${_c_red}"
		_sym="#"
		_sym_color="${_c_red}"
		_term_color="${_c_red}"
	fi

	local _branch _is_dirty
	_git_branch

	local _mode="pty"
	_is_raw_tty && _mode="tty"

	local _style="${PROMPT_STYLE:-multi}"
	[[ "${_mode}" = "tty" ]] && _style="${PROMPT_STYLE:-pill}"
	case "${_style}" in
		micro|pill) ;;
		multi) [[ "${_mode}" = "tty" ]] && _style="pill" ;;
		*) _style="pill" ;;
	esac

	local _base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
	if [[ "${_mode}_${_style}" != "${_LOADED_PROMPT_STYLE_ZSH:-}" ]]; then
		if [[ -f "${_base_dir}/theme/styles/${_mode}/${_style}.sh" ]]; then
			. "${_base_dir}/theme/styles/${_mode}/${_style}.sh"
			_LOADED_PROMPT_STYLE_ZSH="${_mode}_${_style}"
		fi
	fi

	_theme_render
}

autoload -Uz add-zsh-hook 2> "/dev/null" || true
if typeset -f add-zsh-hook > "/dev/null" 2>&1; then
	add-zsh-hook precmd _update_prompt
else
	precmd_functions+=(_update_prompt)
fi

_update_prompt
