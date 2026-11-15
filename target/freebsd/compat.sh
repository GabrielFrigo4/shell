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
	local _agy_bin="/usr/local/bin/agy"
	if [ ! -x "${_agy_bin}" ]; then
		if command -v _ui_err > "/dev/null" 2>&1; then
			_ui_err "Binário compat '${_agy_bin}' não encontrado ou sem permissão de execução."
		else
			echo "❌ Binário compat '${_agy_bin}' não encontrado ou sem permissão de execução." >&2
		fi
		return 127
	fi

	local _cpu_count _running_count _ecore_count _cpu_first _cpu_second _cpu_list
	_cpu_count="$(sysctl -n hw.ncpu 2> "/dev/null" || echo 4)"
	case "${_cpu_count}" in
		''|*[!0-9]*|0) _cpu_count=4 ;;
	esac

	_running_count="$(pgrep -x agy 2> "/dev/null" | wc -l | tr -d ' ')"
	case "${_running_count}" in
		''|*[!0-9]*) _running_count=0 ;;
	esac

	if [ "${_cpu_count}" -ge 8 ]; then
		_ecore_count=$(( _cpu_count - 4 ))
		_cpu_first=$(( 4 + (_running_count * 2) % _ecore_count ))
		_cpu_second=$(( 4 + (_running_count * 2 + 1) % _ecore_count ))
		_cpu_list="${_cpu_first},${_cpu_second}"
	elif [ "${_cpu_count}" -gt 1 ]; then
		_cpu_first=$(( (_running_count * 2) % _cpu_count ))
		_cpu_second=$(( (_running_count * 2 + 1) % _cpu_count ))
		_cpu_list="${_cpu_first},${_cpu_second}"
	else
		_cpu_list="0"
	fi

	local _has_log_flag=0 _arg
	for _arg in "$@"; do
		case "${_arg}" in
			*--log-file*) _has_log_flag=1; break ;;
		esac
	done

	if [ "${_has_log_flag}" -eq 0 ]; then
		set -- --log-file "/dev/null" "$@"
	fi

	set -- "${_agy_bin}" "$@"
	if command -v nice > "/dev/null" 2>&1; then
		set -- nice -n 10 "$@"
	fi
	if command -v cpuset > "/dev/null" 2>&1; then
		set -- cpuset -l "${_cpu_list}" "$@"
	fi
	set -- env \
		"GODEBUG=${COMPAT_GODEBUG}" \
		"GOMAXPROCS=${COMPAT_GOMAXPROCS}" \
		"GOGC=${COMPAT_GOGC}" \
		"GOMEMLIMIT=${COMPAT_GOMEMLIMIT}" \
		"$@"
	if command -v limits > "/dev/null" 2>&1; then
		set -- limits -m 8g "$@"
	fi

	command "$@"
	local _exit_code=$?
	return "${_exit_code}"
}

### --------------------------------
### ALIASES
### --------------------------------
alias agy-cp="agy-compat"
