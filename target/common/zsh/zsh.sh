### ================================
### ZSH CONFIGURATION
### ================================

### --------------------------------
### Compatibility & Parsing
### --------------------------------
setopt SH_WORD_SPLIT
unset IFS

### --------------------------------
### History
### --------------------------------
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${HOME}/.zsh_history"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

### --------------------------------
### Interaction & Safety
### --------------------------------
unsetopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt RM_STAR_WAIT
setopt NO_CLOBBER
unsetopt BEEP

### --------------------------------
### Keybindings & Line Editing
### --------------------------------
bindkey -e

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
### Navigation
### --------------------------------
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt COMPLETE_IN_WORD

### --------------------------------
### Globbing
### --------------------------------
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NULL_GLOB
setopt KSH_GLOB

### --------------------------------
### Completion Engine
### --------------------------------
zmodload -i zsh/complist 2> "/dev/null" || true

_lazy_compinit() {
	bindkey '^I' expand-or-complete
	autoload -Uz compinit
	if [ -f "${HOME}/.zcompdump" ]; then
		compinit -C -d "${HOME}/.zcompdump"
	else
		compinit -d "${HOME}/.zcompdump"
	fi
	[ -f "${HOME}/.zcompdump.zwc" ] || (zcompile "${HOME}/.zcompdump" 2> "/dev/null" &)
	zle expand-or-complete
}
zle -N _lazy_compinit
bindkey '^I' _lazy_compinit

zstyle ':completion:*' completer _extensions _complete _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3)) numeric)'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' menu select=1
zstyle ':completion:*' select-prompt '%S[ %p | %l ]%s'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' list-packed true
zstyle ':completion:*' list-separator ' ── '

zstyle ':completion:*:*:-command-:*' group-order aliases functions builtins commands

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle -e ':completion:*:descriptions' format \
  'local len=${#3}; (( len == 0 )) && len=15; reply=("%F{blue}── %F{cyan}%d %F{blue}${(r:$((COLUMNS - len - 7))::─:)%f}")'
zstyle -e ':completion:*:messages' format \
  'local len=${#3}; (( len == 0 )) && len=15; reply=("%F{magenta}── %d %F{magenta}${(r:$((COLUMNS - len - 7))::─:)%f}")'
zstyle -e ':completion:*:warnings' format \
  'reply=("%F{red}── sem correspondências ${(r:$((COLUMNS - 25))::─:)%f}")'
zstyle ':completion:*:corrections' format '%F{yellow}── %d (erros: %e) %f'

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
### Native History Autosuggestions
### --------------------------------
if [ -t 0 ] && [ -t 1 ]; then
	_zsh_suggest_fetch() {
		POSTDISPLAY=""
		[ -z "${BUFFER}" ] && return 0
		local -a _hits
		_hits=(${(k)history[(R)${(b)BUFFER}*]})
		if [ "${#_hits}" -gt 0 ]; then
			local _last_id="${_hits[1]}"
			local _candidate="${history[${_last_id}]}"
			_candidate="${_candidate%%$'\n'*}"
			[ "${#_candidate}" -gt 80 ] && return 0
			if [ "${#_candidate}" -gt "${#BUFFER}" ]; then
				POSTDISPLAY="${_candidate[${#BUFFER}+1,-1]}"
				region_highlight=("${#BUFFER} $((${#BUFFER} + ${#POSTDISPLAY})) fg=8")
			fi
		fi
		return 0
	}

	_zsh_suggest_accept() {
		if [ -n "${POSTDISPLAY}" ] && [ "${CURSOR}" -eq "${#BUFFER}" ]; then
			BUFFER="${BUFFER}${POSTDISPLAY}"
			CURSOR="${#BUFFER}"
			POSTDISPLAY=""
		else
			zle .forward-char
		fi
	}

	_zsh_suggest_accept_end() {
		if [ -n "${POSTDISPLAY}" ]; then
			BUFFER="${BUFFER}${POSTDISPLAY}"
			CURSOR="${#BUFFER}"
			POSTDISPLAY=""
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
