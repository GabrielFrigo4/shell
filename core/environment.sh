### ================================
### CORE ENVIRONMENT
### ================================

### --------------------------------
### Variables & Sovereign Locale
### --------------------------------
unset CDPATH

if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
	export RAW_TTY=1
	export LC_RAW_TTY=1
	export UNIVERSAL_RAW_TTY=1
	export NVIM_NOTTYFAST=1
	unset COLORTERM
	unset MICRO_TRUECOLOR
else
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1
	unset NVIM_NOTTYFAST
fi

if [ -z "${LANG:-}" ] || [ "${LANG}" = "C" ] || [ "${LANG}" = "POSIX" ]; then
	if [ -r "/etc/locale.conf" ]; then
		_conf_lang="$(grep -E '^[[:space:]]*LANG=' "/etc/locale.conf" 2> "/dev/null" | cut -d= -f2- | tr -d '"'\''')"
		[ -n "${_conf_lang}" ] && export LANG="${_conf_lang}"
		unset _conf_lang
	fi
	[ -z "${LANG:-}" ] && export LANG="pt_BR.UTF-8"
fi
[ -z "${LC_CTYPE:-}" ] && export LC_CTYPE="${LANG}"

### --------------------------------
### Python Bytecode & Cache Policy
### --------------------------------
case "${SHELL_CONTEXT:-desktop}" in
	server)
		unset PYTHONDONTWRITEBYTECODE
		export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/cpython"
		;;
	*)
		export PYTHONDONTWRITEBYTECODE=1
		unset PYTHONPYCACHEPREFIX
		;;
esac

### --------------------------------
### Auto-Correct SHELL
### --------------------------------
_current_sh="${_DETECTED_SHELL:-$(_detect_shell)}"
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
	for _editor in nvim hx micro kak vim nano ee mg mcedit vi; do
		if command -v "${_editor}" > "/dev/null" 2>&1; then
			export EDITOR="${_editor}"
			export VISUAL="${_editor}"
			break
		fi
	done
	unset _editor
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
command -v xterm > "/dev/null" 2>&1 && alias xterm="xterm -bc -bcf 600 -bcn 600"
[ -f "${HOME}/.Xresources" ] && export XENVIRONMENT="${HOME}/.Xresources"
if [ -n "${DISPLAY:-}" ] && [ -f "${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	xrdb -merge "${HOME}/.Xresources" > "/dev/null" 2>&1 || true
fi

### --------------------------------
### Package Compatibility Aliases
### --------------------------------
_env_os="${_DETECTED_OS-$(_detect_os)}"
_bat_bin="${_DETECTED_BAT-$(_detect_bat)}"
_fd_bin="${_DETECTED_FD-$(_detect_fd)}"
_eza_bin="${_DETECTED_EZA-$(_detect_eza)}"
_rg_bin="${_DETECTED_RG-$(_detect_rg)}"

[ "${_bat_bin}" = "batcat" ] && alias bat="batcat"
[ "${_fd_bin}" = "fdfind" ] && alias fd="fdfind"
[ "${_fd_bin}" = "fd-find" ] && alias fd="fd-find"

### --------------------------------
### Directory Listing
### --------------------------------
unalias ls grep cat find ssh agy 2> "/dev/null" || true
eval 'ls() {
	if [ -t 0 ] && [ -t 1 ] && ! _is_raw_tty; then
		local _eza_cmd="${_DETECTED_EZA-$(_detect_eza)}"
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

	case "${_DETECTED_OS-$(_detect_os)}" in
		freebsd|dragonfly*|macos|darwin|netbsd)
			command ls -G "$@"
			;;
		openbsd|illumos|solaris|sunos)
			command ls "$@"
			;;
		*)
			command ls --color=auto "$@"
			;;
	esac
}'

case "${_env_os}" in
	freebsd|dragonfly*|macos|darwin|netbsd)
		_ls_l="ls -lG"
		_ls_ll="ls -laFoG"
		_ls_la="ls -aG"
		;;
	openbsd|illumos|solaris|sunos)
		_ls_l="ls -l"
		_ls_ll="ls -laF"
		_ls_la="ls -a"
		;;
	*)
		_ls_l="ls -l --color=auto"
		_ls_ll="ls -laF --color=auto"
		_ls_la="ls -a --color=auto"
		;;
