### ================================
### SHELL ENVIRONMENT
### ================================

### --------------------------------
### PATH
### --------------------------------
path-front "/usr/sbin"
path-front "/usr/bin"
path-front "/opt/local/sbin"
path-front "/opt/local/bin"

case "${SHELL_USERLAND:-default}" in
	gnu|GNU|1)
		path-front "/usr/gnu/bin"
		;;
	*)
		case ":${PATH:-}:" in
			*":/usr/gnu/bin:"*)
				_remaining_path="${PATH}"
				_clean_path=""
				while [ -n "${_remaining_path}" ]; do
					case "${_remaining_path}" in
						*:*) _path_entry="${_remaining_path%%:*}"; _remaining_path="${_remaining_path#*:}" ;;
						*)   _path_entry="${_remaining_path}"; _remaining_path="" ;;
					esac
					if [ -n "${_path_entry}" ] && [ "${_path_entry}" != "/usr/gnu/bin" ]; then
						_clean_path="${_clean_path:+${_clean_path}:}${_path_entry}"
					fi
				done
				export PATH="${_clean_path}"
				unset -v _remaining_path _clean_path _path_entry
				;;
		esac
		path-back "/usr/gnu/bin"
		;;
esac

path-front "${HOME}/.local/bin"
path-back "${HOME}/.cargo/bin"
path-dedup

### --------------------------------
### ILLUMOS ENVIRONMENT
### --------------------------------
export PAGER="${PAGER:-less}"

_remaining_manpath="${MANPATH:-}"
_clean_manpath=""
while [ -n "${_remaining_manpath}" ]; do
	case "${_remaining_manpath}" in
		*:*) _man_entry="${_remaining_manpath%%:*}"; _remaining_manpath="${_remaining_manpath#*:}" ;;
		*)   _man_entry="${_remaining_manpath}"; _remaining_manpath="" ;;
	esac
	case "${_man_entry}" in
		""|"/usr/gnu/share/man"|"/usr/share/man"|"/opt/local/share/man") continue ;;
	esac
	_clean_manpath="${_clean_manpath:+${_clean_manpath}:}${_man_entry}"
done

_illumos_manpath=""
case "${SHELL_USERLAND:-default}" in
	gnu|GNU|1)
		_illumos_manpath="/usr/gnu/share/man"
		[ -d "/opt/local/share/man" ] && _illumos_manpath="${_illumos_manpath}:/opt/local/share/man"
		_illumos_manpath="${_illumos_manpath}:/usr/share/man"
		[ -n "${_clean_manpath}" ] && _illumos_manpath="${_illumos_manpath}:${_clean_manpath}"
		;;
	*)
		[ -d "/opt/local/share/man" ] && _illumos_manpath="/opt/local/share/man:"
		_illumos_manpath="${_illumos_manpath}/usr/share/man"
		[ -n "${_clean_manpath}" ] && _illumos_manpath="${_illumos_manpath}:${_clean_manpath}"
		_illumos_manpath="${_illumos_manpath}:/usr/gnu/share/man"
		;;
esac
export MANPATH="${_illumos_manpath}"
unset -v _remaining_manpath _clean_manpath _man_entry _illumos_manpath
_SHELL_TARGET_ENV_LOADED=1
