### ================================
### SHELL APPEARANCE
### ================================

_git_branch() {
	if command git rev-parse --is-inside-work-tree > "/dev/null" 2>&1; then
		local _branch="$(command git branch --show-current 2> "/dev/null" || command git rev-parse --short HEAD 2> "/dev/null")"
		if [ -n "${_branch}" ]; then
			local _is_dirty="$(command git status --short -uno 2> "/dev/null" | command tail -n1)"
			local _indicator=""
			[ -n "${_is_dirty}" ] && _indicator="${C_BRT_YELLOW}*"
			if _is_raw_tty; then
				echo " ${C_BRT_BLUE}(${C_BRT_RED}${_branch}${_indicator}${C_BRT_BLUE})${C_RESET}"
			else
				echo "❮${C_BRT_RED}󰊢 ${C_BRT_MAGENTA}${_branch}${_indicator}${C_NORM_YELLOW}❯"
			fi
		fi
	elif [ -d ".got" ] && command -v got > "/dev/null" 2>&1; then
		local _branch="$(command got branch 2> "/dev/null" || command got info 2> "/dev/null" | command awk '/work tree branch:/ {print $NF}')"
		if [ -n "${_branch}" ]; then
			if _is_raw_tty; then
				echo " ${C_BRT_BLUE}(${C_BRT_MAGENTA}${_branch}${C_BRT_BLUE})${C_RESET}"
			else
				echo "❮${C_BRT_RED}󰊢 ${C_BRT_MAGENTA}${_branch}${C_NORM_YELLOW}❯"
			fi
		fi
	fi
}

_update_prompt() {
	local C_RESET="\[\e[0m\]"

	local C_NORM_BLACK="\[\e[0;30m\]"
	local C_NORM_RED="\[\e[0;31m\]"
	local C_NORM_GREEN="\[\e[0;32m\]"
	local C_NORM_YELLOW="\[\e[0;33m\]"
	local C_NORM_BLUE="\[\e[0;34m\]"
	local C_NORM_MAGENTA="\[\e[0;35m\]"
	local C_NORM_CYAN="\[\e[0;36m\]"
	local C_NORM_WHITE="\[\e[0;37m\]"

	local C_BRT_GRAY="\[\e[1;90m\]"
	local C_BRT_RED="\[\e[1;91m\]"
	local C_BRT_GREEN="\[\e[1;92m\]"
	local C_BRT_YELLOW="\[\e[1;93m\]"
	local C_BRT_BLUE="\[\e[1;94m\]"
	local C_BRT_MAGENTA="\[\e[1;95m\]"
	local C_BRT_CYAN="\[\e[1;96m\]"
	local C_BRT_WHITE="\[\e[1;97m\]"

	local _os_icon="${PROMPT_OS_ICON}"
	local _os_name="${PROMPT_OS_NAME}"
	local _sh_name="${0##*/}"
	_sh_name="${_sh_name#-}"
	_sh_name="${_sh_name%.exe}"

	local _os_color
	case "$PROMPT_OS_COLOR" in
		red)  _os_color="${C_BRT_RED}" ;;
		blue) _os_color="${C_BRT_BLUE}" ;;
		*)    _os_color="${C_BRT_BLUE}" ;;
	esac

	local _usr_color
	if [ "$(id -u)" -eq 0 ]; then
		_usr_color="${C_BRT_RED}"
	else
		_usr_color="${C_BRT_GREEN}"
	fi

	if _is_raw_tty; then
		local _git_info="$(_git_branch)"
		[ -n "${_git_info}" ] && _git_info="${_git_info} "
		PS1="${_usr_color}\u${C_BRT_BLUE}@${C_BRT_MAGENTA}\h${C_BRT_GRAY}:${C_BRT_GRAY}[${C_BRT_YELLOW}\W${C_BRT_GRAY}]${C_RESET}${_git_info}${C_BRT_CYAN}\$${C_RESET} "
	else
		PS1="\n${C_NORM_YELLOW}${_os_color}${_os_icon}${C_BRT_MAGENTA}${_os_name}${C_NORM_YELLOW}─${C_BRT_BLUE} ${C_BRT_MAGENTA}${_sh_name}${C_NORM_YELLOW}"
		PS1+="\n${C_NORM_YELLOW}┌──❮ ${C_BRT_GREEN} \t${C_NORM_YELLOW} ❯─❮ ${C_BRT_GREEN} \D{%d/%m/%y}${C_NORM_YELLOW} ❯─❮ ${C_BRT_YELLOW} ${C_BRT_CYAN}\W${C_NORM_YELLOW} ❯─ ❮${C_BRT_BLUE} ${_usr_color}\u${C_NORM_YELLOW}❯ $(_git_branch)"
		PS1+="\n${C_NORM_YELLOW}└─${C_BRT_BLUE}${C_RESET} "
	fi
}

PROMPT_COMMAND=_update_prompt
