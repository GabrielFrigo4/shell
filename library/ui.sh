# ----------------------------------------------------------------
# Utility: Universal Shell UI & Emission Helper
# ----------------------------------------------------------------

### ================================
### ANSI ESCAPE SEQUENCES
### ================================
if [ -n "${BASH_VERSION:-}" ] || [ -n "${ZSH_VERSION:-}" ]; then
	_ui_escape=$'\e'
else
	_ui_escape="$(printf '\033')"
fi
_ui_color_reset="${_ui_escape}[0m"
_ui_color_bold="${_ui_escape}[1m"
_ui_color_cyan="${_ui_escape}[1;36m"
_ui_color_green="${_ui_escape}[1;32m"
_ui_color_yellow="${_ui_escape}[1;33m"
_ui_color_red="${_ui_escape}[1;31m"
_ui_color_blue="${_ui_escape}[1;34m"
_ui_color_magenta="${_ui_escape}[1;35m"
_ui_color_dim="${_ui_escape}[2m"

_ui_has_color() {
	[ -t 1 ] || return 1
	case "${TERM:-}" in
		dumb|"") return 1 ;;
		*) return 0 ;;
	esac
}

### ================================
### SEMANTIC EMISSION FUNCTIONS
### ================================
_ui_step() {
	if _ui_has_color; then
		printf "%s==>%s %s\n" "${_ui_color_cyan}" "${_ui_color_reset}" "$*"
	else
		printf "==> %s\n" "$*"
	fi
}

_ui_sub() {
	if _ui_has_color; then
		printf "%s  ↳%s %s\n" "${_ui_color_blue}" "${_ui_color_reset}" "$*"
	else
		printf "  -> %s\n" "$*"
	fi
}

_ui_ok() {
	if _ui_has_color; then
		printf "%s  ✅%s %s\n" "${_ui_color_green}" "${_ui_color_reset}" "$*"
	else
		printf "  OK %s\n" "$*"
	fi
}

_ui_warn() {
	if _ui_has_color; then
		printf "%s  ⚠️ %s %s\n" "${_ui_yellow}" "${_ui_reset:-${_ui_color_reset}}" "$*"
	else
		printf "  WARN %s\n" "$*"
	fi
}

_ui_err() {
	if [ -t 2 ]; then
		printf "%s  ❌%s %s\n" "${_ui_color_red}" "${_ui_color_reset}" "$*" >&2
	else
		printf "  FAIL %s\n" "$*" >&2
	fi
}

_ui_info() {
	if _ui_has_color; then
		printf "%s  ℹ️ %s %s\n" "${_ui_color_magenta}" "${_ui_color_reset}" "$*"
	else
		printf "  INFO %s\n" "$*"
	fi
}

_ui_banner() {
	local _title="$1"
	local _separator="================================================================"
	echo ""
	if _ui_has_color; then
		echo "${_ui_color_bold}${_ui_color_cyan}${_separator}${_ui_color_reset}"
		echo "${_ui_color_bold}  ${_title}${_ui_color_reset}"
		echo "${_ui_color_bold}${_ui_color_cyan}${_separator}${_ui_color_reset}"
	else
		echo "${_separator}"
		echo "  ${_title}"
		echo "${_separator}"
	fi
	echo ""
}
