#!/usr/bin/env sh

### ================================
### Shell Install Script (Container)
### ================================

exec "$(cd "$(dirname "${0}")" && pwd)/install.sh" --context container "$@"
