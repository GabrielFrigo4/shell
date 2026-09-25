### ================================
### PTY PILL PROMPT THEME
### ================================

_theme_layout() {
	_trim_string "${_user}" 10 "~"
	_user="${_trimmed}"
	_trim_string "${_os_name}" 5 "~"
	_os_name="${_trimmed}"

	_git_frame_string=""
	local _indicator=""
	if [ -n "${_branch}" ]; then
		[ -n "${_is_dirty}" ] && _indicator="*"
		_git_frame_string=" ${_theme_color_red}󰊢 ${_theme_color_magenta}${_indicator}"
	fi

	_fixed_string="${_theme_color_delimiter}${_os_color}${_os_icon}${_theme_color_magenta}${_os_name} ${_theme_color_blue} ${_theme_color_magenta}${_shell_name}${_theme_color_delimiter} ${_theme_color_yellow} ${_theme_color_cyan} ${_user_icon_color:-${_theme_color_blue}} ${_user_color}${_user}${_git_frame_string} ${_terminal_color}${_theme_color_reset} "
}

_theme_render() {
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _indicator=""
		[ -n "${_is_dirty}" ] && _indicator="*"
		_git_info=" ${_theme_color_red}󰊢 ${_theme_color_magenta}${_branch}${_indicator}"
	fi

	PS1="${_theme_color_delimiter}${_os_color}${_os_icon}${_theme_color_magenta}${_os_name} ${_theme_color_blue} ${_theme_color_magenta}${_shell_name}${_theme_color_delimiter} ${_theme_color_yellow} ${_theme_color_cyan}${_pwd} ${_user_icon_color:-${_theme_color_blue}} ${_user_color}${_user}${_git_info} ${_terminal_color}${_theme_color_reset} "
	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
