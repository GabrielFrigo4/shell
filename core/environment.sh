### ================================
### CORE ENVIRONMENT
### ================================

### --------------------------------
### Variables
### --------------------------------
export COLORTERM="truecolor"
export MICRO_TRUECOLOR=1
unset CDPATH

### --------------------------------
### Auto-Correct SHELL
### --------------------------------
_current_sh="$(_detect_shell)"
case "${SHELL:-}" in
	*"/${_current_sh}") ;;
	*) export SHELL="$(command -v "${_current_sh}" 2> "/dev/null")" ;;
esac
unset _current_sh


### --------------------------------
### Privilege Escalation Aliases
### --------------------------------
if command -v doas > "/dev/null" 2>&1; then
	if ! command -v sudo > "/dev/null" 2>&1; then
		alias sudo="doas"
	fi
elif command -v sudo > "/dev/null" 2>&1; then
	if ! command -v doas > "/dev/null" 2>&1; then
		alias doas="sudo"
	fi
fi

### --------------------------------
### AUR Compatibility Aliases
### --------------------------------
if command -v paru > "/dev/null" 2>&1; then
	if ! command -v yay > "/dev/null" 2>&1; then
		alias yay="paru"
	fi
elif command -v yay > "/dev/null" 2>&1; then
	if ! command -v paru > "/dev/null" 2>&1; then
		alias paru="yay"
	fi
fi

### --------------------------------
### Default Editor
### --------------------------------
_is_generic_editor() {
	case "${1}" in
		""|nano|*/nano|vi|*/vi|ee|*/ee|ed|*/ed) return 0 ;;
		*) return 1 ;;
	esac
}

if _is_generic_editor "${EDITOR}"; then
	for _ed in nvim hx micro kak vim nano ee mg mcedit vi; do
		if command -v "${_ed}" > "/dev/null" 2>&1; then
			export EDITOR="${_ed}"
			export VISUAL="${_ed}"
			break
		fi
	done
	unset _ed
fi

### --------------------------------
### Universal Editor
### --------------------------------
editor() {
	if [ "$#" -eq 0 ]; then
		${VISUAL:-${EDITOR:-vi}} .
	else
		${VISUAL:-${EDITOR:-vi}} "$@"
	fi
}
alias e="editor"

### --------------------------------
### Package Compatibility Aliases
### --------------------------------
_env_os="${_DETECTED_OS:-$(_detect_os)}"
_bat_bin="${_DETECTED_BAT:-$(_detect_bat)}"
_fd_bin="${_DETECTED_FD:-$(_detect_fd)}"
_eza_bin="${_DETECTED_EZA:-$(_detect_eza)}"
_rg_bin="${_DETECTED_RG:-$(_detect_rg)}"

[ "${_bat_bin}" = "batcat" ] && alias bat="batcat"
[ "${_fd_bin}" = "fdfind" ] && alias fd="fdfind"
[ "${_fd_bin}" = "fd-find" ] && alias fd="fd-find"

### --------------------------------
### Directory Listing
### --------------------------------
unalias ls 2> "/dev/null" || true
eval 'ls() {
	if [ -t 1 ] && ! _is_raw_tty; then
		local _eza_cmd="${_DETECTED_EZA:-$(_detect_eza)}"
		case "${_eza_cmd}" in
			*eza)
				command "${_eza_cmd}" --icons=auto --group-directories-first "$@"
				return $?
				;;
			*exa)
				command "${_eza_cmd}" --group-directories-first "$@"
				return $?
				;;
		esac
	fi

	if [ "${_DETECTED_OS:-$(_detect_os)}" = "freebsd" ]; then
		command ls -G "$@"
	else
		command ls --color=auto "$@"
	fi
}'

if [ "${_env_os}" = "freebsd" ]; then
	_ls_l="ls -lG"
	_ls_ll="ls -laFoG"
	_ls_la="ls -aG"
else
	_ls_l="ls -l --color=auto"
	_ls_ll="ls -laF --color=auto"
	_ls_la="ls -a --color=auto"
fi

if _is_raw_tty || [ -z "${_eza_bin}" ]; then
	alias l="${_ls_l}"
	alias ll="${_ls_ll}"
	alias la="${_ls_la}"
	command -v tree > "/dev/null" 2>&1 && alias lt="tree"
