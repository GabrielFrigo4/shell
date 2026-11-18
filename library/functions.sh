# ----------------------------------------------------------------
# Library: VCS & General Utilities Dispatcher
# ----------------------------------------------------------------

### ================================
### FUNCTIONS SUBMODULE LOADER
### ================================
_functions_lib_base="${SHELL_REPO_DIR:-}"
if [ -z "${_functions_lib_base}" ] || [ ! -d "${_functions_lib_base}/library/functions" ]; then
	if [ -d "./library/functions" ]; then
		_functions_lib_base="."
	elif [ -d "/usr/local/share/shell/library/functions" ]; then
		_functions_lib_base="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell/library/functions" ]; then
		_functions_lib_base="${HOME}/.local/share/shell"
	fi
fi

for _functions_part in git.sh utils.sh; do
	[ -f "${_functions_lib_base}/library/functions/${_functions_part}" ] && . "${_functions_lib_base}/library/functions/${_functions_part}"
done
unset _functions_lib_base _functions_part
