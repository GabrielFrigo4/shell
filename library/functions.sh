### ================================
### CORE FUNCTIONS
### ================================

### --------------------------------
### Privilege Escalation (_as_root)
### --------------------------------
_as_root() {
	local _escalator="$(_detect_privilege_escalator)"
	case "${_escalator}" in
		root)
			"$@"
			;;
		doas|sudo)
			command "${_escalator}" "$@"
			;;
		*)
			echo "❌ ERROR: Neither 'doas' nor 'sudo' was found to execute command with root privileges." >&2
			return 1
			;;
	esac
}

### --------------------------------
### Path Front (highest priority)
### --------------------------------
path-front() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${1}:${PATH}" ;;
	esac
}

### --------------------------------
### Path Back (lowest priority)
### --------------------------------
path-back() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${PATH}:${1}" ;;
	esac
}

### --------------------------------
### Path Dedup
### --------------------------------
path-dedup() {
	PATH=$(command printf "%s" "${PATH}" | command awk -v RS=: -v ORS=: '!a[$0]++' | command sed 's/:$//')
	export PATH
}

### --------------------------------
### Update Shell (update-shell)
### --------------------------------
update-shell() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -d "${SHELL_REPO_DIR}" ]; then
		echo "🔄 Updating shell repository at ${SHELL_REPO_DIR}..."
		command git -C "${SHELL_REPO_DIR}" pull
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(_detect_shell)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: SHELL_REPO_DIR is not set or invalid."
		echo "Please re-run the install.sh script from your shell repository."
	fi
}

### --------------------------------
### Reinstall Shell (reinstall-shell)
### --------------------------------
reinstall-shell() {
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
	"$(command -v "$(_detect_shell)" 2> "/dev/null")" "${SHELL_REPO_DIR}/install.sh" --context "${SHELL_CONTEXT:-desktop}"

	echo "♻️ Reloading shell environment..."
	. "${HOME}/.$(_detect_shell)rc" 2> "/dev/null" || true

	echo "✅ Shell fully reinstalled and reloaded!"
}

