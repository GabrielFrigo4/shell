### ================================
### DESKTOP CONTEXT
### ================================

### --------------------------------
### Packages Core
### --------------------------------
case "$(detect_distro_family)" in
	arch)
		alias upman="sudo pacman --noconfirm -Syu"
		alias upsys="upman"
		alias upall="upsys"
		;;
	debian)
		alias upapt="sudo apt update && sudo apt upgrade --yes"
		alias upsys="upapt"
		alias upall="upsys"
		;;
	fedora)
		alias updnf="sudo dnf upgrade --yes"
		alias upsys="updnf"
		alias upall="upsys"
		;;
esac

### --------------------------------
### Packages Extras
### --------------------------------
command -v yay     > "/dev/null" 2>&1 && alias upyay="yay --noconfirm -Syu"
command -v flatpak > "/dev/null" 2>&1 && alias upflat="flatpak update --yes"
command -v snap    > "/dev/null" 2>&1 && alias upsnap="sudo snap refresh"

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
