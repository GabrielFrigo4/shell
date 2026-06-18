#!/usr/bin/env sh

### ================================
### Shell Install Script (Desktop)
### ================================

exec "$(cd "$(dirname "${0}")" && pwd)/install.sh" --context desktop "$@"
