### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Plasma Window
### --------------------------------
alias way='exec ck-launch-session dbus-run-session startplasma-wayland'
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
### Software
### --------------------------------
alias code="vscode"

### --------------------------------
### GUI Editors
### --------------------------------
alias ok="nohup kate . &> "/dev/null" &"
alias oc="code ."

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

	export QT_QPA_PLATFORMTHEME="$(detect_qt_platform_theme)"
	export ELECTRON_OZONE_PLATFORM_HINT="auto"
	export _JAVA_AWT_WM_NONREPARENTING=1
fi
