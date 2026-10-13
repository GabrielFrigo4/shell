### ================================
### FREEBSD COMPAT RUNTIME
### ================================

### --------------------------------
### Go Runtime Linux Compat Tuning
### --------------------------------
export COMPAT_GODEBUG="netdns=go,http2client=0,asyncpreemptoff=1"
export COMPAT_GOMAXPROCS=2
export COMPAT_GOGC=8
export COMPAT_GOMEMLIMIT="1GiB"

### --------------------------------
### Antigravity under Linux Compat
### --------------------------------
agy-compat() {
	_ncpu="$(sysctl -n hw.ncpu 2> "/dev/null" || echo 4)"
	_running_count="$(pgrep -x agy 2> "/dev/null" | wc -l | tr -d ' ')"
	[ -z "${_running_count}" ] && _running_count=0
	_c1=$(( (_running_count * 2) % _ncpu ))
	_c2=$(( (_running_count * 2 + 1) % _ncpu ))

	_has_log=0
	for _arg in "$@"; do
		case "${_arg}" in
			*--log-file*) _has_log=1; break ;;
		esac
	done

	if [ "${_has_log}" -eq 1 ]; then
		limits -v 8g \
			env GODEBUG="${COMPAT_GODEBUG}" \
				GOMAXPROCS="${COMPAT_GOMAXPROCS}" \
				GOGC="${COMPAT_GOGC}" \
				GOMEMLIMIT="${COMPAT_GOMEMLIMIT}" \
			cpuset -l "${_c1},${_c2}" nice -n 16 \
			/usr/local/bin/agy "$@"
	else
		limits -v 8g \
			env GODEBUG="${COMPAT_GODEBUG}" \
				GOMAXPROCS="${COMPAT_GOMAXPROCS}" \
				GOGC="${COMPAT_GOGC}" \
				GOMEMLIMIT="${COMPAT_GOMEMLIMIT}" \
			cpuset -l "${_c1},${_c2}" nice -n 16 \
			/usr/local/bin/agy --log-file /dev/null "$@"
	fi
}

### --------------------------------
### Aliases
### --------------------------------
alias agy-cp="agy-compat"
