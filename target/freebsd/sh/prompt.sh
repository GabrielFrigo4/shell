### ================================
### TRIGGERS ENVIRONMENT
### ================================

TRIGGERS_CACHE="${HOME}/.cache/triggers.sh"

triggers-setup() {
	mkdir -p "${HOME}/.cache"
	echo "# $(command date +%Y-%m-%d)" > "${TRIGGERS_CACHE}"

	local IGNORE_LIST=" sh command eval alias unalias return echo printf test [ clear "
	TRIGGERS=""

	for file in /bin/* /sbin/* /usr/bin/* /usr/sbin/*; do
		if [ -f "$file" ] && [ -x "$file" ]; then
			local cmd_name="${file##*/}"
			case "${IGNORE_LIST}" in
				*" ${cmd_name} "*) continue ;;
			esac
			TRIGGERS="${TRIGGERS} ${cmd_name}"
		fi
	done

	for file in /usr/local/bin/? /usr/local/sbin/? \
				/usr/local/bin/?? /usr/local/sbin/?? \
				/usr/local/bin/??? /usr/local/sbin/??? \
				/usr/local/bin/???? /usr/local/sbin/???? \
				/usr/local/bin/????? /usr/local/sbin/?????; do
		if [ -f "$file" ] && [ -x "$file" ]; then
			local cmd_name="${file##*/}"
			case "${IGNORE_LIST}" in
				*" ${cmd_name} "*) continue ;;
			esac
			TRIGGERS="${TRIGGERS} ${cmd_name}"
		fi
	done

	TRIGGERS=$(echo ${TRIGGERS} | tr ' ' '\n' | sort -u | tr '\n' ' ')
	for cmd in ${TRIGGERS}; do
		if command -v "$cmd" > "/dev/null" 2>&1; then
			echo "unalias ${cmd} > \"/dev/null\" 2>&1" >> "${TRIGGERS_CACHE}"
			case "$cmd" in
				*+*|*-*|*.*)
					echo "alias ${cmd}='run_and_update ${cmd}'" >> "${TRIGGERS_CACHE}"
					;;
				*)
					echo "${cmd}() { run_and_update ${cmd} \"\$@\"; }" >> "${TRIGGERS_CACHE}"
					;;
			esac
		fi
	done
}

if [ -f "${TRIGGERS_CACHE}" ]; then
	read -r TRIGGERS_DATE < "${TRIGGERS_CACHE}"
	if [ "${TRIGGERS_DATE}" != "# $(command date +%Y-%m-%d)" ]; then
		command rm -f "${TRIGGERS_CACHE}"
	fi
fi

if [ ! -f "${TRIGGERS_CACHE}" ]; then
	triggers-setup
fi

### ================================
### TERMINAL ENVIRONMENT
### ================================

case "$(command ps -o comm= -p $PPID)" in
	su|-su) unset SHELL_INIT ;;
esac

if [ "${USER}" != "$(command id -un)" ]; then
	export USER="$(command id -un)"
	unset SHELL_INIT
fi

if [ -z "${SHELL_INIT}" ]; then
	if [ -z "${SHELL_TARGET}" ]; then
		case "$(command tty 2> "/dev/null")" in
			"/dev/ttyv"*|"/dev/console") SHELL_TARGET="$(command -v sh 2> "/dev/null")" ;;
			*) SHELL_TARGET="$(command -v zsh 2> "/dev/null")" ;;
		esac
		[ -x "${SHELL_TARGET}" ] || SHELL_TARGET="$(command -v sh 2> "/dev/null")"
	fi

	if [ -x "${SHELL_TARGET}" ] && [ "${SHELL_TARGET}" != "$(command -v sh 2> "/dev/null")" ]; then
		export SHELL_INIT=1
		export SHELL="${SHELL_TARGET}"
		unset SHELL_TARGET
		command printf "\033[H\033[2J\033[3J"
		exec "${SHELL}"
	else
		unset SHELL_TARGET
	fi
fi

### ================================
### SHELL INITIALIZATION
### ================================

export SHELL_INIT=1
find "${HOME}" -maxdepth 1 -name ":*" -delete

### ================================
### SHELL ENVIRONMENT
### ================================

path_front() {
	if [ -d "${1}" ]; then
		case ":${PATH}:" in
			*":${1}:"*) ;;
			*) export PATH="${1}:${PATH}" ;;
		esac
	fi
}

path_back() {
	if [ -d "${1}" ]; then
		case ":${PATH}:" in
			*":${1}:"*) ;; 
			*) export PATH="${PATH}:${1}" ;;
		esac
	fi
}

path_front "${HOME}/.local/bin"
path_front "${HOME}/.cargo/bin"
export PATH=$(command printf "%s" "${PATH}" | command awk -v RS=: -v ORS=: '!a[$(0)]++' | command sed 's/:$//')

export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"
export MICRO_TRUECOLOR=1

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

### ================================
### SHELL ALIAS
### ================================

### --------------------------------
### Commands
### --------------------------------
alias clear="command printf \"\033[H\033[2J\033[3J\""
### --------------------------------
### Software
### --------------------------------
alias code="vscode"
### --------------------------------
### Packages
### --------------------------------
alias uppkg="command sudo pkg update && command sudo pkg upgrade --yes"
alias upall="uppkg"
### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="emacs --daemon"
alias er="ek && es"
alias ec="emacsclient --create-frame --alternate-editor \"\""
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . > \"/dev/null\" 2>&1 &"
### --------------------------------
### Editors
### --------------------------------
alias ok="nohup kate . > \"/dev/null\" 2>&1 &"
alias oc="code ."
alias on="nvim ."
alias ov="vim ."

### ================================
### SHELL CONFIGURATION
### ================================
