### ================================
### CORE ENVIRONMENT
### ================================

export MICRO_TRUECOLOR=1

### --------------------------------
### Auto-Correct SHELL
### --------------------------------
export SHELL="$(command -v "$(detect_shell)" 2> "/dev/null")"
