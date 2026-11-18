# ----------------------------------------------------------------
# Core: PATH Manipulation & Forkless Binary Lookup
# ----------------------------------------------------------------

### ================================
### PATH MANIPULATION
### ================================
path-front() {
	local _prefix="" _arg _dir _rem _entry _rest=""
	for _arg in "$@"; do
		[ -z "${_arg}" ] && continue
		_dir="${_arg}"
		if [ ! -d "${_dir}" ]; then
			case "${_dir}" in
				"${HOME}/"*) mkdir -p "${_dir}" 2> "/dev/null" || true ;;
			esac
		fi
		[ -d "${_dir}" ] || continue
		case ":${_prefix}:" in
			*":${_dir}:"*) ;;
			*) _prefix="${_prefix:+${_prefix}:}${_dir}" ;;
		esac
	done
	[ -z "${_prefix}" ] && return 0
	_rem="${PATH:-}"
	while [ -n "${_rem}" ]; do
		case "${_rem}" in
			*:*) _entry="${_rem%%:*}"; _rem="${_rem#*:}" ;;
			*)   _entry="${_rem}"; _rem="" ;;
		esac
		[ -z "${_entry}" ] && continue
		case ":${_prefix}:" in
			*":${_entry}:"*) continue ;;
		esac
		case ":${_rest}:" in
			*":${_entry}:"*) continue ;;
		esac
		_rest="${_rest:+${_rest}:}${_entry}"
	done
	export PATH="${_prefix}${_rest:+:${_rest}}"
}

path-back() {
	local _arg _dir
	for _arg in "$@"; do
		[ -z "${_arg}" ] && continue
		_dir="${_arg}"
		case ":${PATH}:" in
			*":${_dir}:"*) ;;
			*)
				if [ ! -d "${_dir}" ]; then
					case "${_dir}" in
						"${HOME}/"*) mkdir -p "${_dir}" 2> "/dev/null" || true ;;
					esac
				fi
				[ -d "${_dir}" ] && export PATH="${PATH:+${PATH}:}${_dir}"
				;;
		esac
	done
}

path-dedup() {
	local _rem="${PATH:-}" _new_path="" _dir
	while [ -n "${_rem}" ]; do
		case "${_rem}" in
			*:*) _dir="${_rem%%:*}"; _rem="${_rem#*:}" ;;
			*)   _dir="${_rem}"; _rem="" ;;
		esac
		[ -z "${_dir}" ] && continue
		case ":${_new_path}:" in
			*":${_dir}:"*) ;;
			*) _new_path="${_new_path:+${_new_path}:}${_dir}" ;;
		esac
	done
	export PATH="${_new_path}"
}

### ================================
### FORKLESS BINARY LOOKUP
### ================================
_resolve_bin() {
	local _target="${1:-}"
	[ -z "${_target}" ] && return 1
	case "${_target}" in
		*/*)
			if [ -f "${_target}" ] && [ -x "${_target}" ]; then
				printf '%s\n' "${_target}"
				return 0
			fi
			return 1
			;;
	esac
	[ -z "${PATH:-}" ] && return 1
	local _rem="${PATH}:" _dir=""
	while [ -n "${_rem}" ]; do
		_dir="${_rem%%:*}"
		_rem="${_rem#*:}"
		[ -z "${_dir}" ] && _dir="."
		if [ -f "${_dir}/${_target}" ] && [ -x "${_dir}/${_target}" ]; then
			printf '%s\n' "${_dir}/${_target}"
			return 0
		fi
	done
	return 1
}

_has_bin() {
	local _target="${1:-}"
	[ -z "${_target}" ] && return 1
	case "${_target}" in
		*/*)
			[ -f "${_target}" ] && [ -x "${_target}" ]
			return "$?"
			;;
	esac
	[ -z "${PATH:-}" ] && return 1
	local _rem="${PATH}:" _dir=""
	while [ -n "${_rem}" ]; do
		_dir="${_rem%%:*}"
		_rem="${_rem#*:}"
		[ -z "${_dir}" ] && _dir="."
		if [ -f "${_dir}/${_target}" ] && [ -x "${_dir}/${_target}" ]; then
			return 0
		fi
	done
	return 1
}
