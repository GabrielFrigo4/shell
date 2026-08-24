### ================================
### CORE FUNCTIONS
### ================================

### --------------------------------
### Path Front (highest priority)
### --------------------------------
path_front() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${1}:${PATH}" ;;
	esac
}

### --------------------------------
### Path Back (lowest priority)
### --------------------------------
path_back() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${PATH}:${1}" ;;
	esac
}

### --------------------------------
### Path Dedup
### --------------------------------
path_dedup() {
	PATH=$(command printf "%s" "${PATH}" | command awk -v RS=: -v ORS=: '!a[$0]++' | command sed 's/:$//')
	export PATH
}

### --------------------------------
### Update Shell (upsh)
### --------------------------------
upsh() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -d "${SHELL_REPO_DIR}" ]; then
		echo "🔄 Updating shell repository at ${SHELL_REPO_DIR}..."
		command git -C "${SHELL_REPO_DIR}" pull
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(detect_shell)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: SHELL_REPO_DIR is not set or invalid."
		echo "Please re-run the install.sh script from your shell repository."
	fi
}

### --------------------------------
### Reinstall Shell (resh)
### --------------------------------
resh() {
	if [ -z "${SHELL_REPO_DIR}" ] || [ ! -d "${SHELL_REPO_DIR}" ]; then
		echo "❌ ERROR: SHELL_REPO_DIR is not set or invalid."
		echo "Please re-run the install.sh script from your shell repository."
		return 1
	fi

	echo "🔄 Updating shell repository at ${SHELL_REPO_DIR}..."
	command git -C "${SHELL_REPO_DIR}" pull || {
		echo "❌ ERROR: git pull failed."
		return 1
	}

	echo "🔧 Re-running install.sh with context '${SHELL_CONTEXT:-desktop}'..."
	"$(command -v "$(detect_shell)" 2> "/dev/null")" "${SHELL_REPO_DIR}/install.sh" --context "${SHELL_CONTEXT:-desktop}"

	echo "♻️ Reloading shell environment..."
	. "${HOME}/.$(detect_shell)rc" 2> "/dev/null" || true

	echo "✅ Shell fully reinstalled and reloaded!"
}

