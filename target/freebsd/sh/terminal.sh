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
fi

if [ -z "${SHELL_INIT:-}" ]; then
	if [ -z "${SHELL_TARGET:-}" ]; then
		if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
			SHELL_TARGET="$(command -v sh 2> "/dev/null")"
		elif command -v _detect_enabled_shell > "/dev/null" 2>&1; then
			SHELL_TARGET="$(_detect_enabled_shell)"
		fi
		[ -x "${SHELL_TARGET}" ] || SHELL_TARGET="$(command -v sh 2> "/dev/null")"
	fi

	if [ -x "${SHELL_TARGET}" ] && [ "${SHELL_TARGET}" != "$(command -v sh 2> "/dev/null")" ]; then
		export SHELL_INIT=1
		export SHELL="${SHELL_TARGET}"
		unset SHELL_TARGET
		[ -t 1 ] && echo -n $'\e[2J\e[3J\e[H'
		exec "${SHELL}"
	else
		unset SHELL_TARGET
	fi
fi

if [ -t 0 ] && [ -t 1 ]; then
	case "$-" in
		*i*)
			if command -v bind > "/dev/null" 2>&1 && (bind -e) > "/dev/null" 2>&1; then
				bind "\e[1;5C" em-next-word 2> "/dev/null" || true
				bind "\e[1;5D" ed-prev-word 2> "/dev/null" || true
				bind "\e[5C" em-next-word 2> "/dev/null" || true
				bind "\e[5D" ed-prev-word 2> "/dev/null" || true
				bind "\eOc" em-next-word 2> "/dev/null" || true
				bind "\eOd" ed-prev-word 2> "/dev/null" || true
			fi
			;;
	esac
fi
