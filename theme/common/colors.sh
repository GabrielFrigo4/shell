### ================================
### PROMPT COLOR PALETTE
### ================================

_THEME_ESCAPE=$'\e'
if [ "${#_THEME_ESCAPE}" -ne 1 ]; then
	_THEME_ESCAPE="$(printf '\x1b')"
fi

_THEME_KSH_DELIM=""
if [ -n "${KSH_VERSION:-}" ]; then
	_THEME_KSH_DELIM=$'\x01'
	if [ "${#_THEME_KSH_DELIM}" -ne 1 ]; then
		_THEME_KSH_DELIM="$(printf '\x01')"
	fi
fi

_setup_colors() {
	if [ -z "${_THEME_ESCAPE:-}" ] || [ "${#_THEME_ESCAPE}" -ne 1 ]; then
		_THEME_ESCAPE=$'\e'
		if [ "${#_THEME_ESCAPE}" -ne 1 ]; then
			_THEME_ESCAPE="$(printf '\x1b')"
		fi
	fi
	local _escape="${_THEME_ESCAPE}"

	local _theme_color_open="\["
	local _theme_color_close="\]"
	if [ -n "${ZSH_VERSION:-}" ]; then
		_theme_color_open="%{"
		_theme_color_close="%}"
	elif [ -n "${KSH_VERSION:-}" ]; then
		if [ -z "${_THEME_KSH_DELIM:-}" ] || [ "${#_THEME_KSH_DELIM}" -ne 1 ]; then
			_THEME_KSH_DELIM=$'\x01'
			if [ "${#_THEME_KSH_DELIM}" -ne 1 ]; then
				_THEME_KSH_DELIM="$(printf '\x01')"
			fi
		fi
		_theme_color_open="${_THEME_KSH_DELIM}"
		_theme_color_close="${_THEME_KSH_DELIM}"
	fi

	_theme_color_reset="${_theme_color_open}${_escape}[0m${_theme_color_close}"
	_theme_color_bold="${_theme_color_open}${_escape}[1m${_theme_color_close}"
	_theme_color_delimiter="${_theme_color_open}${_escape}[90m${_theme_color_close}"

	_theme_color_bright_gray="${_theme_color_open}${_escape}[90m${_theme_color_close}"
	_theme_color_bright_red="${_theme_color_open}${_escape}[91m${_theme_color_close}"
	_theme_color_bright_green="${_theme_color_open}${_escape}[92m${_theme_color_close}"
	_theme_color_bright_yellow="${_theme_color_open}${_escape}[93m${_theme_color_close}"
	_theme_color_bright_blue="${_theme_color_open}${_escape}[94m${_theme_color_close}"
	_theme_color_bright_magenta="${_theme_color_open}${_escape}[95m${_theme_color_close}"
	_theme_color_bright_cyan="${_theme_color_open}${_escape}[96m${_theme_color_close}"
	_theme_color_bright_white="${_theme_color_open}${_escape}[97m${_theme_color_close}"

	_theme_color_gray="${_theme_color_bright_gray}"
	_theme_color_red="${_theme_color_bright_red}"
	_theme_color_green="${_theme_color_bright_green}"
	_theme_color_yellow="${_theme_color_bright_yellow}"
	_theme_color_blue="${_theme_color_bright_blue}"
	_theme_color_magenta="${_theme_color_bright_magenta}"
	_theme_color_cyan="${_theme_color_bright_cyan}"
	_theme_color_white="${_theme_color_bright_white}"
}
