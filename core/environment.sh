### ================================
### CORE ENVIRONMENT
### ================================

export MICRO_TRUECOLOR=1

### --------------------------------
### Auto-correct SHELL
### --------------------------------
_current_shell="$(command ps -p "$$" -o comm= 2> "/dev/null" | command sed 's/^-//')"
_current_shell="${_current_shell##*/}"
if [ -n "${_current_shell}" ]; then
	_shell_path="$(command -v "${_current_shell}" 2> "/dev/null")"
	[ -n "${_shell_path}" ] && [ -x "${_shell_path}" ] && export SHELL="${_shell_path}"
	unset _shell_path
fi
unset _current_shell
