### ================================
### GIT AND VERSION CONTROL ENGINE
### ================================

_git_branch() {
	_branch=""
	_is_dirty=""
	local _d="${PWD}"
	local _git_root=""
	while [ -n "${_d}" ]; do
		if [ -d "${_d}/.git" ]; then
			_git_root="${_d}/.git"
			break
		elif [ -f "${_d}/.git" ]; then
			local _gitdir=""
			read -r _gitdir < "${_d}/.git" 2> "/dev/null" || true
			case "${_gitdir}" in
				gitdir:\ *) _git_root="${_gitdir#gitdir: }" ;;
			esac
			break
		fi
		case "${_d}" in
			/|"${HOME}"/..|//*) break ;;
			*) _d="${_d%/*}" ;;
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
		[ -n "${_branch}" ] && _is_dirty="$(command git status --porcelain=v1 --untracked-files=no 2> "/dev/null" | command head -n 1)"
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		_branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
	fi
}
