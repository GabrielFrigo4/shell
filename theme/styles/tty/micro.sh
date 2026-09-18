### ================================
### TTY MICRO PROMPT THEME
### ================================

_theme_layout() {
	_trim_string "${_user}" 10 "~"
	_user="${_trimmed}"
	_trim_string "${_host}" 10 "~"
	_host="${_trimmed}"

	_git_frame_string=""
	local _indicator=""
	if [ -n "${_branch}" ]; then
		[ -n "${_is_dirty}" ] && _indicator="*"
		_git_frame_string=" ${_theme_color_blue}(${_theme_color_red}${_indicator}${_theme_color_blue})"
	fi

	_fixed_string="${_user_color}${_user}${_theme_color_blue}@${_theme_color_magenta}${_host}${_theme_color_gray}:${_theme_color_yellow}${_git_frame_string} ${_prompt_symbol_color}${_prompt_symbol}${_theme_color_reset} "
}

_theme_render() {
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _indicator=""
		[ -n "${_is_dirty}" ] && _indicator="*"
		_git_info=" ${_theme_color_blue}(${_theme_color_red}${_branch}${_indicator}${_theme_color_blue})"
	fi

	PS1="${_user_color}${_user}${_theme_color_blue}@${_theme_color_magenta}${_host}${_theme_color_gray}:${_theme_color_yellow}${_pwd}${_git_info} ${_prompt_symbol_color}${_prompt_symbol}${_theme_color_reset} "
	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
