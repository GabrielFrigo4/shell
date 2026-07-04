### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Commands
### --------------------------------
alias clear="echo -n $'\e[2J\e[3J\e[H'"

### --------------------------------
### Packages
### --------------------------------
alias uppkg="sudo pkg update && sudo pkg upgrade --yes"
alias upsys="uppkg"
alias upall="upsys"

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
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . &>/dev/null &"

### --------------------------------
### Software
### --------------------------------
alias code="vscode"

### --------------------------------
### GUI Editors
### --------------------------------
alias ok="nohup kate . &>/dev/null &"
alias oc="code ."

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
