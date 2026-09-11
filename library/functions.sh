### ================================
### CORE FUNCTIONS
### ================================

### --------------------------------
### Privilege Escalation
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
### Path Front
### --------------------------------
path-front() {
	case ":${PATH}:" in
		*":${1}:"*) ;;
		*) [ -d "${1}" ] && export PATH="${1}:${PATH}" ;;
	esac
}

### --------------------------------
### Path Back
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
	local _old_ifs="${IFS+x}"
	local _saved_ifs="${IFS:-}"
	local _new_path=""
	local _dir
	IFS=":"
	for _dir in ${PATH}; do
		[ -z "${_dir}" ] && continue
		case ":${_new_path}:" in
			*":${_dir}:"*) ;;
			*)
				if [ -z "${_new_path}" ]; then
					_new_path="${_dir}"
				else
					_new_path="${_new_path}:${_dir}"
				fi
				;;
		esac
	done
	if [ -n "${_old_ifs}" ]; then
		IFS="${_saved_ifs}"
	else
		unset IFS
	fi
	PATH="${_new_path}"
	export PATH
}

### --------------------------------
### Clean Cache
### --------------------------------
clean-cache() {
	_cache_clean
	echo "🧹 Universal Shell cache cleared."
}
alias cleancache="clean-cache"
alias ccache="clean-cache"

### --------------------------------
### Update Shell
### --------------------------------
update-shell() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -d "${SHELL_REPO_DIR}" ]; then
		echo "🔄 Updating shell repository at ${SHELL_REPO_DIR}..."
		command git -C "${SHELL_REPO_DIR}" pull
		if [ -d "${OSH:-${HOME}/.oh-my-bash}" ]; then
			echo "🔄 Updating Oh-My-Bash..."
			command git -C "${OSH:-${HOME}/.oh-my-bash}" pull --ff-only 2> "/dev/null" || true
		fi
		if [ -d "${ZSH:-${HOME}/.oh-my-zsh}" ]; then
			echo "🔄 Updating Oh-My-Zsh..."
			command git -C "${ZSH:-${HOME}/.oh-my-zsh}" pull --ff-only 2> "/dev/null" || true
		fi
		_cache_clean
		echo "♻️ Reloading shell environment..."
		. "${HOME}/.$(_detect_shell)rc" 2> "/dev/null" || true
	else
		echo "❌ ERROR: SHELL_REPO_DIR is not set or invalid."
		echo "Please re-run the install.sh script from your shell repository."
	fi
}

### --------------------------------
### Update Editors
### --------------------------------
update-editors() {
	_env_root="${ENVIRONMENT_DIR:-${HOME}/Documentos/Environment}"
	_ed_list="Emacs Helix NeoVim Vim"
	_found=0

	for _ed in ${_ed_list}; do
		_target=""
		if [ -e "${_env_root}/Editor/${_ed}/.git" ]; then
			_target="${_env_root}/Editor/${_ed}"
		else
			case "${_ed}" in
				Emacs)   [ -e "${HOME}/.emacs.d/.git" ] && _target="${HOME}/.emacs.d" ;;
				Helix)   [ -e "${HOME}/.config/helix/.git" ] && _target="${HOME}/.config/helix" ;;
				NeoVim)  [ -e "${HOME}/.config/nvim/.git" ] && _target="${HOME}/.config/nvim" ;;
				Vim)     [ -e "${HOME}/vimfiles/.git" ] && _target="${HOME}/vimfiles" ;;
			esac
		fi

		if [ -n "${_target}" ]; then
			echo "⬇️  Updating ${_ed} at ${_target}..."
			command git -C "${_target}" pull --ff-only || echo "⚠️  ${_ed}: git pull failed."
			_found=1
		fi
	done

	if [ "${_found}" -eq 0 ]; then
		echo "ℹ️  No editor repositories found in ${_env_root}/Editor or standard paths."
	fi
	unset _env_root _ed_list _found _ed _target
}

### --------------------------------
### Update Git Repositories
### --------------------------------
update-git() {
	_target_root="${1:-${PWD}}"
	if [ ! -d "${_target_root}" ]; then
		echo "❌ ERROR: Diretório não encontrado: ${_target_root}"
		return 1
	fi

	echo "🔄 [upgit] Buscando e atualizando repositórios Git em: ${_target_root}"
	echo ""

	find "${_target_root}" -maxdepth 3 -name ".git" 2> "/dev/null" | while read -r _git_entry; do
		_repo_dir="$(dirname "${_git_entry}")"
		echo "# ----------------------------------------------------------------"
		echo "# ${_repo_dir}"
		echo "# ----------------------------------------------------------------"
		command git -C "${_repo_dir}" pull --ff-only 2> "/dev/null" || command git -C "${_repo_dir}" pull || echo "⚠️  Falha ao atualizar ${_repo_dir}"
		echo ""
	done

	unset _target_root _git_entry _repo_dir
}

