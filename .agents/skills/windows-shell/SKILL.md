---
name: windows-shell
description: >-
  Deep technical reference and runbook for Windows shell environments via MSYS2 (UCRT64, MINGW64, CLANG64) and WSL.
  Covers process fork latency, path translation (cygpath, /c/ vs C:\), CRLF vs LF traps, and Windows Terminal ConPTY.
  Use when maintaining, developing, or auditing Windows/MSYS2-specific shell behaviors.
---

# Windows (MSYS2 & WSL) Shell — Architecture, Paths & Runtime Runbook

Este documento consolida o conhecimento canônico, particularidades da camada POSIX sobre NT e padrões de engenharia para o ecossistema **Windows** no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. MSYS2 vs WSL: Dois Modelos de Execução Distintos

1. **MSYS2 (Runtime Nativo via Camada de Emulação POSIX):**
   - Roda executáveis Windows nativos compilados com GCC/Clang (`ucrt64`, `mingw64`, `clang64`).
   - A camada `msys-2.0.dll` (baseada em Cygwin) fornece APIs POSIX (`fork`, `exec`, pipes) sobre o kernel Windows NT.
   - **Variável de Ambiente Chave:** `$MSYSTEM` (`UCRT64`, `MINGW64`, `MSYS`).
2. **WSL (Windows Subsystem for Linux):**
   - Executa um kernel Linux autêntico dentro de uma micro-VM Hyper-V.
   - Trata-se como ambiente Linux padrão, mas com pontes de interoperabilidade (`/mnt/c/`, `.exe` executáveis a partir do Linux).

---

## 2. A Penalidade de Fork no Windows NT

No Windows NT, o conceito de `fork()` (duplicação de processo preservando espaço de memória) **não existe nativamente**:

- A DLL do MSYS2 emula `fork()` através de `CreateProcess()`, cópia de páginas de memória e reconstrução de ponteiros.
- **Custo Temporal:** Um subshell `$(comando)` no MSYS2 leva entre **20ms a 60ms** (enquanto no Linux/FreeBSD leva menos de 0.5ms).
- **Regra de Ouro de Otimização:** **Zero subshells em loops ou no hot-path de inicialização do shell**.
  - Prefira manipulação de strings em memória via substituição de parâmetros POSIX (`${var##*/}`, `${var%/*}`) em vez de chamar `cut`, `awk` ou `basename`.

---

## 3. Tradução de Caminhos e Armadilhas de Barra

1. **Caminhos de Unidade:**
   - No MSYS2, discos são montados na raiz: `C:\Users\Nome` ➔ `/c/Users/Nome`.
   - No WSL, discos são montados sob `/mnt`: `C:\Users\Nome` ➔ `/mnt/c/Users/Nome`.
2. **Utilitário `cygpath`:**
   - Para converter caminhos para ferramentas nativas do Windows (`code.exe`, `explorer.exe`):
     ```sh
     command -v cygpath > "/dev/null" 2>&1 && win_path="$(cygpath -w "${posix_path}")"
     ```
3. **Sufixo `.exe`:**
   - Na checagem com `command -v`, binários compilados para Windows possuem extensão `.exe`.
   - Ao manipular `$0` ou nome do shell:
     ```sh
     _sh_name="${0##*/}"
     _sh_name="${_sh_name#-}"
     _sh_name="${_sh_name%.exe}"
     ```

---

## 4. Quebras de Linha: O Perigo do CRLF (`\r\n`)

- O Git no Windows frequentemente converte quebras de linha para `CRLF` se `core.autocrlf` estiver ativado.
- Se um script `.sh` for salvo com `\r\n`, o Bash/Zsh tentará executar linhas terminando em `\r`, gerando erros misteriosos como `\r: command not found` ou corrompendo a montagem do prompt.
- **Regra:** Todos os arquivos `.sh` e `.md` no repositório DEVEM ter quebras de linha estritamente em formato UNIX (`LF`).

---

## 5. Emulação de Terminal e ConPTY

- No Windows 10/11, o **Windows Terminal** utiliza a arquitetura moderna ConPTY, suportando sequências ANSI completas, 24-bit TrueColor e Nerd Fonts v3.
- Em consoles legados (`conhost.exe` antigo), o suporte a ANSI é degradado. O instalador configura o ambiente preferencialmente dentro do Windows Terminal ou Mintty.
