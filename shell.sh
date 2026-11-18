#!/usr/bin/env sh
# ----------------------------------------------------------------
# Interface: Universal Shell Component & Runtime Entrypoint
# ----------------------------------------------------------------

if [ -n "${SHELL_REPO_DIR:-}" ] && [ -d "${SHELL_REPO_DIR}" ]; then
	_SHELL_ROOT="${SHELL_REPO_DIR}"
else
	if [ -n "${ZSH_VERSION:-}" ]; then
		case "${ZSH_EVAL_CONTEXT:-}" in
			*:file*) eval '_script_src="${(%):-%x}"' 2> "/dev/null" || _script_src="${0}" ;;
			*)       _script_src="${0}" ;;
		esac
	elif [ -n "${BASH_VERSION:-}" ]; then
		eval '_script_src="${BASH_SOURCE[0]:-${0}}"' 2> "/dev/null" || _script_src="${0}"
	else
		_script_src="${0}"
	fi
	case "${_script_src}" in
		-*|"") _script_dir="" ;;
		*/*)  _script_dir="${_script_src%/*}" ;;
		*)    _script_dir="" ;;
	esac
	if [ -n "${_script_dir}" ] && [ -d "${_script_dir}" ]; then
		_SHELL_ROOT="$(cd "${_script_dir}" && pwd)"
	elif [ -f "${PWD}/shell.sh" ] && [ -d "${PWD}/core" ]; then
		_SHELL_ROOT="${PWD}"
	elif [ -d "/usr/local/share/shell" ]; then
		_SHELL_ROOT="/usr/local/share/shell"
	elif [ -d "${HOME}/.local/share/shell" ]; then
		_SHELL_ROOT="${HOME}/.local/share/shell"
	else
		_SHELL_ROOT="${PWD}"
	fi
	unset _script_src _script_dir
fi
export SHELL_REPO_DIR="${_SHELL_ROOT}"

### ================================
### DETECCAO DE INVOCACAO
### ================================
_shell_is_sourced() {
	if [ -n "${ZSH_VERSION:-}" ]; then
		case "${ZSH_EVAL_CONTEXT:-}" in
			*:file*) return 0 ;;
			*) return 1 ;;
		esac
	fi
	if [ -n "${BASH_VERSION:-}" ]; then
		eval '_bash_src="${BASH_SOURCE[0]:-}"'
		if [ -n "${_bash_src}" ] && [ "${_bash_src}" != "${0}" ]; then
			unset _bash_src
			return 0
		fi
		unset _bash_src
		return 1
	fi
	case "${0##*/}" in
		shell.sh|init.sh) return 1 ;;
		*) return 0 ;;
	esac
}

### ================================
### BOOTSTRAP DE RUNTIME
### ================================
_shell_bootstrap() {
	for _module in detect.sh ui.sh elevate.sh perms.sh path.sh; do
		[ -f "${_SHELL_ROOT}/core/${_module}" ] && . "${_SHELL_ROOT}/core/${_module}"
	done
	command -v _self_heal_perms > "/dev/null" 2>&1 && _self_heal_perms "${_SHELL_ROOT}"
	_ctx="${SHELL_CONTEXT:-desktop}"
	for _module in "${_SHELL_ROOT}/library/"*.sh; do
		case "${_module##*/}" in
			desktop.sh) [ "${_ctx}" = "desktop" ] || continue ;;
		esac
		[ -f "${_module}" ] && . "${_module}"
	done
	_ctx_os="${_DETECTED_OS-$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]')}"
	[ -f "${_SHELL_ROOT}/target/${_ctx_os}/environment.sh" ] && . "${_SHELL_ROOT}/target/${_ctx_os}/environment.sh"
	for _module in "${_SHELL_ROOT}/core/"*.sh; do
		case "${_module##*/}" in
			deploy.sh|perms.sh|detect.sh|ui.sh|elevate.sh|path.sh) continue ;;
		esac
		[ -f "${_module}" ] && . "${_module}"
	done
	[ -f "${_SHELL_ROOT}/context/${_ctx}/common.sh" ] && . "${_SHELL_ROOT}/context/${_ctx}/common.sh"
	[ -f "${_SHELL_ROOT}/context/${_ctx}/${_ctx_os}.sh" ] && . "${_SHELL_ROOT}/context/${_ctx}/${_ctx_os}.sh"
	_SHELL_TARGET_ENV_LOADED=1
	_SHELL_CONTEXT_LOADED=1
	unset _module _ctx _ctx_os
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
		if command -v zsh > "/dev/null" 2>&1; then
			find "${_SHELL_ROOT}" -name "*.sh" -not -path "*/.git/*" -not -path "*/OSS/*" -not -path "*/bash/*" -not -name "bash.sh" -exec zsh -n {} +
		fi
		if command -v bash > "/dev/null" 2>&1; then
			find "${_SHELL_ROOT}" -name "*.sh" -not -path "*/.git/*" -not -path "*/OSS/*" -not -path "*/zsh/*" -not -name "zsh.sh" -exec bash -n {} +
		elif sh -c 'f-f() { :; }' 2> "/dev/null"; then
			find "${_SHELL_ROOT}" -name "*.sh" -not -path "*/.git/*" -not -path "*/OSS/*" -not -path "*/zsh/*" -not -name "zsh.sh" -exec sh -n {} +
		fi
		if command -v ksh > "/dev/null" 2>&1; then
			find "${_SHELL_ROOT}/core" "${_SHELL_ROOT}/library" "${_SHELL_ROOT}/target/openbsd/ksh" "${_SHELL_ROOT}/target/common/ksh" "${_SHELL_ROOT}/theme/ksh.sh" -name "*.sh" -exec ksh -n {} +
		elif command -v oksh > "/dev/null" 2>&1; then
			find "${_SHELL_ROOT}/core" "${_SHELL_ROOT}/library" "${_SHELL_ROOT}/target/openbsd/ksh" "${_SHELL_ROOT}/target/common/ksh" "${_SHELL_ROOT}/theme/ksh.sh" -name "*.sh" -exec oksh -n {} +
		fi
		if command -v fish > "/dev/null" 2>&1; then
			for _fish_file in "${_SHELL_ROOT}/target/common/fish/"*.fish; do
				[ -f "${_fish_file}" ] && fish -n "${_fish_file}"
			done
			unset _fish_file
		fi
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
