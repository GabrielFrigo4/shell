# 🐚 POSIX Shell — Portabilidade Universal & Análise de Parsers

O `/bin/sh` estrito é o denominador comum de execução do repositório (`library/`, `core/`, `install.sh`). Ele garante inicialização instantânea (< 5ms) e funcionamento em qualquer ambiente UNIX.

---

## 🔍 Análise Comparativa de Parsers e `kebab-case`

A sintaxe de funções públicas em `kebab-case` (`path-front`, `open-editor`) é aceita ou rejeitada conforme o parser:

| Sistema / Shell        | Parser Interno                 | Suporta `kebab-case`? | Comportamento Observado                            |
| :--------------------- | :----------------------------- | :-------------------: | :------------------------------------------------- |
| **FreeBSD `/bin/sh`**  | `bin/sh/parser.c` (modificado) |        **Sim**        | Aceita hífens normalmente em declaração de funções |
| **OpenBSD `/bin/ksh`** | `bin/ksh/syn.c` (pdksh)        |        **Sim**        | Aceita hífens na BNF de identificadores            |
| **Debian `/bin/dash`** | `src/parser.c` (Dash estrito)  |        **Não**        | Falha imediata: `Syntax error: Bad function name`  |
| **Bash (`--posix`)**   | `legal_identifier()`           |        **Não**        | Rejeita hífens: `'path-front': not a valid ident`  |
| **NetBSD `/bin/sh`**   | `bin/sh/parser.c:goodname()`   |        **Não**        | Rejeita com `bad function name`                    |
| **illumos KSH93**      | AT&T KSH93 grammar             |        **Não**        | Rejeita com `invalid function name`                |

---

## 🚫 Eliminação Rigorosa de Bashismos

| Recurso Proibido | Equivalente POSIX Canônico                          |
| :--------------- | :-------------------------------------------------- |
| `[[ $a == $b ]]` | `[ "$a" = "$b" ]`                                   |
| `&> file`        | `> file 2>&1`                                       |
| `source file.sh` | `. ./file.sh`                                       |
| `arr=(a b c)`    | `set -- a b c` e iterar com `"$@"`                  |
| `<<< "texto"`    | `printf '%s\n' "texto" \| cmd` ou `cat <<- 'EOF'`   |
| `<(cmd)`         | Pipes nomeados ou arquivos temporários via `mktemp` |
| `which cmd`      | `command -v cmd > "/dev/null" 2>&1`                 |

---

## ⚡ Manipulação de Strings sem Forks (Zero Subshells)

Manipulações no hot path de boot utilizam expansão de parâmetros POSIX:

- Nome do arquivo: `_file="${path##*/}"`
- Diretório pai: `_dir="${path%/*}"`
- Extensão: `_ext="${file##*.}"`
- Tamanho: `_len="${#var}"`
- Truncamento progressivo: `_var="${_var%?}"` em loop `while` sem subshell.
