# ⚙️ target/common/ — Configurações Comuns de Shell

> Configurações de comportamento, histórico, navegação, interação, segurança e autocompletamento comuns a cada família de interpretador, organizadas em diretórios soberanos.

---

## 📁 Catálogo de Shells Comuns

| Diretório   | Shell                       | Domínio Principal                                                                         |
| :---------- | :-------------------------- | :---------------------------------------------------------------------------------------- |
| **`sh/`**   | POSIX `/bin/sh`             | Configuração estrita POSIX, edição Emacs, histórico em `~/.sh_history`, `set -C`          |
| **`bash/`** | GNU Bash (`bash`)           | Histórico compartilhado (`histappend`), `checkwinsize`, navegação (`autocd`), completions |
| **`zsh/`**  | Z Shell (`zsh`)             | `SHARE_HISTORY`, navegação avançada (`AUTO_CD`), segurança e cache `.zcompdump.zwc`       |
| **`fish/`** | Fish Shell (`fish`)         | Arquitetura modular (`config.fish`, `prompt.fish`, `ui.fish`, `aliases.fish`)             |
| **`ksh/`**  | Korn Shell (`ksh` / `oksh`) | Histórico, edição de linha e compatibilidade BSD                                          |
