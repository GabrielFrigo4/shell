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
	unset RAW_TTY LC_RAW_TTY UNIVERSAL_RAW_TTY NVIM_NOTTYFAST
	export COLORTERM="truecolor"
	export MICRO_TRUECOLOR=1
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
### GRAPHICS ACCELERATION
### --------------------------------
_env_os_name="${_DETECTED_OS-$(_detect_os)}"
case "${_env_os_name}" in
	freebsd)
		[ -z "${LIBVA_DRIVER_NAME:-}" ] && export LIBVA_DRIVER_NAME="iHD"
		[ -z "${KDEVARTMP:-}" ] && export KDEVARTMP="/tmp"
		;;
	linux)
		if [ -z "${LIBVA_DRIVER_NAME:-}" ] && [ -d "/dev/dri" ]; then
			if [ -r "/sys/class/drm/card0/device/vendor" ] && [ "$(cat /sys/class/drm/card0/device/vendor 2> "/dev/null")" = "0x8086" ]; then
				export LIBVA_DRIVER_NAME="iHD"
			fi
		fi
		;;
esac
unset _env_os_name

### --------------------------------
### PYTHON BYTECODE & CACHE POLICY
### --------------------------------
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"

### --------------------------------
### AUTO-CORRECT SHELL
### --------------------------------
_current_sh="${_DETECTED_SHELL:-$(_detect_shell)}"
case "${SHELL:-}" in
	*"/${_current_sh}") ;;
	*) export SHELL="$(command -v "${_current_sh}" 2> "/dev/null")" ;;
esac
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
	xrdb -merge "${HOME}/.Xresources" > "/dev/null" 2>&1 || true
fi

### --------------------------------
### PACKAGE COMPATIBILITY ALIASES
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
### DIRECTORY LISTING
### --------------------------------
unalias ls grep cat find ssh agy 2> "/dev/null" || true
unset -f ls grep cat find 2> "/dev/null" || true

case "${_env_os}" in
	freebsd|dragonfly*|macos|darwin|netbsd)
		alias ls="command ls -G"
		_ls_l="command ls -lG"
		_ls_ll="command ls -laFoG"
		_ls_la="command ls -aG"
		_ls_lr="command ls -RG"
		_ls_llr="command ls -laFoRG"
		_ls_lar="command ls -aRG"
		;;
	openbsd|illumos|solaris|sunos)
		_ls_l="command ls -l"
		_ls_ll="command ls -laF"
		_ls_la="command ls -a"
		_ls_lr="command ls -R"
		_ls_llr="command ls -laFR"
		_ls_lar="command ls -aR"
		;;
	*)
		alias ls="command ls --color=auto"
		_ls_l="command ls -l --color=auto"
		_ls_ll="command ls -laF --color=auto"
		_ls_la="command ls -a --color=auto"
		_ls_lr="command ls -R --color=auto"
		_ls_llr="command ls -laFR --color=auto"
		_ls_lar="command ls -aR --color=auto"
		;;
esac

if { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; } || [ -z "${_eza_bin}" ]; then
	alias l="${_ls_l}"
	alias ll="${_ls_ll}"
	alias la="${_ls_la}"
	alias lr="${_ls_lr}"
	alias llr="${_ls_llr}"
	alias lar="${_ls_lar}"
	command -v tree > "/dev/null" 2>&1 && alias lt="tree"
else
	case "${_eza_bin}" in
		*eza)
			alias l="${_eza_bin} --icons=auto --group-directories-first"
			alias ll="${_eza_bin} -la --icons=auto --group-directories-first --git"
			alias la="${_eza_bin} -a --icons=auto --group-directories-first"
			alias lt="${_eza_bin} --tree --icons=auto --group-directories-first"
			alias lr="${_eza_bin} -R --icons=auto --group-directories-first"
			alias lar="${_eza_bin} -aR --icons=auto --group-directories-first"
			alias llr="${_eza_bin} -laR --icons=auto --group-directories-first --git"
			;;
		*exa)
			alias l="${_eza_bin} --group-directories-first"
			alias ll="${_eza_bin} -la --group-directories-first --git"
			alias la="${_eza_bin} -a --group-directories-first"
			alias lt="${_eza_bin} --tree --group-directories-first"
			alias lr="${_eza_bin} -R --group-directories-first"
			alias lar="${_eza_bin} -aR --group-directories-first"
			alias llr="${_eza_bin} -laR --group-directories-first --git"
			;;
	esac
fi
unset _ls_l _ls_ll _ls_la _ls_lr _ls_llr _ls_lar _eza_bin

### --------------------------------
### SEARCH IN FILES
### --------------------------------
case "${_env_os}" in
	freebsd|dragonfly*|openbsd|netbsd|illumos|solaris|sunos) ;;
	*) alias grep="command grep --color=auto" ;;
esac

