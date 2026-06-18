### ================================
### DESKTOP CONTEXT - FreeBSD
### ================================

### --------------------------------
### Commands
### --------------------------------
alias clear="printf \"\033[H\033[2J\033[3J\""

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
