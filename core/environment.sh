# ----------------------------------------------------------------
# Core: Universal Environment, Variables & Aliases
# ----------------------------------------------------------------

### ================================
### CORE ENVIRONMENT
### ================================

### --------------------------------
### VARIABLES & SOVEREIGN LOCALE
### --------------------------------
unset CDPATH

if [ -z "${_DETECTED_OS:-}" ]; then
	if command -v _detect_os > "/dev/null" 2>&1; then
		_DETECTED_OS="$(_detect_os)"
	else
		_DETECTED_OS="$(uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')"
	fi
fi
if [ -z "${_DETECTED_SHELL:-}" ] && command -v _detect_shell > "/dev/null" 2>&1; then
	_DETECTED_SHELL="$(_detect_shell)"
fi

if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
	export RAW_TTY=1
	export LC_RAW_TTY=1
	export UNIVERSAL_RAW_TTY=1
	export NVIM_NOTTYFAST=1
	unset COLORTERM
	unset MICRO_TRUECOLOR
else
	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1
fi

if [ -z "${LANG:-}" ] || [ "${LANG}" = "C" ] || [ "${LANG}" = "POSIX" ]; then
	if [ -r "/etc/locale.conf" ]; then
		while IFS= read -r _line || [ -n "${_line}" ]; do
			while :; do
				case "${_line}" in
					" "*|"	"*) _line="${_line#?}" ;;
					*) break ;;
				esac
			done
			case "${_line}" in
				LANG=*)
					_conf_lang="${_line#LANG=}"
					_conf_lang="${_conf_lang%\"}"
					_conf_lang="${_conf_lang#\"}"
					_conf_lang="${_conf_lang%\'}"
					_conf_lang="${_conf_lang#\'}"
					[ -n "${_conf_lang}" ] && export LANG="${_conf_lang}"
					break
					;;
			esac
		done < "/etc/locale.conf"
		unset _line _conf_lang
	fi
	[ -z "${LANG:-}" ] && export LANG="pt_BR.UTF-8"
fi
[ -z "${LC_CTYPE:-}" ] && export LC_CTYPE="${LANG}"

### --------------------------------
### GRAPHICS ACCELERATION
### --------------------------------
case "${_DETECTED_OS}" in
	freebsd)
		if [ -z "${LIBVA_DRIVER_NAME:-}" ] && [ -d "/dev/dri" ]; then
			if kldstat -q -n i915kms 2> "/dev/null" || pciconf -l 2> "/dev/null" | command grep -q 'vgapci.*vendor=0x8086'; then
				export LIBVA_DRIVER_NAME="iHD"
			fi
		fi
		[ -z "${KDEVARTMP:-}" ] && export KDEVARTMP="/tmp"
		;;
	linux)
		if [ -z "${LIBVA_DRIVER_NAME:-}" ] && [ -d "/dev/dri" ] && [ -r "/sys/class/drm/card0/device/vendor" ]; then
			read -r _drm_vendor < "/sys/class/drm/card0/device/vendor" 2> "/dev/null" || _drm_vendor=""
			[ "${_drm_vendor}" = "0x8086" ] && export LIBVA_DRIVER_NAME="iHD"
			unset _drm_vendor
		fi
		;;
esac

### --------------------------------
### PYTHON BYTECODE & CACHE POLICY
### --------------------------------
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"

### --------------------------------
### AUTO-CORRECT SHELL
### --------------------------------
_current_sh="${_DETECTED_SHELL:-}"
if [ -n "${_current_sh}" ]; then
	case "${SHELL:-}" in
		*"/${_current_sh}") ;;
		*)
			_sh_path="$(command -v "${_current_sh}" 2> "/dev/null" || true)"
			[ -n "${_sh_path}" ] && export SHELL="${_sh_path}"
			unset _sh_path
			;;
	esac
fi
unset _current_sh

### --------------------------------
### PRIVILEGE ESCALATION ALIASES
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
### AUR COMPATIBILITY ALIASES
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
### DEFAULT EDITOR
### --------------------------------
_is_generic_editor() {
	case "${1:-}" in
		""|nano|*/nano|vi|*/vi|ee|*/ee|ed|*/ed) return 0 ;;
		*) return 1 ;;
	esac
}