### --------------------------------
### Update Wi-Fi (update-wifi)
### --------------------------------
update-wifi() {
	echo "📡 Updating Wi-Fi configurations..."

	if ! env | grep -q "^WIFI_SSID_"; then
		echo "⚠️ No Wi-Fi credentials found in the environment."
		return 1
	fi

	if command -v nmcli > "/dev/null" 2>&1; then
		echo "🐧 Network Manager (nmcli) detected. Applying Wi-Fi configurations..."

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r _name _ssid; do
			_suffix="${_name#WIFI_SSID_}"
			_pass_var="WIFI_PASS_${_suffix}"
			eval _pass="\$${_pass_var}"

			if [ -n "${_ssid}" ] && [ -n "${_pass}" ]; then
				if nmcli connection show "${_ssid}" > "/dev/null" 2>&1; then
					echo "   🔄 Updating network: '${_ssid}'"
					nmcli connection modify "${_ssid}" wifi-sec.psk "${_pass}" > "/dev/null" 2>&1
				else
					echo "   ➕ Adding network: '${_ssid}'"
					nmcli connection add type wifi con-name "${_ssid}" ssid "${_ssid}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${_pass}" > "/dev/null" 2>&1
				fi
			fi
		done
		echo "✅ Linux Wi-Fi configs applied!"

	elif [ "$(command uname -s 2> "/dev/null")" = "FreeBSD" ] || [ -f "/etc/wpa_supplicant.conf" ]; then
		echo "😈 FreeBSD/wpa_supplicant detected. Syncing Wi-Fi configurations..."

		_tmp_conf=$(command mktemp)
		cat <<-EOF >| "${_tmp_conf}"
			ctrl_interface=/var/run/wpa_supplicant
			ctrl_interface_group=wheel
			update_config=1

		EOF

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r _name _ssid; do
			_suffix="${_name#WIFI_SSID_}"
			_pass_var="WIFI_PASS_${_suffix}"
			eval _pass="\$${_pass_var}"

			if [ -n "${_ssid}" ] && [ -n "${_pass}" ]; then
				echo "   ➕ Mapping network: '${_ssid}'"
				cat <<-EOF >> "${_tmp_conf}"
					network={
					    ssid="${_ssid}"
					    psk="${_pass}"
					}

				EOF
			fi
		done

		_wifi_dir="/etc"
		_wifi_target="${_wifi_dir}/wpa_supplicant.conf"

		if _as_root cmp -s "${_tmp_conf}" "${_wifi_target}" 2> "/dev/null"; then
			echo "   👉 FreeBSD ${_wifi_target} is already up-to-date."
		else
			echo "   🔄 Changes detected! Overwriting ${_wifi_target}..."
			_as_root cp "${_tmp_conf}" "${_wifi_target}"

			echo "   ⚡ Restarting network stack (netif)..."
			_as_root service netif restart > "/dev/null" 2>&1 || true
		fi

		_wifibox_dir="/usr/local/etc/wifibox"
		_wifibox_target="${_wifibox_dir}/wpa_supplicant/wpa_supplicant.conf"

		if [ -d "${_wifibox_dir}" ] || command -v wifibox > "/dev/null" 2>&1 || [ -f "${_wifibox_target}" ]; then
			echo "   📦 Wifibox detected. Syncing Wifibox Wi-Fi configuration..."
			_as_root mkdir -p "${_wifibox_dir}/wpa_supplicant"

			if _as_root cmp -s "${_tmp_conf}" "${_wifibox_target}" 2> "/dev/null"; then
				echo "   👉 Wifibox configuration is already up-to-date."
			else
				echo "   🔄 Changes detected! Overwriting ${_wifibox_target}..."
				_as_root cp "${_tmp_conf}" "${_wifibox_target}"

				if _as_root service wifibox status > "/dev/null" 2>&1; then
					echo "   ⚡ Restarting wifibox service..."
					_as_root service wifibox restart > "/dev/null" 2>&1 || true
				fi
			fi
		fi

		command rm -f "${_tmp_conf}"

		echo "✅ FreeBSD Wi-Fi configs applied!"

	elif command -v netsh > "/dev/null" 2>&1; then
		echo "🪟 Windows Network Shell (netsh) detected. Syncing Wi-Fi profiles..."

		env | grep "^WIFI_SSID_" | sort | while IFS='=' read -r _name _ssid; do
			_suffix="${_name#WIFI_SSID_}"
			_pass_var="WIFI_PASS_${_suffix}"
			eval _pass="\$${_pass_var}"

			if [ -n "${_ssid}" ] && [ -n "${_pass}" ]; then
				echo "   ➕ Injecting profile: '${_ssid}'"
				_xml_file=$(command mktemp)

				cat <<-EOF >| "${_xml_file}"
					<?xml version="1.0"?>
					<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
					    <name>${_ssid}</name>
					    <SSIDConfig>
					        <SSID>
					            <name>${_ssid}</name>
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
					                <keyMaterial>${_pass}</keyMaterial>
					            </sharedKey>
					        </security>
					    </MSM>
					</WLANProfile>
				EOF

				_win_path="${_xml_file}"
				command -v cygpath > "/dev/null" 2>&1 && _win_path=$(cygpath -w "${_xml_file}")

				command netsh wlan add profile filename="${_win_path}" > "/dev/null" 2>&1
				command rm -f "${_xml_file}"
			fi
		done
		echo "✅ Windows Wi-Fi configs applied!"

	else
		echo "❌ No supported Wi-Fi manager (nmcli/wpa_supplicant/netsh) found."
	fi

	unset _name _ssid _suffix _pass_var _pass _tmp_conf _xml_file _win_path _wifi_dir _wifi_target _wifibox_dir _wifibox_target 2> "/dev/null" || true
}

### --------------------------------
### Update Network (update-network)
### --------------------------------
update-network() {
	echo "🌐 Starting network..."
	update-wifi
	echo "✅ Network update complete!"
}

