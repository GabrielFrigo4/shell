### --------------------------------
### Triggers Setup
### --------------------------------
_TRIGGERS_CACHE="${HOME}/.cache/triggers.sh"

_triggers_setup() {
	mkdir -p "${HOME}/.cache"
	echo "# $(command date +%Y-%m-%d)" > "${_TRIGGERS_CACHE}"

	local _IGNORE_LIST_BASE="sh command eval alias unalias return echo printf test [ clear"
	local _IGNORE_LIST_EXT="cat grep egrep awk sed wc head tail less more cut tr sort uniq xargs find ls"
	local _IGNORE_LIST_PKG="exa eza rg fd fzf jq bat ag ack htop tmux neofetch fastfetch"
	local _IGNORE_LIST=" ${_IGNORE_LIST_BASE} ${_IGNORE_LIST_EXT} ${_IGNORE_LIST_PKG} "
	local _triggers=""

	for _file in /bin/* /usr/bin/*; do
		if [ -f "${_file}" ] && [ -x "${_file}" ]; then
			local _cmd_name="${_file##*/}"
			case "${_IGNORE_LIST}" in
				*" ${_cmd_name} "*) continue ;;
			esac
			_triggers="${_triggers} ${_cmd_name}"
		fi
	done

	for _file in /usr/local/bin/? \
				/usr/local/bin/?? \
				/usr/local/bin/??? \
				/usr/local/bin/???? \
				/usr/local/bin/?????; do
		if [ -f "${_file}" ] && [ -x "${_file}" ]; then
			local _cmd_name="${_file##*/}"
			case "${_IGNORE_LIST}" in
				*" ${_cmd_name} "*) continue ;;
			esac
			_triggers="${_triggers} ${_cmd_name}"
		fi
	done

	_triggers=$(echo ${_triggers} | tr ' ' '\n' | sort -u | tr '\n' ' ')
	for _cmd in ${_triggers}; do
		if command -v "${_cmd}" > "/dev/null" 2>&1; then
			echo "unalias ${_cmd} > \"/dev/null\" 2>&1" >> "${_TRIGGERS_CACHE}"
			case "${_cmd}" in
				*+*|*-*|*.*)
					echo "alias ${_cmd}='_run_and_update ${_cmd}'" >> "${_TRIGGERS_CACHE}"
					;;
				*)
					echo "${_cmd}() { _run_and_update ${_cmd} \"\$@\"; }" >> "${_TRIGGERS_CACHE}"
					;;
			esac
		fi
	done
}

if [ -f "${_TRIGGERS_CACHE}" ]; then
	read -r _triggers_date < "${_TRIGGERS_CACHE}"
	if [ "${_triggers_date}" != "# $(command date +%Y-%m-%d)" ]; then
		command rm -f "${_TRIGGERS_CACHE}"
	fi
fi

if [ ! -f "${_TRIGGERS_CACHE}" ]; then
	_triggers_setup
fi