if _is_generic_editor "${EDITOR:-}"; then
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
### UNIVERSAL EDITOR
### --------------------------------
editor() {
	if [ "$#" -eq 0 ]; then
		"${VISUAL:-${EDITOR:-vi}}" .
	else
		"${VISUAL:-${EDITOR:-vi}}" "$@"
	fi
}
alias e="editor"
command -v xterm > "/dev/null" 2>&1 && alias xterm="xterm -bc -bcf 600 -bcn 600"
[ -f "${HOME}/.Xresources" ] && export XENVIRONMENT="${HOME}/.Xresources"
if [ -n "${DISPLAY:-}" ] && [ -f "${HOME}/.Xresources" ] && command -v xrdb > "/dev/null" 2>&1; then
	_xrdb_disp="${DISPLAY}"
	while :; do
		case "${_xrdb_disp}" in
			*:*) _xrdb_disp="${_xrdb_disp%%:*}_${_xrdb_disp#*:}" ;;
			*/*) _xrdb_disp="${_xrdb_disp%%/*}_${_xrdb_disp#*/}" ;;
			*)   break ;;
		esac
	done
	_xrdb_stamp="${_SHELL_CACHE_DIR:-/tmp}/xresources_merged_${_xrdb_disp}"
	if [ -z "${_SHELL_CACHE_DIR:-}" ] || [ ! -f "${_xrdb_stamp}" ] || [ "${HOME}/.Xresources" -nt "${_xrdb_stamp}" ]; then
		xrdb -merge "${HOME}/.Xresources" > "/dev/null" 2>&1 || true
		if [ -n "${_SHELL_CACHE_DIR:-}" ]; then
			[ -d "${_SHELL_CACHE_DIR}" ] || command mkdir -p "${_SHELL_CACHE_DIR}" 2> "/dev/null" || true
			: >| "${_xrdb_stamp}" 2> "/dev/null" || true
		fi
	fi
	unset _xrdb_disp _xrdb_stamp
fi

### --------------------------------
### PACKAGE COMPATIBILITY ALIASES
### --------------------------------
_SHELL_ENV_OS="${_DETECTED_OS}"
_SHELL_BAT_BIN="${_DETECTED_BAT-$(_detect_bat)}"
_SHELL_FD_BIN="${_DETECTED_FD-$(_detect_fd)}"
_SHELL_EZA_BIN="${_DETECTED_EZA-$(_detect_eza)}"
_SHELL_RG_BIN="${_DETECTED_RG-$(_detect_rg)}"
_SHELL_GNU_LS_BIN=""

[ "${_SHELL_BAT_BIN}" = "batcat" ] && alias bat="batcat"
[ "${_SHELL_FD_BIN}" = "fdfind" ] && alias fd="fdfind"
[ "${_SHELL_FD_BIN}" = "fd-find" ] && alias fd="fd-find"

### --------------------------------
### DIRECTORY LISTING
### --------------------------------
unalias ls grep cat find ssh agy l la ll lt lr lar llr c b g f ff d p pst 2> "/dev/null" || true
unset -f ls grep cat find l la ll lt lr lar llr c b g f ff d p pst _shell_ls 2> "/dev/null" || true

case "${_SHELL_ENV_OS}" in
	freebsd|macos|darwin)
		alias ls="command ls -G"
		;;
	openbsd|netbsd|illumos|solaris|sunos)
		;;
	*)
		alias ls="command ls --color=auto"
		;;
esac

