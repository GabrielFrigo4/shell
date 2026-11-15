### ================================
### POSIX SHELL APPEARANCE
### ================================

_base_dir="${SHELL_REPO_DIR:-/usr/local/share/shell}"
[ -f "${_base_dir}/theme/common/colors.sh" ] && . "${_base_dir}/theme/common/colors.sh"
[ -f "${_base_dir}/theme/common/git.sh" ] && . "${_base_dir}/theme/common/git.sh"
unset _base_dir

_trim_string() {
	_trimmed="$1"
	[ "${2:-0}" -le 0 ] && _trimmed="" && return 0
	if [ "${#_trimmed}" -gt "$2" ]; then
		local _target_length=$(( $2 - 1 ))
		while [ "${#_trimmed}" -gt "${_target_length}" ] && [ -n "${_trimmed}" ]; do
			_trimmed="${_trimmed%?}"
		done
		_trimmed="${_trimmed}$3"
	fi
}

_calc_c_len() {
	local _string="$1"
	local _raw_length="${#_string}"

	local _remaining_string="${_string}" _open_delimiter_count=0
	while true; do
		case "${_remaining_string}" in
			*"\\["*) _open_delimiter_count=$(( _open_delimiter_count + 1 )); _remaining_string="${_remaining_string#*"\\["}" ;;
			*) break ;;
		esac
	done

	_remaining_string="${_string}"
	local _close_delimiter_count=0
	while true; do
		case "${_remaining_string}" in
			*"\\]"*) _close_delimiter_count=$(( _close_delimiter_count + 1 )); _remaining_string="${_remaining_string#*"\\]"}" ;;
			*) break ;;
		esac
	done

	_remaining_string="${_string}"
	local _escape_count=0
	while true; do
		case "${_remaining_string}" in
			*"\\e"*) _escape_count=$(( _escape_count + 1 )); _remaining_string="${_remaining_string#*"\\e"}" ;;
			*) break ;;
		esac
	done

	local _utf8_extra=0
	local _glyph
	for _glyph in "" "" "" "" "" "" "" "" "󰊢" "" "" "🐡" "" "" "" "" "" "" "󰖨" "" "" "󰣆"; do
		local _scan="${_string}"
		local _weight=2
		case "${_glyph}" in
			"󰊢"|"🐡"|"󰖨"|""|""|"󰣆") _weight=3 ;;
			*) _weight=2 ;;
		esac
		while true; do
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

	if [ -z "${_THEME_USER:-}" ]; then
		_THEME_USER="${USER:-${USERNAME:-${LOGNAME:-$(command id -un 2> "/dev/null" || echo "user")}}}"
	fi
	if [ -z "${_THEME_UID:-}" ]; then
		_THEME_UID="${EUID:-$(command id -u 2> "/dev/null" || echo 1000)}"
	fi
	if [ -z "${_THEME_HOST:-}" ]; then
		_THEME_HOST="${HOSTNAME:-$(command uname -n 2> "/dev/null" || echo "host")}"
		_THEME_HOST="${_THEME_HOST%%.*}"
	fi

	local _user="${USER:-${_THEME_USER}}"
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
	local _trimmed="" _c_bytes=0 _git_frame_string=""
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

	local _user_color="${_theme_color_green}" _user_icon_color="${_theme_color_blue}" _terminal_color="${_theme_color_blue}" _prompt_symbol="\$" _prompt_symbol_color="${_theme_color_cyan}"
	if [ "${EUID:-${_THEME_UID}}" -eq 0 ]; then
		_user="root"
		_user_icon_color="${_theme_color_red}"
		_terminal_color="${_theme_color_red}"
		if [ "${_mode}" = "tty" ]; then
			_user_color="${_theme_color_red}"
		else
			_user_color="${_theme_color_magenta}"
		fi
		_prompt_symbol="#"
		_prompt_symbol_color="${_theme_color_red}"
	fi

	local _host="${HOSTNAME:-${_THEME_HOST}}"
	_host="${_host%%.*}"

	local _os_icon="${PROMPT_OS_ICON:-${_DETECTED_DISTRO_ICON:- }}"
	_trim_string "${_os_icon}" 4 ""
	_os_icon="${_trimmed}"
	if [ -z "${PROMPT_OS_NAME:-}" ] && [ -z "${_DETECTED_DISTRO_VERSION:-}" ] && [ -z "${_THEME_FALLBACK_OS_NAME:-}" ]; then
		_THEME_FALLBACK_OS_NAME="$(_detect_distro_version 2> "/dev/null" || _detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || uname -s 2> "/dev/null" || echo "UNIX")"
	fi
	local _os_name="${PROMPT_OS_NAME:-${_DETECTED_DISTRO_VERSION:-${_THEME_FALLBACK_OS_NAME:-UNIX}}}"
	_os_name="${_os_name%%[-+~_]*}"
	if [ -z "${_DETECTED_KERNEL_RELEASE:-}" ] && [ -z "${_THEME_FALLBACK_KERNEL+x}" ]; then
		_THEME_FALLBACK_KERNEL="$(_detect_kernel_release 2> "/dev/null" || uname -r 2> "/dev/null" || echo "")"
	fi
	local _kernel_release="${_DETECTED_KERNEL_RELEASE:-${_THEME_FALLBACK_KERNEL:-}}"
	_kernel_release="${_kernel_release%%[-+~_]*}"
	if [ -z "${PROMPT_OS_TYPE:-}" ] && [ -z "${_DETECTED_OS:-}" ] && [ -z "${_THEME_FALLBACK_OS_TYPE:-}" ]; then
		_THEME_FALLBACK_OS_TYPE="$(_detect_os 2> "/dev/null" || uname -s 2> "/dev/null" | tr '[:upper:]' '[:lower:]' || echo "unix")"
	fi
	local _os_type="${PROMPT_OS_TYPE:-${_DETECTED_OS:-${_THEME_FALLBACK_OS_TYPE:-unix}}}"
	local _os_color

	case "${PROMPT_OS_COLOR:-blue}" in
		red)     _os_color="${_theme_color_red}" ;;
		green)   _os_color="${_theme_color_green}" ;;
		yellow)  _os_color="${_theme_color_yellow}" ;;
		blue)    _os_color="${_theme_color_blue}" ;;
		magenta) _os_color="${_theme_color_magenta}" ;;
		cyan)    _os_color="${_theme_color_cyan}" ;;
		white)   _os_color="${_theme_color_white}" ;;
		*)       _os_color="${_theme_color_blue}" ;;
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

	if [ -t 1 ]; then
		if [ "${_mode}" = "tty" ]; then
			[ "${TERM:-}" = "linux" ] && [ "${_os_type}" = "linux" ] && echo -n $'\e%G\e[?16;238;0c'
		else
			echo -n $'\e[1 q'
		fi
	fi
}

