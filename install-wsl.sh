#!/usr/bin/env sh

### ================================
### Shell Install Script (WSL)
### ================================

exec "$(cd "$(dirname "${0}")" && pwd)/install.sh" --context wsl "$@"