_shell_ls() {
	_mode="${1:-l}"
	[ "$#" -ge 1 ] && shift 1
	_is_tty=0
	[ -t 1 ] && _is_tty=1
	if [ -n "${_SHELL_EZA_BIN:-}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		case "${_mode}" in
			ll|llr) set -- --git "$@" ;;
		esac
		set -- --group-directories-first "$@"
		case "${_SHELL_EZA_BIN}" in
			*eza)
				if [ "${_is_tty}" -eq 1 ]; then
					set -- --icons=auto "$@"
				else
					set -- --icons=never --color=never "$@"
				fi
				;;
			*exa)
				[ "${_is_tty}" -eq 0 ] && set -- --color=never "$@"
				;;
		esac
		case "${_mode}" in
			l)   ;;
			ll)  set -- -la "$@" ;;
			la)  set -- -a "$@" ;;
			lt)  set -- --tree "$@" ;;
			lr)  set -- -R "$@" ;;
			lar) set -- -aR "$@" ;;
			llr) set -- -laR "$@" ;;
		esac
		command "${_SHELL_EZA_BIN}" "$@"
		_rc=$?
		unset _mode _is_tty
		eval "unset _rc; return ${_rc}"
	fi
	_ls_bin="ls"
	_ls_is_gnu=0
	if [ -n "${_SHELL_GNU_LS_BIN:-}" ]; then
		_ls_bin="${_SHELL_GNU_LS_BIN}"
		_ls_is_gnu=1
	else
		case "${_SHELL_ENV_OS:-}" in
			linux|windows) _ls_is_gnu=1 ;;
		esac
	fi
	if [ "${_mode}" = "lt" ]; then
		if command -v tree > "/dev/null" 2>&1; then
			if [ "${_is_tty}" -eq 1 ]; then
				command tree "$@"
			else
				command tree -n "$@"
			fi
		else
			command "${_ls_bin}" -R "$@"
		fi
		_rc=$?
		unset _mode _is_tty _ls_bin _ls_is_gnu
		eval "unset _rc; return ${_rc}"
	fi
	_ls_o=""
	_ls_c=""
	_ls_g=""
	if [ "${_ls_is_gnu}" -eq 1 ]; then
		[ "${_is_tty}" -eq 1 ] && _ls_c="--color=auto"
		_ls_g="--group-directories-first"
	else
		case "${_SHELL_ENV_OS:-}" in
			freebsd|macos|darwin)
				_ls_o="o"
				[ "${_is_tty}" -eq 1 ] && _ls_c="-G"
				;;
			netbsd|openbsd|illumos|solaris|sunos) ;;
			*)
				[ "${_is_tty}" -eq 1 ] && _ls_c="--color=auto"
				;;
		esac
	fi
	case "${_mode}" in
		l)   set -- -l "$@" ;;
		ll)  set -- "-laF${_ls_o}" "$@" ;;
		la)  set -- -a "$@" ;;
		lr)  set -- -R "$@" ;;
		lar) set -- -aR "$@" ;;
		llr) set -- "-laF${_ls_o}R" "$@" ;;
	esac
	[ -n "${_ls_g}" ] && set -- "${_ls_g}" "$@"
	[ -n "${_ls_c}" ] && set -- "${_ls_c}" "$@"
	command "${_ls_bin}" "$@"
	_rc=$?
	unset _mode _is_tty _ls_bin _ls_is_gnu _ls_o _ls_c _ls_g
	eval "unset _rc; return ${_rc}"
}

l()   { _shell_ls l "$@"; }
ll()  { _shell_ls ll "$@"; }
la()  { _shell_ls la "$@"; }
lt()  { _shell_ls lt "$@"; }
lr()  { _shell_ls lr "$@"; }
lar() { _shell_ls lar "$@"; }
llr() { _shell_ls llr "$@"; }

### --------------------------------
### SEARCH IN FILES
### --------------------------------
case "${_SHELL_ENV_OS}" in
	freebsd|openbsd|netbsd|illumos|solaris|sunos) ;;
	*) alias grep="command grep --color=auto" ;;
esac