else
	case "${_eza_bin}" in
		*eza)
			alias l="${_eza_bin} --icons=auto --group-directories-first"
			alias ll="${_eza_bin} -la --icons=auto --group-directories-first --git"
			alias la="${_eza_bin} -a --icons=auto --group-directories-first"
			alias lt="${_eza_bin} --tree --icons=auto --group-directories-first"
			;;
		*exa)
			alias l="${_eza_bin} --group-directories-first"
			alias ll="${_eza_bin} -la --group-directories-first --git"
			alias la="${_eza_bin} -a --group-directories-first"
			alias lt="${_eza_bin} --tree --group-directories-first"
			;;
	esac
fi
unset _ls_l _ls_ll _ls_la _eza_bin

### --------------------------------
### Search in Files
### --------------------------------
unalias grep 2> "/dev/null" || true
eval 'grep() {
	if [ -t 1 ] && ! _is_raw_tty; then
		local _rg_cmd="${_DETECTED_RG:-$(_detect_rg)}"
		if [ -n "${_rg_cmd}" ]; then
			command "${_rg_cmd}" --smart-case "$@"
			return $?
		fi
	fi
	if [ "${_DETECTED_OS:-$(_detect_os)}" = "freebsd" ]; then
		command grep "$@"
	else
		command grep --color=auto "$@"
	fi
}'

if [ -n "${_rg_bin}" ]; then
	alias g="${_rg_bin} --smart-case"
elif [ "${_env_os}" = "freebsd" ]; then
	alias g="egrep -i"
else
	alias g="grep -Ei"
fi
unset _rg_bin

### --------------------------------
### File Preview
### --------------------------------
unalias cat 2> "/dev/null" || true
eval 'cat() {
	if [ -t 1 ] && ! _is_raw_tty; then
		local _bat_cmd="${_DETECTED_BAT:-$(_detect_bat)}"
		if [ -n "${_bat_cmd}" ]; then
			command "${_bat_cmd}" --paging=never "$@"
			return $?
		fi
	fi
	command cat "$@"
}'

if [ -n "${_bat_bin}" ]; then
	alias c="${_bat_bin} --paging=never"
	alias b="${_bat_bin}"
else
	alias c="cat"
fi
unset _bat_bin

### --------------------------------
### File & Path Search
### --------------------------------
unalias find 2> "/dev/null" || true
eval 'find() {
	if [ -t 1 ] && ! _is_raw_tty; then
		local _fd_cmd="${_DETECTED_FD:-$(_detect_fd)}"
		if [ -n "${_fd_cmd}" ]; then
			for _arg in "$@"; do
				case "${_arg}" in
					-name|-iname|-type|-exec*|-maxdepth|-mindepth|-mtime*|-size|-perm|-user|-group|-path|-prune|-delete|-print*)
						command find "$@"
						return $?
						;;
				esac
			done
			command "${_fd_cmd}" "$@"
			return $?
		fi
	fi
	command find "$@"
}'

if [ -n "${_fd_bin}" ]; then
	alias f="${_fd_bin}"
	alias ff="${_fd_bin} --hidden --no-ignore"
else
	alias f="find"
	alias ff="find"
fi
unset _fd_bin _env_os

### --------------------------------
### Navigation Aliases
### --------------------------------
if command -v shopt > "/dev/null" 2>&1; then
	shopt -s autocd 2> "/dev/null" || true
else
	alias /="cd /" 2> "/dev/null" || true
fi
alias ~="cd ~"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"
alias clear="echo -n $'\e[2J\e[3J\e[H'"

### --------------------------------
### Universal Benchmark Aliases
### --------------------------------
alias bsh="bench-shell"
alias shell-bench="bench-shell"

### --------------------------------
### Universal Update Aliases
### --------------------------------
alias u="update-all"
alias upall="update-all"
alias upsys="update-system"
alias upsh="update-shell"
alias uped="update-editors"
alias upgit="update-git"
alias resh="reinstall-shell"
alias ccache="clean-cache"
alias cleancache="clean-cache"
alias upwf="update-wifi"
alias upnet="update-network"

### --------------------------------
### Package Managers
### --------------------------------
alias upman="update-pacman"
alias upapt="update-apt"
alias updnf="update-dnf"
alias upzyp="update-zypper"
alias upxbps="update-xbps"
alias upapk="update-apk"
alias uppkg="update-pkg"
alias upaur="update-aur"
alias upyay="update-aur"
alias upparu="update-aur"
alias update-yay="update-aur"
alias update-paru="update-aur"
alias upflat="update-flatpak"
alias upsnap="update-snap"

### ================================
### Version Control Aliases (Got & Git)
### ================================
alias gs="vcs-status"
alias gd="vcs-diff"

command -v tog > "/dev/null" 2>&1 && {
	alias tg="tog"
	alias tgl="tog log"
	alias tgd="tog diff"
	alias tgb="tog blame"
	alias tgt="tog tree"
}
