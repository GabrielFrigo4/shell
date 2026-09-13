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
		if _is_raw_tty; then
			SHELL_TARGET="$(command -v sh 2> "/dev/null")"
		else
			SHELL_TARGET="$(command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || command -v sh 2> "/dev/null")"
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
