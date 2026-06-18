### ================================
### DESKTOP CONTEXT - FreeBSD
### ================================

### --------------------------------
### Commands
### --------------------------------
alias clear="echo -n $'\e[2J\e[3J\e[H'"

### --------------------------------
### Packages
### --------------------------------
alias uppkg="sudo pkg update && sudo pkg upgrade --yes"
alias upall="uppkg"

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
