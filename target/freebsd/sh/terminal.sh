### ================================
### TERMINAL ENVIRONMENT
### ================================

case "$(command ps -o comm= -p "${PPID}" 2> "/dev/null")" in
	su|-su) unset SHELL_INIT ;;
esac

if [ "${USER}" != "$(command id -un)" ]; then
	export USER="$(command id -un)"
	unset SHELL_INIT
fi

if [ -z "${SHELL_INIT}" ]; then
	if [ -z "${SHELL_TARGET}" ]; then
		if _is_raw_tty; then
			SHELL_TARGET="$(command -v sh 2> "/dev/null")"
		else
			SHELL_TARGET="$(command -v zsh 2> "/dev/null")"
		fi
		[ -x "${SHELL_TARGET}" ] || SHELL_TARGET="$(command -v sh 2> "/dev/null")"
	fi

	if [ -x "${SHELL_TARGET}" ] && [ "${SHELL_TARGET}" != "$(command -v sh 2> "/dev/null")" ]; then
		export SHELL_INIT=1
		export SHELL="${SHELL_TARGET}"
		unset SHELL_TARGET
		command echo -n $'\e[2J\e[3J\e[H'
		exec "${SHELL}"
	else
		unset SHELL_TARGET
	fi
fi
