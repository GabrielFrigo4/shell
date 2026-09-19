#!/usr/bin/env sh
# ----------------------------------------------------------------
# Utility: Universal Shell Installer
# ----------------------------------------------------------------

SHELL_REPO_DIR="$(cd "$(dirname "${0}")" && pwd)"
unset IFS
[ -n "${ZSH_VERSION:-}" ] && setopt SH_WORD_SPLIT 2> "/dev/null" || true

### --------------------------------
### Active Shell Elevation Guard
### --------------------------------
if [ -z "${ZSH_VERSION:-}" ]; then
	if ! (eval 'f-f() { :; }') 2> "/dev/null"; then
		if command -v zsh > "/dev/null" 2>&1; then
			exec zsh "$0" "$@"
		elif command -v bash > "/dev/null" 2>&1; then
			exec bash "$0" "$@"
		fi
	fi
fi


### --------------------------------
### Help Documentation
### --------------------------------
_show_help() {
	cat <<- EOF
		Universal Shell Installer

		Usage:
		  install.sh [OPTIONS]

		Options:
		  -c, --context <CTX>      Context profile: desktop, server, container (default: desktop)
		  -s, --shell <SHELL>      Target shell: all, zsh, bash, sh, ksh (default: all)
		      --pure               Native standalone templates, zero overhead (default)
		      --no-framework       Alias for --pure
		      --framework          Enable external frameworks (Oh-My-Zsh, Oh-My-Bash)
		      --with-framework     Alias for --framework
		      --oh-my-shell        Alias for --framework
		  -h, --help               Show this help message and exit

		Defaults:
		  By default, install.sh runs in pure mode (--pure) with desktop context (-c desktop)
		  and configures all supported shells found on the system (-s all).

		Examples:
		  install.sh                         # Default pure install for all detected shells
		  install.sh -c server               # Pure install configured for server environment
		  install.sh -s zsh                  # Configure only Zsh
		  install.sh --framework             # Install with Oh-My-Zsh and Oh-My-Bash enabled
		  install.sh -c container -s bash    # Minimal container setup for Bash
	EOF
}

### --------------------------------
### Parse Arguments
### --------------------------------
SHELL_CONTEXT="${SHELL_CONTEXT:-desktop}"
SHELL_TARGET="${SHELL_TARGET:-all}"
SHELL_FRAMEWORK="${SHELL_FRAMEWORK:-0}"

for arg in "$@"; do
	case "${arg}" in
		--help|-h)
			_show_help
			exit 0
			;;
		--context=*) SHELL_CONTEXT="${arg#*=}" ;;
		-c=*)        SHELL_CONTEXT="${arg#*=}" ;;
		--shell=*)   SHELL_TARGET="${arg#*=}" ;;
		-s=*)        SHELL_TARGET="${arg#*=}" ;;
		--framework|--with-framework|--oh-my-shell|--ohmysh|--omz|--omb) SHELL_FRAMEWORK=1 ;;
		--pure|--no-framework) SHELL_FRAMEWORK=0 ;;
	esac
done

_skip_next=0
for arg in "$@"; do
	if [ "${_skip_next}" -eq 1 ]; then
		SHELL_CONTEXT="${arg}"
		_skip_next=0
		continue
	fi
	if [ "${_skip_next}" -eq 2 ]; then
		SHELL_TARGET="${arg}"
		_skip_next=0
		continue
	fi
	case "${arg}" in
		--context|-c) _skip_next=1 ;;
		--shell|-s)   _skip_next=2 ;;
	esac
done
unset _skip_next

case "${SHELL_CONTEXT}" in
	desktop|server|container) ;;
	*)
		echo "❌ ERROR: Invalid context '${SHELL_CONTEXT}'. Use 'desktop', 'server' or 'container'." >&2
		echo "   Run '$0 --help' for usage instructions." >&2
		exit 1
		;;
esac

case "${SHELL_TARGET}" in
	all|zsh|bash|sh|ksh) ;;
	*)
		echo "❌ ERROR: Invalid shell '${SHELL_TARGET}'. Use 'all', 'zsh', 'bash', 'sh' or 'ksh'." >&2
		echo "   Run '$0 --help' for usage instructions." >&2
		exit 1
		;;
