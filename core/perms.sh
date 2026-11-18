# ----------------------------------------------------------------
# Core: Repository Permissions & Self-Healing
# ----------------------------------------------------------------

### ================================
### PERMISSIONS & GIT SELF-HEAL
### ================================
_perms_resolve_git_dir() {
	local _repo_dir="${1:-}"
	local _git_dir=""
	local _gitlink=""
	local _git_rel=""
	if [ -d "${_repo_dir}/.git" ]; then
		_git_dir="${_repo_dir}/.git"
	elif [ -f "${_repo_dir}/.git" ]; then
		IFS= read -r _gitlink < "${_repo_dir}/.git" 2> "/dev/null" || _gitlink=""
		case "${_gitlink}" in
			"gitdir: "*)
				_git_rel="${_gitlink#gitdir: }"
				case "${_git_rel}" in
					/*) _git_dir="${_git_rel}" ;;
					*)  _git_dir="${_repo_dir}/${_git_rel}" ;;
				esac
				;;
		esac
		if [ -z "${_git_dir}" ] && command -v git > "/dev/null" 2>&1; then
			_git_dir="$(command git -C "${_repo_dir}" rev-parse --absolute-git-dir 2> "/dev/null" || true)"
		fi
	fi
	printf '%s\n' "${_git_dir}"
}

_perms_apply_entrypoints() {
	local _repo_dir="${1:-}"
	local _script_item=""
	local _first_line=""
	if [ -d "${_repo_dir}/.githooks" ]; then
		chmod 0755 "${_repo_dir}/.githooks/"* 2> "/dev/null" || true
	fi
	if [ -d "${_repo_dir}/.scripts" ]; then
		for _script_item in "${_repo_dir}/.scripts/"*; do
			if [ -f "${_script_item}" ]; then
				read -r _first_line < "${_script_item}" 2> "/dev/null" || _first_line=""
				case "${_first_line}" in
					"#!"*) chmod 0755 "${_script_item}" 2> "/dev/null" || true ;;
				esac
			fi
		done
	fi
	[ -f "${_repo_dir}/shell.sh" ] && chmod 0755 "${_repo_dir}/shell.sh" 2> "/dev/null" || true
	[ -f "${_repo_dir}/init.sh" ] && chmod 0755 "${_repo_dir}/init.sh" 2> "/dev/null" || true
	[ -f "${_repo_dir}/install.sh" ] && chmod 0755 "${_repo_dir}/install.sh" 2> "/dev/null" || true
	[ -f "${_repo_dir}/benchmark.sh" ] && chmod 0755 "${_repo_dir}/benchmark.sh" 2> "/dev/null" || true
}

_self_heal_perms() {
	local _repo_dir="${1:-${_SHELL_ROOT:-${SHELL_REPO_DIR:-}}}"
	[ -n "${_repo_dir}" ] && [ -d "${_repo_dir}" ] || return 0

	local _git_dir=""
	if [ -d "${_repo_dir}/.git" ]; then
		_git_dir="${_repo_dir}/.git"
	elif [ -f "${_repo_dir}/.git" ]; then
		_git_dir="$(_perms_resolve_git_dir "${_repo_dir}")"
	fi

	if [ -x "${_repo_dir}/shell.sh" ] && [ -x "${_repo_dir}/.scripts/emacs-client" ] && { [ -z "${_git_dir}" ] || [ ! -d "${_git_dir}/objects" ] || [ -w "${_git_dir}/objects" ]; }; then
		return 0
	fi

	case "$(uname -s 2> "/dev/null")" in
		MINGW*|MSYS*|CYGWIN*|Windows_NT*|*_NT*) ;;
		*)
			local _cur_uid="$(id -u 2> "/dev/null" || echo 1000)"
			local _real_user="${SUDO_USER:-${DOAS_USER:-$(id -un 2> "/dev/null")}}"
			local _real_group="$(id -gn "${_real_user}" 2> "/dev/null" || id -gn 2> "/dev/null")"
			if [ "${_cur_uid}" -ne 0 ] && { [ -d "${_repo_dir}/.git" ] || [ -f "${_repo_dir}/.git" ]; }; then
				if [ ! -w "${_repo_dir}" ] || [ ! -w "${_repo_dir}/.git" ] || [ -z "${_git_dir}" ] || [ ! -w "${_git_dir}" ] || { [ -e "${_git_dir}/objects" ] && [ ! -w "${_git_dir}/objects" ]; }; then
					if command -v _as_root > "/dev/null" 2>&1; then
						_as_root chown -R "${_real_user}:${_real_group}" "${_repo_dir}" 2> "/dev/null" || true
						_as_root chmod -R u+rwX,go+rX "${_repo_dir}" 2> "/dev/null" || true
						if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_repo_dir}/.git" ]; then
							_as_root chown -R "${_real_user}:${_real_group}" "${_git_dir}" 2> "/dev/null" || true
							_as_root chmod -R u+rwX,go+rX "${_git_dir}" 2> "/dev/null" || true
						fi
					fi
				fi
			fi
			;;
	esac

	if { [ -d "${_repo_dir}/.git" ] || [ -f "${_repo_dir}/.git" ]; } && command -v git > "/dev/null" 2>&1; then
		git -C "${_repo_dir}" config core.hooksPath .githooks 2> "/dev/null" || true
		git config --global --add safe.directory "${_repo_dir}" 2> "/dev/null" || true
	fi
	_perms_apply_entrypoints "${_repo_dir}"
}

_install_repo_perms() {
	local _repo_dir="${1:-${SHELL_REPO_DIR:-}}"
	local _os_name="${2:-${OS_NAME:-$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}}"
	[ -n "${_repo_dir}" ] && [ -d "${_repo_dir}" ] || return 0

	local _git_dir=""
	_git_dir="$(_perms_resolve_git_dir "${_repo_dir}")"

	if [ "${_os_name}" != "windows" ]; then
		local _real_user="${SUDO_USER:-${DOAS_USER:-$(id -un)}}"
		local _real_group="$(id -gn "${_real_user}" 2> "/dev/null" || id -gn)"
		if [ "$(id -u)" -eq 0 ]; then
			if [ -n "${_real_user}" ] && [ "${_real_user}" != "root" ]; then
				chown -R "${_real_user}:${_real_group}" "${_repo_dir}" 2> "/dev/null" || true
				if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_repo_dir}/.git" ]; then
					chown -R "${_real_user}:${_real_group}" "${_git_dir}" 2> "/dev/null" || true
				fi
			fi
		elif command -v _as_root > "/dev/null" 2>&1; then
			_as_root chown -R "${_real_user}:${_real_group}" "${_repo_dir}" 2> "/dev/null" || true
			if [ -n "${_git_dir}" ] && [ "${_git_dir}" != "${_repo_dir}/.git" ]; then
				_as_root chown -R "${_real_user}:${_real_group}" "${_git_dir}" 2> "/dev/null" || true
			fi
		else
			chown -R "${_real_user}:${_real_group}" "${_repo_dir}" 2> "/dev/null" || true
		fi
		find "${_repo_dir}" -path "${_repo_dir}/.git" -prune -o -type d -exec chmod 0755 {} + 2> "/dev/null" || true
		find "${_repo_dir}" -path "${_repo_dir}/.git" -prune -o -type f -exec chmod 0644 {} + 2> "/dev/null" || true
		_perms_apply_entrypoints "${_repo_dir}"
		command git config --global --add safe.directory "${_repo_dir}" 2> "/dev/null" || true
	fi

	if { [ -d "${_repo_dir}/.git" ] || [ -f "${_repo_dir}/.git" ]; } && command -v git > "/dev/null" 2>&1; then
		command git -C "${_repo_dir}" config core.hooksPath .githooks 2> "/dev/null" || true
	fi
}