g() {
	if [ -n "${_SHELL_RG_BIN:-}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		if [ -t 1 ]; then
			command "${_SHELL_RG_BIN}" --smart-case "$@"
		else
			command "${_SHELL_RG_BIN}" --smart-case --color=never "$@"
		fi
	elif [ -t 1 ]; then
		grep -Ei "$@"
	else
		command grep -Ei "$@"
	fi
}

### --------------------------------
### FILE PREVIEW
### --------------------------------
c() {
	if [ -n "${_SHELL_BAT_BIN:-}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		if [ -t 1 ]; then
			command "${_SHELL_BAT_BIN}" --paging=never "$@"
		else
			command "${_SHELL_BAT_BIN}" --plain --color=never --paging=never "$@"
		fi
	else
		command cat "$@"
	fi
}

b() {
	if [ -n "${_SHELL_BAT_BIN:-}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		if [ -t 1 ]; then
			command "${_SHELL_BAT_BIN}" "$@"
		else
			command "${_SHELL_BAT_BIN}" --plain --color=never --paging=never "$@"
		fi
	elif [ -t 1 ]; then
		command "${PAGER:-less}" "$@"
	else
		command cat "$@"
	fi
}

### --------------------------------
### FILE & PATH SEARCH
### --------------------------------
f() {
	if [ -n "${_SHELL_FD_BIN:-}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		if [ -t 1 ]; then
			command "${_SHELL_FD_BIN}" "$@"
		else
			command "${_SHELL_FD_BIN}" --color=never "$@"
		fi
	else
		command find "$@"
	fi
}

ff() {
	if [ -n "${_SHELL_FD_BIN:-}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
		if [ -t 1 ]; then
			command "${_SHELL_FD_BIN}" --hidden --no-ignore "$@"
		else
			command "${_SHELL_FD_BIN}" --hidden --no-ignore --color=never "$@"
		fi
	else
		command find "$@"
	fi
}

### --------------------------------
### SSH CLIENT TTY PROPAGATION
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
		unset _is_raw
		command ssh -o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1 "$@"
	else
		unset _is_raw
		command ssh "$@"
	fi
}'

### --------------------------------
### DUST DISK USAGE
### --------------------------------
_SHELL_DUST_BIN="${_DETECTED_DUST-$(_detect_dust)}"
if [ -n "${_SHELL_DUST_BIN}" ]; then
	alias dust="${_SHELL_DUST_BIN}"
fi

d() {
	if [ -n "${_SHELL_DUST_BIN:-}" ]; then
		if [ -t 1 ]; then
			command "${_SHELL_DUST_BIN}" "$@"
		else
			NO_COLOR=1 command "${_SHELL_DUST_BIN}" "$@"
		fi
	else
		command du -h "$@"
	fi
}

### --------------------------------
### PROCS PROCESS INSPECTION
### --------------------------------
_SHELL_PROCS_BIN="${_DETECTED_PROCS-$(_detect_procs)}"
if [ -n "${_SHELL_PROCS_BIN}" ]; then
	alias procs="${_SHELL_PROCS_BIN}"
fi

p() {
	if [ -n "${_SHELL_PROCS_BIN:-}" ]; then
		if [ -t 1 ]; then
			command "${_SHELL_PROCS_BIN}" "$@"
		else
			NO_COLOR=1 command "${_SHELL_PROCS_BIN}" --color disable "$@"
		fi
	else
		case "${_SHELL_ENV_OS:-}" in
			illumos|solaris|sunos) command ps -ef "$@" ;;
			*)                     command ps aux "$@" ;;
		esac
	fi
}

pst() {
	if [ -n "${_SHELL_PROCS_BIN:-}" ]; then
		if [ -t 1 ]; then
			command "${_SHELL_PROCS_BIN}" --tree "$@"
		else
			NO_COLOR=1 command "${_SHELL_PROCS_BIN}" --tree --color disable "$@"
		fi
	else
		case "${_SHELL_ENV_OS:-}" in
			illumos|solaris|sunos) command ps -ef "$@" ;;
			*)                     command ps aux "$@" ;;
		esac
	fi
}

### --------------------------------
### BOTTOM SYSTEM MONITOR
### --------------------------------
_btm_bin="${_DETECTED_BOTTOM-$(_detect_bottom)}"
if [ -n "${_btm_bin}" ]; then
	alias btm="${_btm_bin}"
	alias t="${_btm_bin}"
elif command -v btop > "/dev/null" 2>&1; then
	alias t="btop"
elif command -v htop > "/dev/null" 2>&1; then
	alias t="htop"
else
	alias t="top"
fi
unset _btm_bin

### --------------------------------
### ZOXIDE SMART NAVIGATION
### --------------------------------
unalias z zi 2> "/dev/null" || true
_zoxide_bin="${_DETECTED_ZOXIDE-$(_detect_zoxide)}"
if [ -n "${_zoxide_bin}" ]; then
	_ZO_DOCTOR=0
	export _ZO_DOCTOR
	case "${_DETECTED_SHELL:-posix}" in
		zsh)  _zoxide_mode="zsh" ;;
		bash) _zoxide_mode="bash" ;;
		*)    _zoxide_mode="posix" ;;
	esac
	_zoxide_cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/shell"
	_zoxide_cache="${_zoxide_cache_dir}/zoxide_${_zoxide_mode}.sh"
	if [ ! -s "${_zoxide_cache}" ] || [ "${_zoxide_bin}" -nt "${_zoxide_cache}" ]; then
		mkdir -p "${_zoxide_cache_dir}" 2> "/dev/null" || true
		case "${_zoxide_mode}" in
			zsh)  "${_zoxide_bin}" init zsh --hook prompt >| "${_zoxide_cache}" 2> "/dev/null" || rm -f "${_zoxide_cache}" ;;
			bash) "${_zoxide_bin}" init bash >| "${_zoxide_cache}" 2> "/dev/null" || rm -f "${_zoxide_cache}" ;;
			*)    "${_zoxide_bin}" init posix --hook prompt >| "${_zoxide_cache}" 2> "/dev/null" || rm -f "${_zoxide_cache}" ;;
		esac
	fi
	if [ -s "${_zoxide_cache}" ]; then
		. "${_zoxide_cache}"
	else
		case "${_zoxide_mode}" in
			zsh)  eval "$("${_zoxide_bin}" init zsh --hook prompt)" ;;
			bash) eval "$("${_zoxide_bin}" init bash)" ;;
			*)    eval "$("${_zoxide_bin}" init posix --hook prompt)" ;;
		esac
	fi
	if [ "${_zoxide_mode}" = "zsh" ] && command -v __zoxide_pwd > "/dev/null" 2>&1; then
		__zoxide_oldpwd="${PWD}"
		__zoxide_hook() {
			_pwd_tmp="$(__zoxide_pwd)"
			if [ "${__zoxide_oldpwd}" != "${_pwd_tmp}" ]; then
				__zoxide_oldpwd="${_pwd_tmp}"
				command zoxide add -- "${__zoxide_oldpwd}" 2> "/dev/null"
			fi
			unset _pwd_tmp
		}
	fi
	unset _zoxide_mode _zoxide_cache_dir _zoxide_cache