esac

### --------------------------------
### Detect Environment
### --------------------------------
. "${SHELL_REPO_DIR}/library/detect.sh"
. "${SHELL_REPO_DIR}/library/functions.sh"
_cache_clean
OS_NAME="$(_detect_os)"
SHELL_NAME="$(_detect_shell)"

### --------------------------------
### Determine Target Shells
### --------------------------------
if [ "${SHELL_TARGET}" != "all" ]; then
	TARGET_SHELLS="${SHELL_TARGET}"
else
	TARGET_SHELLS=""
	case "${OS_NAME}" in
		freebsd)
			command -v zsh > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} zsh"
			command -v bash > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} bash"
			TARGET_SHELLS="${TARGET_SHELLS} sh"
			;;
		openbsd)
			command -v zsh > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} zsh"
			command -v bash > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} bash"
			command -v ksh > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} ksh"
			;;
		linux|macos|windows|netbsd|illumos)
			command -v zsh > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} zsh"
			command -v bash > "/dev/null" 2>&1 && TARGET_SHELLS="${TARGET_SHELLS} bash"
			;;
		*)
			TARGET_SHELLS="${SHELL_NAME}"
			;;
	esac

	if [ -z "${TARGET_SHELLS}" ]; then
		TARGET_SHELLS="${SHELL_NAME}"
	fi
	TARGET_SHELLS="$(echo "${TARGET_SHELLS}" | sed 's/^[ ]*//')"
fi

echo "=== Shell Installer ==="
echo "Detected repo:   ${SHELL_REPO_DIR}"
echo "Detected OS:     ${OS_NAME}"
echo "Current shell:   ${SHELL_NAME}"
echo "Target shell(s): ${TARGET_SHELLS}"
echo "Context:         ${SHELL_CONTEXT}"
if [ "${SHELL_FRAMEWORK}" -eq 1 ]; then
	echo "Mode:            framework (Oh-My-Bash / Oh-My-Zsh enabled)"
else
	echo "Mode:            pure (standalone native templates, zero overhead)"
fi

### --------------------------------
### Repository Permissions
### --------------------------------
if [ "${OS_NAME}" != "windows" ]; then
	_as_root chown -R "$(id -un):$(id -gn)" "${SHELL_REPO_DIR}" 2> "/dev/null" || true
	_as_root find "${SHELL_REPO_DIR}" -type d -exec chmod 0755 {} + 2> "/dev/null" || true
	_as_root find "${SHELL_REPO_DIR}" -type f -exec chmod 0644 {} + 2> "/dev/null" || true
	[ -f "${SHELL_REPO_DIR}/install.sh" ] && chmod 0755 "${SHELL_REPO_DIR}/install.sh" 2> "/dev/null" || true
	[ -f "${SHELL_REPO_DIR}/benchmark.sh" ] && chmod 0755 "${SHELL_REPO_DIR}/benchmark.sh" 2> "/dev/null" || true
	[ -f "${SHELL_REPO_DIR}/.githooks/pre-commit" ] && chmod 0755 "${SHELL_REPO_DIR}/.githooks/pre-commit" 2> "/dev/null" || true
fi

if [ -d "${SHELL_REPO_DIR}/.git" ] && command -v git > "/dev/null" 2>&1; then
	command git -C "${SHELL_REPO_DIR}" config core.hooksPath .githooks 2> "/dev/null" || true
fi

