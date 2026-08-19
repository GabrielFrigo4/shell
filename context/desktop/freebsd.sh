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
	export GTK_THEME="$(detect_gtk_theme)"
	export QT_STYLE_OVERRIDE="$(detect_qt_theme)"
	export QT_QPA_PLATFORMTHEME="xdgdesktopportal"
	export ELECTRON_OZONE_PLATFORM_HINT="auto"
	export _JAVA_AWT_WM_NONREPARENTING=1
fi