### --------------------------------
### PRECISION TRIGGERS
### --------------------------------
[ -z "${_zoxide_sh_oldpwd+x}" ] && _zoxide_sh_oldpwd="${PWD:-}"

_create_trigger() {
	local _command
	local _zoxide_block
	if [ -z "${_DETECTED_ZOXIDE+x}" ] && command -v _detect_zoxide > "/dev/null" 2>&1; then
		_detect_zoxide > "/dev/null" 2>&1 || true
	fi
	for _command in "$@"; do
		_zoxide_block=""
		if [ "${_command}" = "cd" ]; then
			_zoxide_block='
			if [ "${_exit_code}" -eq 0 ]; then
				if command -v __zoxide_hook > "/dev/null" 2>&1; then
					__zoxide_hook
				elif [ -n "${_DETECTED_ZOXIDE:-}" ]; then
					local _pwd_now="${PWD:-}"
					if [ "${_zoxide_sh_oldpwd:-}" != "${_pwd_now}" ]; then
						_zoxide_sh_oldpwd="${_pwd_now}"
						command zoxide add -- "${_zoxide_sh_oldpwd}" 2> "/dev/null" || true
					fi
				fi
			fi'
		fi
		eval "
		${_command}() {
			local _exit_code=0
			command ${_command} \"\$@\" || _exit_code=\$?
			${_zoxide_block}
			_update_prompt
			return \${_exit_code}
		}
		"
	done
}

_create_trigger cd git got
unalias : 2> "/dev/null" || true

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
