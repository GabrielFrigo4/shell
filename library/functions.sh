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
	PATH=$(command printf "%s" "${PATH}" | command awk -v RS=: -v ORS=: '!a[$(0)]++' | command sed 's/:$//')
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
		
		env | grep "^WIFI_SSID_" | while IFS='=' read -r name ssid; do
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
		{
			echo "ctrl_interface=/var/run/wpa_supplicant"
			echo "ctrl_interface_group=wheel"
			echo "update_config=1"
			echo ""
		} > "$tmp_conf"

		env | grep "^WIFI_SSID_" | while IFS='=' read -r name ssid; do
			suffix="${name#WIFI_SSID_}"
			pass_var="WIFI_PASS_${suffix}"
			eval pass="\$${pass_var}"
			
			if [ -n "$ssid" ] && [ -n "$pass" ]; then
				echo "   ➕ Mapping network: '$ssid'"
				{
					echo "network={"
					echo "    ssid=\"$ssid\""
					echo "    psk=\"$pass\""
					echo "}"
					echo ""
				} >> "$tmp_conf"
			fi
		done

		if command cmp -s "$tmp_conf" "/etc/wpa_supplicant.conf"; then
			echo "   👉 Configuration is already up-to-date. Skipping restart."
			command rm -f "$tmp_conf"
		else
			echo "   🔄 Changes detected! Overwriting /etc/wpa_supplicant.conf..."
			command sudo cp "$tmp_conf" "/etc/wpa_supplicant.conf"
			
			echo "   ⚡ Restarting network stack (netif)..."
			command sudo service netif restart > "/dev/null" 2>&1 || true
			command rm -f "$tmp_conf"
		fi
		
		echo "✅ FreeBSD Wi-Fi configs applied!"

	elif command -v netsh > "/dev/null" 2>&1; then
		echo "🪟 Windows Network Shell (netsh) detected. Syncing Wi-Fi profiles..."

		env | grep "^WIFI_SSID_" | while IFS='=' read -r name ssid; do
			suffix="${name#WIFI_SSID_}"
			pass_var="WIFI_PASS_${suffix}"
			eval pass="\$${pass_var}"

			if [ -n "$ssid" ] && [ -n "$pass" ]; then
				echo "   ➕ Injecting profile: '$ssid'"
				xml_file=$(command mktemp)

				{
					echo '<?xml version="1.0"?>'
					echo '<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">'
					echo "    <name>$ssid</name>"
					echo "    <SSIDConfig>"
					echo "        <SSID>"
					echo "            <name>$ssid</name>"
					echo "        </SSID>"
					echo "    </SSIDConfig>"
					echo "    <connectionType>ESS</connectionType>"
					echo "    <connectionMode>auto</connectionMode>"
					echo "    <MSM>"
					echo "        <security>"
					echo "            <authEncryption>"
					echo "                <authentication>WPA2PSK</authentication>"
					echo "                <encryption>AES</encryption>"
					echo "                <useOneX>false</useOneX>"
					echo "            </authEncryption>"
					echo "            <sharedKey>"
					echo "                <keyType>passPhrase</keyType>"
					echo "                <protected>false</protected>"
					echo "                <keyMaterial>$pass</keyMaterial>"
					echo "            </sharedKey>"
					echo "        </security>"
					echo "    </MSM>"
					echo "</WLANProfile>"
				} > "$xml_file"

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
