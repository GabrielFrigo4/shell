# 🪟 Windows (MSYS2 & WSL) Shell — Performance & Caminhos

No ecossistema Windows (MSYS2 e WSL), os alvos interativos suportados são **estritamente `bash` e `zsh`** (`target/windows/bash` e `target/windows/zsh`). Não existe alvo `target/windows/sh`.

---

## ⚡ A Penalidade de Fork no Windows NT

O Windows NT não possui a chamada de sistema `fork()` nativa. A DLL do MSYS2 emula `fork()` via `CreateProcess()` e replicação manual de páginas de memória:

- Cada subshell `$(comando)` custa entre **20ms e 60ms** (contra < 0.5ms no Linux/FreeBSD).
- **Regra de Ouro:** **Zero subshells no boot interativo do shell**. Use manipulação de parâmetros em memória (`${var##*/}`, `${var%/*}`) para evitar invocar `basename`, `dirname` ou `cut`.

---

## 📂 Tradução de Caminhos & Utilitário `cygpath`

1. **Unidades de Disco:**
    - MSYS2: `C:\Users` ➔ `/c/Users`.
    - WSL: `C:\Users` ➔ `/mnt/c/Users`.
2. **Conversão com `cygpath`:**
    ```sh
    command -v cygpath > "/dev/null" 2>&1 && win_path="$(cygpath -w "$posix_path")"
    ```
3. **Sufixo `.exe`:**
   Tratamento de nome do shell:
    ```sh
    _sh_name="${0##*/}"
    _sh_name="${_sh_name#-}"
    _sh_name="${_sh_name%.exe}"
    ```

---

## 🚫 Higiene de Quebras de Linha: Perigo do CRLF (`\r\n`)

- Scripts de shell executados no Bash/Zsh do MSYS2 com finais de linha CRLF falham com erros misteriosos (`\r: command not found`).
- **Regra:** Todos os arquivos `.sh` e `.md` no repositório DEVEM ter quebras de linha estritamente em formato UNIX (`LF`).

---

## 🖥️ Terminal Moderno: ConPTY

O Windows Terminal utiliza o subsistema ConPTY, suportando sequências ANSI completas, 24-bit TrueColor e Nerd Fonts v3.