### --------------------------------
### Reinstall Shell
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

	_cache_clean

	local _args="--context ${SHELL_CONTEXT:-desktop}"
	if [ "${SHELL_FRAMEWORK:-0}" -eq 1 ]; then
		_args="${_args} --framework"
	fi

	local _cur_shell="$(_detect_shell)"
	local _cur_bin
	_cur_bin="$(command -v "${_cur_shell}" 2> "/dev/null" || command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || command -v sh 2> "/dev/null")"

	echo "🔧 Re-running install.sh with context '${SHELL_CONTEXT:-desktop}' using ${_cur_shell}..."
	"${_cur_bin}" "${SHELL_REPO_DIR}/install.sh" ${_args} "$@"

	echo "♻️ Reloading shell environment..."
	. "${HOME}/.${_cur_shell}rc" 2> "/dev/null" || true

	echo "✅ Shell fully reinstalled and reloaded!"
}

### --------------------------------
### Benchmark Shell
### --------------------------------
bench-shell() {
	if [ -n "${SHELL_REPO_DIR}" ] && [ -f "${SHELL_REPO_DIR}/scripts/benchmark.sh" ]; then
		local _cur_bin
		_cur_bin="$(command -v "$(_detect_shell)" 2> "/dev/null" || command -v zsh 2> "/dev/null" || command -v bash 2> "/dev/null" || command -v sh 2> "/dev/null")"
		"${_cur_bin}" "${SHELL_REPO_DIR}/scripts/benchmark.sh" "$@"
	else
		echo "❌ ERROR: Benchmark script not found in ${SHELL_REPO_DIR}/scripts/benchmark.sh."
		return 1
	fi
}

### --------------------------------
### Update Wi-Fi
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
### Update Network
### --------------------------------
update-network() {
	echo "🌐 Starting network..."
	update-wifi
	echo "✅ Network update complete!"
}

### --------------------------------
### Package Managers
### --------------------------------
update-pacman() {
	command -v pacman > "/dev/null" 2>&1 || { echo "❌ pacman not found." >&2; return 127; }
	if [ "$(_detect_os)" = "windows" ]; then
		command pacman --noconfirm -Syu "$@"
	else
		_as_root pacman --noconfirm -Syu "$@"
	fi
}

update-apt() {
	command -v apt > "/dev/null" 2>&1 || { echo "❌ apt not found." >&2; return 127; }
	_as_root apt update && _as_root apt upgrade --yes "$@"
}

update-dnf() {
	command -v dnf > "/dev/null" 2>&1 || { echo "❌ dnf not found." >&2; return 127; }
	_as_root dnf upgrade --assumeyes "$@"
}

update-zypper() {
	command -v zypper > "/dev/null" 2>&1 || { echo "❌ zypper not found." >&2; return 127; }
	_as_root zypper --non-interactive update "$@"
}

update-xbps() {
	command -v xbps-install > "/dev/null" 2>&1 || { echo "❌ xbps-install not found." >&2; return 127; }
	_as_root xbps-install --yes -Su "$@"
}

update-apk() {
	command -v apk > "/dev/null" 2>&1 || { echo "❌ apk not found." >&2; return 127; }
	_as_root apk update && _as_root apk upgrade "$@"
}

update-pkg() {
	command -v pkg > "/dev/null" 2>&1 || { echo "❌ pkg not found." >&2; return 127; }
	_as_root pkg update && _as_root pkg upgrade --yes "$@"
}

update-aur() {
	if command -v paru > "/dev/null" 2>&1; then
		command paru --noconfirm -Syu "$@"
	elif command -v yay > "/dev/null" 2>&1; then
		command yay --noconfirm -Syu "$@"
	else
		echo "❌ Neither 'paru' nor 'yay' found." >&2
		return 127
	fi
}

update-flatpak() {
	command -v flatpak > "/dev/null" 2>&1 || { echo "❌ flatpak not found." >&2; return 127; }
	command flatpak update --assumeyes "$@"
}

update-snap() {
	command -v snap > "/dev/null" 2>&1 || { echo "❌ snap not found." >&2; return 127; }
	_as_root snap refresh "$@"
}


### --------------------------------
### Update System
### --------------------------------
update-system() {
	echo "📦 Updating OS system packages..."
	case "$(_detect_distro_family)" in
		arch)   command -v pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
		debian) command -v apt > "/dev/null" 2>&1 && update-apt "$@" ;;
		fedora) command -v dnf > "/dev/null" 2>&1 && update-dnf "$@" ;;
		suse)   command -v zypper > "/dev/null" 2>&1 && update-zypper "$@" ;;
		void)   command -v xbps-install > "/dev/null" 2>&1 && update-xbps "$@" ;;
		alpine) command -v apk > "/dev/null" 2>&1 && update-apk "$@" ;;
		*)
			case "$(_detect_os)" in
				freebsd) command -v pkg > "/dev/null" 2>&1 && update-pkg "$@" ;;
				windows) command -v pacman > "/dev/null" 2>&1 && update-pacman "$@" ;;
			esac
			;;
	esac
	echo "✅ OS system packages updated!"
}

### --------------------------------
### Update All Packages
### --------------------------------
update-all() {
	echo "🚀 Starting full system update..."
	echo ""
	update-system "$@"

	if command -v paru > "/dev/null" 2>&1 || command -v yay > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating AUR packages..."
		update-aur "$@" && echo "✅ AUR packages updated!"
	fi

	if command -v flatpak > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Flatpak packages..."
		update-flatpak "$@" && echo "✅ Flatpak packages updated!"
	fi

	if command -v snap > "/dev/null" 2>&1; then
		echo ""
		echo "📦 Updating Snap packages..."
		update-snap "$@" && echo "✅ Snap packages updated!"
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
