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
		_git_frame_str=" ${_c_blue}(${_c_red}${_ind}${_c_blue})"
	fi

	_fixed_str="${_u_color}${_user}${_c_blue}@${_c_magenta}${_host}${_c_gray}:${_c_yellow}${_git_frame_str} ${_sym_color}${_sym}${_c_reset} "
}

_theme_render() {
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _ind=""
		[ -n "${_is_dirty}" ] && _ind="*"
		_git_info=" ${_c_blue}(${_c_red}${_branch}${_ind}${_c_blue})"
	fi

	PS1="${_u_color}${_user}${_c_blue}@${_c_magenta}${_host}${_c_gray}:${_c_yellow}${_pwd}${_git_info} ${_sym_color}${_sym}${_c_reset} "
	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
