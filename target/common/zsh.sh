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
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="${HOME}/.zsh_history"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
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

# History search by typed prefix (Up / Down)
bindkey '^[[A' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[OA' up-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[[B' down-line-or-beginning-search 2> "/dev/null" || true
bindkey '^[OB' down-line-or-beginning-search 2> "/dev/null" || true
[ -n "${terminfo[kcuu1]:-}" ] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search 2> "/dev/null" || true
[ -n "${terminfo[kcud1]:-}" ] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search 2> "/dev/null" || true

# Home key
bindkey '^[[H' beginning-of-line 2> "/dev/null" || true
bindkey '^[OH' beginning-of-line 2> "/dev/null" || true
bindkey '^[[1~' beginning-of-line 2> "/dev/null" || true
bindkey '^[[7~' beginning-of-line 2> "/dev/null" || true
[ -n "${terminfo[khome]:-}" ] && bindkey "${terminfo[khome]}" beginning-of-line 2> "/dev/null" || true

# End key
bindkey '^[[F' end-of-line 2> "/dev/null" || true
bindkey '^[OF' end-of-line 2> "/dev/null" || true
bindkey '^[[4~' end-of-line 2> "/dev/null" || true
bindkey '^[[8~' end-of-line 2> "/dev/null" || true
[ -n "${terminfo[kend]:-}" ] && bindkey "${terminfo[kend]}" end-of-line 2> "/dev/null" || true

# Delete key
bindkey '^[[3~' delete-char 2> "/dev/null" || true
[ -n "${terminfo[kdch1]:-}" ] && bindkey "${terminfo[kdch1]}" delete-char 2> "/dev/null" || true

# Backspace
bindkey '^?' backward-delete-char 2> "/dev/null" || true
bindkey '^H' backward-delete-char 2> "/dev/null" || true

# Word navigation (Ctrl+Left / Ctrl+Right)
bindkey '^[[1;5C' forward-word 2> "/dev/null" || true
bindkey '^[[1;5D' backward-word 2> "/dev/null" || true
bindkey '^[[5C' forward-word 2> "/dev/null" || true
bindkey '^[[5D' backward-word 2> "/dev/null" || true
bindkey '^[^[[C' forward-word 2> "/dev/null" || true
bindkey '^[^[[D' backward-word 2> "/dev/null" || true

# Word deletion (Ctrl+Delete)
bindkey '^[[3;5~' kill-word 2> "/dev/null" || true

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
autoload -Uz compinit
if [ -f "${HOME}/.zcompdump" ]; then
    compinit -C -d "${HOME}/.zcompdump"
else
    compinit -d "${HOME}/.zcompdump"
fi
[ -f "${HOME}/.zcompdump.zwc" ] || (zcompile "${HOME}/.zcompdump" 2> "/dev/null" &)
