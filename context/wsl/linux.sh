### ================================
### WSL CONTEXT
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
### Terminal Editors
### --------------------------------
alias on="nvim ."
alias ov="vim ."

### --------------------------------
### Windows Integration
### --------------------------------
alias explorer="explorer.exe"
alias powershell="powershell.exe"
alias pwsh="pwsh.exe"
alias cmd="cmd.exe"
alias clip="win32yank.exe"
