### ================================
### SERVER CONTEXT COMMON
### ================================

### --------------------------------
### OPEN PORTS
### --------------------------------
ports() {
	if command -v ss > "/dev/null" 2>&1; then
		command ss -tulnp "$@"
	elif command -v netstat > "/dev/null" 2>&1; then
		command netstat -tulnp "$@" 2> "/dev/null" || command netstat -an "$@"
	elif command -v sockstat > "/dev/null" 2>&1; then
		command sockstat -l "$@"
	else
		_ui_err "No port inspection tool found (ss/netstat/sockstat)."
		return 1
	fi
}

### --------------------------------
### ACTIVE CONNECTIONS
### --------------------------------
conns() {
	if command -v ss > "/dev/null" 2>&1; then
		command ss -tunp "$@"
	elif command -v netstat > "/dev/null" 2>&1; then
		command netstat -tunp "$@" 2> "/dev/null" || command netstat -an "$@"
	elif command -v sockstat > "/dev/null" 2>&1; then
		command sockstat "$@"
	else
		_ui_err "No connection inspection tool found (ss/netstat/sockstat)."
		return 1
	fi
}

### --------------------------------
### LOG STREAM
### --------------------------------
logs() {
	if command -v journalctl > "/dev/null" 2>&1; then
		command journalctl -f --no-hostname -n 50 "$@"
	elif [ -f "/var/adm/messages" ]; then
		_as_root tail -f -n 50 "/var/adm/messages"
	elif [ -f "/var/log/messages" ]; then
		_as_root tail -f -n 50 "/var/log/messages"
	elif [ -f "/var/log/syslog" ]; then
		_as_root tail -f -n 50 "/var/log/syslog"
	else
		_ui_err "No log source found (journalctl/messages/syslog)."
		return 1
	fi
}

### --------------------------------
### SERVICE STATUS
### --------------------------------
services() {
	if command -v systemctl > "/dev/null" 2>&1; then
		command systemctl list-units --type=service --state=running --no-pager "$@"
	elif command -v svcs > "/dev/null" 2>&1; then
		command svcs "$@"
	elif command -v rcctl > "/dev/null" 2>&1; then
		command rcctl ls on 2> "/dev/null" || command rcctl ls started 2> "/dev/null" || _ui_info "Use: rcctl check <service>"
	elif command -v service > "/dev/null" 2>&1; then
		command service -e 2> "/dev/null" || command service -l 2> "/dev/null" || _ui_info "Use: service <name> status"
	elif command -v rc-status > "/dev/null" 2>&1; then
		command rc-status "$@"
	else
		_ui_err "No service manager found (systemctl/svcs/rcctl/service/rc-status)."
		return 1
	fi
}

### --------------------------------
### SERVER ALIASES
### --------------------------------
alias p="ports"
alias svc="services"

### --------------------------------
### SSH & REMOTE SESSION
### --------------------------------
if command -v _is_ssh > "/dev/null" 2>&1 && _is_ssh; then
	export REMOTE_SESSION=1
	who-remote() {
		local _ssh_client="${SSH_CLIENT:-}"
		local _ssh_connection="${SSH_CONNECTION:-}"
		local _ip_address="${_ssh_client%% *}"
		[ -z "${_ip_address}" ] && _ip_address="${_ssh_connection%% *}"
		printf "🌐 Connected via SSH from: %s\n" "${_ip_address:-unknown}"
	}
	alias myip="who-remote"
fi

### --------------------------------
### PYTHON PERFORMANCE CACHE
### --------------------------------
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"
