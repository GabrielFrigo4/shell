### ================================
### PROMPT COLOR PALETTE
### ================================

_setup_colors() {
	local _esc
	_esc="$(printf '\033')"

	local _theme_color_open="\["
	local _theme_color_close="\]"
	if [ -n "${ZSH_VERSION:-}" ]; then
		_theme_color_open="%{"
		_theme_color_close="%}"
	fi

	_theme_color_reset="${_theme_color_open}${_esc}[0m${_theme_color_close}"
	_theme_color_bold="${_theme_color_open}${_esc}[1m${_theme_color_close}"

	_theme_color_del="${_theme_color_open}${_esc}[0;33m${_theme_color_close}"
	_theme_color_red="${_theme_color_open}${_esc}[0;31m${_theme_color_close}"
	_theme_color_green="${_theme_color_open}${_esc}[0;32m${_theme_color_close}"
	_theme_color_yellow="${_theme_color_open}${_esc}[0;33m${_theme_color_close}"
	_theme_color_blue="${_theme_color_open}${_esc}[0;34m${_theme_color_close}"
	_theme_color_magenta="${_theme_color_open}${_esc}[0;35m${_theme_color_close}"
	_theme_color_cyan="${_theme_color_open}${_esc}[0;36m${_theme_color_close}"
	_theme_color_white="${_theme_color_open}${_esc}[0;37m${_theme_color_close}"

	_theme_color_b_gray="${_theme_color_open}${_esc}[1;90m${_theme_color_close}"
	_theme_color_b_red="${_theme_color_open}${_esc}[1;91m${_theme_color_close}"
	_theme_color_b_green="${_theme_color_open}${_esc}[1;92m${_theme_color_close}"
	_theme_color_b_yellow="${_theme_color_open}${_esc}[1;93m${_theme_color_close}"
	_theme_color_b_blue="${_theme_color_open}${_esc}[1;94m${_theme_color_close}"
	_theme_color_b_magenta="${_theme_color_open}${_esc}[1;95m${_theme_color_close}"
	_theme_color_b_cyan="${_theme_color_open}${_esc}[1;96m${_theme_color_close}"
	_theme_color_b_white="${_theme_color_open}${_esc}[1;97m${_theme_color_close}"

	_theme_color_gray="${_theme_color_b_gray}"
	if ! _is_raw_tty; then
		_theme_color_red="${_theme_color_b_red}"
		_theme_color_green="${_theme_color_b_green}"
		_theme_color_yellow="${_theme_color_b_yellow}"
		_theme_color_blue="${_theme_color_b_blue}"
		_theme_color_magenta="${_theme_color_b_magenta}"
		_theme_color_cyan="${_theme_color_b_cyan}"
	fi
}
