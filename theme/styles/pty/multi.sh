### ================================
### PTY MULTI PROMPT THEME
### ================================

_theme_render() {
	local _delimiter="${_theme_color_gray}"
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _indicator=""
		[ -n "${_is_dirty}" ] && _indicator="${_theme_color_yellow}*"
		_git_info=" ${_delimiter}❮${_theme_color_red}󰊢 ${_theme_color_magenta}${_branch}${_indicator}${_delimiter}❯"
	fi

	local _time
	local _date
	if [ -n "${ZSH_VERSION:-}" ]; then
		_time="%D{%H:%M:%S}"
		_date="%D{%d/%m/%y}"
	elif [ -n "${BASH_VERSION:-}" ]; then
		_time="\t"
		_date="\D{%d/%m/%y}"
	else
		_time="$(command date +%H:%M:%S 2> "/dev/null" || true)"
		_date="$(command date +%d/%m/%y 2> "/dev/null" || true)"
	fi

	local _newline="
"

	PS1="${_newline}${_delimiter}${_os_color}${_os_icon}${_theme_color_magenta}${_os_name}${_delimiter}─${_theme_color_blue} ${_theme_color_magenta}${_shell_name}${_delimiter}"
	PS1="${PS1}${_newline}${_delimiter}┌──❮ ${_theme_color_green} ${_time}${_delimiter} ❯─❮ ${_theme_color_green} ${_date}${_delimiter} ❯─❮ ${_theme_color_yellow} ${_theme_color_cyan}${_pwd}${_delimiter} ❯─ ❮${_theme_color_blue} ${_user_color}${_user}${_delimiter}❯${_git_info}"
	PS1="${PS1}${_newline}${_delimiter}└─${_terminal_color}${_theme_color_reset} "

	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
