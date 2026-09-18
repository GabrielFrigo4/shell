### ================================
### POSIX SHELL APPEARANCE
### ================================

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"

_trim_str() {
	_trimmed="$1"
	if [ "${#_trimmed}" -gt "$2" ]; then
		local _target=$(( $2 - 1 ))
		while [ "${#_trimmed}" -gt "${_target}" ]; do
			_trimmed="${_trimmed%?}"
		done
		_trimmed="${_trimmed}$3"
	fi
}

_calc_theme_color_len() {
	local _s="$1"
	local _raw="${#_s}"

	local _tmp="${_s}" _n_open=0
	while :; do
		case "${_tmp}" in
			*"\\["*) _n_open=$(( _n_open + 1 )); _tmp="${_tmp#*"\\["}" ;;
			*) break ;;
		esac
	done

	_tmp="${_s}"
	local _n_close=0
	while :; do
		case "${_tmp}" in
			*"\\]"*) _n_close=$(( _n_close + 1 )); _tmp="${_tmp#*"\\]"}" ;;
			*) break ;;
		esac
	done

	_tmp="${_s}"
	local _n_esc=0
	while :; do
		case "${_tmp}" in
			*"\\e"*) _n_esc=$(( _n_esc + 1 )); _tmp="${_tmp#*"\\e"}" ;;
			*) break ;;
		esac
	done

	_theme_color_bytes=$(( _raw - _n_open - _n_close - _n_esc ))
}

_update_prompt() {
	_setup_colors

	local _user="${USER:-$(command id -un)}"
	local _sh_name="sh"

	local _pwd="${PWD:-$(command pwd)}"
	if [ "${_pwd}" = "${HOME}" ]; then
		_pwd="~"
	elif [ "${_pwd}" = "/" ]; then
		_pwd="/"
	else
		_pwd="${_pwd##*/}"
		[ -z "${_pwd}" ] && _pwd="/"
	fi

	local _branch _is_dirty
	_git_branch

	local _budget _max_pwd _max_branch
	local _pwd_len="${#_pwd}"
	local _branch_len="${#_branch}"

	local _prompt_limit="${PROMPT_BUFFER_LIMIT:-192}"
	local _style="${PROMPT_STYLE:-pill}"
	case "${_style}" in
		micro) ;;
		*) _style="pill" ;;
	esac
	[ "${_prompt_limit}" -lt 192 ] && _style="micro"

	local _mode="pty"
	_is_raw_tty && _mode="tty"

	local _base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
	if [ "${_mode}_${_style}" != "${_LOADED_PROMPT_STYLE_SH:-}" ]; then
		if [ -f "${_base_dir}/theme/styles/${_mode}/${_style}.sh" ]; then
			. "${_base_dir}/theme/styles/${_mode}/${_style}.sh"
			_LOADED_PROMPT_STYLE_SH="${_mode}_${_style}"
		fi
	fi

	local _u_color="${_theme_color_green}" _term_color="${_theme_color_blue}" _sym="\$" _sym_color="${_theme_color_cyan}"
	if [ "${EUID:-$(command id -u)}" -eq 0 ]; then
		_u_color="${_theme_color_red}"
		_term_color="${_theme_color_red}"
		_sym="#"
		_sym_color="${_theme_color_red}"
	fi

	local _host="${HOSTNAME%%.*}"
	[ -z "${_host}" ] && _host="$(command uname -n 2> "/dev/null" | command cut -d. -f1)"

	local _os_icon="${PROMPT_OS_ICON:- }"
	_trim_str "${_os_icon}" 4 ""
	_os_icon="${_trimmed}"
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_KERNEL_RELEASE:-$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "BSD")}}"
	_os_name="${_os_name%%-*}"
	local _os_color

	case "${PROMPT_OS_COLOR:-red}" in
		red)  _os_color="${_theme_color_b_red}" ;;
		blue) _os_color="${_theme_color_b_blue}" ;;
		*)    _os_color="${_theme_color_b_blue}" ;;
	esac

	local _fixed_str=""
	_theme_layout

	_calc_theme_color_len "${_fixed_str}"
	_budget=$(( _prompt_limit - 2 - _theme_color_bytes ))
	[ "${_budget}" -lt 4 ] && _budget=4

	if [ -n "${_branch}" ]; then
		if [ $(( _pwd_len + _branch_len )) -le "${_budget}" ]; then
			_max_pwd="${_pwd_len}"
			_max_branch="${_branch_len}"
		else
			local _half=$(( _budget / 2 ))
			if [ "${_pwd_len}" -lt "${_half}" ]; then
				_max_pwd="${_pwd_len}"
				_max_branch=$(( _budget - _pwd_len ))
			elif [ "${_branch_len}" -lt "${_half}" ]; then
				_max_branch="${_branch_len}"
				_max_pwd=$(( _budget - _branch_len ))
			else
				_max_pwd="${_half}"
				_max_branch=$(( _budget - _half ))
			fi
		fi
		_trim_str "${_branch}" "${_max_branch}" "~"
		_branch="${_trimmed}"
	else
		_max_pwd="${_budget}"
	fi

	_trim_str "${_pwd}" "${_max_pwd}" "~"
	_pwd="${_trimmed}"

	_theme_render
}

### --------------------------------
### Precision Triggers
### --------------------------------
_create_trigger() {
	for _cmd in "$@"; do
		eval "
		${_cmd}() {
			command ${_cmd} \"\$@\"
			local _ret=\$?
			_update_prompt
			return \${_ret}
		}
		"
	done
}

_create_trigger cd git got

alias :="_update_prompt; command :"

case "$-" in
	*i*)
		if [ -t 1 ]; then
			_update_prompt
		else
			PS1='$ '
		fi
		;;
	*) PS1='$ ' ;;
esac