if [ -n "${_rg_bin}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
	alias g="${_rg_bin} --smart-case"
else
	alias g="grep -Ei"
fi
unset _rg_bin

### --------------------------------
### FILE PREVIEW
### --------------------------------
if [ -n "${_bat_bin}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
	alias c="${_bat_bin} --paging=never"
	alias b="${_bat_bin}"
else
	alias c="cat"
	alias b="${PAGER:-less}"
fi
unset _bat_bin

### --------------------------------
### FILE & PATH SEARCH
### --------------------------------
if [ -n "${_fd_bin}" ] && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
	alias f="${_fd_bin}"
	alias ff="${_fd_bin} --hidden --no-ignore"
else
	alias f="find"
	alias ff="find"
fi
unset _fd_bin _env_os

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
_dust_bin="${_DETECTED_DUST-$(_detect_dust)}"
if [ -n "${_dust_bin}" ]; then
	alias d="${_dust_bin}"
	alias dust="${_dust_bin}"
else
	alias d="du -h"
fi
unset _dust_bin

### --------------------------------
### PROCS PROCESS INSPECTION
### --------------------------------
_procs_bin="${_DETECTED_PROCS-$(_detect_procs)}"
if [ -n "${_procs_bin}" ]; then
	alias p="${_procs_bin}"
	alias procs="${_procs_bin}"
	alias pst="${_procs_bin} --tree"
else
	alias p="ps aux"
fi
unset _procs_bin

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
_zoxide_bin="${_DETECTED_ZOXIDE-$(_detect_zoxide)}"
if [ -n "${_zoxide_bin}" ]; then
	_ZO_DOCTOR=0
	export _ZO_DOCTOR
	case "${_DETECTED_SHELL-$(_detect_shell)}" in
		zsh)
			eval "$("${_zoxide_bin}" init zsh --hook prompt)"
			__zoxide_oldpwd="$(__zoxide_pwd)"
			__zoxide_hook() {
				_pwd_tmp="$(__zoxide_pwd)"
				if [ "${__zoxide_oldpwd}" != "${_pwd_tmp}" ]; then
					__zoxide_oldpwd="${_pwd_tmp}"
					command zoxide add -- "${__zoxide_oldpwd}" 2> "/dev/null"
				fi
				unset _pwd_tmp
			}
			;;
		bash) eval "$("${_zoxide_bin}" init bash)" ;;
		*)	eval "$("${_zoxide_bin}" init posix --hook prompt)" ;;
	esac
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
alias -- ~="cd ~" ..="cd .." ...="cd ../.." ....="cd ../../.." -="cd -"
alias take="take-dir" mkcd="take-dir" cdb="cd-git-root"
alias clear="[ -t 1 ] && echo -n \$'\e[2J\e[3J\e[H'"

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
### GOOGLE ANTIGRAVITY CLI & ALIASES
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
		if [ "${TERM:-}" = "linux" ] && [ "${_DETECTED_OS-$(_detect_os)}" = "linux" ]; then
			echo -n $'\e%G\e[?16;238;0c\e]P0000000\e]P17f0000\e]P2007f00\e]P3c4a100\e]P43366a3\e]P57f007f\e]P6007f7f\e]P7bfbfbf\e]P873828a\e]P9ff0000\e]Pa00ff00\e]Pbffff00\e]Pc739ecf\e]Pdff00ff\e]Pe00ffff\e]Pfffffff'
			command -v stty > "/dev/null" 2>&1 && stty iutf8 2> "/dev/null" || true
		fi
	else
		echo -n $'\e[1 q'
	fi
fi

### ================================
### USERLAND MANAGEMENT
### ================================

_userland_set_gnu() {
	_silent="${1:-}"
	export SHELL_USERLAND="gnu"
	_u_os="$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')"
	case "${_u_os}" in
		freebsd|openbsd|netbsd|dragonfly*|macos|darwin)
			for _gnubin in "/usr/local/libexec/gnubin" "/opt/homebrew/opt/coreutils/libexec/gnubin" "/usr/local/opt/coreutils/libexec/gnubin"; do
				if [ -d "${_gnubin}" ]; then
					case ":${PATH}:" in
						*":${_gnubin}:"*) ;;
						*) export PATH="${_gnubin}:${PATH}" ;;
					esac
				fi
			done
			command -v gsed > "/dev/null" 2>&1 && alias sed="gsed"
			command -v gawk > "/dev/null" 2>&1 && alias awk="gawk"
			command -v ggrep > "/dev/null" 2>&1 && alias grep="ggrep"
			command -v gtar > "/dev/null" 2>&1 && alias tar="gtar"
			command -v gfind > "/dev/null" 2>&1 && alias find="gfind"
			command -v gmake > "/dev/null" 2>&1 && alias make="gmake"
			command -v gstat > "/dev/null" 2>&1 && alias stat="gstat"
			command -v gdate > "/dev/null" 2>&1 && alias date="gdate"
			command -v gls > "/dev/null" 2>&1 && alias ls="gls --color=auto"
			;;
		*)
			unalias make tar cpio cat nc man 2> "/dev/null" || true
			alias ls="command ls --color=auto"
			alias grep="command grep --color=auto"
			;;
	esac
	unset _u_os _gnubin
	if [ "${_silent}" != "--silent" ]; then
		if command -v _ui_ok > "/dev/null" 2>&1; then
			_ui_ok "Userland alternado para GNU."
		else
			echo "Userland alternado para GNU."
		fi
	fi
}