esac

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
eval 'grep() {
	if [ -t 0 ] && [ -t 1 ] && ! _is_raw_tty; then
		local _rg_cmd="${_DETECTED_RG-$(_detect_rg)}"
		if [ -n "${_rg_cmd}" ]; then
			case "$*" in
				*"-E "*|*"-E") command grep --color=auto "$@" ; return $? ;;
			esac
			command "${_rg_cmd}" --smart-case "$@"
			return $?
		fi
	fi
	case "${_DETECTED_OS-$(_detect_os)}" in
		freebsd|dragonfly*|openbsd|netbsd|illumos|solaris|sunos)
			command grep "$@"
			;;
		*)
			command grep --color=auto "$@"
			;;
	esac
}'

if [ -n "${_rg_bin}" ]; then
	alias g="${_rg_bin} --smart-case"
else
	alias g="grep -Ei"
fi
unset _rg_bin

### --------------------------------
### File Preview
### --------------------------------
eval 'cat() {
	if [ -t 0 ] && [ -t 1 ] && ! _is_raw_tty; then
		local _bat_cmd="${_DETECTED_BAT-$(_detect_bat)}"
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
eval 'find() {
	if [ -t 1 ] && ! _is_raw_tty; then
		local _fd_cmd="${_DETECTED_FD-$(_detect_fd)}"
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
### SSH Client TTY Propagation
### --------------------------------
eval 'ssh() {
	_is_raw=0
	case "${RAW_TTY:-}${LC_RAW_TTY:-}${UNIVERSAL_RAW_TTY:-}" in
		*1*|*true*|*yes*) _is_raw=1 ;;
	esac
	if [ -t 0 ] && [ -t 1 ] && { [ "${_is_raw}" -eq 1 ] || { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; }; then
		export LC_RAW_TTY=1
		export RAW_TTY=1
		export UNIVERSAL_RAW_TTY=1
		command ssh -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1 "$@"
	else
		command ssh "$@"
	fi
}'

### --------------------------------
### Dust Disk Usage
### --------------------------------
_dust_bin="${_DETECTED_DUST-$(_detect_dust)}"
if [ -n "${_dust_bin}" ]; then
	alias du="${_dust_bin}"
	alias dust="${_dust_bin}"
fi
unset _dust_bin

### --------------------------------
### Procs Process Inspection
### --------------------------------
_procs_bin="${_DETECTED_PROCS-$(_detect_procs)}"
if [ -n "${_procs_bin}" ]; then
	alias procs="${_procs_bin}"
	alias pst="${_procs_bin} --tree"
fi
unset _procs_bin

### --------------------------------
### Bottom System Monitor
### --------------------------------
_btm_bin="${_DETECTED_BOTTOM-$(_detect_bottom)}"
if [ -n "${_btm_bin}" ]; then
	alias btm="${_btm_bin}"
	alias top="${_btm_bin}"
elif command -v btop > "/dev/null" 2>&1; then
	alias top="btop"
elif command -v htop > "/dev/null" 2>&1; then
	alias top="htop"
fi
unset _btm_bin

### --------------------------------
### Zoxide Smart Navigation
### --------------------------------
_zoxide_bin="${_DETECTED_ZOXIDE-$(_detect_zoxide)}"
if [ -n "${_zoxide_bin}" ]; then
	_ZO_DOCTOR=0
	export _ZO_DOCTOR
	case "${_DETECTED_SHELL-$(_detect_shell)}" in
		zsh)
			eval "$("${_zoxide_bin}" init zsh --hook prompt)"
			__zoxide_oldpwd="$(__zoxide_pwd)"
			__zoxide_hook() {
				local _pwd_tmp="$(__zoxide_pwd)"
				if [ "${__zoxide_oldpwd}" != "${_pwd_tmp}" ]; then
					__zoxide_oldpwd="${_pwd_tmp}"
					command zoxide add -- "${__zoxide_oldpwd}" 2> "/dev/null"
				fi
			}
			;;
		bash) eval "$("${_zoxide_bin}" init bash)" ;;
		*)    eval "$("${_zoxide_bin}" init posix --hook prompt)" ;;
	esac
else
	alias z="cd"
fi
unset _zoxide_bin

### --------------------------------
### Navigation Aliases
### --------------------------------
if command -v shopt > "/dev/null" 2>&1; then
	shopt -s autocd 2> "/dev/null" || true
