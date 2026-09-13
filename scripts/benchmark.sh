#!/usr/bin/env sh
# ----------------------------------------------------------------
# Benchmark: Shell Startup Latency
# ----------------------------------------------------------------

### --------------------------------
### Environment Setup
### --------------------------------
_repo_dir="$(cd "$(dirname "${0}")/.." && pwd)"

case ":${PATH}:" in
	*":/usr/local/bin:"*) ;;
	*) PATH="/usr/local/bin:${PATH}"; export PATH ;;
esac
case ":${PATH}:" in
	*":/usr/pkg/bin:"*) ;;
	*) PATH="/usr/pkg/bin:${PATH}"; export PATH ;;
esac

_py_bin=""
if command -v python3 > "/dev/null" 2>&1; then
	_py_bin="python3"
elif command -v python > "/dev/null" 2>&1 && python -c "import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)" > "/dev/null" 2>&1; then
	_py_bin="python"
else
	for _c in python3.13 python3.12 python3.11 python3.10 python3.9; do
		if command -v "${_c}" > "/dev/null" 2>&1; then
			_py_bin="${_c}"
			break
		fi
	done
fi

if [ -z "${_py_bin}" ]; then
	echo "❌ ERRO: 'python3' não foi encontrado no PATH." >&2
	echo "Instale o python3 para executar o benchmark (ex: pkg install python3)." >&2
	exit 1
fi

if [ -f "${_repo_dir}/library/detect.sh" ]; then
	. "${_repo_dir}/library/detect.sh"
	_os="${_os:-$(_detect_os)}"
fi

_iterations=5
for _arg in "$@"; do
	case "${_arg}" in
		--iterations=*|-i=*) _iterations="${_arg#*=}" ;;
		--os=*)              _os="${_arg#*=}" ;;
		[0-9]*)              _iterations="${_arg}" ;;
	esac
done
case "${_iterations}" in
	""|*[!0-9]*|0) _iterations=5 ;;
esac

if [ -t 1 ]; then
	_c_reset=$'\e[0m'
	_c_bold=$'\e[1m'
	_c_green=$'\e[32m'
	_c_yellow=$'\e[33m'
	_c_red=$'\e[31m'
	_c_cyan=$'\e[36m'
else
	_c_reset=""
	_c_bold=""
	_c_green=""
	_c_yellow=""
	_c_red=""
	_c_cyan=""
fi

printf "%b⚡ Shell Startup Latency Benchmark%b (iters: %s, standard: 2^n)\n\n" "${_c_bold}${_c_cyan}" "${_c_reset}" "${_iterations}"

### --------------------------------
### Measurement Runner
### --------------------------------
_measure_cmd() {
	_cmd="${1}"
	"${_py_bin}" -c "
import sys, time, subprocess, shlex
cmd_str = sys.argv[1]
iters = max(1, int(sys.argv[2]))
try:
    cmd_args = shlex.split(cmd_str)
    use_shell = any(tok in ('|', '||', '&&', ';', '&', '>', '>>', '<') for tok in cmd_args)
    if use_shell:
        cmd_args = cmd_str
except Exception:
    use_shell = True
    cmd_args = cmd_str
times = []
for _ in range(iters):
    t0 = time.perf_counter()
    try:
        subprocess.run(cmd_args, shell=use_shell, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
    except Exception:
        pass
    times.append((time.perf_counter() - t0) * 1000)
avg = sum(times) / len(times)
print(f'{avg:.1f}')
" "${_cmd}" "${_iterations}" 2> "/dev/null" || echo "0.0"
}

_format_ms() {
	_val="${1}"
	_limit="${2:-64}"
	_val_int="${_val%.*}"
	_ultra_limit="$(( _limit / 2 ))"
	if [ "${_val_int:-0}" -lt "${_ultra_limit}" ]; then
		printf "%b%sms%b" "${_c_bold}${_c_cyan}" "${_val}" "${_c_reset}"
	elif [ "${_val_int:-0}" -lt "${_limit}" ]; then
		printf "%b%sms%b" "${_c_green}" "${_val}" "${_c_reset}"
	elif [ "${_val_int:-0}" -le "$(( _limit * 2 ))" ]; then
		printf "%b%sms%b" "${_c_yellow}" "${_val}" "${_c_reset}"
	else
		printf "%b%sms%b" "${_c_red}" "${_val}" "${_c_reset}"
	fi
}

### --------------------------------
### Benchmark Interactive Shells
### --------------------------------
printf "%b%-12s %-12s %-10s %s%b\n" "${_c_bold}" "SHELL" "LATENCY" "STATUS" "TARGET (PASS / ULTRA / WARN)" "${_c_reset}"
printf "%s\n" "----------------------------------------------------------------"

_specified_shells=""
for _arg in "$@"; do
	case "${_arg}" in
		zsh|bash|sh|dash|ksh|oksh|fish) _specified_shells="${_specified_shells} ${_arg}" ;;
	esac
