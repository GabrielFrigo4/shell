### ================================
### SHELL APPEARANCE (SH)
### ================================

_git_branch() {
	_git_branch=""
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		local _branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		if [ -n "${_branch}" ]; then
			local _is_dirty="$(command git status --short -uno 2> "/dev/null" | command tail -n1)"
			local _indicator=""
			[ -n "${_is_dirty}" ] && _indicator="\[\e[1;93m\]*"
			_git_branch=" \[\e[1;94m\](\[\e[1;91m\]${_branch}${_indicator}\[\e[1;94m\])\[\e[0m\]"
		fi
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		local _branch="$(got branch 2> "/dev/null" || got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
		if [ -n "${_branch}" ]; then
			_git_branch=" \[\e[1;94m\](\[\e[1;95m\]${_branch}\[\e[1;94m\])\[\e[0m\]"
		fi
	fi
}

_update_prompt() {
	local _u _sym
	if [ "$(command id -u)" -eq 0 ]; then
		_u="\[\e[1;91m\]"
		_sym="#"
	else
		_u="\[\e[1;92m\]"
		_sym="\$"
	fi

	local _git_branch
	_git_branch

	export PS1="${_u}\u\[\e[1;94m\]@\[\e[1;95m\]\h \[\e[1;94m\](\[\e[1;96m\]sh\[\e[1;94m\])\[\e[1;90m\]:[\[\e[1;93m\]\W\[\e[1;90m\]]\[\e[0m\]${_git_branch} \[\e[1;96m\]${_sym}\[\e[0m\] "
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
