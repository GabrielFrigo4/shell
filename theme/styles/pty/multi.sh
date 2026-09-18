### ================================
### PTY MULTI PROMPT THEME
### ================================

_theme_render() {
	local _git_info=""
	if [ -n "${_branch}" ]; then
		local _ind=""
		[ -n "${_is_dirty}" ] && _ind="${_c_yellow}*"
		_git_info=" ❮${_c_red}󰊢 ${_c_magenta}${_branch}${_ind}${_c_del}❯"
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

	local _nl="
"

	PS1="${_nl}${_c_del}${_os_color}${_os_icon}${_c_magenta}${_os_name}${_c_del}─${_c_blue} ${_c_magenta}${_sh_name}${_c_del}"
	PS1="${PS1}${_nl}${_c_del}┌──❮ ${_c_green} ${_time}${_c_del} ❯─❮ ${_c_green} ${_date}${_c_del} ❯─❮ ${_c_yellow} ${_c_cyan}${_pwd}${_c_del} ❯─ ❮${_c_blue} ${_u_color}${_user}${_c_del}❯${_git_info}"
	PS1="${PS1}${_nl}${_c_del}└─${_term_color}${_c_reset} "

	[ -n "${ZSH_VERSION:-}" ] && export PROMPT="${PS1}"
	return 0
}
