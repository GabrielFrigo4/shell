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

_trim_str() {
	_trimmed="$1"
	if [ "${#_trimmed}" -gt "$2" ]; then
		local _target=$(( $2 - 1 ))
		while [ "${#_trimmed}" -gt "${_target}" ]; do
			_trimmed="${_trimmed%?}"
		done
		_trimmed="${_trimmed}$3"
	fi
}

_git_branch() {
	_branch=""
	_is_dirty=""
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		_branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		[ -n "${_branch}" ] && _is_dirty="$(command git status --short -uno 2> "/dev/null" | command tail -n 1)"
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		_branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
	fi
}

_update_prompt() {
	local _u_color _sym
	if [ "$(command id -u)" -eq 0 ]; then
		_u_color="\[\e[1;91m\]"
		_sym="#"
	else
		_u_color="\[\e[1;92m\]"
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

	local _branch _is_dirty
	_git_branch

	local _budget _max_pwd _max_branch
	local _pwd_len="${#_pwd}"
	local _branch_len="${#_branch}"

	if _is_raw_tty; then
		_trim_str "${_user}" 14 "~"
		_user="${_trimmed}"
		_trim_str "${_host}" 12 "~"
		_host="${_trimmed}"

		local _base_cost=91
		local _git_frame=0
		[ -n "${_branch}" ] && _git_frame=24
		[ -n "${_is_dirty}" ] && [ -n "${_branch}" ] && _git_frame=$(( _git_frame + 8 ))
		local _fixed_used=$(( _base_cost + ${#_host} + ${#_user} + _git_frame ))
		_budget=$(( 190 - _fixed_used ))
		[ "${_budget}" -lt 6 ] && _budget=6

		if [ -n "${_branch}" ]; then
			if [ $(( _pwd_len + _branch_len )) -le "${_budget}" ]; then
				_max_pwd="${_pwd_len}"
				_max_branch="${_branch_len}"
			else
				local _half=$(( _budget / 2 ))
				if [ "${_pwd_len}" -lt "${_half}" ]; then
					_max_pwd="${_pwd_len}"
					_max_branch=$(( _budget - _pwd_len ))
				elif [ "${_branch_len}" -lt "${_half}" ]; then
					_max_branch="${_branch_len}"
					_max_pwd=$(( _budget - _branch_len ))
				else
					_max_pwd="${_half}"
					_max_branch=$(( _budget - _half ))
				fi
			fi
			_trim_str "${_branch}" "${_max_branch}" "~"
			_branch="${_trimmed}"
		else
			_max_pwd="${_budget}"
		fi

		_trim_str "${_pwd}" "${_max_pwd}" "~"
		_pwd="${_trimmed}"

		local _git_info=""
		if [ -n "${_branch}" ]; then
			local _ind=""
			[ -n "${_is_dirty}" ] && _ind="${_c_yellow}*"
			_git_info=" ${_c_blue}(${_c_red}${_branch}${_ind}${_c_blue})"
		fi

		export PS1="${_u_color}${_user}${_c_blue}@${_c_magenta}${_host} ${_c_blue}(${_c_cyan}sh${_c_blue})${_c_gray}:[${_c_yellow}${_pwd}${_c_gray}]${_git_info} ${_c_cyan}${_sym}${_c_reset} "
	else
		_trim_str "${_user}" 12 "…"
		_user="${_trimmed}"

		local _os_icon="${PROMPT_OS_ICON:- }"
		_trim_str "${_os_icon}" 4 ""
		_os_icon="${_trimmed}"

		local _os_name="${PROMPT_OS_NAME:-15.1}"
		_trim_str "${_os_name}" 6 "…"
		_os_name="${_trimmed}"

		local _os_color
		case "${PROMPT_OS_COLOR:-red}" in
			red)  _os_color="${_c_red}" ;;
			blue) _os_color="${_c_blue}" ;;
			*)    _os_color="${_c_blue}" ;;
		esac

		local _base_cost=122
		local _git_frame=0
		[ -n "${_branch}" ] && _git_frame=33
		[ -n "${_is_dirty}" ] && [ -n "${_branch}" ] && _git_frame=$(( _git_frame + 1 ))
		local _fixed_used=$(( _base_cost + ${#_os_name} + ${#_user} + _git_frame ))
		_budget=$(( 186 - _fixed_used ))
		[ "${_budget}" -lt 4 ] && _budget=4

		if [ -n "${_branch}" ]; then
			if [ $(( _pwd_len + _branch_len )) -le "${_budget}" ]; then
				_max_pwd="${_pwd_len}"
				_max_branch="${_branch_len}"
			else
				local _half=$(( _budget / 2 ))
				if [ "${_pwd_len}" -lt "${_half}" ]; then
					_max_pwd="${_pwd_len}"
					_max_branch=$(( _budget - _pwd_len ))
				elif [ "${_branch_len}" -lt "${_half}" ]; then
					_max_branch="${_branch_len}"
					_max_pwd=$(( _budget - _branch_len ))
				else
					_max_pwd="${_half}"
					_max_branch=$(( _budget - _half ))
				fi
			fi
			_trim_str "${_branch}" "${_max_branch}" "…"
			_branch="${_trimmed}"
		else
			_max_pwd="${_budget}"
		fi

		_trim_str "${_pwd}" "${_max_pwd}" "…"
		_pwd="${_trimmed}"

		local _git_info=""
		if [ -n "${_branch}" ]; then
			local _ind=""
			[ -n "${_is_dirty}" ] && _ind="*"
			_git_info=" ❮${_c_red}󰊢 ${_c_magenta}${_branch}${_c_del}${_ind}❯"
		fi

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
