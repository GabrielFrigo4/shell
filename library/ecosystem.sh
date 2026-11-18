# ----------------------------------------------------------------
# Library: Ecosystem Updaters & Maintenance Dispatcher
# ----------------------------------------------------------------

### ================================
### ECOSYSTEM SUBMODULE LOADER
### ================================
_ecosystem_lib_base="${SHELL_REPO_DIR:-}"
if [ -z "${_ecosystem_lib_base}" ] || [ ! -d "${_ecosystem_lib_base}/library/ecosystem" ]; then
	if [ -d "./library/ecosystem" ]; then
		_ecosystem_lib_base="."
	elif [ -d "/usr/local/share/shell/library/ecosystem" ]; then
		_ecosystem_lib_base="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell/library/ecosystem" ]; then
		_ecosystem_lib_base="${HOME}/.local/share/shell"
	fi
fi

for _ecosystem_part in shell.sh profile.sh editors.sh; do
	[ -f "${_ecosystem_lib_base}/library/ecosystem/${_ecosystem_part}" ] && . "${_ecosystem_lib_base}/library/ecosystem/${_ecosystem_part}"
done
unset _ecosystem_lib_base _ecosystem_part
