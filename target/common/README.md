# ⚙️ target/common/ — Configurações Comuns de Shell

Esta pasta contém as configurações de comportamento, histórico, navegação, interação, segurança e autocompletamento específicas de cada família de shell (`bash`, `zsh`, `sh`), independentemente do sistema operacional hospedeiro.

---

## 📁 Arquivos de Configuração

- **`bash.sh`**:
    - Gerenciamento de histórico (`HISTCONTROL`, `HISTSIZE`, `shopt -s histappend`).
    - Opções de interação & segurança (`checkwinsize`, `set -o noclobber`).
    - Navegação amigável (`autocd`, `cdspell`, `dirspell`).
    - Integração com `bash_completion` nativo do sistema operacional.
- **`zsh.sh`**:
    - Gerenciamento de histórico compartilhado e deduplicação (`SHARE_HISTORY`, `HIST_IGNORE_DUPS`, etc.).
    - Opções de navegação avançada (`AUTO_CD`, `AUTO_PUSHD`, `COMPLETE_IN_WORD`).
    - Opções de interação & segurança (`NO_CLOBBER`, `CORRECT`, `RM_STAR_WAIT`, `unsetopt BEEP`).
    - Expansão e globbing (`EXTENDED_GLOB`, `GLOB_DOTS`).
    - Engine de completamento compilado (`compinit -C` com compilação em background `.zcompdump.zwc`).
- **`sh.sh`**:
    - Configurações universais para shells estritamente POSIX (FreeBSD `/bin/sh`, NetBSD `/bin/sh`, Dash).
    - Gerenciamento de histórico unificado (`HISTFILE="${HOME}/.sh_history"`, `HISTSIZE=10000`).
    - Opção de segurança e rigor de escrita (`set -C`) e line editing (`set -o emacs`).
    - Aliases padrão POSIX (`h`, `j`, `m`, `history`).
