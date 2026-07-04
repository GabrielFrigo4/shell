### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Packages
### --------------------------------
alias upsys="pacman --noconfirm -Syu"
alias upall="upsys"
alias pac="pacman"
alias pacs="pacman -Ss"
alias paci="pacman -S"
alias pacr="pacman -Rcns"
alias pacu="pacman -Syu"

### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="runemacs --fg-daemon"
alias er="ek && es"
alias ec="emacsclientw --create-frame --alternate-editor \"\""
alias oe="emacsclientw --create-frame --alternate-editor \"\" ."

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
