# ⚙️ target/common/ — Configurações Comuns de Shell

> Configurações de comportamento, histórico, navegação, interação, segurança e autocompletamento comuns a cada família de interpretador, organizadas em diretórios soberanos.

---

## 📁 Catálogo de Shells Comuns

| Diretório   | Shell                       | Domínio Principal                                                                                     |
| :---------- | :-------------------------- | :---------------------------------------------------------------------------------------------------- |
| **`sh/`**   | POSIX `sh` (`0644`)         | Configuração estrita POSIX (FreeBSD `sh`), edição Emacs, histórico `~/.sh_history`, `set -C`          |
| **`bash/`** | GNU Bash (`bash`, `0644`)   | Histórico compartilhado (`histappend`), `checkwinsize`, navegação (`autocd`), completions             |
| **`zsh/`**  | Z Shell (`zsh`, `0644`)     | `SHARE_HISTORY`, navegação avançada (`AUTO_CD`), segurança e cache `.zcompdump.zwc`                   |
| **`fish/`** | Fish Shell (`fish`, `0644`) | Arquitetura modular (`config.fish`, `prompt.fish`, `ui.fish`, `aliases.fish`) + `PYTHONPYCACHEPREFIX` |
| **`ksh/`**  | Korn Shell (`ksh`, `0644`)  | Edição `set -o emacs`, histórico `~/.ksh_history`, `set -C` e integração OpenBSD `pdksh`/`oksh`       |

Inclui também **`session.sh`** (`0644`), responsável pela propagação comum de tema gráfico (`GTK_THEME`, `QT_STYLE_OVERRIDE`, `QT_QPA_PLATFORMTHEME`, `SAL_USE_VCLPLUGIN`) e export de `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"`.
