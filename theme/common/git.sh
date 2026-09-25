### ================================
### GIT AND VERSION CONTROL ENGINE
### ================================

_git_branch() {
	_branch=""
	_is_dirty=""
	local _dir="${PWD}"
	local _git_root=""
	while [ -n "${_dir}" ]; do
		if [ -d "${_dir}/.git" ]; then
			_git_root="${_dir}/.git"
			break
		elif [ -f "${_dir}/.git" ]; then
			local _gitdir=""
			read -r _gitdir < "${_dir}/.git" 2> "/dev/null" || true
			case "${_gitdir}" in
				gitdir:\ *) _git_root="${_gitdir#gitdir: }" ;;
			esac
			break
		fi
		case "${_dir}" in
			/|"${HOME}"/..|//*) break ;;
			*) _dir="${_dir%/*}" ;;
		esac
	done

	if [ -n "${_git_root}" ]; then
		if [ -f "${_git_root}/HEAD" ]; then
			local _head=""
			read -r _head < "${_git_root}/HEAD" 2> "/dev/null" || true
			case "${_head}" in
				"ref: refs/heads/"*) _branch="${_head#ref: refs/heads/}" ;;
				"ref: "*)            _branch="${_head#ref: }" ;;
				*)                   _branch="$(command git rev-parse --short HEAD 2> "/dev/null" || true)" ;;
			esac
		fi
		if [ -n "${_branch}" ]; then
			if ! command git diff-index --quiet --ignore-submodules=dirty HEAD -- 2> "/dev/null"; then
				_is_dirty="*"
			fi
		fi
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		_branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
	fi
}
