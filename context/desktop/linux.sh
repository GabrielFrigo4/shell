### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Virtualization & Containers
### --------------------------------
command -v incus   > "/dev/null" 2>&1 && alias incus="LC_ALL=C incus"

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
### Terminal Editors
### --------------------------------
alias on="nvim ."
alias ov="vim ."

### --------------------------------
### Servers
### --------------------------------
alias frigo-server='ssh -i "${FRIGO_SERVER_KEY}" "ubuntu@${FRIGO_SERVER_IP}"'
alias orbs-server='ssh -i "${ORBS_SERVER_KEY}" "ubuntu@${ORBS_SERVER_IP}"'
