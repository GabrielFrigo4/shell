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

if ! command -v python3 > "/dev/null" 2>&1; then
	echo "❌ ERRO: 'python3' não foi encontrado no PATH." >&2
	echo "Instale o python3 para executar o benchmark (ex: pkg install python3)." >&2
	exit 1
fi

if [ -f "${_repo_dir}/library/detect.sh" ]; then
	. "${_repo_dir}/library/detect.sh"
	_os="$(_detect_os)"
fi

_iterations=5
for _arg in "$@"; do
	case "${_arg}" in
		--iterations=*|-i=*) _iterations="${_arg#*=}" ;;
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
	python3 -c "
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
    subprocess.run(cmd_args, shell=use_shell, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    times.append((time.perf_counter() - t0) * 1000)
avg = sum(times) / len(times)
print(f'{avg:.1f}')
" "${_cmd}" "${_iterations}" 2> "/dev/null" || echo "0.0"
}

_format_ms() {
	_val="${1}"
	_limit="${2:-64}"
	_val_int="${_val%.*}"
	if [ "${_val_int:-0}" -lt "${_limit}" ]; then
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
printf "%b%-12s %-12s %-10s %s%b\n" "${_c_bold}" "SHELL" "LATENCY" "STATUS" "TARGET" "${_c_reset}"
printf "%s\n" "----------------------------------------------------"

for _sh in zsh bash sh; do
	if command -v "${_sh}" > "/dev/null" 2>&1; then
		case "${_sh}" in
			zsh)  _target="< 64ms"; _target_limit=64 ;;
			bash) _target="< 64ms"; _target_limit=64 ;;
			sh)   _target="< 32ms"; _target_limit=32 ;;
			*)    _target="< 64ms"; _target_limit=64 ;;
		esac
		_ms="$(_measure_cmd "${_sh} -i -c exit")"
		_ms_int="${_ms%.*}"
		if [ "${_ms_int:-0}" -lt "${_target_limit}" ]; then
			_status_text="PASS"
			_status_color="${_c_green}"
			_lat_color="${_c_green}"
		elif [ "${_ms_int:-0}" -le "$(( _target_limit * 2 ))" ]; then
			_status_text="WARN"
			_status_color="${_c_yellow}"
			_lat_color="${_c_yellow}"
		else
			_status_text="SLOW"
			_status_color="${_c_red}"
			_lat_color="${_c_red}"
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
printf "%s\n" "----------------------------------------------------"

_shell_core_ms="$(_measure_cmd "sh -c '. ${_repo_dir}/library/detect.sh; . ${_repo_dir}/library/functions.sh; . ${_repo_dir}/core/environment.sh'")"
printf "%-24s %b\n" "Shell Core (sh)" "$(_format_ms "${_shell_core_ms}" 32)"

if command -v zsh > "/dev/null" 2>&1; then
	_prompt_zsh="${_repo_dir}/target/${_os}/zsh/prompt.sh"
	[ ! -f "${_prompt_zsh}" ] && _prompt_zsh="${_repo_dir}/target/linux/zsh/prompt.sh"
	if [ -f "${_prompt_zsh}" ]; then
		_shell_zsh_ms="$(_measure_cmd "zsh -c 'export SHELL_REPO_DIR=${_repo_dir}; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_zsh}\"'")"
		printf "%-24s %b\n" "Shell Stack (zsh)" "$(_format_ms "${_shell_zsh_ms}" 64)"
	fi
fi

if command -v bash > "/dev/null" 2>&1; then
	_prompt_bash="${_repo_dir}/target/${_os}/bash/prompt.sh"
	[ ! -f "${_prompt_bash}" ] && _prompt_bash="${_repo_dir}/target/linux/bash/prompt.sh"
	if [ -f "${_prompt_bash}" ]; then
		_shell_bash_ms="$(_measure_cmd "bash -c 'export SHELL_REPO_DIR=${_repo_dir}; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_bash}\"'")"
		printf "%-24s %b\n" "Shell Stack (bash)" "$(_format_ms "${_shell_bash_ms}" 64)"
	fi
fi

if command -v sh > "/dev/null" 2>&1; then
	_prompt_sh="${_repo_dir}/target/${_os}/sh/prompt.sh"
	[ ! -f "${_prompt_sh}" ] && _prompt_sh="${_repo_dir}/target/linux/sh/prompt.sh"
	if [ -f "${_prompt_sh}" ]; then
		_shell_sh_ms="$(_measure_cmd "sh -c 'export SHELL_REPO_DIR=${_repo_dir}; for f in ${_repo_dir}/library/*.sh ${_repo_dir}/core/*.sh; do . \"\$f\"; done; . \"${_prompt_sh}\"'")"
		printf "%-24s %b\n" "Shell Stack (sh)" "$(_format_ms "${_shell_sh_ms}" 64)"
	fi
fi

printf "\n%b✨ Benchmark completed successfully.%b\n" "${_c_green}" "${_c_reset}"
