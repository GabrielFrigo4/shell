### ================================
### SHELL APPEARANCE
### ================================

_c_reset="\[\e[0m\]"
_c_del_start="\[\e[1;33m\]"
_c_del="\[\e[33m\]"
_c_red="\[\e[91m\]"
_c_green="\[\e[92m\]"
_c_yellow="\[\e[93m\]"
_c_blue="\[\e[94m\]"
_c_magenta="\[\e[95m\]"
_c_cyan="\[\e[96m\]"
_c_gray="\[\e[90m\]"

_git_branch() {
	_git_info=""
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		local _branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		if [ -n "${_branch}" ]; then
			local _is_dirty="$(command git status --short -uno 2> "/dev/null" | command tail -n 1)"
			local _indicator=""
			if _is_raw_tty; then
				[ -n "${_is_dirty}" ] && _indicator="${_c_yellow}*"
				_git_info=" ${_c_blue}(${_c_red}${_branch}${_indicator}${_c_blue})${_c_reset}"
			else
				[ -n "${_is_dirty}" ] && _indicator="${_c_yellow}*"
				_git_info=" ❮${_c_red}󰊢 ${_c_magenta}${_branch}${_indicator}${_c_del}❯"
			fi
		fi
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		local _branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
		if [ -n "${_branch}" ]; then
			if _is_raw_tty; then
				_git_info=" ${_c_blue}(${_c_magenta}${_branch}${_c_blue})${_c_reset}"
			else
				_git_info=" ❮${_c_red}󰊢 ${_c_magenta}${_branch}${_c_del}❯"
			fi
		fi
	fi
}

_update_prompt() {
	local _u_color _sym
	if [ "$(command id -u)" -eq 0 ]; then
		_u_color="${_c_red}"
		_sym="#"
	else
		_u_color="${_c_green}"
		_sym="\$"
	fi

	local _user="${USER:-$(command id -un)}"
	local _host="$(command uname -n 2> "/dev/null" | command cut -d. -f1)"
	[ -z "${_host}" ] && _host="${HOSTNAME%%.*}"

	local _pwd="${PWD:-$(command pwd)}"
	if [ "${_pwd}" = "${HOME}" ]; then
		_pwd="~"
	elif [ "${_pwd}" = "/" ]; then
		_pwd="/"
	else
		_pwd="${_pwd##*/}"
		[ -z "${_pwd}" ] && _pwd="/"
	fi

	local _git_info
	_git_branch

	if _is_raw_tty; then
		export PS1="${_u_color}${_user}${_c_blue}@${_c_magenta}${_host} ${_c_blue}(${_c_cyan}sh${_c_blue})${_c_gray}:[${_c_yellow}${_pwd}${_c_gray}]${_c_reset}${_git_info} ${_c_cyan}${_sym}${_c_reset} "
	else
		local _os_icon="${PROMPT_OS_ICON:- }"
		local _os_name="${PROMPT_OS_NAME:-15.1}"
		local _os_color
		case "${PROMPT_OS_COLOR:-red}" in
			red)  _os_color="${_c_red}" ;;
			blue) _os_color="${_c_blue}" ;;
			*)    _os_color="${_c_blue}" ;;
		esac

		export PS1="${_c_del_start}${_os_color}${_os_icon}${_c_magenta}${_os_name}${_c_del} ❮${_c_yellow} ${_c_cyan}${_pwd}${_c_del}❯ ❮${_c_blue} ${_u_color}${_user}${_c_del}❯${_git_info} ${_c_blue}${_c_reset} "
	fi
}

### --------------------------------
### Precision Triggers
### --------------------------------
_create_trigger() {
	for _cmd in "$@"; do
		eval "
		${_cmd}() {
			command ${_cmd} \"\$@\"
			local _ret=\$?
			_update_prompt
			return \${_ret}
		}
		"
	done
}

_create_trigger cd git got

alias :="_update_prompt; command :"
_update_prompt
