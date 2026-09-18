### ================================
### PROMPT COLOR PALETTE
### ================================

_setup_colors() {
	local _escape
	_escape="$(printf '\033')"

	local _theme_color_open="\["
	local _theme_color_close="\]"
	if [ -n "${ZSH_VERSION:-}" ]; then
		_theme_color_open="%{"
		_theme_color_close="%}"
	fi

	_theme_color_reset="${_theme_color_open}${_escape}[0m${_theme_color_close}"
	_theme_color_bold="${_theme_color_open}${_escape}[1m${_theme_color_close}"

	_theme_color_delimiter="${_theme_color_open}${_escape}[0;33m${_theme_color_close}"
	_theme_color_red="${_theme_color_open}${_escape}[0;31m${_theme_color_close}"
	_theme_color_green="${_theme_color_open}${_escape}[0;32m${_theme_color_close}"
	_theme_color_yellow="${_theme_color_open}${_escape}[0;33m${_theme_color_close}"
	_theme_color_blue="${_theme_color_open}${_escape}[0;34m${_theme_color_close}"
	_theme_color_magenta="${_theme_color_open}${_escape}[0;35m${_theme_color_close}"
	_theme_color_cyan="${_theme_color_open}${_escape}[0;36m${_theme_color_close}"
	_theme_color_white="${_theme_color_open}${_escape}[0;37m${_theme_color_close}"

	_theme_color_bright_gray="${_theme_color_open}${_escape}[1;90m${_theme_color_close}"
	_theme_color_bright_red="${_theme_color_open}${_escape}[1;91m${_theme_color_close}"
	_theme_color_bright_green="${_theme_color_open}${_escape}[1;92m${_theme_color_close}"
	_theme_color_bright_yellow="${_theme_color_open}${_escape}[1;93m${_theme_color_close}"
	_theme_color_bright_blue="${_theme_color_open}${_escape}[1;94m${_theme_color_close}"
	_theme_color_bright_magenta="${_theme_color_open}${_escape}[1;95m${_theme_color_close}"
	_theme_color_bright_cyan="${_theme_color_open}${_escape}[1;96m${_theme_color_close}"
	_theme_color_bright_white="${_theme_color_open}${_escape}[1;97m${_theme_color_close}"

	local _is_raw=0
	if command -v _is_raw_tty > "/dev/null" 2>&1; then
		_is_raw_tty && _is_raw=1
	fi

	_theme_color_gray="${_theme_color_bright_gray}"
	if [ "${_is_raw}" -eq 0 ]; then
		_theme_color_delimiter="${_theme_color_bright_yellow}"
		_theme_color_red="${_theme_color_bright_red}"
		_theme_color_green="${_theme_color_bright_green}"
		_theme_color_yellow="${_theme_color_bright_yellow}"
		_theme_color_blue="${_theme_color_bright_blue}"
		_theme_color_magenta="${_theme_color_bright_magenta}"
		_theme_color_cyan="${_theme_color_bright_cyan}"
	fi
}