### --------------------------------
### Package Managers (Defensive)
### --------------------------------
if command -v pacman > "/dev/null" 2>&1; then
	update-pacman() {
		if [ "$(_detect_os)" = "windows" ]; then
			command pacman --noconfirm -Syu "$@"
		else
			_as_root pacman --noconfirm -Syu "$@"
		fi
	}
fi

if command -v apt > "/dev/null" 2>&1; then
	update-apt() {
		_as_root apt update && _as_root apt upgrade --yes "$@"
	}
fi

if command -v dnf > "/dev/null" 2>&1; then
	update-dnf() {
		_as_root dnf upgrade --assumeyes "$@"
	}
fi

if command -v zypper > "/dev/null" 2>&1; then
	update-zypper() {
		_as_root zypper --non-interactive update "$@"
	}
fi

if command -v xbps-install > "/dev/null" 2>&1; then
	update-xbps() {
		_as_root xbps-install --yes -Su "$@"
	}
fi

if command -v apk > "/dev/null" 2>&1; then
	update-apk() {
		_as_root apk update && _as_root apk upgrade "$@"
	}
fi

if command -v pkg > "/dev/null" 2>&1; then
	update-pkg() {
		_as_root pkg update && _as_root pkg upgrade --yes "$@"
	}
fi

if command -v paru > "/dev/null" 2>&1 || command -v yay > "/dev/null" 2>&1; then
	update-aur() {
		if command -v paru > "/dev/null" 2>&1; then
			command paru --noconfirm -Syu "$@"
		elif command -v yay > "/dev/null" 2>&1; then
			command yay --noconfirm -Syu "$@"
		fi
	}
fi

if command -v flatpak > "/dev/null" 2>&1; then
	update-flatpak() {
		command flatpak update --assumeyes "$@"
	}
fi

if command -v snap > "/dev/null" 2>&1; then
	update-snap() {
		_as_root snap refresh "$@"
	}
fi

### --------------------------------
### Update System (update-system)
### --------------------------------
update-system() {
	echo "📦 Updating OS system packages..."
	case "$(_detect_distro_family)" in
		arch)   command -v update-pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
		debian) command -v update-apt > "/dev/null" 2>&1 && update-apt "$@" ;;
		fedora) command -v update-dnf > "/dev/null" 2>&1 && update-dnf "$@" ;;
		suse)   command -v update-zypper > "/dev/null" 2>&1 && update-zypper "$@" ;;
		void)   command -v update-xbps > "/dev/null" 2>&1 && update-xbps "$@" ;;
		alpine) command -v update-apk > "/dev/null" 2>&1 && update-apk "$@" ;;
		*)
			case "$(_detect_os)" in
				freebsd) command -v update-pkg > "/dev/null" 2>&1 && update-pkg "$@" ;;
				windows) command -v update-pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
			esac
			;;
	esac
	echo "✅ OS system packages updated!"
}

### --------------------------------
### Update All Packages (update-all)
### --------------------------------
update-all() {
	echo "🚀 Starting full system update..."
	echo ""
	update-system "$@"

	if command -v update-aur > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating AUR packages..."
		update-aur "$@" && echo "✅ AUR packages updated!"
	fi

	if command -v update-flatpak > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Flatpak packages..."
		update-flatpak && echo "✅ Flatpak packages updated!"
	fi

	if command -v snap > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Snap packages..."
		update-snap && echo "✅ Snap packages updated!"
	fi

	echo ""
	echo "✅ All packages updated!"
}

### --------------------------------
### Poweroff System
### --------------------------------
poweroff() {
	case "$(_detect_os)" in
		windows)
			shutdown.exe /s /t 0 "$@"
			return $?
			;;
		freebsd)
			_flag="-p"
			;;
		*)
			_flag="-h"
			;;
	esac

	_as_root shutdown "${_flag}" now "$@"
	unset _flag
}

### --------------------------------
### Reboot System
### --------------------------------
reboot() {
	case "$(_detect_os)" in
		windows)
			shutdown.exe /r /t 0 "$@"
			return $?
			;;
		*)
			_as_root shutdown -r now "$@"
			;;
	esac
}
