# ----------------------------------------------------------------
# Core: Dual-Mode GNU & BSD Userland Engine
# ----------------------------------------------------------------

### ================================
### USERLAND MANAGEMENT
### ================================
_userland_gnu_path_strip() {
	_rem="${PATH:-}"
	_clean_p=""
	while [ -n "${_rem}" ]; do
		case "${_rem}" in
			*:*) _entry="${_rem%%:*}"; _rem="${_rem#*:}" ;;
			*)   _entry="${_rem}"; _rem="" ;;
		esac
		case "${_entry}" in
			""|"/usr/gnu/bin"|"/usr/pkg/gnu/bin"|"/usr/local/gnu/bin"|*/gnubin|*/libexec/gnubin) continue ;;
		esac
		_clean_p="${_clean_p:+${_clean_p}:}${_entry}"
	done
	export PATH="${_clean_p}"
	unset _rem _clean_p _entry
}

_userland_build_gnu_cache() {
	_ubc_cache="${1}"
	[ -n "${ZSH_VERSION:-}" ] && setopt LOCAL_OPTIONS NULL_GLOB 2> "/dev/null" || true
	_ubc_dir="${_ubc_cache%/*}"
	mkdir -p "${_ubc_dir}" 2> "/dev/null" || return 1
	_ubc_tmp="${_ubc_cache}.tmp.$$"
	: >| "${_ubc_tmp}" 2> "/dev/null" || return 1

	set --
	for _ubc_pkg in "/usr/local/bin" "/usr/pkg/bin" "/opt/local/bin" "/opt/homebrew/bin"; do
		[ -d "${_ubc_pkg}" ] && set -- "$@" "${_ubc_pkg}"
	done
	for _ubc_opt in "/opt/homebrew/opt" "/usr/local/opt"; do
		if [ -d "${_ubc_opt}" ]; then
			for _ubc_pkg in "${_ubc_opt}/"*/bin; do
				[ -d "${_ubc_pkg}" ] && set -- "$@" "${_ubc_pkg}"
			done
		fi
	done

	_ubc_seen=" "
	_ubc_names=""
	_ubc_ls=""
	for _ubc_pkg in "$@"; do
		for _ubc_gbin in "${_ubc_pkg}/g"*; do
			[ -f "${_ubc_gbin}" ] && [ -x "${_ubc_gbin}" ] || continue
			_ubc_gname="${_ubc_gbin##*/}"
			_ubc_base="${_ubc_gname#g}"
			case "${_ubc_base}" in
				""|*[!a-zA-Z0-9_-]*) continue ;;
			esac
			case "${_ubc_gname}" in
				gcc|git|gdb|gpg|gpg2|gpgv|gpg-agent|gzip|gunzip|go|gofmt|gs|gperf|gprof|gcov|gcov-tool|gawkbug|grun) continue ;;
			esac
			case "${_ubc_base}" in
				cc|c++|it|db|pg|zip|unzip|o|s|perf|prof|cov|echo|printf|pwd|test|true|false|kill|sh|bash|zsh|ksh|csh|tcsh|su|login|vi|ex) continue ;;
			esac
			case "${_ubc_seen}" in
				*" ${_ubc_base} "*) continue ;;
			esac
			_ubc_cand=0
			if [ -x "/bin/${_ubc_base}" ] || [ -x "/usr/bin/${_ubc_base}" ]; then
				_ubc_cand=1
			else
				case "${_ubc_base}" in
					stat|date|nproc|realpath|readlink|seq|shuf|timeout|truncate|tac|numfmt|base64|base32|basenc|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|md5sum|b2sum|cksum|sum|dircolors|vdir|dir|watch|pinky|ptx|stdbuf|factor|tsort|unexpand|expand|fmt|fold|nl|pr|shred|split|csplit|comm|join|paste|sort|uniq|cut|tr|head|tail|wc|tee|cat|cp|mv|rm|ln|ls|mkdir|rmdir|mktemp|touch|chmod|chown|chgrp|df|du|dd|env|id|who|whoami|users|groups|uname|tty|arch|hostid|uptime|basename|dirname|link|unlink|mkfifo|mknod|pathchk|printenv|sleep|stty|sync|yes|expr|install|awk|sed|grep|egrep|fgrep|tar|find|xargs|diff|cmp|sdiff|diff3|make|patch|m4|indent)
						_ubc_cand=1
						;;
				esac
			fi
			[ "${_ubc_cand}" -eq 1 ] || continue
			_ubc_gver="$(DISPLAY="" WAYLAND_DISPLAY="" "${_ubc_gbin}" --version < "/dev/null" 2> "/dev/null" | head -n 5)"
			case "${_ubc_gver}" in
				*GNU*|*"Free Software Foundation"*) ;;
				*) continue ;;
			esac
			_ubc_seen="${_ubc_seen}${_ubc_base} "
			_ubc_names="${_ubc_names:+${_ubc_names} }${_ubc_base}"
			case "${_ubc_base}" in
				ls)
					_ubc_ls="${_ubc_gname}"
					printf 'alias ls="%s --color=auto"\n' "${_ubc_gname}" >> "${_ubc_tmp}"
					;;
				grep|egrep|fgrep)
					printf 'alias %s="%s --color=auto"\n' "${_ubc_base}" "${_ubc_gname}" >> "${_ubc_tmp}"
					;;
				*)
					printf 'alias %s="%s"\n' "${_ubc_base}" "${_ubc_gname}" >> "${_ubc_tmp}"
					;;
			esac
		done
	done

	printf '_SHELL_GNU_ALIASES="%s"\n' "${_ubc_names}" >> "${_ubc_tmp}"
	if [ -n "${_ubc_ls}" ]; then
		printf '_SHELL_GNU_LS_BIN="%s"\n' "${_ubc_ls}" >> "${_ubc_tmp}"
	fi
	mv -f "${_ubc_tmp}" "${_ubc_cache}"
	unset _ubc_cache _ubc_dir _ubc_tmp _ubc_pkg _ubc_opt _ubc_seen _ubc_names _ubc_ls _ubc_gbin _ubc_gname _ubc_base _ubc_cand _ubc_gver
}

