### ================================
### WSL CONTEXT (LINUX)
### ================================

### --------------------------------
### Windows Integration
### --------------------------------
command -v explorer.exe > "/dev/null" 2>&1 && alias explorer="explorer.exe"
command -v powershell.exe > "/dev/null" 2>&1 && alias powershell="powershell.exe"
command -v pwsh.exe > "/dev/null" 2>&1 && alias pwsh="pwsh.exe"
command -v cmd.exe > "/dev/null" 2>&1 && alias cmd="cmd.exe"
command -v win32yank.exe > "/dev/null" 2>&1 && alias clip="win32yank.exe"
