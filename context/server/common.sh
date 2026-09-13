### ================================
### SERVER CONTEXT COMMON
### ================================

### --------------------------------
### Open Ports
### --------------------------------
ports() {
	if command -v ss > "/dev/null" 2>&1; then
		command ss -tulnp "$@"
	elif command -v netstat > "/dev/null" 2>&1; then
		command netstat -tulnp "$@" 2> "/dev/null" || command netstat -an "$@"
	elif command -v sockstat > "/dev/null" 2>&1; then
		command sockstat -l "$@"
	else
		echo "❌ No port inspection tool found (ss/netstat/sockstat)." >&2
		return 1
	fi
}

### --------------------------------
### Active Connections
### --------------------------------
conns() {
	if command -v ss > "/dev/null" 2>&1; then
		command ss -tunp "$@"
	elif command -v netstat > "/dev/null" 2>&1; then
		command netstat -tunp "$@" 2> "/dev/null" || command netstat -an "$@"
	elif command -v sockstat > "/dev/null" 2>&1; then
		command sockstat "$@"
	else
		echo "❌ No connection inspection tool found (ss/netstat/sockstat)." >&2
		return 1
	fi
}

### --------------------------------
### Log Stream
### --------------------------------
logs() {
	if command -v journalctl > "/dev/null" 2>&1; then
		command journalctl -f --no-hostname -n 50 "$@"
	elif [ -f /var/adm/messages ]; then
		_as_root tail -f -n 50 /var/adm/messages
	elif [ -f /var/log/messages ]; then
		_as_root tail -f -n 50 /var/log/messages
	elif [ -f /var/log/syslog ]; then
		_as_root tail -f -n 50 /var/log/syslog
	else
		echo "❌ No log source found (journalctl/messages/syslog)." >&2
		return 1
	fi
}

### --------------------------------
### Service Status
### --------------------------------
services() {
	if command -v systemctl > "/dev/null" 2>&1; then
		command systemctl list-units --type=service --state=running --no-pager "$@"
	elif command -v svcs > "/dev/null" 2>&1; then
		command svcs "$@"
	elif command -v rcctl > "/dev/null" 2>&1; then
		command rcctl ls on 2> "/dev/null" || command rcctl ls started 2> "/dev/null" || echo "Use: rcctl check <service>"
	elif command -v service > "/dev/null" 2>&1; then
		command service -e 2> "/dev/null" || command service -l 2> "/dev/null" || echo "Use: service <name> status"
	elif command -v rc-status > "/dev/null" 2>&1; then
		command rc-status "$@"
	else
		echo "❌ No service manager found (systemctl/svcs/rcctl/service/rc-status)." >&2
		return 1
	fi
}

### --------------------------------
### Server Aliases
### --------------------------------
alias p="ports"
alias svc="services"