_userland_set_gnu() {
	_silent="${1:-}"
	export SHELL_USERLAND="gnu"
	_u_os="${_DETECTED_OS:-$(uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}"
	[ -n "${ZSH_VERSION:-}" ] && setopt LOCAL_OPTIONS NULL_GLOB 2> "/dev/null" || true
	_SHELL_GNU_LS_BIN=""
	case "${_u_os}" in
		freebsd|openbsd|netbsd|macos|darwin|illumos|solaris|sunos)
			set --
			for _gnubin in "/usr/gnu/bin" "/usr/pkg/gnu/bin" "/usr/local/gnu/bin" "/usr/local/libexec/gnubin"; do
				[ -d "${_gnubin}" ] && set -- "$@" "${_gnubin}"
			done
			for _opt_root in "/opt/homebrew/opt" "/usr/local/opt"; do
				if [ -d "${_opt_root}" ]; then
					for _gnubin in "${_opt_root}/"*/libexec/gnubin; do
						[ -d "${_gnubin}" ] && set -- "$@" "${_gnubin}"
					done
				fi
			done
			if [ "$#" -gt 0 ]; then
				path-front "$@"
				[ -d "${HOME}/.local/bin" ] && path-front "${HOME}/.local/bin"
			fi

			_gnu_cache="${XDG_CACHE_HOME:-${HOME}/.cache}/shell/gnu_aliases_${_u_os}.sh"
			_cache_stale=0
			if [ ! -s "${_gnu_cache}" ]; then
				_cache_stale=1
			else
				for _pkg_dir in "/usr/local/bin" "/usr/pkg/bin" "/opt/local/bin" "/opt/homebrew/bin"; do
					if [ -d "${_pkg_dir}" ] && [ "${_pkg_dir}" -nt "${_gnu_cache}" ]; then
						_cache_stale=1
						break
					fi
				done
				if [ "${_cache_stale}" -eq 0 ]; then
					for _opt_root in "/opt/homebrew/opt" "/usr/local/opt"; do
						if [ -d "${_opt_root}" ]; then
							for _pkg_dir in "${_opt_root}/"*/bin; do
								if [ -d "${_pkg_dir}" ] && [ "${_pkg_dir}" -nt "${_gnu_cache}" ]; then
									_cache_stale=1
									break 2
								fi
							done
						fi
					done
				fi
			fi
			if [ "${_cache_stale}" -eq 1 ]; then
				_userland_build_gnu_cache "${_gnu_cache}" || true
			fi
			[ -s "${_gnu_cache}" ] && . "${_gnu_cache}"

			if [ -z "${_SHELL_GNU_LS_BIN:-}" ]; then
				if command -v gls > "/dev/null" 2>&1; then
					_SHELL_GNU_LS_BIN="gls"
					alias ls="gls --color=auto"
				else
					for _gnubin in "$@"; do
						if [ -x "${_gnubin}/ls" ]; then
							_SHELL_GNU_LS_BIN="ls"
							alias ls="command ls --color=auto"
							break
						fi
					done
				fi
			fi
			unset _gnubin _opt_root _pkg_dir _gnu_cache _cache_stale
			;;
		*)
			unalias make tar cpio cat nc man 2> "/dev/null" || true
			alias ls="command ls --color=auto"
			alias grep="command grep --color=auto"
			_SHELL_GNU_LS_BIN="ls"
			;;
	esac
	unset _u_os
	if [ "${_silent}" != "--silent" ]; then
		if command -v _ui_ok > "/dev/null" 2>&1; then
			_ui_ok "Userland alternado para GNU."
		else
			printf '%s\n' "Userland alternado para GNU."
		fi
	fi
}

