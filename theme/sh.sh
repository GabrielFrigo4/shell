### ================================
### SHELL APPEARANCE (SH)
### ================================

_git_branch() {
	_git_branch=" "
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		local _branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		if [ -n "${_branch}" ]; then
			local _is_dirty="$(command git status --short -uno 2> "/dev/null" | command tail -n1)"
			local _indicator=""
			[ -n "${_is_dirty}" ] && _indicator="${Y}*"
			_git_branch=" ${B}(${R}${_branch}${_indicator}${B})${z} "
		fi
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		local _branch="$(got branch 2> "/dev/null" || got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
		if [ -n "${_branch}" ]; then
			_git_branch=" ${B}(${M}${_branch}${B})${z} "
		fi
	fi
}

_update_prompt() {
	local z="\[\e[0m\]"
	local R="\[\e[1;91m\]"
	local G="\[\e[1;92m\]"
	local Y="\[\e[1;93m\]"
	local B="\[\e[1;94m\]"
	local M="\[\e[1;95m\]"
	local C="\[\e[1;96m\]"
	local K="\[\e[1;90m\]"

	local _git_branch
	_git_branch

	local _u
	if [ "$(command id -u)" -eq 0 ]; then _u="${R}"; else _u="${G}"; fi

	local _cur_user="$(command id -un)"
	local _cur_host="$(command hostname -s)"
	local _cur_dir="${PWD##*/}"
	[ "${PWD}" = "${HOME}" ] && _cur_dir="~"
	[ "${PWD}" = "/" ] && _cur_dir="/"

	export PS1="${_u}${_cur_user}${B}@${M}${_cur_host} ${B}(${C}sh${B})${K}:${K}[${Y}${_cur_dir}${K}]${z}${_git_branch}${C}\$${z} "
}

### --------------------------------
### Precision Triggers
### --------------------------------
cd() {
	if command -v builtin > "/dev/null" 2>&1; then
		builtin cd "$@"
	else
		command cd "$@"
	fi
	local _ret=$?
	_update_prompt
	return ${_ret}
}

git() {
	command git "$@"
	local _ret=$?
	_update_prompt
	return ${_ret}
}

got() {
	command got "$@"
	local _ret=$?
	_update_prompt
	return ${_ret}
}

alias :="_update_prompt; command :"
_update_prompt
