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
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt RM_STAR_WAIT
setopt NO_CLOBBER
unsetopt BEEP

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
