# 🐚 POSIX sh — Runtime Comum

> Configuração canônica comum (`0644`, carregada via `source`) para o `sh` interativo suportado (FreeBSD `/bin/sh`).

---

## 📁 Arquivos

- **`sh.sh`**: Configuração universal de line editing (`set -o emacs`), histórico (`HISTFILE="${HOME}/.sh_history"`, `HISTSIZE=50000`) e salvaguarda contra sobrescrita acidental (`set -C`). Shells não interativos como `dash` e NetBSD `/bin/sh` (`ash`) são rejeitados e promovidos/roteados para `zsh`/`bash`.
