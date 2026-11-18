# ----------------------------------------------------------------
# Library: Cross-Platform Hypervisor & Container Dispatcher
# ----------------------------------------------------------------

### ================================
### HYPERVISOR SUBMODULE LOADER
### ================================
_hypervisor_lib_base="${SHELL_REPO_DIR:-}"
if [ -z "${_hypervisor_lib_base}" ] || [ ! -d "${_hypervisor_lib_base}/library/hypervisor" ]; then
	if [ -d "./library/hypervisor" ]; then
		_hypervisor_lib_base="."
	elif [ -d "/usr/local/share/shell/library/hypervisor" ]; then
		_hypervisor_lib_base="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell/library/hypervisor" ]; then
		_hypervisor_lib_base="${HOME}/.local/share/shell"
	fi
fi

for _hypervisor_part in common.sh managers.sh; do
	[ -f "${_hypervisor_lib_base}/library/hypervisor/${_hypervisor_part}" ] && . "${_hypervisor_lib_base}/library/hypervisor/${_hypervisor_part}"
done
unset _hypervisor_lib_base _hypervisor_part
