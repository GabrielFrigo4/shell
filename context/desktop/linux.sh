### ================================
### DESKTOP CONTEXT - Linux (Arch)
### ================================

### --------------------------------
### Plasma Window
### --------------------------------
alias way='sh -c "setsid dbus-run-session startplasma-wayland > \"/dev/null\" 2>&1 &"'

### --------------------------------
### Software
### --------------------------------
alias wh="which"
alias ds="disown"
alias brw="lynx -use_mouse=on -nobrowse=on -nopause=on -show_cursor=off"
alias mmdc="mmdc -p ~/.mermaid-puppeteer-config.json -c ~/.mermaid-theme-config.json -b \"#191919\" -s 4"

### --------------------------------
### Manual
### --------------------------------
alias wman="win-man"
alias uman="unix-man"
alias mandoc="unix-man"

### --------------------------------
### Packages
### --------------------------------
alias upyay="yay --noconfirm -Syu"
alias upall="upyay"
alias yays="yay -Ss"
alias yayi="yay -S"
alias yayr="yay -Rcns"
alias yayu="yay -Syu"
alias pac="pacman"
alias pacs="pacman -Ss"
alias paci="pacman -S"
alias pacr="pacman -Rcns"
alias pacu="pacman -Syu"

### --------------------------------
### Goto
### --------------------------------
alias desk="cd ~/'Área de trabalho'"
alias down="cd ~/Downloads"

### --------------------------------
### Emacs
### --------------------------------
alias ek="pkill emacs"
alias es="emacs --daemon"
alias er="ek && es"
alias ec="emacsclient --create-frame --alternate-editor \"\""
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . &>/dev/null &"

### --------------------------------
### GUI Editors
### --------------------------------
alias ok="nohup kate . &>/dev/null &"
alias og="nohup geany . &>/dev/null &"
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
### GUI Apps
### --------------------------------
alias show="dolphin ."

### --------------------------------
### Select GPU
### --------------------------------
alias nvc="DRI_PRIME=1"
alias hdc="DRI_PRIME=0"

### --------------------------------
### Select Theme
### --------------------------------
alias dark="GTK_THEME=Adwaita:dark"
alias light="GTK_THEME=Adwaita:light"
