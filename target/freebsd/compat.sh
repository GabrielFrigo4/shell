### ================================
### FREEBSD COMPAT RUNTIME
### ================================

### --------------------------------
### GO RUNTIME LINUX COMPAT TUNING
### --------------------------------
export COMPAT_GODEBUG="netdns=go,http2client=0,asyncpreemptoff=1"
export COMPAT_GOMAXPROCS=2
export COMPAT_GOGC=8
export COMPAT_GOMEMLIMIT="1GiB"

### --------------------------------
### ANTIGRAVITY UNDER LINUX COMPAT
### --------------------------------
agy-compat() {
	_ncpu="$(sysctl -n hw.ncpu 2> "/dev/null" || echo 4)"
	case "${_ncpu}" in
		''|*[!0-9]*) _ncpu=4 ;;
	esac
	_running_count="$(pgrep -x agy 2> "/dev/null" | wc -l | tr -d ' ')"
	case "${_running_count}" in
		''|*[!0-9]*) _running_count=0 ;;
	esac

	if [ "${_ncpu}" -ge 8 ]; then
		_ecore_count=$(( _ncpu - 4 ))
		_c1=$(( 4 + (_running_count * 2) % _ecore_count ))
		_c2=$(( 4 + (_running_count * 2 + 1) % _ecore_count ))
	else
		_c1=$(( (_running_count * 2) % _ncpu ))
		_c2=$(( (_running_count * 2 + 1) % _ncpu ))
	fi

	_has_log=0
	for _arg in "$@"; do
		case "${_arg}" in
			*--log-file*) _has_log=1; break ;;
		esac
	done

	if [ "${_has_log}" -eq 0 ]; then
		set -- --log-file /dev/null "$@"
	fi

	limits -m 8g \
		env GODEBUG="${COMPAT_GODEBUG}" \
			GOMAXPROCS="${COMPAT_GOMAXPROCS}" \
			GOGC="${COMPAT_GOGC}" \
			GOMEMLIMIT="${COMPAT_GOMEMLIMIT}" \
		cpuset -l "${_c1},${_c2}" nice -n 10 \
		/usr/local/bin/agy "$@"
	_rc=$?

	unset _ncpu _running_count _ecore_count _c1 _c2 _has_log _arg
	eval "unset _rc; return \"${_rc}\""
}

### --------------------------------
### ALIASES
### --------------------------------
alias agy-cp="agy-compat"