else
	alias z="cd"
fi
unset _zoxide_bin

### --------------------------------
### NAVIGATION ALIASES
### --------------------------------
if command -v shopt > "/dev/null" 2>&1; then
	shopt -s autocd 2> "/dev/null" || true
else
	alias /="cd /" 2> "/dev/null" || true
fi
alias ~="cd ~" ..="cd .." ...="cd ../.." ....="cd ../../.."
alias -- -="cd -" 2> "/dev/null" || alias -="cd -" 2> "/dev/null" || true
alias take="take-dir" mkcd="take-dir" cdb="cd-git-root"
_shell_esc=$'\e'
if [ "${#_shell_esc}" -ne 1 ]; then
	_shell_esc="$(printf '\x1b')"
fi
alias clear="if [ -t 1 ]; then printf '%s[2J%s[3J%s[H' '${_shell_esc}' '${_shell_esc}' '${_shell_esc}'; fi"

### --------------------------------
### UTILITY & BENCHMARK ALIASES
### --------------------------------
alias hist="hist-search" hg="hist-search"
alias extract="extract-archive" x="extract-archive"
alias bsh="bench-shell" shell-bench="bench-shell"

### --------------------------------
### UNIVERSAL UPDATE ALIASES
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
### PACKAGE MANAGERS
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
### VERSION CONTROL ALIASES
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
### ANTIGRAVITY CLI & ALIASES
### ================================
eval 'agy() {
	if [ -t 1 ] && command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		COLORTERM="" TERM="${TERM:-linux}" command agy "$@"
	else
		command agy "$@"
	fi
}'

alias a="agy"
alias aa="agy --dangerously-skip-permissions" ad="agy --dangerously-skip-permissions"
alias agy-continue="agy -c" agyc="agy -c"
alias agy-return="agy -c" agyr="agy -c"
alias agy-auto="agy --dangerously-skip-permissions" agy-danger="agy --dangerously-skip-permissions"
alias agya="agy --dangerously-skip-permissions" agyd="agy --dangerously-skip-permissions"
alias agy-continue-auto="agy -c --dangerously-skip-permissions"
alias agy-continue-danger="agy -c --dangerously-skip-permissions"
alias agy-return-auto="agy -c --dangerously-skip-permissions"
alias agy-return-danger="agy -c --dangerously-skip-permissions"
alias agyca="agy -c --dangerously-skip-permissions" agycd="agy -c --dangerously-skip-permissions"
alias agyra="agy -c --dangerously-skip-permissions" agyrd="agy -c --dangerously-skip-permissions"

if [ -t 1 ]; then
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		if [ "${TERM:-}" = "linux" ] && [ "${_SHELL_ENV_OS:-}" = "linux" ]; then
			printf '%s' "${_shell_esc}%G${_shell_esc}[?16;238;0c${_shell_esc}]P0000000${_shell_esc}]P17f0000${_shell_esc}]P2007f00${_shell_esc}]P3c4a100${_shell_esc}]P43366a3${_shell_esc}]P57f007f${_shell_esc}]P6007f7f${_shell_esc}]P7bfbfbf${_shell_esc}]P873828a${_shell_esc}]P9ff0000${_shell_esc}]Pa00ff00${_shell_esc}]Pbffff00${_shell_esc}]Pc739ecf${_shell_esc}]Pdff00ff${_shell_esc}]Pe00ffff${_shell_esc}]Pfffffff"
			command -v stty > "/dev/null" 2>&1 && stty iutf8 2> "/dev/null" || true
		fi
	else
		printf '%s[1 q' "${_shell_esc}"
	fi
fi
unset _shell_esc
