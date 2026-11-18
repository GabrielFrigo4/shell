### ================================
### DESKTOP CONTEXT COMMON
### ================================

### --------------------------------
### SESSION & GRAPHICAL THEME
### --------------------------------
[ -n "${SHELL_REPO_DIR:-}" ] && [ -f "${SHELL_REPO_DIR}/target/common/session.sh" ] && . "${SHELL_REPO_DIR}/target/common/session.sh"

export ELECTRON_OZONE_PLATFORM_HINT="auto"
export _JAVA_AWT_WM_NONREPARENTING=1
export SAL_USE_VCLPLUGIN="gtk3"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"

if command -v _desktop_apply_theme_context > "/dev/null" 2>&1; then
	_desktop_apply_theme_context
fi

### --------------------------------
### LIGHTWEIGHT CLI ALIASES
### --------------------------------
if command -v rg > "/dev/null" 2>&1 && ! { command -v _is_raw_tty > "/dev/null" 2>&1 && _is_raw_tty; }; then
	alias r="rg --smart-case"
else
	alias r="grep -Ei"
fi

if ! command -v delta > "/dev/null" 2>&1 && command -v git-delta > "/dev/null" 2>&1; then
	alias delta="git-delta"
fi