### --------------------------------
### Standalone Base Template
### --------------------------------
_generate_rc_pure() {
	local _target="${1:-}"
	cat <<- 'EOF'
		### ================================
		### INTERACTIVE GUARD
		### ================================
		case "$-" in
		    *i*) ;;
		    *) return ;;
		esac
	EOF

	if [ "${_target}" = "sh" ]; then
		cat <<- 'EOF'

			### ================================
			### SHELL COMPATIBILITY GUARD
			### ================================
			[ -n "${ZSH_VERSION:-}" ] && return 0
			[ -n "${BASH_VERSION:-}" ] && return 0
			[ -n "${KSH_VERSION:-}" ] && return 0
			[ -n "${NETBSD_SHELL:-}" ] && return 0
			[ -n "${YASH_VERSION:-}" ] && return 0

			case "${0##*/}" in
			    *zsh*|*bash*|*dash*|*busybox*|*ash*|*hush*|*ksh*|*mksh*|*pdksh*|*oksh*|*yash*|*posh*) return 0 ;;
			esac

			builtin : 2> "/dev/null" || return 0
		EOF
	elif [ "${_target}" = "ksh" ]; then
		cat <<- 'EOF'

			### ================================
			### SHELL COMPATIBILITY GUARD
			### ================================
			[ -n "${ZSH_VERSION:-}" ] && return 0
			[ -n "${BASH_VERSION:-}" ] && return 0
			[ -n "${NETBSD_SHELL:-}" ] && return 0
			[ -n "${YASH_VERSION:-}" ] && return 0

			case "${0##*/}" in
			    *zsh*|*bash*|*dash*|*busybox*|*ash*|*hush*|*yash*|*posh*) return 0 ;;
			esac
		EOF
	fi
}

