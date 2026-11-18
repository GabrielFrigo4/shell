# ----------------------------------------------------------------
# Library: System Package, Network & Lifecycle Dispatcher
# ----------------------------------------------------------------

### ================================
### SYSTEM SUBMODULE LOADER
### ================================
_system_lib_base="${SHELL_REPO_DIR:-}"
if [ -z "${_system_lib_base}" ] || [ ! -d "${_system_lib_base}/library/system" ]; then
	if [ -d "./library/system" ]; then
		_system_lib_base="."
	elif [ -d "/usr/local/share/shell/library/system" ]; then
		_system_lib_base="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell/library/system" ]; then
		_system_lib_base="${HOME}/.local/share/shell"
	fi
fi

for _system_part in packages.sh network.sh lifecycle.sh; do
	[ -f "${_system_lib_base}/library/system/${_system_part}" ] && . "${_system_lib_base}/library/system/${_system_part}"
done
unset _system_lib_base _system_part
