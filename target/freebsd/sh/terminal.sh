### ================================
### TERMINAL ENVIRONMENT
### ================================
### Sistema de inicialização do FreeBSD sh.
### chsh é sempre sh; este módulo detecta o tipo de terminal
### e faz exec para zsh quando apropriado.
### - ttyv*/console → mantém sh (terminal burro / sem GUI)
### - outros ttys   → exec para zsh (terminal gráfico / SSH)

case "$(command ps -o comm= -p $PPID)" in
	su|-su) unset SHELL_INIT ;;
esac

if [ "${USER}" != "$(command id -un)" ]; then
	export USER="$(command id -un)"
	unset SHELL_INIT
fi

if [ -z "${SHELL_INIT}" ]; then
	if [ -z "${SHELL_TARGET}" ]; then
		case "$(command tty 2> "/dev/null")" in
			"/dev/ttyv"*|"/dev/console") SHELL_TARGET="$(command -v sh 2> "/dev/null")" ;;
			*) SHELL_TARGET="$(command -v zsh 2> "/dev/null")" ;;
		esac
		[ -x "${SHELL_TARGET}" ] || SHELL_TARGET="$(command -v sh 2> "/dev/null")"
	fi

	if [ -x "${SHELL_TARGET}" ] && [ "${SHELL_TARGET}" != "$(command -v sh 2> "/dev/null")" ]; then
		export SHELL_INIT=1
		export SHELL="${SHELL_TARGET}"
		unset SHELL_TARGET
		command printf "\033[H\033[2J\033[3J"
		exec "${SHELL}"
	else
		unset SHELL_TARGET
	fi
fi
