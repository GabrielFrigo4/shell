### ================================
### SHELL APPEARANCE
### ================================

git_branch() {
	_git_branch=" "
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		local branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		if [ -n "$branch" ]; then
			local is_dirty="$(command git status --short -uno 2> "/dev/null" | command tail -n1)"
			local indicator=""
			[ -n "$is_dirty" ] && indicator="${Y}*"
			_git_branch=" ${B}(${R}${branch}${indicator}${B})${z} "
		fi
	fi
}

update_prompt() {
	local z="\[\e[0m\]"
	local R="\[\e[1;91m\]"
	local G="\[\e[1;92m\]"
	local Y="\[\e[1;93m\]"
	local B="\[\e[1;94m\]"
	local M="\[\e[1;95m\]"
	local C="\[\e[1;96m\]"
	local K="\[\e[1;90m\]"

	local _git_branch
	git_branch

	local u
	if [ "$(command id -u)" -eq 0 ]; then u="${R}"; else u="${G}"; fi

	local cur_user="$(command id -un)"
	local cur_host="$(command hostname -s)"
	local cur_dir="${PWD##*/}"
	[ "${PWD}" = "${HOME}" ] && cur_dir="~"
	[ "${PWD}" = "/" ] && cur_dir="/"

	export PS1="${u}${cur_user}${B}@${M}${cur_host}${K}:${K}[${Y}${cur_dir}${K}]${z}${_git_branch}${C}\$${z} "
}

alias :="update_prompt; command :"
update_prompt

run_and_update() {
	local cmd="${1}"
	shift
	command "$cmd" "$@"
	local ret=$?
	update_prompt
	return $ret
}

alias triggers-reset="rm -f ${TRIGGERS_CACHE} && triggers-setup && . ${TRIGGERS_CACHE}"
. "${TRIGGERS_CACHE}"
