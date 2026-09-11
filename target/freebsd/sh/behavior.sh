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
alias history='fc -l'

### --------------------------------
### Key Bindings
### --------------------------------
bind ^[[A ed-search-prev-history
bind ^[OA ed-search-prev-history
bind ^[[B ed-search-next-history
bind ^[OB ed-search-next-history
bind ^[[H ed-move-to-beg
bind ^[OH ed-move-to-beg
bind ^[[1~ ed-move-to-beg
bind ^[[7~ ed-move-to-beg
bind ^[[F ed-move-to-end
bind ^[OF ed-move-to-end
bind ^[[4~ ed-move-to-end
bind ^[[8~ ed-move-to-end
bind ^[[3~ ed-delete-next-char
bind "\e[1;5C" em-next-word
bind "\e[1;5D" ed-prev-word