done

_is_shell_selected() {
	[ -z "${_specified_shells}" ] || case " ${_specified_shells} " in *" ${1} "*) return 0 ;; *) return 1 ;; esac
}

if [ -n "${_specified_shells}" ]; then
	set -- ${_specified_shells}
elif [ "${_os}" = "freebsd" ]; then
	set -- zsh bash sh
elif [ "${_os}" = "openbsd" ]; then
	if command -v ksh > "/dev/null" 2>&1; then
		set -- zsh bash ksh
	else
		set -- zsh bash oksh
	fi
elif [ "${_os}" = "netbsd" ]; then
	set -- zsh bash
else
	set -- zsh bash
fi

if [ "${_os}" = "windows" ]; then
	_target_limit=256
	_ultra_limit=128
	_max_tolerance=512
else
	_target_limit=64
	_ultra_limit=32
	_max_tolerance=128
fi

_has_failure=0

for _sh in "$@"; do
	if command -v "${_sh}" > "/dev/null" 2>&1; then
		_target="< ${_target_limit}ms (U < ${_ultra_limit}ms, W < ${_max_tolerance}ms)"
		_cmd_bench="${_sh} -i -c exit"
		if [ "${_sh}" = "sh" ] && [ -f "${HOME}/.shrc" ]; then
			_cmd_bench="ENV=\"${HOME}/.shrc\" SHELL_INIT=1 ${_sh} -i -c exit"
		elif [ "${_sh}" = "ksh" ] && [ -f "${HOME}/.kshrc" ]; then
			_cmd_bench="ENV=\"${HOME}/.kshrc\" SHELL_INIT=1 ${_sh} -i -c exit"
		fi
		_ms="$(_measure_cmd "${_cmd_bench}")"
		_ms_int="${_ms%.*}"
		if [ "${_ms_int:-0}" -lt "${_ultra_limit}" ]; then
			_status_text="ULTRA"
			_status_color="${_c_bold}${_c_cyan}"
			_lat_color="${_c_bold}${_c_cyan}"
		elif [ "${_ms_int:-0}" -lt "${_target_limit}" ]; then
			_status_text="PASS"
			_status_color="${_c_green}"
			_lat_color="${_c_green}"
		elif [ "${_ms_int:-0}" -le "${_max_tolerance}" ]; then
			_status_text="WARN"
			_status_color="${_c_yellow}"
			_lat_color="${_c_yellow}"
		else
			_status_text="FAIL"
			_status_color="${_c_bold}${_c_red}"
			_lat_color="${_c_bold}${_c_red}"
			_has_failure=1
		fi
		printf "%-12s %b%-12s%b %b%-10s%b %s\n" \
			"${_sh}" \
			"${_lat_color}" "${_ms}ms" "${_c_reset}" \
			"${_status_color}" "${_status_text}" "${_c_reset}" \
			"${_target}"
	fi
