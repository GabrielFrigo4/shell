# 🐟 Fish Shell — Runtime Comum

> Configuração modular e ativa do Fish Shell para o ecossistema Universal Shell (`0644`).

---

## 🧭 Arquitetura Modular

O runtime do Fish foi decomposto em módulos de responsabilidade única:

| Arquivo            | Função                                                                                    |
| :----------------- | :---------------------------------------------------------------------------------------- |
| **`config.fish`**  | Entrypoint (`PATH`, `PYTHONPYCACHEPREFIX` em `$XDG_CACHE_HOME/pycache`, `SHELL_USERLAND`) |
| **`ui.fish`**      | Biblioteca semântica de interface terminal (`_ui_*`)                                      |
| **`prompt.fish`**  | Renderização visual de 3 linhas (`fish_prompt`) com `PROMPT_OS_COLOR` e alerta `root`     |
| **`aliases.fish`** | Funções universais de atualização (`update-*`) e atalhos (`up*`, `userland`, ferramentas) |

---

## 🚀 Instalação e Deploy

O deploy do runtime instala/vincula os módulos em `~/.config/fish/config.fish` e grava `SHELL_USERLAND` in-place via `install.sh`:

```sh
sh install.sh -s fish
sh install.sh -s fish -u gnu
```
