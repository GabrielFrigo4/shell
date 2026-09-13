### ================================
### KORN SHELL APPEARANCE
### ================================

_esc="$(printf '\033')"
_c_reset="\[${_esc}[0m\]"
_c_bold="\[${_esc}[1m\]"
_c_red="\[${_esc}[1;31m\]"
_c_green="\[${_esc}[1;32m\]"
_c_yellow="\[${_esc}[1;33m\]"
_c_blue="\[${_esc}[1;34m\]"
_c_magenta="\[${_esc}[1;35m\]"
_c_cyan="\[${_esc}[1;36m\]"
_c_white="\[${_esc}[1;37m\]"

_git_branch() {
	_branch=""
	_is_dirty=""
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		_branch="$(command git symbolic-ref --quiet --short HEAD 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		[ -n "${_branch}" ] && _is_dirty="$(command git status --porcelain=v1 --untracked-files=no 2> "/dev/null" | command head -n 1)"
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		_branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
	fi
}

_ksh_prompt() {
	local _pwd="${PWD:-$(command pwd)}"
	if [ "${_pwd}" = "${HOME}" ]; then
		_pwd="~"
	elif [ "${_pwd}" = "/" ]; then
		_pwd="/"
	else
		_pwd="${_pwd##*/}"
		[ -z "${_pwd}" ] && _pwd="/"
	fi

	local _branch _is_dirty
	_git_branch

	local _git_str=""
	if [ -n "${_branch}" ]; then
		local _indicator=""
		[ -n "${_is_dirty}" ] && _indicator="${_c_yellow}*"
		if _is_raw_tty; then
			_git_str=" ${_c_blue}(${_c_red}${_branch}${_indicator}${_c_blue})${_c_reset}"
		else
			_git_str=" ❮${_c_red}󰊢 ${_c_magenta}${_branch}${_indicator}${_c_yellow}❯${_c_reset}"
		fi
	fi

	local _user="${USER:-${LOGNAME:-$(command id -un 2> "/dev/null" || echo "user")}}"
	local _u_color="${_c_green}"
	local _sym="\$"
	if [ "${EUID:-$(id -u 2> "/dev/null")}" -eq 0 ]; then
		_u_color="${_c_red}"
		_sym="#"
	fi

	if _is_raw_tty; then
		printf "%s" "${_u_color}${_user}${_c_blue}@\h ${_c_blue}(${_c_cyan}ksh${_c_blue}):[${_c_yellow}${_pwd}${_c_reset}]${_git_str} ${_c_cyan}${_sym}${_c_reset} "
	else
		printf "%s" "${_c_yellow}🐡 ${_u_color}${_user}${_c_reset}:${_c_blue}${_pwd}${_c_reset}${_git_str} ${_c_cyan}${_sym}${_c_reset} "
	fi
}

export PS1='$(_ksh_prompt)'
