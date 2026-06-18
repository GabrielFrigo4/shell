### ================================
### SHELL BEHAVIOR
### ================================

### --------------------------------
### Line Editing
### --------------------------------
set -o emacs

### --------------------------------
### History
### --------------------------------
export HISTSIZE=10000
export HISTFILE="${HOME}/.sh_history"

### --------------------------------
### Standard Aliases
### --------------------------------
alias h='fc -l'
alias j='jobs'
alias m="${PAGER:-less}"
alias g='egrep -i'
alias history='fc -l'

### --------------------------------
### Navigation
### --------------------------------
alias ~='cd ~'
alias /='cd /'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

### --------------------------------
### Directory Listing
### --------------------------------
alias ls='ls -G'
alias ll='ls -laFoG'
alias l='ls -lG'

### --------------------------------
### Key Bindings
### --------------------------------
bind ^[[A ed-search-prev-history
bind ^[[B ed-search-next-history
bind "\e[1;5C" em-next-word
bind "\e[1;5D" ed-prev-word
bind ^[[5~ ed-move-to-beg
bind ^[[6~ ed-move-to-end
bind ^[[1~ ed-move-to-beg
bind ^[[4~ ed-move-to-end
bind ^[[3~ ed-delete-next-char
