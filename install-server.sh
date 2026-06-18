#!/usr/bin/env sh

### ================================
### Shell Install Script (Server)
### ================================

exec "$(cd "$(dirname "${0}")" && pwd)/install.sh" --context server "$@"
