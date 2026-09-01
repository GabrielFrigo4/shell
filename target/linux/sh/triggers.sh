### ================================
### PRECISION TRIGGERS
### ================================

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
