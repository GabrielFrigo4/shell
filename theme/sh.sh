### ================================
### POSIX SHELL APPEARANCE
### ================================

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"

_trim_string() {
	_trimmed="$1"
	if [ "${#_trimmed}" -gt "$2" ]; then
		local _target_length=$(( $2 - 1 ))
		while [ "${#_trimmed}" -gt "${_target_length}" ]; do
			_trimmed="${_trimmed%?}"
		done
		_trimmed="${_trimmed}$3"
	fi
}

_calc_c_len() {
	local _string="$1"
	local _raw_length="${#_string}"

	local _remaining_string="${_string}" _open_delimiter_count=0
	while :; do
		case "${_remaining_string}" in
			*"\\["*) _open_delimiter_count=$(( _open_delimiter_count + 1 )); _remaining_string="${_remaining_string#*"\\["}" ;;
			*) break ;;
		esac
	done

	_remaining_string="${_string}"
	local _close_delimiter_count=0
	while :; do
		case "${_remaining_string}" in
			*"\\]"*) _close_delimiter_count=$(( _close_delimiter_count + 1 )); _remaining_string="${_remaining_string#*"\\]"}" ;;
			*) break ;;
		esac
	done

	_remaining_string="${_string}"
	local _escape_count=0
	while :; do
		case "${_remaining_string}" in
			*"\\e"*) _escape_count=$(( _escape_count + 1 )); _remaining_string="${_remaining_string#*"\\e"}" ;;
			*) break ;;
		esac
	done

	local _utf8_extra=0
	for _glyph in "" "" "" "" "" "" "󰊢" "" "🐡" "" "" "" "" "󰖨"; do
		local _scan="${_string}"
		local _weight=2
		case "${_glyph}" in
			"󰊢"|"🐡"|"󰖨") _weight=3 ;;
			*) _weight=2 ;;
		esac
		while :; do
			case "${_scan}" in
				*"${_glyph}"*)
					_utf8_extra=$(( _utf8_extra + _weight ))
					_scan="${_scan#*"${_glyph}"}"
					;;
				*) break ;;
			esac
		done
	done

	_c_bytes=$(( _raw_length + _utf8_extra - _open_delimiter_count - _close_delimiter_count - _escape_count ))
}

_update_prompt() {
	_setup_colors

	local _user="${USER:-$(command id -un)}"
	local _shell_name="sh"

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
	if command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; then
		_mode="tty"
	fi

	local _base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
	if [ "${_mode}_${_style}" != "${_LOADED_PROMPT_STYLE_SH:-}" ]; then
		if [ -f "${_base_dir}/theme/styles/${_mode}/${_style}.sh" ]; then
			. "${_base_dir}/theme/styles/${_mode}/${_style}.sh"
			_LOADED_PROMPT_STYLE_SH="${_mode}_${_style}"
		fi
	fi

	local _user_color="${_theme_color_green}" _terminal_color="${_theme_color_blue}" _prompt_symbol="\$" _prompt_symbol_color="${_theme_color_cyan}"
	if [ "${EUID:-$(command id -u)}" -eq 0 ]; then
		[ "${_mode}" = "tty" ] && _user_color="${_theme_color_red}"
		_terminal_color="${_theme_color_red}"
		_prompt_symbol="#"
		_prompt_symbol_color="${_theme_color_red}"
	fi

	local _host="${HOSTNAME%%.*}"
	[ -z "${_host}" ] && _host="$(command uname -n 2> "/dev/null" | command cut -d. -f1)"

	local _os_icon="${PROMPT_OS_ICON:- }"
	_trim_string "${_os_icon}" 4 ""
	_os_icon="${_trimmed}"
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_KERNEL_RELEASE:-$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "BSD")}}"
	_os_name="${_os_name%%-*}"
	local _os_color

	case "${PROMPT_OS_COLOR:-red}" in
		red)  _os_color="${_theme_color_bright_red}" ;;
		blue) _os_color="${_theme_color_bright_blue}" ;;
		*)    _os_color="${_theme_color_bright_blue}" ;;
	esac

	local _fixed_string=""
	if command -v _theme_layout > "/dev/null" 2>&1; then
		_theme_layout
	fi

	_calc_c_len "${_fixed_string}"
	_budget=$(( _prompt_limit - 2 - _c_bytes ))
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
		_trim_string "${_branch}" "${_max_branch}" "~"
		_branch="${_trimmed}"
	else
		_max_pwd="${_budget}"
	fi

	_trim_string "${_pwd}" "${_max_pwd}" "~"
	_pwd="${_trimmed}"

	if command -v _theme_render > "/dev/null" 2>&1; then
		_theme_render
	fi
}

### --------------------------------
### Precision Triggers
### --------------------------------
_create_trigger() {
	for _command in "$@"; do
		eval "
		${_command}() {
			command ${_command} \"\$@\"
			local _exit_code=\$?
			_update_prompt
			return \${_exit_code}
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
