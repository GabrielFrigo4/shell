### ================================
### DESKTOP CONTEXT (FREEBSD)
### ================================

### --------------------------------
### Software
### --------------------------------
if command -v vscode > "/dev/null" 2>&1 && ! command -v code > "/dev/null" 2>&1; then
	alias code="vscode"
fi
