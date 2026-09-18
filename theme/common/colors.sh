### ================================
### PROMPT COLOR PALETTE
### ================================

_setup_colors() {
	local _esc
	_esc="$(printf '\033')"

	local _c_open="\["
	local _c_close="\]"
	if [ -n "${ZSH_VERSION:-}" ]; then
		_c_open="%{"
		_c_close="%}"
	fi

	_c_reset="${_c_open}${_esc}[0m${_c_close}"
	_c_bold="${_c_open}${_esc}[1m${_c_close}"

	_c_del="${_c_open}${_esc}[0;33m${_c_close}"
	_c_red="${_c_open}${_esc}[0;31m${_c_close}"
	_c_green="${_c_open}${_esc}[0;32m${_c_close}"
	_c_yellow="${_c_open}${_esc}[0;33m${_c_close}"
	_c_blue="${_c_open}${_esc}[0;34m${_c_close}"
	_c_magenta="${_c_open}${_esc}[0;35m${_c_close}"
	_c_cyan="${_c_open}${_esc}[0;36m${_c_close}"
	_c_white="${_c_open}${_esc}[0;37m${_c_close}"

	_c_b_gray="${_c_open}${_esc}[1;90m${_c_close}"
	_c_b_red="${_c_open}${_esc}[1;91m${_c_close}"
	_c_b_green="${_c_open}${_esc}[1;92m${_c_close}"
	_c_b_yellow="${_c_open}${_esc}[1;93m${_c_close}"
	_c_b_blue="${_c_open}${_esc}[1;94m${_c_close}"
	_c_b_magenta="${_c_open}${_esc}[1;95m${_c_close}"
	_c_b_cyan="${_c_open}${_esc}[1;96m${_c_close}"
	_c_b_white="${_c_open}${_esc}[1;97m${_c_close}"

	_c_gray="${_c_b_gray}"
	if ! _is_raw_tty; then
		_c_red="${_c_b_red}"
		_c_green="${_c_b_green}"
		_c_yellow="${_c_b_yellow}"
		_c_blue="${_c_b_blue}"
		_c_magenta="${_c_b_magenta}"
		_c_cyan="${_c_b_cyan}"
	fi
}
