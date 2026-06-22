### ================================
### WSL CONTEXT - Linux
### ================================

### --------------------------------
### Packages
### --------------------------------
case "$(detect_distro_family)" in
	arch)
		alias upsys="sudo pacman --noconfirm -Syu"
		alias upall="upsys"
		;;
	debian)
		alias upsys="sudo apt update && sudo apt upgrade --yes"
		alias upall="upsys"
		;;
	fedora)
		alias upsys="sudo dnf upgrade --yes"
		alias upall="upsys"
		;;
esac

### --------------------------------
### Packages (extras)
### --------------------------------
command -v flatpak > "/dev/null" 2>&1 && alias upflat="flatpak update --yes"
command -v snap    > "/dev/null" 2>&1 && alias upsnap="sudo snap refresh"

### --------------------------------
### Windows Integration
### --------------------------------
alias explorer="explorer.exe"
alias cmd="cmd.exe"
alias powershell="powershell.exe"
alias clip="clip.exe"
alias winopen="cmd.exe /c start"

### --------------------------------
### Terminal Editors
### --------------------------------
alias on="nvim ."
alias ov="vim ."
