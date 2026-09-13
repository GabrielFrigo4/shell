### ================================
### KORN SHELL APPEARANCE
### ================================

_esc="$(printf '\033')"
_c_reset="\[${_esc}[0m\]"
_c_bold="\[${_esc}[1m\]"
_c_del="\[${_esc}[0;33m\]"

_c_red="\[${_esc}[1;91m\]"
_c_green="\[${_esc}[1;92m\]"
_c_yellow="\[${_esc}[1;93m\]"
_c_blue="\[${_esc}[1;94m\]"
_c_magenta="\[${_esc}[1;95m\]"
_c_cyan="\[${_esc}[1;96m\]"
_c_gray="\[${_esc}[1;90m\]"

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

	local _user="${USER:-${LOGNAME:-$(command id -un 2> "/dev/null" || echo "user")}}"
	local _u_color="${_c_green}"
	local _term_color="${_c_blue}"
	local _sym="\$"
	if [ "${EUID:-$(id -u 2> "/dev/null")}" -eq 0 ]; then
		_u_color="${_c_red}"
		_term_color="${_c_red}"
		_sym="#"
	fi

	local _os_icon="${PROMPT_OS_ICON:-🐡 }"
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_KERNEL_RELEASE:-$(uname -r 2> "/dev/null" || echo "OpenBSD")}}"
	_os_name="${_os_name%%-*}"

	local _os_color="${_c_yellow}"
	case "${PROMPT_OS_COLOR:-yellow}" in
		red)    _os_color="${_c_red}" ;;
		blue)   _os_color="${_c_blue}" ;;
		yellow) _os_color="${_c_yellow}" ;;
		*)      _os_color="${_c_yellow}" ;;
	esac

	if _is_raw_tty; then
		local _git_info=""
		if [ -n "${_branch}" ]; then
			local _ind=""
			[ -n "${_is_dirty}" ] && _ind="${_c_yellow}*"
			_git_info=" ${_c_blue}(${_c_red}${_branch}${_ind}${_c_blue})"
		fi
		printf "%s" "${_u_color}${_user}${_c_blue}@\h ${_c_blue}(${_c_cyan}ksh${_c_blue})${_c_gray}:[${_c_yellow}${_pwd}${_c_gray}]${_git_info} ${_term_color}${_sym}${_c_reset} "
	else
		local _git_info=""
		if [ -n "${_branch}" ]; then
			local _ind=""
			[ -n "${_is_dirty}" ] && _ind="${_c_yellow}*"
			_git_info=" ${_c_red}󰊢 ${_c_magenta}${_branch}${_ind}"
		fi
		printf "%s" "${_c_del}${_os_color}${_os_icon}${_c_magenta}${_os_name} ${_c_blue} ${_c_magenta}ksh${_c_del} ${_c_bold} ${_c_cyan}${_pwd} ${_c_blue} ${_u_color}${_user}${_git_info} ${_term_color}${_c_reset} "
	fi
}

export PS1='$(_ksh_prompt)'
