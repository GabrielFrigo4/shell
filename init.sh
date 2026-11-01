#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: Universal Shell Runtime Initializer
# ----------------------------------------------------------------

_init_src="${BASH_SOURCE[0]:-${0}}"
case "${_init_src}" in
	-*|"") _init_dir="" ;;
	*/*)  _init_dir="${_init_src%/*}" ;;
	*)    _init_dir="" ;;
esac

if [ -n "${_init_dir}" ] && [ -d "${_init_dir}" ]; then
	SHELL_REPO_DIR="$(cd "${_init_dir}" && pwd)"
elif [ -z "${SHELL_REPO_DIR:-}" ]; then
	if [ -f "${PWD}/shell.sh" ] && [ -d "${PWD}/core" ]; then
		SHELL_REPO_DIR="${PWD}"
	elif [ -d "/usr/local/share/shell" ]; then
		SHELL_REPO_DIR="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell" ]; then
		SHELL_REPO_DIR="${HOME}/.local/share/shell"
	else
		SHELL_REPO_DIR="${PWD}"
	fi
fi
export SHELL_REPO_DIR
unset _init_src _init_dir

. "${SHELL_REPO_DIR}/shell.sh" "$@"
