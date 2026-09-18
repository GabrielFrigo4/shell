# ----------------------------------------------------------------
# Utility: Universal Shell UI & Emission Helper
# ----------------------------------------------------------------

### ================================
### ANSI ESCAPE SEQUENCES
### ================================
_ui_esc="$(printf '\033')"
_ui_color_reset="${_ui_esc}[0m"
_ui_color_bold="${_ui_esc}[1m"
_ui_color_cyan="${_ui_esc}[1;36m"
_ui_color_green="${_ui_esc}[1;32m"
_ui_color_yellow="${_ui_esc}[1;33m"
_ui_color_red="${_ui_esc}[1;31m"
_ui_color_blue="${_ui_esc}[1;34m"
_ui_color_magenta="${_ui_esc}[1;35m"
_ui_color_dim="${_ui_esc}[2m"

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
		echo -n "${_ui_color_cyan}==>${_ui_color_reset} "
	else
		printf "==> "
	fi
	echo "$@"
}

_ui_sub() {
	if _ui_has_color; then
		echo -n "${_ui_color_blue}  ↳${_ui_color_reset} "
	else
		printf "  -> "
	fi
	echo "$@"
}

_ui_ok() {
	if _ui_has_color; then
		echo -n "${_ui_color_green}  ✅${_ui_color_reset} "
	else
		printf "  OK "
	fi
	echo "$@"
}

_ui_warn() {
	if _ui_has_color; then
		echo -n "${_ui_color_yellow}  ⚠️ ${_ui_color_reset} "
	else
		printf "  WARN "
	fi
	echo "$@"
}

_ui_err() {
	if [ -t 2 ]; then
		echo -n "${_ui_color_red}  ❌${_ui_color_reset} " >&2
	else
		printf "  FAIL " >&2
	fi
	echo "$@" >&2
}

_ui_info() {
	if _ui_has_color; then
		echo -n "${_ui_color_magenta}  ℹ️ ${_ui_color_reset} "
	else
		printf "  INFO "
	fi
	echo "$@"
}

_ui_banner() {
	local _title="$1"
	local _sep="================================================================"
	echo ""
	if _ui_has_color; then
		echo "${_ui_color_bold}${_ui_color_cyan}${_sep}${_ui_color_reset}"
		echo "${_ui_color_bold}  ${_title}${_ui_color_reset}"
		echo "${_ui_color_bold}${_ui_color_cyan}${_sep}${_ui_color_reset}"
	else
		echo "${_sep}"
		echo "  ${_title}"
		echo "${_sep}"
	fi
	echo ""
}
