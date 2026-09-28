# 🍏 macOS (Darwin) Shell — Homebrew & Transição para Zsh

No ecossistema macOS (Darwin), os alvos interativos suportados são **estritamente `zsh` e `bash`** (`target/macos/zsh` e `target/macos/bash`).

---

## 🚫 Congelamento do Bash 3.2 & Descarte do `/bin/sh`

1. **GPLv3 Embargo:** A Apple congelou o Bash nativo na versão 3.2.57 (2007).
2. **Zsh como Padrão:** Desde o macOS Catalina (10.15), `/bin/zsh` é o shell padrão nativo.
3. **Descarte do `/bin/sh` Interativo:** No Darwin, `/bin/sh` é o Bash 3.2 em modo POSIX, que rejeita funções em `kebab-case`. Portanto, não há alvo interativo `sh`.

---

## 🍺 Prefixos do Homebrew: Apple Silicon vs Intel

| Arquitetura               | Prefixo Base    | Binários de Usuário | Binários de Admin    |
| :------------------------ | :-------------- | :------------------ | :------------------- |
| **Apple Silicon (ARM64)** | `/opt/homebrew` | `/opt/homebrew/bin` | `/opt/homebrew/sbin` |
| **Intel (x86_64)**        | `/usr/local`    | `/usr/local/bin`    | `/usr/local/sbin`    |

Injeção no topo do `PATH` via `path-front`:

```sh
[ -d "/opt/homebrew/bin" ] && path-front "/opt/homebrew/bin"
[ -d "/opt/homebrew/sbin" ] && path-front "/opt/homebrew/sbin"
```

---

## ⚠️ Peculiaridades do BSD Userland vs GNU

- **`sed -i`:** Exige extensão vazia para editar in-place sem backup: `sed -i '' 's/old/new/g' file` (no Linux GNU, aspas vazias causam erro de sintaxe).
- **`stat`:** macOS usa `stat -f %z file`; Linux usa `stat -c %s file`.
- **`readlink -f`:** Inexistente por padrão; use `realpath` ou `cd -P`.
- **Dark Mode:** Consulta nativa via `defaults read -g AppleInterfaceStyle` (`Dark`).