### --------------------------------
### Update Wi-Fi (upwf)
### --------------------------------
upwf() {
	echo "📡 Updating Wi-Fi configurations..."

	if ! env | grep -q "^WIFI_SSID_"; then
		echo "⚠️ No Wi-Fi credentials found in the environment."
		return 1
	fi

	if command -v nmcli > "/dev/null" 2>&1; then
		echo "🐧 Network Manager (nmcli) detected. Applying Wi-Fi configurations..."

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r name ssid; do
			suffix="${name#WIFI_SSID_}"
			pass_var="WIFI_PASS_${suffix}"
			eval pass="\$${pass_var}"

			if [ -n "$ssid" ] && [ -n "$pass" ]; then
				if nmcli connection show "$ssid" > "/dev/null" 2>&1; then
					echo "   🔄 Updating network: '$ssid'"
					nmcli connection modify "$ssid" wifi-sec.psk "$pass" > "/dev/null" 2>&1
				else
					echo "   ➕ Adding network: '$ssid'"
					nmcli connection add type wifi con-name "$ssid" ssid "$ssid" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$pass" > "/dev/null" 2>&1
				fi
			fi
		done
		echo "✅ Linux Wi-Fi configs applied!"

	elif [ "$(command uname -s 2> "/dev/null")" = "FreeBSD" ] || [ -f "/etc/wpa_supplicant.conf" ]; then
		echo "😈 FreeBSD/wpa_supplicant detected. Syncing Wi-Fi configurations..."

		tmp_conf=$(command mktemp)
		cat <<-EOF >| "${tmp_conf}"
			ctrl_interface=/var/run/wpa_supplicant
			ctrl_interface_group=wheel
			update_config=1

		EOF

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r name ssid; do
			suffix="${name#WIFI_SSID_}"
			pass_var="WIFI_PASS_${suffix}"
			eval pass="\$${pass_var}"

			if [ -n "$ssid" ] && [ -n "$pass" ]; then
				echo "   ➕ Mapping network: '$ssid'"
				cat <<-EOF >> "${tmp_conf}"
					network={
					    ssid="$ssid"
					    psk="$pass"
					}

				EOF
			fi
		done

		wifi_dir="/etc"
		wifi_target="${wifi_dir}/wpa_supplicant.conf"

		if command sudo cmp -s "${tmp_conf}" "${wifi_target}" 2> "/dev/null"; then
			echo "   👉 FreeBSD ${wifi_target} is already up-to-date."
		else
			echo "   🔄 Changes detected! Overwriting ${wifi_target}..."
			command sudo cp "${tmp_conf}" "${wifi_target}"

			echo "   ⚡ Restarting network stack (netif)..."
			command sudo service netif restart > "/dev/null" 2>&1 || true
		fi

		wifibox_dir="/usr/local/etc/wifibox"
		wifibox_target="${wifibox_dir}/wpa_supplicant/wpa_supplicant.conf"

		if [ -d "${wifibox_dir}" ] || command -v wifibox > "/dev/null" 2>&1 || [ -f "${wifibox_target}" ]; then
			echo "   📦 Wifibox detected. Syncing Wifibox Wi-Fi configuration..."
			command sudo mkdir -p "${wifibox_dir}/wpa_supplicant"

			if command sudo cmp -s "${tmp_conf}" "${wifibox_target}" 2> "/dev/null"; then
				echo "   👉 Wifibox configuration is already up-to-date."
			else
				echo "   🔄 Changes detected! Overwriting $wifibox_target..."
				command sudo cp "${tmp_conf}" "${wifibox_target}"

				if command sudo service wifibox status > "/dev/null" 2>&1; then
					echo "   ⚡ Restarting wifibox service..."
					command sudo service wifibox restart > "/dev/null" 2>&1 || true
				fi
			fi
		fi

		command rm -f "${tmp_conf}"

		echo "✅ FreeBSD Wi-Fi configs applied!"

	elif command -v netsh > "/dev/null" 2>&1; then
		echo "🪟 Windows Network Shell (netsh) detected. Syncing Wi-Fi profiles..."

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r name ssid; do
			suffix="${name#WIFI_SSID_}"
			pass_var="WIFI_PASS_${suffix}"
			eval pass="\$${pass_var}"

			if [ -n "$ssid" ] && [ -n "$pass" ]; then
				echo "   ➕ Injecting profile: '$ssid'"
				xml_file=$(command mktemp)

				cat <<-EOF >| "$xml_file"
					<?xml version="1.0"?>
					<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
					    <name>$ssid</name>
					    <SSIDConfig>
					        <SSID>
					            <name>$ssid</name>
					        </SSID>
					    </SSIDConfig>
					    <connectionType>ESS</connectionType>
					    <connectionMode>auto</connectionMode>
					    <MSM>
					        <security>
					            <authEncryption>
					                <authentication>WPA2PSK</authentication>
					                <encryption>AES</encryption>
					                <useOneX>false</useOneX>
					            </authEncryption>
					            <sharedKey>
					                <keyType>passPhrase</keyType>
					                <protected>false</protected>
					                <keyMaterial>$pass</keyMaterial>
					            </sharedKey>
					        </security>
					    </MSM>
					</WLANProfile>
				EOF

				win_path="$xml_file"
				command -v cygpath > "/dev/null" 2>&1 && win_path=$(cygpath -w "$xml_file")

				command netsh wlan add profile filename="$win_path" > "/dev/null" 2>&1
				command rm -f "$xml_file"
			fi
		done
		echo "✅ Windows Wi-Fi configs applied!"

	else
		echo "❌ No supported Wi-Fi manager (nmcli/wpa_supplicant/netsh) found."
	fi
}

### --------------------------------
### Update Network (upnet)
### --------------------------------
upnet() {
	echo "🌐 Starting network..."
	upwf
	echo "✅ Network update complete!"
}

### --------------------------------
### Package Managers
### --------------------------------
upman() {
	if [ "$(detect_os)" = "windows" ]; then
		command pacman --noconfirm -Syu "$@"
	else
		command sudo pacman --noconfirm -Syu "$@"
	fi
}

upapt() {
	command sudo apt update && command sudo apt upgrade --yes "$@"
}

updnf() {
	command sudo dnf upgrade --assumeyes "$@"
}

upzyp() {
	command sudo zypper --non-interactive update "$@"
}

upxbps() {
	command sudo xbps-install --yes -Su "$@"
}

upapk() {
	command sudo apk update && command sudo apk upgrade "$@"
}

uppkg() {
	command sudo pkg update && command sudo pkg upgrade --yes "$@"
}

upyay() {
	command yay --noconfirm -Syu "$@"
}

upflat() {
	command flatpak update --assumeyes "$@"
}

upsnap() {
	command sudo snap refresh "$@"
}

### --------------------------------
### Update System (upsys)
### --------------------------------
upsys() {
	echo "📦 Updating OS system packages..."
	case "$(detect_distro_family)" in
		arch)   upman "$@" ;;
		debian) upapt "$@" ;;
		fedora) updnf "$@" ;;
		suse)   upzyp "$@" ;;
		void)   upxbps "$@" ;;
		alpine) upapk "$@" ;;
		*)
			case "$(detect_os)" in
				freebsd) uppkg "$@" ;;
				windows) upman "$@" ;;
			esac
			;;
	esac
	echo "✅ OS system packages updated!"
}

