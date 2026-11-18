# ----------------------------------------------------------------
# Library: Navigation, Cache, History & Archive Utilities
# ----------------------------------------------------------------

### --------------------------------
### CLEAN CACHE
### --------------------------------
clean-cache() {
	_ui_step "Limpando cache do Universal Shell..."
	_cache_clean
	_ui_ok "Cache do Universal Shell limpo com sucesso!"
}
alias cleancache="clean-cache"
alias ccache="clean-cache"

### --------------------------------
### NAVIGATION HISTORY & ARCHIVES
### --------------------------------
take-dir() {
	if [ "$#" -eq 0 ]; then
		printf "Uso: take <diretorio>\n" >&2
		return 1
	fi
	command mkdir -p -- "$1" && cd -- "$1"
}

cd-git-root() {
	local _root
	_root="$(command git rev-parse --show-toplevel 2> "/dev/null")" || {
		_ui_err "Não está dentro de um repositório git."
		return 1
	}
	cd -- "${_root}"
}

hist-search() {
	if [ "$#" -eq 0 ]; then
		if [ -n "${BASH_VERSION:-}" ]; then command history 30
		elif [ -n "${ZSH_VERSION:-}" ]; then command history -30
		else command fc -l -30 2> "/dev/null" || command fc -l -1 2> "/dev/null"; fi
	else
		if [ -n "${BASH_VERSION:-}" ]; then command history | command grep -i "$@"
		elif [ -n "${ZSH_VERSION:-}" ]; then command history 1 | command grep -i "$@"
		else command fc -l 1 2> "/dev/null" | command grep -i "$@"; fi
	fi
}

extract-archive() {
	if [ "$#" -eq 0 ]; then
		echo "Uso: extract <arquivo>" >&2
		return 1
	fi
	if [ ! -f "$1" ]; then
		_ui_err "Arquivo '$1' não encontrado."
		return 1
	fi
	case "$1" in
		*.tar.bz2|*.tbz2) command tar -xjvf "$1" ;;
		*.tar.gz|*.tgz)   command tar -xzvf "$1" ;;
		*.tar.xz|*.txz)   command tar -xJvf "$1" ;;
		*.tar.zst)        command tar --zstd -xvf "$1" 2> "/dev/null" || command tar -xvf "$1" ;;
		*.tar)            command tar -xvf "$1" ;;
		*.gz)             command gunzip "$1" ;;
		*.bz2)            command bunzip2 "$1" ;;
		*.xz)             command unxz "$1" ;;
		*.zip)            command unzip "$1" ;;
		*.7z)             command 7z x "$1" ;;
		*.rar)            command unrar x "$1" ;;
		*.Z)              command uncompress "$1" ;;
		*)                _ui_err "Formato não suportado para extração: '$1'"; return 1 ;;
	esac
}
