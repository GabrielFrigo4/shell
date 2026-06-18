### ================================
### DESKTOP CONTEXT - Windows (MSYS2)
### ================================

### --------------------------------
### Software
### --------------------------------
alias wh="which"
alias brw="lynx -use_mouse=on -nobrowse=on -nopause=on -show_cursor=off"

### --------------------------------
### Manual
### --------------------------------
alias wman="win-man"
alias uman="unix-man"
alias mandoc="unix-man"

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
