# ----------------------------------------------------------------
# Utility: Universal Shell UI & Emission Helper
# ----------------------------------------------------------------

### ================================
### ANSI ESCAPE SEQUENCES
### ================================
_ui_color_reset=$'\e[0m'
_ui_color_bold=$'\e[1m'
_ui_color_cyan=$'\e[1;36m'
_ui_color_green=$'\e[1;32m'
_ui_color_yellow=$'\e[1;33m'
_ui_color_red=$'\e[1;31m'
_ui_color_blue=$'\e[1;34m'
_ui_color_magenta=$'\e[1;35m'
_ui_color_dim=$'\e[2m'

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
		echo -n $'\e[1;36m==>\e[0m '
	else
		echo -n "==> "
	fi
	echo "$*"
}

_ui_sub() {
	if _ui_has_color; then
		echo -n $'\e[1;34m  ↳\e[0m '
	else
		echo -n "  -> "
	fi
	echo "$*"
}

_ui_ok() {
	if _ui_has_color; then
		echo -n $'\e[1;32m  ✅\e[0m '
	else
		echo -n "  OK "
	fi
	echo "$*"
}

_ui_warn() {
	if _ui_has_color; then
		echo -n $'\e[1;33m  ⚠️ \e[0m '
	else
		echo -n "  WARN "
	fi
	echo "$*"
}

_ui_err() {
	if [ -t 2 ]; then
		echo -n $'\e[1;31m  ❌\e[0m ' >&2
	else
		echo -n "  FAIL " >&2
	fi
	echo "$*" >&2
}

_ui_info() {
	if _ui_has_color; then
		echo -n $'\e[1;35m  ℹ️ \e[0m '
	else
		echo -n "  INFO "
	fi
	echo "$*"
}

_ui_banner() {
	local _title="$1"
	local _separator="================================================================"
	echo ""
	if _ui_has_color; then
		echo -n $'\e[1;36m'
		echo "${_separator}"
		echo -n $'\e[1m  '
		echo -n "${_title}"
		echo $'\e[0m'
		echo -n $'\e[1;36m'
		echo "${_separator}"
		echo -n $'\e[0m'
	else
		echo "${_separator}"
		echo "  ${_title}"
		echo "${_separator}"
	fi
	echo ""
}
