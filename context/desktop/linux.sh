### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Plasma Window
### --------------------------------
alias way='exec dbus-run-session startplasma-wayland'
alias xorg='startx'

### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="emacs --daemon"
alias er="ek && es"
alias ec="emacsclient --create-frame --alternate-editor \"\""
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . &> "/dev/null" &"

### --------------------------------
### GUI Editors
### --------------------------------
alias ok="nohup kate . &> "/dev/null" &"
alias og="nohup geany . &> "/dev/null" &"
alias oc="code ."
alias ocm="codium ."
alias oa="antigravity-ide ."
alias oz="zed ."
alias ant="antigravity-ide"

### --------------------------------
### GUI Integration
### --------------------------------
if [ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ]; then
	_gtk_theme="$(detect_gtk_theme)"
	if [ -n "${_gtk_theme}" ]; then
		export GTK_THEME="${_gtk_theme}"
	else
		unset GTK_THEME
	fi
	unset _gtk_theme

	_qt_style="$(detect_qt_theme)"
	if [ -n "${_qt_style}" ]; then
		export QT_STYLE_OVERRIDE="${_qt_style}"
	else
		unset QT_STYLE_OVERRIDE
	fi
	unset _qt_style

	_qt_platform="$(detect_qt_platform_theme)"
	if [ -n "${_qt_platform}" ]; then
		export QT_QPA_PLATFORMTHEME="${_qt_platform}"
	else
		unset QT_QPA_PLATFORMTHEME
	fi
	unset _qt_platform

	export ELECTRON_OZONE_PLATFORM_HINT="auto"
	export _JAVA_AWT_WM_NONREPARENTING=1
fi
