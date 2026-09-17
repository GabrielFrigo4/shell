# ----------------------------------------------------------------
# Utility: Universal Shell UI & Emission Helper
# ----------------------------------------------------------------

### ================================
### ANSI ESCAPE SEQUENCES
### ================================
_ui_esc="$(printf '\033')"
_c_reset="${_ui_esc}[0m"
_c_bold="${_ui_esc}[1m"
_c_cyan="${_ui_esc}[1;36m"
_c_green="${_ui_esc}[1;32m"
_c_yellow="${_ui_esc}[1;33m"
_c_red="${_ui_esc}[1;31m"
_c_blue="${_ui_esc}[1;34m"
_c_magenta="${_ui_esc}[1;35m"
_c_dim="${_ui_esc}[2m"

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
		echo -n "${_c_cyan}==>${_c_reset} "
	else
		printf "==> "
	fi
	echo "$@"
}

_ui_sub() {
	if _ui_has_color; then
		echo -n "${_c_blue}  ↳${_c_reset} "
	else
		printf "  -> "
	fi
	echo "$@"
}

_ui_ok() {
	if _ui_has_color; then
		echo -n "${_c_green}  ✅${_c_reset} "
	else
		printf "  OK "
	fi
	echo "$@"
}

_ui_warn() {
	if _ui_has_color; then
		echo -n "${_c_yellow}  ⚠️ ${_c_reset} "
	else
		printf "  WARN "
	fi
	echo "$@"
}

_ui_err() {
	if [ -t 2 ]; then
		echo -n "${_c_red}  ❌${_c_reset} " >&2
	else
		printf "  FAIL " >&2
	fi
	echo "$@" >&2
}

_ui_info() {
	if _ui_has_color; then
		echo -n "${_c_magenta}  ℹ️ ${_c_reset} "
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
		echo "${_c_bold}${_c_cyan}${_sep}${_c_reset}"
		echo "${_c_bold}  ${_title}${_c_reset}"
		echo "${_c_bold}${_c_cyan}${_sep}${_c_reset}"
	else
		echo "${_sep}"
		echo "  ${_title}"
		echo "${_sep}"
	fi
	echo ""
}
