### ================================
### ZSH CONFIGURATION
### ================================

### --------------------------------
### COMPATIBILITY AND PARSING
### --------------------------------
setopt SH_WORD_SPLIT
IFS=$' \t\n'

### --------------------------------
### HISTORY
### --------------------------------
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${HOME}/.zsh_history"

setopt APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS HIST_VERIFY

### --------------------------------
### INTERACTION & SAFETY
### --------------------------------
unsetopt CORRECT BEEP
setopt INTERACTIVE_COMMENTS RM_STAR_WAIT NO_CLOBBER
disable r 2> "/dev/null" || true
unalias r 2> "/dev/null" || true
unset -f r 2> "/dev/null" || true

r() {
	if command -v rg > "/dev/null" 2>&1; then
		if [ -t 1 ]; then
			command rg --smart-case "$@"
		else
			command rg --smart-case --color=never "$@"
		fi
	elif command -v grep > "/dev/null" 2>&1; then
		if [ -t 1 ]; then
			grep -Ei "$@"
		else
			command grep -Ei "$@"
		fi
	fi
}

### --------------------------------
### KEYBINDINGS & LINE EDITING
### --------------------------------
bindkey -e
zmodload -i zsh/terminfo 2> "/dev/null" || true

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
	_zle_line_init() { echoti smkx 2> "/dev/null" || true }
	_zle_line_finish() { echoti rmkx 2> "/dev/null" || true }
	zle -N zle-line-init _zle_line_init 2> "/dev/null" || true
	zle -N zle-line-finish _zle_line_finish 2> "/dev/null" || true
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search 2> "/dev/null" || true
zle -N up-line-or-beginning-search 2> "/dev/null" || true
zle -N down-line-or-beginning-search 2> "/dev/null" || true