else
	alias /="cd /" 2> "/dev/null" || true
fi
alias ~="cd ~" ..="cd .." ...="cd ../.." ....="cd ../../.." -- -="cd -"
alias take="take-dir" mkcd="take-dir" cdb="cd-git-root"
alias clear="echo -n $'\e[2J\e[3J\e[H'"

### --------------------------------
### Utility & Benchmark Aliases
### --------------------------------
alias hist="hist-search" hg="hist-search"
alias extract="extract-archive" x="extract-archive"
alias bsh="bench-shell" shell-bench="bench-shell"

### --------------------------------
### Universal Update Aliases
### --------------------------------
alias u="update-all" upall="update-all" upsys="update-system"
alias upsh="update-shell" uped="update-editors" upmodes="update-emacs-modes"
alias uprc="update-profile" upprofile="update-profile" sync-profile="update-profile"
alias upext="sync-extensions" update-extensions="sync-extensions"
alias upgit="update-git" plgit="pull-git" psgit="push-git"
alias resh="reinstall-shell" ccache="clean-cache" cleancache="clean-cache"
alias cleansys="clean-system" clearsys="clean-system" sysclean="clean-system"
alias syscls="clean-system" clear-system="clean-system"
alias upwf="update-wifi" upnet="update-network" uplx="update-linux" updeb="update-linux"

### --------------------------------
### Package Managers
### --------------------------------
alias upman="update-pacman" upapt="update-apt" updnf="update-dnf"
alias upzyp="update-zypper" upxbps="update-xbps" upapk="update-apk"
alias uppkg="update-pkg" upp="update-ports" upport="update-ports"
alias upadd="update-pkg-add" uppkgadd="update-pkg-add"
alias upin="update-pkgin" uppkgin="update-pkgin" upips="update-ips"
alias uptdnf="update-tdnf" upguix="update-guix" upopkg="update-opkg"
alias upemerge="update-emerge" upnix="update-nix" upeopkg="update-eopkg"
alias upslack="update-slackpkg" upbrew="update-brew" upmas="update-mas"
alias upaur="update-aur" upyay="update-aur" upparu="update-aur"
alias update-yay="update-aur" update-paru="update-aur"
alias upflat="update-flatpak" upsnap="update-snap"

### ================================
### Version Control Aliases
### ================================
alias gs="vcs-status" gd="vcs-diff" gst="git status"
alias gco="git checkout" gcb="git checkout -b"
alias gsw="git switch" gswc="git switch -c"
alias gcm="git commit -m" gaa="git add --all"
alias gl="git pull" gp="git push"
alias glog="git log --oneline --decorate --graph -n 20"

if command -v tog > "/dev/null" 2>&1; then
	alias tg="tog" tgl="tog log" tgd="tog diff" tgb="tog blame" tgt="tog tree"
fi

### ================================
### Google Antigravity CLI & Aliases
### ================================
alias agy-continue="agy -c" agyc="agy -c"
alias agy-auto="agy --dangerously-skip-permissions" agy-danger="agy --dangerously-skip-permissions"
alias agya="agy --dangerously-skip-permissions" agyd="agy --dangerously-skip-permissions"
alias agy-continue-auto="agy -c --dangerously-skip-permissions"
alias agy-continue-danger="agy -c --dangerously-skip-permissions"
alias agyca="agy -c --dangerously-skip-permissions" agycd="agy -c --dangerously-skip-permissions"

eval 'agy() {
	if [ -t 1 ] && command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		COLORTERM="" TERM="${TERM:-linux}" command agy "$@"
	else
		command agy "$@"
	fi
}'

if [ -t 1 ]; then
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		if [ "${TERM:-}" = "linux" ] && [ "${_DETECTED_OS-$(_detect_os)}" = "linux" ]; then
			echo -n $'\e%G\e[?16;238;0c\e]P0000000\e]P17f0000\e]P2007f00\e]P3c4a100\e]P43366a3\e]P57f007f\e]P6007f7f\e]P7bfbfbf\e]P873828a\e]P9ff0000\e]Pa00ff00\e]Pbffff00\e]Pc739ecf\e]Pdff00ff\e]Pe00ffff\e]Pfffffff'
			command -v stty > "/dev/null" 2>&1 && stty iutf8 2> "/dev/null" || true
		fi
	else
		echo -n $'\e[1 q'
	fi
fi