_userland_set_bsd() {
	_silent="${1:-}"
	export SHELL_USERLAND="bsd"
	_u_os="${_DETECTED_OS:-$(uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}"
	case "${_u_os}" in
		freebsd|openbsd|netbsd|macos|darwin|illumos|solaris|sunos)
			_userland_gnu_path_strip
			[ -n "${_SHELL_GNU_ALIASES:-}" ] && eval "unalias ${_SHELL_GNU_ALIASES}" 2> "/dev/null" || true
			unalias sed awk grep egrep fgrep tar find xargs diff cmp sdiff diff3 patch make m4 indent stat date ls cat cp mv rm ln mkdir rmdir mktemp touch chmod chown chgrp head tail sort uniq cut tr wc df du dd readlink realpath nproc seq timeout 2> "/dev/null" || true
			unset _SHELL_GNU_ALIASES _SHELL_GNU_LS_BIN
			case "${_u_os}" in
				freebsd|macos|darwin) alias ls="command ls -G" ;;
			esac
			;;
		*)
			unset _SHELL_GNU_LS_BIN
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
			printf '%s\n' "Userland alternado para BSD."
		fi
	fi
}

_userland_set_default() {
	_silent="${1:-}"
	export SHELL_USERLAND="default"
	_u_os="${_DETECTED_OS:-$(uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}"
	_userland_gnu_path_strip
	[ -n "${_SHELL_GNU_ALIASES:-}" ] && eval "unalias ${_SHELL_GNU_ALIASES}" 2> "/dev/null" || true
	unalias sed awk grep egrep fgrep tar find xargs diff cmp sdiff diff3 patch make m4 indent stat date ls cat cp mv rm ln mkdir rmdir mktemp touch chmod chown chgrp head tail sort uniq cut tr wc df du dd readlink realpath nproc seq timeout cpio nc man 2> "/dev/null" || true
	unset _SHELL_GNU_ALIASES _SHELL_GNU_LS_BIN

	case "${_u_os}" in
		freebsd|macos|darwin)
			alias ls="command ls -G"
			;;
		illumos|solaris|sunos)
			[ -d "/usr/gnu/bin" ] && path-back "/usr/gnu/bin"
			;;
		openbsd|netbsd)
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
			printf '%s\n' "Userland restaurado para o padrão do SO hospedeiro."
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
				printf '%s\n' "Userland ativo: ${SHELL_USERLAND:-default}"
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