### --------------------------------
### Update All Packages (upall)
### --------------------------------
upall() {
	echo "🚀 Starting full system update..."
	echo ""
	upsys "$@"

	if command -v yay > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Yay (AUR) packages..."
		upyay && echo "✅ Yay (AUR) packages updated!"
	fi

	if command -v flatpak > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Flatpak packages..."
		upflat && echo "✅ Flatpak packages updated!"
	fi

	if command -v snap > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Snap packages..."
		upsnap && echo "✅ Snap packages updated!"
	fi

	echo ""
	echo "✅ All packages updated!"
}

### --------------------------------
### Poweroff System
### --------------------------------
poweroff() {
	case "$(detect_os)" in
		freebsd)
			if [ "$(id -u)" -eq 0 ]; then
				command shutdown -p now "$@"
			elif command -v sudo > "/dev/null" 2>&1; then
				command sudo shutdown -p now "$@"
			else
				command shutdown -p now "$@"
			fi
			;;
		windows)
			shutdown.exe /s /t 0 "$@"
			;;
		*)
			if [ "$(id -u)" -eq 0 ]; then
				command shutdown -h now "$@"
			elif command -v sudo > "/dev/null" 2>&1; then
				command sudo shutdown -h now "$@"
			else
				command shutdown -h now "$@"
			fi
			;;
	esac
}

### --------------------------------
### Reboot System
### --------------------------------
reboot() {
	case "$(detect_os)" in
		windows)
			shutdown.exe /r /t 0 "$@"
			;;
		*)
			if [ "$(id -u)" -eq 0 ]; then
				command shutdown -r now "$@"
			elif command -v sudo > "/dev/null" 2>&1; then
				command sudo shutdown -r now "$@"
			else
				command shutdown -r now "$@"
			fi
			;;
	esac
}

### --------------------------------
### Mount Device (mount-device)
### --------------------------------
mount-device() {
	_target="${HOME}/Device"
	[ ! -d "${_target}" ] && command mkdir -p "${_target}"

	if command mount 2> "/dev/null" | grep -F " ${_target} " > "/dev/null" 2>&1; then
		echo "📱 Dispositivo já está montado em ~/Device."
		if [ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ]; then
			echo "📂 Abrindo gerenciador de arquivos..."
			if command -v xdg-open > "/dev/null" 2>&1; then
				nohup xdg-open "${_target}" > "/dev/null" 2>&1 &
			elif command -v gio > "/dev/null" 2>&1; then
				nohup gio open "${_target}" > "/dev/null" 2>&1 &
			fi
		fi
		return 0
	fi

	_driver=""
	if command -v simple-mtpfs > "/dev/null" 2>&1; then
		_driver="simple-mtpfs"
	elif command -v jmtpfs > "/dev/null" 2>&1; then
		_driver="jmtpfs"
	else
		echo "❌ Nenhum driver MTP compatível (simple-mtpfs ou jmtpfs) foi encontrado."
		echo ""
		echo "💡 Para instalar o driver necessário, execute:"
		case "$(detect_distro_family)" in
			fedora) echo "   sudo dnf install jmtpfs" ;;
			debian) echo "   sudo apt install simple-mtpfs  # ou: sudo apt install jmtpfs" ;;
			arch)   echo "   sudo pacman -S simple-mtpfs    # ou: sudo pacman -S jmtpfs" ;;
			suse)   echo "   sudo zypper install simple-mtpfs  # ou: sudo zypper install jmtpfs" ;;
			void)   echo "   sudo xbps-install -S simple-mtpfs" ;;
			alpine) echo "   sudo apk add simple-mtpfs" ;;
			*)
				case "$(detect_os)" in
					freebsd) echo "   sudo pkg install fusefs-simple-mtpfs  # ou: sudo pkg install fusefs-jmtpfs" ;;
					*)       echo "   Instale 'simple-mtpfs' ou 'jmtpfs' através do gerenciador de pacotes do seu sistema." ;;
				esac
				;;
		esac
		return 1
	fi

	echo "📱 Montando dispositivo MTP em ~/Device (via ${_driver})..."

	if [ "$(detect_os)" = "freebsd" ]; then
		if ! command kldstat -m fusefs > "/dev/null" 2>&1 && ! command kldstat -m fuse > "/dev/null" 2>&1; then
			if [ "$(id -u)" -eq 0 ]; then
				command kldload fusefs > "/dev/null" 2>&1 || true
			elif command -v sudo > "/dev/null" 2>&1; then
				command sudo kldload fusefs > "/dev/null" 2>&1 || true
			fi
		fi
	fi

	if [ "${_driver}" = "simple-mtpfs" ]; then
		_output=$(simple-mtpfs "${_target}" 2>&1)
		_status=$?
		if [ "${_status}" -ne 0 ] && command -v sudo > "/dev/null" 2>&1; then
			_output=$(command sudo simple-mtpfs -o "allow_other,uid=$(id -u),gid=$(id -g)" "${_target}" 2>&1)
			_status=$?
		fi
	else
		_output=$(jmtpfs "${_target}" 2>&1)
		_status=$?
		if [ "${_status}" -ne 0 ] && command -v sudo > "/dev/null" 2>&1; then
			_output=$(command sudo jmtpfs -o "allow_other,uid=$(id -u),gid=$(id -g)" "${_target}" 2>&1)
			_status=$?
		fi
	fi

	if [ "${_status}" -eq 0 ] && command mount 2> "/dev/null" | grep -F " ${_target} " > "/dev/null" 2>&1; then
		echo "✅ Dispositivo montado com sucesso em ~/Device!"
		if [ -n "${DISPLAY}" ] || [ -n "${WAYLAND_DISPLAY}" ]; then
			echo "📂 Abrindo gerenciador de arquivos..."
			if command -v xdg-open > "/dev/null" 2>&1; then
				nohup xdg-open "${_target}" > "/dev/null" 2>&1 &
			elif command -v gio > "/dev/null" 2>&1; then
				nohup gio open "${_target}" > "/dev/null" 2>&1 &
			fi
		fi
	else
		echo "❌ Falha ao montar o dispositivo em ~/Device."
		[ -n "${_output}" ] && echo "   Log: ${_output}"
		echo ""
		echo "💡 Dicas para resolução:"
		echo "   1. Desbloqueie a tela do dispositivo (mantenha a tela ligada)."
		echo "   2. Na notificação USB do dispositivo, selecione o modo 'Transferência de Arquivos (MTP)'."
		echo "   3. Certifique-se de que o cabo USB está devidamente conectado."
		echo "   4. Caso o dispositivo tenha sido desconectado abruptamente, reconecte o cabo USB."
		if [ "$(detect_os)" = "freebsd" ]; then
			echo ""
			echo "😈 Dicas específicas para o FreeBSD:"
			echo "   - Permissão de montagem para usuário: sudo sysctl vfs.usermount=1"
			echo "   - Grupo de acesso USB: sudo pw groupmod operator -m $(id -un)"
			echo "   - Módulo FUSE carregado: sudo kldload fusefs"
		fi
		return 1
	fi
}

