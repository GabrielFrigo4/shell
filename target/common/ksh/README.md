# 🐚 Ksh — Runtime Comum

> Configurações comuns (`0644`, carregadas via `source`) do Korn Shell (`ksh`/`pdksh`/`oksh`) independentes de SO.

---

## 📁 Arquivos

- **`ksh.sh`**: Configuração de histórico persistente (`HISTFILE="${HOME}/.ksh_history"`, `HISTSIZE=50000`), modo de edição Emacs (`set -o emacs`), proteção `set -C` e compatibilidade com OpenBSD `/bin/ksh` (em conjunto com `target/openbsd/ksh/` e `theme/ksh.sh`).
