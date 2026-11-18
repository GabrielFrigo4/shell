# ----------------------------------------------------------------
# Core: Privilege Escalation Helper
# ----------------------------------------------------------------

### ================================
### PRIVILEGE ESCALATION
### ================================
_as_root() {
	local _escalator=""
	if command -v _detect_privilege_escalator > "/dev/null" 2>&1; then
		_escalator="$(_detect_privilege_escalator)"
	elif [ "$(id -u 2> "/dev/null" || echo 1000)" -eq 0 ]; then
		_escalator="root"
	elif command -v doas > "/dev/null" 2>&1; then
		_escalator="doas"
	elif command -v sudo > "/dev/null" 2>&1; then
		_escalator="sudo"
	fi
	case "${_escalator}" in
		root)      "$@" ;;
		doas|sudo) command "${_escalator}" "$@" ;;
		*)
			if command -v _ui_err > "/dev/null" 2>&1; then
				_ui_err "Neither 'doas' nor 'sudo' was found to execute command with root privileges."
			else
				printf '  FAIL %s\n' "Neither 'doas' nor 'sudo' was found to execute command with root privileges." >&2
			fi
			return 1
			;;
	esac
}