### --------------------------------
### Unmount Device (umount-device)
### --------------------------------
umount-device() {
	_target="${HOME}/Device"

	if ! command mount 2> "/dev/null" | grep -F " ${_target} " > "/dev/null" 2>&1; then
		echo "ℹ️ O diretório ~/Device não está montado."
		return 0
	fi

	echo "🔌 Desmontando ~/Device com segurança..."

	_unmounted=0
	if [ "$(detect_os)" = "freebsd" ]; then
		if command umount "${_target}" 2> "/dev/null"; then
			_unmounted=1
		elif command -v sudo > "/dev/null" 2>&1 && command sudo umount "${_target}" 2> "/dev/null"; then
			_unmounted=1
		fi
	else
		if command -v fusermount3 > "/dev/null" 2>&1 && command fusermount3 -u "${_target}" 2> "/dev/null"; then
			_unmounted=1
		elif command -v fusermount > "/dev/null" 2>&1 && command fusermount -u "${_target}" 2> "/dev/null"; then
			_unmounted=1
		elif command umount "${_target}" 2> "/dev/null"; then
			_unmounted=1
		elif command -v sudo > "/dev/null" 2>&1 && command sudo umount "${_target}" 2> "/dev/null"; then
			_unmounted=1
		fi
	fi

	if [ "${_unmounted}" -eq 1 ] || ! command mount 2> "/dev/null" | grep -F " ${_target} " > "/dev/null" 2>&1; then
		echo "✅ Dispositivo desmontado com sucesso de ~/Device."
		echo "🔒 É seguro desconectar o cabo USB."
	else
		echo "❌ Não foi possível desmontar ~/Device."
		echo "💡 Verifique se existem programas, terminais ou gerenciadores de arquivos abertos dentro de ~/Device."
		return 1
	fi
}

### --------------------------------
### Device Aliases
### --------------------------------
alias mntdev="mount-device"
alias mdev="mount-device"
alias umntdev="umount-device"
alias umdev="umount-device"
alias udev="umount-device"
alias unmount-device="umount-device"

