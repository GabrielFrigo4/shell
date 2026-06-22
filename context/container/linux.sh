### ================================
### CONTAINER CONTEXT - Linux
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
