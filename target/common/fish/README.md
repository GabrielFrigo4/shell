# 🐟 Fish Shell — Runtime Comum

> Configuração modular do Fish Shell para o ecossistema Universal Shell.

---

## 🧭 Arquitetura Modular

O runtime do Fish foi decomposto em módulos de responsabilidade única:

| Arquivo            | Função                                                             |
| :----------------- | :----------------------------------------------------------------- |
| **`config.fish`**  | Ponto de entrada, bootstrapping de PATH e orquestração de módulos  |
| **`ui.fish`**      | Biblioteca semântica de interface terminal (`_ui_*`)               |
| **`prompt.fish`**  | Renderização visual de alta densidade (`fish_prompt`) com git info |
| **`aliases.fish`** | Funções universais de atualização (`update-*`) e atalhos (`up*`)   |

---

## 🚀 Instalação e Deploy

O deploy do runtime no sistema hospedeiro vincula `config.fish` em `~/.config/fish/config.fish`:

```sh
sh install.sh -s fish
```
