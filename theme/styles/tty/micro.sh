### ================================
### TTY MICRO PROMPT THEME
### ================================

_theme_layout() {
	_trim_str "${_user}" 10 "~"
	_user="${_trimmed}"
	_trim_str "${_host}" 10 "~"
	_host="${_trimmed}"

	local _ind=""
	if [ -n "${_branch}" ]; then
		[ -n "${_is_dirty}" ] && _ind="*"
		_git_frame_str=" ${_theme_color_blue}(${_theme_color_red}${_ind}${_theme_color_blue})"
	fi

	_fixed_str="${_u_color}${_user}${_theme_color_blue}@${_theme_color_magenta}${_host}${_theme_color_gray}:${_theme_color_yellow}${_git_frame_str} ${_sym_color}${_sym}${_theme_color_reset} "
}

_theme_render() {
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _ind=""
		[ -n "${_is_dirty}" ] && _ind="*"
		_git_info=" ${_theme_color_blue}(${_theme_color_red}${_branch}${_ind}${_theme_color_blue})"
	fi

	PS1="${_u_color}${_user}${_theme_color_blue}@${_theme_color_magenta}${_host}${_theme_color_gray}:${_theme_color_yellow}${_pwd}${_git_info} ${_sym_color}${_sym}${_theme_color_reset} "
	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
