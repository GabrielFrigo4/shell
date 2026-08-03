### ================================
### TRIGGERS ENVIRONMENT
### ================================

TRIGGERS_CACHE="${HOME}/.cache/triggers.sh"

triggers-setup() {
	mkdir -p "${HOME}/.cache"
	echo "# $(command date +%Y-%m-%d)" > "${TRIGGERS_CACHE}"

	local IGNORE_LIST_BASE="sh command eval alias unalias return echo printf test [ clear"
	local IGNORE_LIST_EXT="cat grep egrep awk sed wc head tail less more cut tr sort uniq xargs find ls"
	local IGNORE_LIST_PKG="exa eza rg fd fzf jq bat ag ack htop tmux neofetch fastfetch"
	local IGNORE_LIST=" ${IGNORE_LIST_BASE} ${IGNORE_LIST_EXT} ${IGNORE_LIST_PKG} "
	local TRIGGERS=""

	for file in /bin/* /usr/bin/*; do
		if [ -f "$file" ] && [ -x "$file" ]; then
			local cmd_name="${file##*/}"
			case "${IGNORE_LIST}" in
				*" ${cmd_name} "*) continue ;;
			esac
			TRIGGERS="${TRIGGERS} ${cmd_name}"
		fi
	done

	for file in /usr/local/bin/? \
				/usr/local/bin/?? \
				/usr/local/bin/??? \
				/usr/local/bin/???? \
				/usr/local/bin/?????; do
		if [ -f "$file" ] && [ -x "$file" ]; then
			local cmd_name="${file##*/}"
			case "${IGNORE_LIST}" in
				*" ${cmd_name} "*) continue ;;
			esac
			TRIGGERS="${TRIGGERS} ${cmd_name}"
		fi
	done

	TRIGGERS=$(echo ${TRIGGERS} | tr ' ' '\n' | sort -u | tr '\n' ' ')
	for cmd in ${TRIGGERS}; do
		if command -v "$cmd" > "/dev/null" 2>&1; then
			echo "unalias ${cmd} > \"/dev/null\" 2>&1" >> "${TRIGGERS_CACHE}"
			case "$cmd" in
				*+*|*-*|*.*)
					echo "alias ${cmd}='run_and_update ${cmd}'" >> "${TRIGGERS_CACHE}"
					;;
				*)
					echo "${cmd}() { run_and_update ${cmd} \"\$@\"; }" >> "${TRIGGERS_CACHE}"
					;;
			esac
		fi
	done
}

if [ -f "${TRIGGERS_CACHE}" ]; then
	read -r TRIGGERS_DATE < "${TRIGGERS_CACHE}"
	if [ "${TRIGGERS_DATE}" != "# $(command date +%Y-%m-%d)" ]; then
		command rm -f "${TRIGGERS_CACHE}"
	fi
fi

if [ ! -f "${TRIGGERS_CACHE}" ]; then
	triggers-setup
fi