### --------------------------------
### Target Shell Installer
### --------------------------------
_install_shell_target() {
	local _target_shell="${1}"
	local _prompt_file="${SHELL_REPO_DIR}/target/${OS_NAME}/${_target_shell}/prompt.sh"

	if [ ! -f "${_prompt_file}" ]; then
		echo "⚠️  No prompt file found for ${_target_shell} at: ${_prompt_file}"
		echo "   Skipping ${_target_shell}."
		return 0
	fi

	local _rc_file
	local _root_rc_file
	case "${_target_shell}" in
		zsh)  _rc_file="${HOME}/.zshrc";  _root_rc_file="/root/.zshrc" ;;
		bash) _rc_file="${HOME}/.bashrc"; _root_rc_file="/root/.bashrc" ;;
		sh)   _rc_file="${HOME}/.shrc";   _root_rc_file="/root/.shrc" ;;
		ksh)  _rc_file="${HOME}/.kshrc";  _root_rc_file="/root/.kshrc" ;;
		*)    _rc_file="${HOME}/.${_target_shell}rc"; _root_rc_file="/root/.${_target_shell}rc" ;;
	esac

	rm -f "${_rc_file}"
	if [ "${OS_NAME}" != "windows" ]; then
		_as_root rm -f "${_root_rc_file}" 2> "/dev/null" || true
	fi

	if [ "${_target_shell}" = "zsh" ]; then
		local _zshenv="${HOME}/.zshenv"
		local _root_zshenv="/root/.zshenv"
		if [ ! -f "${_zshenv}" ] || ! grep -qF "unsetopt GLOBAL_RCS" "${_zshenv}" 2> "/dev/null"; then
			cat <<- 'EOF' >| "${_zshenv}"
				### ================================
				### ZSH ENVIRONMENT
				### ================================
				unsetopt GLOBAL_RCS
			EOF
		fi
		if [ "${OS_NAME}" != "windows" ]; then
			if ! _as_root test -f "${_root_zshenv}" 2> "/dev/null" || ! _as_root grep -qF "unsetopt GLOBAL_RCS" "${_root_zshenv}" 2> "/dev/null"; then
				cat <<- 'EOF' | _as_root tee "${_root_zshenv}" > "/dev/null" 2>&1 || true
					### ================================
					### ZSH ENVIRONMENT
					### ================================
					unsetopt GLOBAL_RCS
				EOF
			fi
		fi
	fi

	if [ "${_target_shell}" = "ksh" ] || [ "${_target_shell}" = "sh" ]; then
		local _profile="${HOME}/.profile"
		local _root_profile="/root/.profile"
		local _rc_name=".${_target_shell}rc"
		local _env_line="export ENV=\"\${HOME}/${_rc_name}\""
		if [ -f "${_profile}" ]; then
			if ! grep -qF "export ENV=" "${_profile}" 2> "/dev/null"; then
				echo "${_env_line}" >> "${_profile}"
			fi
		else
			echo "${_env_line}" >| "${_profile}"
		fi
		if [ "${OS_NAME}" != "windows" ]; then
			if _as_root test -f "${_root_profile}" 2> "/dev/null"; then
				if ! _as_root grep -qF "export ENV=" "${_root_profile}" 2> "/dev/null"; then
					echo "export ENV=\"/root/${_rc_name}\"" | _as_root tee -a "${_root_profile}" > "/dev/null" 2>&1 || true
				fi
			else
				echo "export ENV=\"/root/${_rc_name}\"" | _as_root tee "${_root_profile}" > "/dev/null" 2>&1 || true
			fi
		fi
	fi

	if [ "${SHELL_FRAMEWORK}" -eq 0 ] || [ "${_target_shell}" = "sh" ] || [ "${_target_shell}" = "ksh" ]; then
		_generate_rc_pure "${_target_shell}" >| "${_rc_file}"
		if [ "${OS_NAME}" != "windows" ]; then
			_generate_rc_pure "${_target_shell}" | _as_root tee "${_root_rc_file}" > "/dev/null" 2>&1 || true
		fi
	else
		case "${_target_shell}" in
			zsh)
				if command -v zsh > "/dev/null" 2>&1; then
					if [ ! -d "${HOME}/.oh-my-zsh" ]; then
						KEEP_ZSHRC=no OVERWRITE_CONFIRMATION=no curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | zsh -s -- --unattended
					else
						cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${_rc_file}"
					fi
					if [ -f "${_rc_file}" ]; then
						sed -i.bak "s/^# zstyle ':omz:update' mode disabled/zstyle ':omz:update' mode disabled/" "${_rc_file}" && rm -f "${_rc_file}.bak"
						if ! grep -qF 'ZSH_DISABLE_COMPFIX' "${_rc_file}" 2> "/dev/null"; then
							sed -i.bak '/^export ZSH=/i ZSH_DISABLE_COMPFIX="true"' "${_rc_file}" && rm -f "${_rc_file}.bak"
						fi
					fi
					[ -f "${HOME}/.zcompdump" ] && zsh -c 'zcompile "${HOME}/.zcompdump"' 2> "/dev/null" || true
					if [ "${OS_NAME}" != "windows" ]; then
						if ! _as_root test -d "/root/.oh-my-zsh"; then
							_as_root env KEEP_ZSHRC=no OVERWRITE_CONFIRMATION=no sh -c 'curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | zsh -s -- --unattended'
						else
							_as_root cp "/root/.oh-my-zsh/templates/zshrc.zsh-template" "${_root_rc_file}"
						fi
						if _as_root test -f "${_root_rc_file}"; then
							_as_root sed -i.bak "s/^# zstyle ':omz:update' mode disabled/zstyle ':omz:update' mode disabled/" "${_root_rc_file}" && _as_root rm -f "${_root_rc_file}.bak"
							if ! _as_root grep -qF 'ZSH_DISABLE_COMPFIX' "${_root_rc_file}" 2> "/dev/null"; then
								_as_root sed -i.bak '/^export ZSH=/i ZSH_DISABLE_COMPFIX="true"' "${_root_rc_file}" && _as_root rm -f "${_root_rc_file}.bak"
							fi
						fi
					fi
				fi
				;;
			bash)
				if command -v bash > "/dev/null" 2>&1; then
					if [ ! -d "${HOME}/.oh-my-bash" ]; then
						KEEP_BASHRC=no curl -fsSL "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh" | bash -s -- --unattended
					else
						cp "${HOME}/.oh-my-bash/templates/bashrc.osh-template" "${_rc_file}"
					fi
					if [ -f "${_rc_file}" ]; then
						sed -i.bak 's/OSH_THEME="[^"]*"/OSH_THEME=""/' "${_rc_file}" && rm -f "${_rc_file}.bak"
						sed -i.bak 's/^# DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' "${_rc_file}" && rm -f "${_rc_file}.bak"
						awk '
							/^completions=\(/ { print "completions=(git ssh)"; skip=1; next }
							/^aliases=\(/     { print "aliases=(general)"; skip=1; next }
							/^plugins=\(/     { print "plugins=(bashmarks)"; skip=1; next }
							skip && /^\)/     { skip=0; next }
							!skip             { print }
						' "${_rc_file}" > "${_rc_file}.tmp" && mv -f "${_rc_file}.tmp" "${_rc_file}"
					fi
					if [ "${OS_NAME}" != "windows" ]; then
						if ! _as_root test -d "/root/.oh-my-bash"; then
							_as_root env KEEP_BASHRC=no sh -c 'curl -fsSL "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh" | bash -s -- --unattended'
						else
							_as_root cp "/root/.oh-my-bash/templates/bashrc.osh-template" "${_root_rc_file}"
						fi
						if _as_root test -f "${_root_rc_file}"; then
							_as_root sed -i.bak 's/OSH_THEME="[^"]*"/OSH_THEME=""/' "${_root_rc_file}" && _as_root rm -f "${_root_rc_file}.bak"
							_as_root sed -i.bak 's/^# DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' "${_root_rc_file}" && _as_root rm -f "${_root_rc_file}.bak"
							_as_root sh -c 'awk '\''
								/^completions=\(/ { print "completions=(git ssh)"; skip=1; next }
								/^aliases=\(/     { print "aliases=(general)"; skip=1; next }
								/^plugins=\(/     { print "plugins=(bashmarks)"; skip=1; next }
								skip && /^\)/     { skip=0; next }
								!skip             { print }
							'\'' "$1" > "$1.tmp" && mv -f "$1.tmp" "$1"' _ "${_root_rc_file}"
						fi
					fi
				fi
				;;
		esac
	fi

	local _source_cmd="."
	local _repo_dir_line="export SHELL_REPO_DIR=\"${SHELL_REPO_DIR}\""
	local _context_line="export SHELL_CONTEXT=\"${SHELL_CONTEXT}\""
	local _source_line="${_source_cmd} \"\${SHELL_REPO_DIR}/target/${OS_NAME}/${_target_shell}/prompt.sh\""
	local _setup_block

	_setup_block="$(cat <<- EOF

		### ================================
		### Shell Environment Setup
		### ================================
		${_repo_dir_line}
		${_context_line}
		export SHELL_FRAMEWORK=${SHELL_FRAMEWORK}

		for _file in "\${SHELL_REPO_DIR}/library/"*.sh; do [ -f "\${_file}" ] && ${_source_cmd} "\${_file}"; done
		for _file in "\${SHELL_REPO_DIR}/core/"*.sh; do [ -f "\${_file}" ] && ${_source_cmd} "\${_file}"; done
		unset _file

		${_source_line}
	EOF
	)"

	echo "Target RC file: ${_rc_file}"
	if grep -qF "${_source_line}" "${_rc_file}" 2> "/dev/null"; then
		echo "Shell config already installed in ${_rc_file}"
		echo "Skipping."
	else
		echo "${_setup_block}" | tee -a "${_rc_file}" > "/dev/null"
		echo "Done! Added source lines to ${_rc_file}"
	fi

	if [ "${OS_NAME}" != "windows" ]; then
		echo "Target RC file: ${_root_rc_file} (root)"
		if _as_root grep -qF "${_source_line}" "${_root_rc_file}" 2> "/dev/null"; then
			echo "Shell config already installed in ${_root_rc_file}"
			echo "Skipping."
		else
			echo "${_setup_block}" | _as_root tee -a "${_root_rc_file}" > "/dev/null" 2>&1 || true
			echo "Done! Added source lines to ${_root_rc_file}"
		fi
	fi
}

### --------------------------------
### Execute Installation
### --------------------------------
for _target in ${TARGET_SHELLS}; do
	echo ""
	echo "🔧 Configuring for shell: ${_target}"
	_install_shell_target "${_target}"
done

echo ""
echo "✨ Installation finished for target shells: ${TARGET_SHELLS}"
echo "Restart your terminal or reload your shell profile."