bindkey '^[[A' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[OA' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[B' down-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[OB' down-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[5~' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[6~' down-line-or-beginning-search 2> "/dev/null" || true
[ -n "${terminfo[kcuu1]:-}" ] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search 2> "/dev/null" || true
[ -n "${terminfo[kcud1]:-}" ] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search 2> "/dev/null" || true

bindkey '^[[C' forward-char 2> "/dev/null" || true
bindkey '^[OC' forward-char 2> "/dev/null" || true
[ -n "${terminfo[kcuf1]:-}" ] && bindkey "${terminfo[kcuf1]}" forward-char 2> "/dev/null" || true

bindkey '^[[D' backward-char 2> "/dev/null" || true
bindkey '^[OD' backward-char 2> "/dev/null" || true
[ -n "${terminfo[kcub1]:-}" ] && bindkey "${terminfo[kcub1]}" backward-char 2> "/dev/null" || true

bindkey '^R' history-incremental-pattern-search-backward 2> "/dev/null" || true
bindkey '^S' history-incremental-pattern-search-forward 2> "/dev/null" || true

bindkey '^[[H' beginning-of-line 2> "/dev/null" || true
bindkey '^[OH' beginning-of-line 2> "/dev/null" || true
bindkey '^[[1~' beginning-of-line 2> "/dev/null" || true
bindkey '^[[7~' beginning-of-line 2> "/dev/null" || true
[ -n "${terminfo[khome]:-}" ] && bindkey "${terminfo[khome]}" beginning-of-line 2> "/dev/null" || true

bindkey '^[[F' end-of-line 2> "/dev/null" || true
bindkey '^[OF' end-of-line 2> "/dev/null" || true
bindkey '^[[4~' end-of-line 2> "/dev/null" || true
bindkey '^[[8~' end-of-line 2> "/dev/null" || true
[ -n "${terminfo[kend]:-}" ] && bindkey "${terminfo[kend]}" end-of-line 2> "/dev/null" || true

bindkey '^[[3~' delete-char 2> "/dev/null" || true
[ -n "${terminfo[kdch1]:-}" ] && bindkey "${terminfo[kdch1]}" delete-char 2> "/dev/null" || true

bindkey '^?' backward-delete-char 2> "/dev/null" || true
bindkey '^H' backward-delete-char 2> "/dev/null" || true
bindkey '^W' backward-kill-word 2> "/dev/null" || true
bindkey '^U' backward-kill-line 2> "/dev/null" || true
bindkey '^[^?' backward-kill-word 2> "/dev/null" || true
bindkey '^[^H' backward-kill-word 2> "/dev/null" || true

bindkey '^[[1;5C' forward-word 2> "/dev/null" || true
bindkey '^[[1;5D' backward-word 2> "/dev/null" || true
bindkey '^[[1;3C' forward-word 2> "/dev/null" || true
bindkey '^[[1;3D' backward-word 2> "/dev/null" || true
bindkey '^[[5C' forward-word 2> "/dev/null" || true
bindkey '^[[5D' backward-word 2> "/dev/null" || true
bindkey '^[Oc' forward-word 2> "/dev/null" || true
bindkey '^[Od' backward-word 2> "/dev/null" || true
bindkey '^[^[[C' forward-word 2> "/dev/null" || true
bindkey '^[^[[D' backward-word 2> "/dev/null" || true

bindkey '^[[3;5~' kill-word 2> "/dev/null" || true

bindkey '^[[1;2A' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[1;2B' down-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[1;2C' forward-word 2> "/dev/null" || true
bindkey '^[[1;2D' backward-word 2> "/dev/null" || true
bindkey '^[[a' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[b' down-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[c' forward-word 2> "/dev/null" || true
bindkey '^[[d' backward-word 2> "/dev/null" || true

bindkey '^[[[A' undefined-key 2> "/dev/null" || true
bindkey '^[[[B' undefined-key 2> "/dev/null" || true
bindkey '^[[[C' undefined-key 2> "/dev/null" || true
bindkey '^[[[D' undefined-key 2> "/dev/null" || true

bindkey -s '^[Op' '0' 2> "/dev/null" || true
bindkey -s '^[Oq' '1' 2> "/dev/null" || true
bindkey -s '^[Or' '2' 2> "/dev/null" || true
bindkey -s '^[Os' '3' 2> "/dev/null" || true
bindkey -s '^[Ot' '4' 2> "/dev/null" || true
bindkey -s '^[Ou' '5' 2> "/dev/null" || true
bindkey -s '^[Ov' '6' 2> "/dev/null" || true
bindkey -s '^[Ow' '7' 2> "/dev/null" || true
bindkey -s '^[Ox' '8' 2> "/dev/null" || true
bindkey -s '^[Oy' '9' 2> "/dev/null" || true
bindkey -s '^[On' '.' 2> "/dev/null" || true
bindkey '^[OM' accept-line 2> "/dev/null" || true
bindkey -s '^[Oj' '*' 2> "/dev/null" || true
bindkey -s '^[Ok' '+' 2> "/dev/null" || true
bindkey -s '^[Ol' ',' 2> "/dev/null" || true
bindkey -s '^[Om' '-' 2> "/dev/null" || true
bindkey -s '^[Oo' '/' 2> "/dev/null" || true

### --------------------------------
### NAVIGATION
### --------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT COMPLETE_IN_WORD

### --------------------------------
### GLOBBING
### --------------------------------
setopt EXTENDED_GLOB GLOB_DOTS NULL_GLOB KSH_GLOB

### --------------------------------
### COMPLETION ENGINE
### --------------------------------
zmodload -i zsh/complist 2> "/dev/null" || true

_zsh_strip_ansi() {
	setopt LOCAL_OPTIONS EXTENDED_GLOB MULTIBYTE
	local _stripped="${1:-}"
	_stripped="${_stripped//$'\x1b'\[[0-9:;?]#[a-zA-Z@~]/}"
	_stripped="${_stripped//$'\x1b'\][^$'\x07\x1b']#($'\x07'|$'\x1b'\\)/}"
	_stripped="${_stripped//$'\x1b'%[G@]/}"
	_stripped="${_stripped//$'\x1b'[()][AB012]/}"
	_stripped="${_stripped//$'\x1b'[=>]/}"
	_stripped="${_stripped//[$'\x01\x0e\x0f']/}"
	REPLY="${_stripped}"
}

_zsh_comp_format() {
	setopt LOCAL_OPTIONS EXTENDED_GLOB MULTIBYTE
	local _kind="${1:-description}"
	local _raw_text="${2:-}"
	local _err_spec="${3:-}"
	local _cols=$(( COLUMNS > 0 ? COLUMNS : 80 ))
	local _pad_fill=""
	local _pad_width=0
	local _text_width=0
	local _clean_text=""

	if [[ -n "${_raw_text}" ]]; then
		_zsh_strip_ansi "${_raw_text}"
		_clean_text="${REPLY}"
		_clean_text="${_clean_text//\%[FK]\{[^\}]#\}/}"
		_clean_text="${_clean_text//\%[fkBbSsUu]/}"
		_clean_text="${_clean_text//\%\%/%}"
		if [[ "${_clean_text}" == *[[:cntrl:]]* ]]; then
			_text_width=-1
		else
			_text_width=${(m)#_clean_text}
		fi
	fi

	case "${_kind}" in
		description)
			if (( _text_width > 0 && _text_width < _cols - 8 )); then
				_pad_width=$(( _cols - _text_width - 6 ))
				reply=("%F{blue}── %F{cyan}%d %F{blue}${(r:${_pad_width}::─:)_pad_fill}%f")
			elif (( _text_width > 0 && _cols >= 12 )); then
				reply=("%F{blue}── %F{cyan}%$(( _cols - 6 ))>..>%d%<<%f")
			else
				reply=("%F{blue}── %F{cyan}%d%f")
			fi
			;;
		message)
			if (( _text_width > 0 && _text_width < _cols - 8 )); then
				_pad_width=$(( _cols - _text_width - 6 ))
				reply=("%F{magenta}── %d %F{magenta}${(r:${_pad_width}::─:)_pad_fill}%f")
			elif (( _text_width > 0 && _cols >= 12 )); then
				reply=("%F{magenta}── %$(( _cols - 6 ))>..>%d%<<%f")
			else
				reply=("%F{magenta}── %d%f")
			fi
			;;
		warning)
			if (( _cols > 28 )); then
				_pad_width=$(( _cols - 26 ))
				reply=("%F{red}── sem correspondências ${(r:${_pad_width}::─:)_pad_fill}%f")
			elif (( _cols >= 25 )); then
				reply=("%F{red}── sem correspondências%f")
			else
				reply=("%F{red}── nenhum%f")
			fi
			;;
		correction)
			local _err_width=${(m)#_err_spec}
			(( _err_width < 1 )) && _err_width=1
			if (( _text_width > 0 && _text_width + _err_width < _cols - 18 )); then
				_pad_width=$(( _cols - _text_width - _err_width - 16 ))
				reply=("%F{yellow}── %d (erros: %e) ${(r:${_pad_width}::─:)_pad_fill}%f")
			elif (( _text_width >= 0 && 14 + _text_width + _err_width <= _cols - 2 )); then
				reply=("%F{yellow}── %d (erros: %e)%f")
			elif (( _text_width >= 0 && 3 + _text_width <= _cols - 2 )); then
				reply=("%F{yellow}── %d%f")
			else
				reply=("%F{yellow}──%f")
			fi
			;;
	esac
}

_zsh_expand_or_complete() {
	POSTDISPLAY=""
	(( ${#region_highlight} )) && region_highlight=(${region_highlight:#*memo=zsh-suggest})
	zle expand-or-complete
}
zle -N _zsh_expand_or_complete

_lazy_compinit() {
	bindkey '^I' _zsh_expand_or_complete
	autoload -Uz compinit
	if [ -s "${HOME}/.zcompdump" ]; then
		compinit -C -d "${HOME}/.zcompdump"
	else
		compinit -d "${HOME}/.zcompdump"
	fi
	if [ -f "${HOME}/.zcompdump" ] && { [ ! -f "${HOME}/.zcompdump.zwc" ] || [ "${HOME}/.zcompdump" -nt "${HOME}/.zcompdump.zwc" ]; }; then
		(zcompile "${HOME}/.zcompdump" 2> "/dev/null" &)
	fi
	zle _zsh_expand_or_complete
}
zle -N _lazy_compinit
bindkey '^I' _lazy_compinit

zstyle ':completion:*' completer _extensions _complete _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3)) numeric)'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' menu select=1
zstyle -e ':completion:*' select-prompt \
	'local _cols=$(( COLUMNS > 0 ? COLUMNS : 80 )); if (( _cols >= 28 )); then reply=("%S[ %p | %l ]%s"); elif (( _cols >= 12 )); then reply=("%S[ %p ]%s"); else reply=(""); fi'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' list-packed true
zstyle ':completion:*' list-separator ' ── '

zstyle ':completion:*:*:-command-:*' group-order aliases functions builtins commands

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle -e ':completion:*:descriptions' format '_zsh_comp_format description "${3:-}"'
zstyle -e ':completion:*:messages' format '_zsh_comp_format message "${1:-}"'
zstyle -e ':completion:*:warnings' format '_zsh_comp_format warning'
zstyle -e ':completion:*:corrections' format '_zsh_comp_format correction "${3:-}" "${_comp_correct:-${4#e:}}"'

zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh"

bindkey -M menuselect '^I' menu-complete 2> "/dev/null" || true
bindkey -M menuselect '^[[Z' reverse-menu-complete 2> "/dev/null" || true
bindkey -M menuselect '^?' undo 2> "/dev/null" || true

### --------------------------------
### NATIVE HISTORY AUTOSUGGESTIONS
### --------------------------------
if [ -t 0 ] && [ -t 1 ]; then
	_zsh_suggest_fetch() {
		POSTDISPLAY=""
		(( ${#region_highlight} )) && region_highlight=(${region_highlight:#*memo=zsh-suggest})
		[[ -z "${BUFFER}" ]] && return 0
		[[ -n "${PREBUFFER:-}" ]] && return 0
		[[ "${BUFFER}" == *$'\n'* ]] && return 0
		[[ "${CONTEXT:-}" == cont ]] && return 0
		local _cols=$(( COLUMNS > 0 ? COLUMNS : 80 ))
		(( _cols < 24 )) && return 0
		local -a _hits
		_hits=(${(k)history[(R)${(b)BUFFER}*]})
		if (( ${#_hits} > 0 )); then
			setopt LOCAL_OPTIONS EXTENDED_GLOB MULTIBYTE
			local _last_id="${_hits[1]}"
			local _candidate="${history[${_last_id}]}"
			_candidate="${_candidate%%$'\n'*}"
			[[ "${_candidate}" == *[[:cntrl:]]* ]] && return 0
			[[ "${_candidate}" == "${BUFFER}"* ]] || return 0
			(( ${#_candidate} <= ${#BUFFER} )) && return 0
			local _prompt_raw="${PROMPT:-${PS1:-}}"
			local _prompt_last="${_prompt_raw##*$'\n'}"
			if [[ -o promptsubst ]]; then
				if [[ "${_prompt_last}" == *'$('* || "${_prompt_last}" == *'`'* ]]; then
					return 0
				fi
				_prompt_last="${(e)_prompt_last}"
			fi
			_prompt_last="${(%)_prompt_last}"
			_zsh_strip_ansi "${_prompt_last}"
			local _prompt_visible="${REPLY}"
			[[ "${_prompt_visible}" == *[[:cntrl:]]* ]] && return 0
			local _prompt_width=${(m)#_prompt_visible}
			local _prompt_col=$(( _prompt_width % _cols ))
			local _cand_width=${(m)#_candidate}
			(( _prompt_col + _cand_width >= _cols - 1 )) && return 0
			(( _cand_width > 80 )) && return 0
			local _suggest_highlight="fg=blue"
			(( ${terminfo[colors]:-8} >= 16 )) && _suggest_highlight="fg=8"
			POSTDISPLAY="${_candidate[${#BUFFER}+1,-1]}"
			region_highlight=("${#BUFFER} $((${#BUFFER} + ${#POSTDISPLAY})) ${_suggest_highlight} memo=zsh-suggest")
		fi
		return 0
	}

	_zsh_suggest_accept() {
		if [ -n "${POSTDISPLAY}" ] && [ "${CURSOR}" -eq "${#BUFFER}" ]; then
			BUFFER="${BUFFER}${POSTDISPLAY}"
			CURSOR="${#BUFFER}"
			POSTDISPLAY=""
			(( ${#region_highlight} )) && region_highlight=(${region_highlight:#*memo=zsh-suggest})
		else
			zle .forward-char
		fi
	}

	_zsh_suggest_accept_end() {
		if [ -n "${POSTDISPLAY}" ]; then
			BUFFER="${BUFFER}${POSTDISPLAY}"
			CURSOR="${#BUFFER}"
			POSTDISPLAY=""
			(( ${#region_highlight} )) && region_highlight=(${region_highlight:#*memo=zsh-suggest})
		else
			zle .end-of-line
		fi
	}

	zle -N zle-line-pre-redraw _zsh_suggest_fetch
	zle -N _zsh_suggest_accept
	zle -N _zsh_suggest_accept_end

	bindkey '^[[C' _zsh_suggest_accept 2> "/dev/null" || true
	bindkey '^[OC' _zsh_suggest_accept 2> "/dev/null" || true
	bindkey '^E' _zsh_suggest_accept_end 2> "/dev/null" || true
	bindkey '^[[F' _zsh_suggest_accept_end 2> "/dev/null" || true
	bindkey '^[OF' _zsh_suggest_accept_end 2> "/dev/null" || true
fi
