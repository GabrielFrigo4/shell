### ================================
### PTY MICRO PROMPT THEME
### ================================

_theme_layout() {
	_trim_str "${_user}" 8 "~"
	_user="${_trimmed}"
	_trim_str "${_os_name}" 5 "~"
	_os_name="${_trimmed}"

	_git_frame_str=""
	local _ind=""
	if [ -n "${_branch}" ]; then
		[ -n "${_is_dirty}" ] && _ind="*"
		_git_frame_str=" ${_theme_color_red}󰊢 ${_theme_color_magenta}${_ind}"
	fi

	_fixed_str="${_os_color}${_os_icon}${_theme_color_magenta}${_os_name} ${_theme_color_yellow} ${_theme_color_cyan} ${_theme_color_blue} ${_u_color}${_user}${_git_frame_str} ${_term_color}${_theme_color_reset} "
}

_theme_render() {
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _ind=""
		[ -n "${_is_dirty}" ] && _ind="*"
		_git_info=" ${_theme_color_red}󰊢 ${_theme_color_magenta}${_branch}${_ind}"
	fi

	PS1="${_os_color}${_os_icon}${_theme_color_magenta}${_os_name} ${_theme_color_yellow} ${_theme_color_cyan}${_pwd} ${_theme_color_blue} ${_u_color}${_user}${_git_info} ${_term_color}${_theme_color_reset} "
	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
