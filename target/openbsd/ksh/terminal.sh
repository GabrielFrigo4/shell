### ================================
### TERMINAL ENVIRONMENT
### ================================

if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ ! -t 0 ] || [ ! -t 1 ]; then
	return 0 2> "/dev/null" || exit 0
fi

case "$-" in
	*i*) ;;
	*) return 0 2> "/dev/null" || exit 0 ;;
esac

case "$(command ps -o comm= -p "${PPID}" 2> "/dev/null")" in
	su|-su) unset SHELL_INIT ;;
esac

if [ -z "${USER:-}" ] || [ "${USER}" != "$(command id -un 2> "/dev/null")" ]; then
	export USER="$(command id -un 2> "/dev/null")"
	unset SHELL_INIT
fi

if [ -z "${SHELL_INIT:-}" ]; then
	if [ -z "${SHELL_TARGET:-}" ]; then
		if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
			SHELL_TARGET="$(command -v ksh 2> "/dev/null")"
		elif command -v _detect_enabled_shell > "/dev/null" 2>&1; then
			SHELL_TARGET="$(_detect_enabled_shell)"
		fi
		[ -x "${SHELL_TARGET}" ] || SHELL_TARGET="$(command -v ksh 2> "/dev/null")"
	fi

	if [ -x "${SHELL_TARGET}" ] && [ "${SHELL_TARGET}" != "$(command -v ksh 2> "/dev/null")" ]; then
		export SHELL_INIT=1
		export SHELL="${SHELL_TARGET}"
		unset SHELL_TARGET
		[ -t 1 ] && printf '\x1b[2J\x1b[3J\x1b[H'
		exec "${SHELL}"
	else
		unset SHELL_TARGET
	fi
fi