done

### --------------------------------
### Benchmark Ecosystem Modules
### --------------------------------
printf "\n%b📦 Ecosystem Modules Latency%b\n" "${_c_bold}${_c_cyan}" "${_c_reset}"
printf "%s\n" "----------------------------------------------------------------"

if _is_shell_selected zsh && command -v zsh > "/dev/null" 2>&1; then
	_prompt_zsh="${_repo_dir}/target/${_os}/zsh/prompt.sh"
	if [ -f "${_prompt_zsh}" ]; then
		_shell_zsh_ms="$(_measure_cmd "zsh -c 'export SHELL_REPO_DIR=${_repo_dir}; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_zsh}\"'")"
		printf "%-24s %b\n" "Shell Stack (zsh)" "$(_format_ms "${_shell_zsh_ms}" "${_target_limit}")"
	fi
fi

if _is_shell_selected bash && command -v bash > "/dev/null" 2>&1; then
	_prompt_bash="${_repo_dir}/target/${_os}/bash/prompt.sh"
	if [ -f "${_prompt_bash}" ]; then
		_shell_bash_ms="$(_measure_cmd "bash -c 'export SHELL_REPO_DIR=${_repo_dir}; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_bash}\"'")"
		printf "%-24s %b\n" "Shell Stack (bash)" "$(_format_ms "${_shell_bash_ms}" "${_target_limit}")"
	fi
fi

if [ "${_os}" = "freebsd" ] && _is_shell_selected sh && command -v sh > "/dev/null" 2>&1; then
	_prompt_sh="${_repo_dir}/target/freebsd/sh/prompt.sh"
	if [ -f "${_prompt_sh}" ]; then
		_shell_sh_ms="$(_measure_cmd "sh -c 'export SHELL_REPO_DIR=${_repo_dir}; export SHELL_INIT=1; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_sh}\"'")"
		printf "%-24s %b\n" "Shell Stack (sh)" "$(_format_ms "${_shell_sh_ms}" "${_target_limit}")"
	fi
fi

if [ "${_os}" = "freebsd" ] && _is_shell_selected sh; then
	_shell_core_ms="$(_measure_cmd "sh -c '. ${_repo_dir}/library/detect.sh; . ${_repo_dir}/library/functions.sh; . ${_repo_dir}/core/environment.sh'")"
	printf "%-24s %b\n" "Shell Core (sh)" "$(_format_ms "${_shell_core_ms}" "${_target_limit}")"
fi

if [ "${_os}" = "openbsd" ]; then
	_ksh_bin=""
	command -v ksh > "/dev/null" 2>&1 && _ksh_bin="ksh"
	[ -z "${_ksh_bin}" ] && command -v oksh > "/dev/null" 2>&1 && _ksh_bin="oksh"
	if [ -n "${_ksh_bin}" ] && _is_shell_selected "${_ksh_bin}"; then
		_prompt_ksh="${_repo_dir}/target/openbsd/ksh/prompt.sh"
		if [ -f "${_prompt_ksh}" ]; then
			_shell_ksh_ms="$(_measure_cmd "${_ksh_bin} -c 'export SHELL_REPO_DIR=${_repo_dir}; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_ksh}\"'")"
			printf "%-24s %b\n" "Shell Stack (${_ksh_bin})" "$(_format_ms "${_shell_ksh_ms}" "${_target_limit}")"
		fi
	fi
fi

if [ "${_has_failure}" -ne 0 ]; then
	printf "\n%b❌ ERRO: Latência de inicialização excedeu o teto de tolerância de %sms (2^n).%b\n" "${_c_bold}${_c_red}" "${_max_tolerance}" "${_c_reset}" >&2
	exit 1
fi

printf "\n%b✨ Benchmark completed successfully.%b\n" "${_c_green}" "${_c_reset}"
