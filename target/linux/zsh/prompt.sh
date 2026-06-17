### ================================
### SHELL APPEARANCE
### ================================

PROMPT_OS_ICON=" "
PROMPT_OS_COLOR="blue"
PROMPT_OS_NAME="$(uname -r)"

SHELL_REPO_DIR="${${(%):-%x}:A:h:h:h:h}"
source "${SHELL_REPO_DIR}/theme/zsh.sh"

### ================================
### SHELL ENVIRONMENT
### ================================

path_front "${HOME}/.local/bin"
path_back  "${HOME}/.cargo/bin"
path_back  "${HOME}/.platformio/penv/bin"
export PATH=$(printf "%s" "${PATH}" | awk -v RS=: -v ORS=: '!a[$(0)]++' | sed 's/:$//')

export EMACS_SOCKET_NAME="${HOME}/.emacs.d/var/server/auth/server"

### ================================
### SHELL ALIAS
### ================================

### --------------------------------
### Software
### --------------------------------
alias wh="which"
alias show="dolphin ."
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
### Management
### --------------------------------
alias upyay="yay --noconfirm -Syu"
alias upflat="flatpak update -y"
alias upall="upyay && upflat"
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
alias oe="nohup emacsclient --create-frame --alternate-editor \"\" . &> \"/dev/null\" &"
### --------------------------------
### Code Editors
### --------------------------------
alias ok="nohup kate . &> \"/dev/null\" &"
alias og="nohup geany . &> \"/dev/null\" &"
alias oc="code ."
alias ocm="codium ."
alias oa="antigravity ."
alias oz="zed ."
alias on="nvim ."
alias ov="vim ."
alias ant="antigravity"
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

### ================================
### SHELL CONFIGURATION
### ================================
