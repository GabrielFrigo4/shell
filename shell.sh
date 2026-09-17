#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: Universal Shell Component & Runtime Entrypoint
# ----------------------------------------------------------------

_SHELL_ROOT="$(cd "$(dirname "$0")" && pwd)"
export SHELL_REPO_DIR="${_SHELL_ROOT}"

### ================================
### DETECCAO DE INVOCACAO (SOURCE VS EXEC)
### ================================
_shell_is_sourced() {
	if [ -n "${ZSH_VERSION:-}" ]; then
		case "${ZSH_EVAL_CONTEXT:-}" in
			*:file*) return 0 ;;
			*) return 1 ;;
		esac
	fi
	if [ -n "${BASH_VERSION:-}" ]; then
		[ "${BASH_SOURCE[0]}" != "$0" ] && return 0 || return 1
	fi
	case "${0##*/}" in
		shell.sh) return 1 ;;
		*) return 0 ;;
	esac
}

### ================================
### BOOTSTRAP DE RUNTIME (MODO SOURCE)
### ================================
_shell_bootstrap() {
	for _mod in "${_SHELL_ROOT}/library/"*.sh; do
		[ -f "${_mod}" ] && . "${_mod}"
	done
	for _mod in "${_SHELL_ROOT}/core/"*.sh; do
		[ -f "${_mod}" ] && . "${_mod}"
	done
	unset _mod
}

### ================================
### SUBCOMANDOS DE LINHA DE COMANDO
### ================================
_shell_help() {
	cat <<- EOF
		Universal Shell — Interface Unificada de Componente

		Uso:
		  shell.sh [comando] [opcoes]
		  . shell.sh               # Sourceia e injeta runtime completo no shell atual

		Comandos:
		  update    Atualiza o repositorio (git pull --ff-only) e recarrega
		  bench     Mede a latencia de boot e inicializacao dos modulos
		  test      Valida a sintaxe Zsh, Bash, POSIX sh e ksh em todos os modulos
		  doctor    Audita presenca de ferramentas CLI modernas (eza, bat, fd, etc)
		  install   Executa instalador de configuracao nos shells do sistema
		  help      Exibe esta mensagem de ajuda
	EOF
}

_shell_update() {
	_shell_bootstrap
	update-shell "$@"
}

_shell_bench() {
	if [ -f "${_SHELL_ROOT}/benchmark.sh" ]; then
		sh "${_SHELL_ROOT}/benchmark.sh" "$@"
	else
		echo "❌ Script de benchmark não encontrado em ${_SHELL_ROOT}/benchmark.sh" >&2
		return 1
	fi
}

_shell_test() {
	echo "🧪 [Shell] Validando sintaxe dos scripts de shell..."
	if command -v make > "/dev/null" 2>&1; then
		make -C "${_SHELL_ROOT}" test
	else
		find "${_SHELL_ROOT}" -name "*.sh" -not -path "*/.git/*" -exec sh -n {} +
		echo "✅ [Shell] Sintaxe validada com sucesso!"
	fi
}

_shell_doctor() {
	_shell_bootstrap
	echo "🔍 [Shell] Diagnosticando ferramentas CLI instaladas..."
	for _tool in eza exa bat batcat fd fdfind rg dust procs btm btop htop; do
		if command -v "${_tool}" > "/dev/null" 2>&1; then
			printf "  ✅ %-12s encontrado: %s\n" "${_tool}" "$(command -v "${_tool}")"
		fi
	done
	unset _tool
}

_shell_install() {
	sh "${_SHELL_ROOT}/install.sh" "$@"
}

### ================================
### EXECUCAO PRINCIPAL
### ================================
if _shell_is_sourced; then
	_shell_bootstrap
	return 0 2> "/dev/null" || exit 0
fi

_cmd="${1:-help}"
shift 2> "/dev/null" || true

case "${_cmd}" in
	update)  _shell_update "$@" ;;
	bench)   _shell_bench "$@" ;;
	test)    _shell_test ;;
	doctor)  _shell_doctor ;;
	install) _shell_install "$@" ;;
	help|-h|--help) _shell_help ;;
	*)
		echo "❌ Comando desconhecido: ${_cmd}" >&2
		_shell_help >&2
		exit 1
		;;
esac