_userland_set_bsd() {
	_silent="${1:-}"
	export SHELL_USERLAND="bsd"
	_u_os="$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')"
	case "${_u_os}" in
		freebsd|openbsd|netbsd|dragonfly*|macos|darwin)
			_clean_p=""
			_old_ifs="${IFS+x}"
			_saved_ifs="${IFS:-}"
			IFS=":"
			for _entry in ${PATH}; do
				case "${_entry}" in
					*/gnubin) continue ;;
					"") continue ;;
				esac
				_clean_p="${_clean_p:+${_clean_p}:}${_entry}"
			done
			if [ -n "${_old_ifs}" ]; then IFS="${_saved_ifs}"; else unset IFS; fi
			export PATH="${_clean_p}"
			unset _clean_p _old_ifs _saved_ifs _entry
			unalias sed awk grep tar find make stat date ls 2> "/dev/null" || true
			case "${_u_os}" in
				openbsd|illumos|solaris|sunos) alias ls="command ls -l" ;;
				*)                             alias ls="command ls -G" ;;
			esac
			;;
		*)
			command -v bmake > "/dev/null" 2>&1 && alias make="bmake"
			command -v bsdtar > "/dev/null" 2>&1 && alias tar="bsdtar"
			command -v bsdcpio > "/dev/null" 2>&1 && alias cpio="bsdcpio"
			command -v bsdcat > "/dev/null" 2>&1 && alias cat="bsdcat"
			command -v nc.openbsd > "/dev/null" 2>&1 && alias nc="nc.openbsd"
			command -v mandoc > "/dev/null" 2>&1 && alias man="mandoc"
			;;
	esac
	unset _u_os
	if [ "${_silent}" != "--silent" ]; then
		if command -v _ui_ok > "/dev/null" 2>&1; then
			_ui_ok "Userland alternado para BSD."
		else
			echo "Userland alternado para BSD."
		fi
	fi
}

_userland_set_default() {
	_silent="${1:-}"
	export SHELL_USERLAND="default"
	_u_os="$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')"
	_clean_p=""
	_old_ifs="${IFS+x}"
	_saved_ifs="${IFS:-}"
	IFS=":"
	for _entry in ${PATH}; do
		case "${_entry}" in
			*/gnubin) continue ;;
			"") continue ;;
		esac
		_clean_p="${_clean_p:+${_clean_p}:}${_entry}"
	done
	if [ -n "${_old_ifs}" ]; then IFS="${_saved_ifs}"; else unset IFS; fi
	export PATH="${_clean_p}"
	unset _clean_p _old_ifs _saved_ifs _entry

	unalias sed awk grep tar find make stat date ls cpio cat nc man 2> "/dev/null" || true
	case "${_u_os}" in
		freebsd|dragonfly*|macos|darwin|netbsd)
			alias ls="command ls -G"
			;;
		openbsd|illumos|solaris|sunos)
			alias ls="command ls -l"
			;;
		*)
			alias ls="command ls --color=auto"
			alias grep="command grep --color=auto"
			;;
	esac
	unset _u_os
	if [ "${_silent}" != "--silent" ]; then
		if command -v _ui_ok > "/dev/null" 2>&1; then
			_ui_ok "Userland restaurado para o padrão do SO hospedeiro."
		else
			echo "Userland restaurado para o padrão do SO hospedeiro."
		fi
	fi
}

userland() {
	case "${1:-}" in
		gnu|GNU)
			_userland_set_gnu "${2:-}"
			;;
		bsd|BSD)
			_userland_set_bsd "${2:-}"
			;;
		default|DEFAULT|native)
			_userland_set_default "${2:-}"
			;;
		status)
			if command -v _ui_info > "/dev/null" 2>&1; then
				_ui_info "Userland ativo: ${SHELL_USERLAND:-default}"
			else
				echo "Userland ativo: ${SHELL_USERLAND:-default}"
			fi
			;;
		*)
			cat <<- EOF
				Uso: userland [gnu|bsd|default|status]
				  gnu      Ativa userland GNU (gnubin / g-prefixed tools)
				  bsd      Ativa userland BSD (bmake, bsdtar, mandoc, etc)
				  default  Restaura o userland nativo do sistema operacional
				  status   Exibe o modo de userland configurado
			EOF
			;;
	esac
}

gnu() { userland gnu "$@"; }
bsd() { userland bsd "$@"; }
default() { userland default "$@"; }

case "$-" in
	*i*)
		case "${SHELL_USERLAND:-default}" in
			gnu|GNU|1) userland gnu --silent ;;
			bsd|BSD)   userland bsd --silent ;;
		esac
		;;
esac
