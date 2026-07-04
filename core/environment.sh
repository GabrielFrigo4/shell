### ================================
### CORE ENVIRONMENT
### ================================

export MICRO_TRUECOLOR=1

### --------------------------------
### Auto-Correct SHELL
### --------------------------------
. "${SHELL_REPO_DIR}/core/detect.sh"
export SHELL="$(command -v "$(detect_shell)" 2> "/dev/null")"
