---
name: posix-shell
description: >-
    Deep technical reference and runbook for pure POSIX Shell (/bin/sh) portability,
    Almquist shell (ash/dash/FreeBSD sh), strict standards (POSIX.1-2008/2017/2024),
    bashism elimination, buffer constraint handling, and zero-fork in-memory paradigms.
    Use when developing, refactoring, or auditing scripts for universal POSIX compatibility.
---

# POSIX Shell — Portability, Runtime & Engineering Runbook

Este runbook consolida os padrões canônicos, limitações de baixo nível, armadilhas de portabilidade e técnicas de engenharia para o desenvolvimento em **POSIX Shell estrito (`/bin/sh`)**, cobrindo o baseline canônico do FreeBSD `/bin/sh`, Dash (Debian/Ubuntu), BusyBox `ash` (Alpine/Embedded), NetBSD `sh`, OpenBSD `pdksh`/`sh` e POSIX mode no Bash (`bash --posix`).

---

## 1. O Papel do POSIX `/bin/sh` no Ecossistema

1. **Scripts e Bootstrapping (`library/`, `core/`, `install.sh`):**
    - Mínimo denominador comum de execução em qualquer ambiente UNIX, FreeBSD base e contêineres mínimos. Inicialização instantânea (< 5ms).
2. **Sessão Interativa (`target/`):**
    - Alvos nativos de sistema exclusivos: **FreeBSD** (`target/freebsd/sh`) e **OpenBSD** (`target/openbsd/ksh`).
    - Nos demais sistemas (Linux, macOS, Windows/MSYS2, NetBSD, illumos), sessões interativas suportam estritamente `bash` e `zsh`.
    - Para entender a razão de `kebab-case` funcionar no FreeBSD/OpenBSD e falhar em parsers rígidos (Dash/macOS sh), consulte [`references/kebab-case-parsers.md`](./references/kebab-case-parsers.md).

---

## 2. Bashismos Terminantemente Proibidos

Ao escrever scripts portáveis para `/bin/sh`, as seguintes construções de Bash/Zsh são estritamente vedadas:

| Bashismo Proibido           | Causa da Falha em `/bin/sh`                       | Equivalente Canônico POSIX                                             |
| :-------------------------- | :------------------------------------------------ | :--------------------------------------------------------------------- |
| `[[ $a == $b ]]`            | Erro de sintaxe (palavra reservada não suportada) | `[ "$a" = "$b" ]` ou `case "$a" in "$b") ;; *) ;; esac`                |
| `[ "$a" == "$b" ]`          | Operador `==` inexiste no `test` POSIX            | `[ "$a" = "$b" ]`                                                      |
| `&>` ou `>& file`           | Redirecionamento combinado inválido               | `> file 2>&1`                                                          |
| `function nome() {`         | Palavra reservada `function` inexiste             | `nome() {`                                                             |
| `arr=(a b c)` / `${arr[@]}` | Não há tipos de array indexados no POSIX          | Listas separadas por espaço, `IFS`, ou argumentos posicionais (`"$@"`) |
| `source file.sh`            | Comando builtin inexistente no padrão             | `. file.sh`                                                            |
| `${var//antigo/novo}`       | Expansão de substituição de string não-POSIX      | Sed, `awk`, ou manipulação de sufixo/prefixo (`${var#*pat}`)           |
| `${var:offset:length}`      | Expansão de substring por índice não-POSIX        | `${var%...}`, `${var#...}` ou loop com `${var%?}`                      |
| `<<< "texto"`               | Here-string inexistente no padrão                 | `echo "texto" \| ...` ou `cat <<- 'EOF'`                               |
| `<(cmd)` / `>(cmd)`         | Process substitution não suportada                | Pipes tradicionais ou arquivos temporários com `trap`                  |
| `echo -e` / `echo -E`       | Flags não portáveis                               | `printf '%s\n'` ou `echo -n $'\e...'`                                  |
| `type cmd` / `which cmd`    | `type` é opcional e `which` é externo instável    | `command -v cmd > "/dev/null" 2>&1`                                    |
| `select` / `let`            | Builtins exclusivos de shells avançados           | Loops `while`/`case` e aritmética `$(( ... ))`                         |

---

## 3. Manipulação Nativa de Strings (Zero Forks)

Para manter a latência de execução abaixo de 64ms (ULTRA < 32ms), manipulações de strings **NUNCA DEVEM USAR SUBSHELLS** (`cut`, `awk`, `sed`, `basename`, `dirname`, `expr`) quando houver alternativa nativa de Parameter Expansion:

```sh
# Extrair nome do arquivo (equivalente a basename)
_filename="${_path##*/}"

# Extrair diretório pai (equivalente a dirname)
_dirname="${_path%/*}"
[ "${_dirname}" = "${_path}" ] && _dirname="."

# Remover extensão de arquivo / extrair extensão
_base="${_filename%.*}"
_ext="${_filename##*.}"

# Fallback se variável estiver nula ou vazia
_user="${USER:-$(command id -un)}"

# Comprimento de string em caracteres
_len="${#_var}"
```

### Algoritmo de Truncagem Recursiva (`_trim_str`):

```sh
_trim_str() {
	_trimmed="$1"
	if [ "${#_trimmed}" -gt "$2" ]; then
		local _target=$(( $2 - 1 ))
		while [ "${#_trimmed}" -gt "${_target}" ]; do
			_trimmed="${_trimmed%?}"
		done
		_trimmed="${_trimmed}$3"
	fi
}
```

---

## 4. Aritmética Nativa POSIX (`$(( ... ))`)

Toda a aritmética de inteiros ocorre via `$(( ... ))`. Nunca invoque `expr` ou `bc`:

```sh
_soma=$(( a + b ))
_sub=$(( a - b ))
_mult=$(( a * b ))
_div=$(( a / b ))
_mod=$(( a % b ))
```

---

## 5. Programação Defensiva e Redirecionamentos

1. **Redirecionamentos com Aspas:** Destinos sempre protegidos por aspas: `command -v git > "/dev/null" 2>&1`.
2. **Operador `>|` (Clobber):** Força escrita atômica mesmo quando `set -C` (_noclobber_) estiver ativo.
3. **Heredocs com Descarte de TABs (`cat <<- 'EOF'`):** O hífen descarta caracteres TAB (`\t`) iniciais de linhas, mantendo alinhamento estético sem vazar espaços para a coluna zero.
4. **Proteção de Terminal:** `[ -t 1 ] && echo -n $'\e[0 q'` garante que escapes ANSI nunca poluam saídas redirecionadas.

---

## 6. Gestão de Argumentos e o Poder de `"$@"`

A lista de argumentos posicionais (`"$@"`) é a única estrutura de dados com garantias canônicas de preservação de espaços no `/bin/sh`:

```sh
for _arg in "$@"; do
	echo "Processando: ${_arg}"
done
```

---

## 7. Variáveis Locais em Funções

1. **Declare no topo da função:** `local _var1 _var2 _ret=0`.
2. **Nunca atribua comandos no comando `local` se precisar do exit code:**
    ```sh
    local _res
    _res="$(comando)"
    _status=$?
    ```

---

## 8. Limitações de Memória em Buffers (`PROMPTLEN`)

No FreeBSD `/bin/sh` e derivados da Almquist shell, o buffer estático de prompt varia de **128 bytes** (FreeBSD $\le 13$) a **192 bytes** (FreeBSD $14+$). Escapes ANSI ocupam apenas 1 byte em C (`\001`/`\033`), enquanto caracteres UTF-8 Nerd Fonts ocupam de 3 a 4 bytes.

- Para a análise completa de consumo e matriz auditada de custos em C (`_base_cost`, `_git_frame`), consulte [`references/promptlen-buffer-constraints.md`](./references/promptlen-buffer-constraints.md).

---

## 9. Impressões Digitais Nativas de Shells (Zero-Fork Detection)

| Interpretador              | Expressão Canônica (Zero Fork)                                       |
| :------------------------- | :------------------------------------------------------------------- |
| **Linux (Qualquer Shell)** | `[ -r "/proc/$$/comm" ] && read -r _name < "/proc/$$/comm"` (0.01ms) |
| **Zsh / Bash**             | `[ -n "${ZSH_VERSION:-}" ]` / `[ -n "${BASH_VERSION:-}" ]`           |
| **NetBSD `/bin/sh`**       | `[ -n "${NETBSD_SHELL:-}" ]`                                         |
| **PDKsh / OpenBSD / MKsh** | `[ -n "${KSH_VERSION:-}" ]`                                          |
| **KornShell 93 / Yash**    | `[ -n "${.sh.version:-}" ]` / `[ -n "${YASH_VERSION:-}" ]`           |
| **FreeBSD `/bin/sh`**      | `[ -z "${BASH_VERSION:-}" ] && builtin : 2> "/dev/null"`             |
| **Dash**                   | `case "${0##*/}" in dash\|*dash*)`                                   |
| **BusyBox `ash`**          | `case "${0##*/}" in busybox\|*busybox*)`                             |

- **Proibição de Cache Compartilhado em Disco:** Nunca grave a identidade do shell em arquivos como `cache.env`. Mantenha `_DETECTED_SHELL` em memória no processo corrente para evitar contaminação cruzada em shells aninhados.

---

## 10. Checklist de Qualidade para Scripts POSIX

- [ ] **Sintaxe validada:** `sh -n <arquivo>` sem erros.
- [ ] **Sem bashismos:** Sem arrays, `[[`, `==`, `source`, `&>`.
- [ ] **Redirecionamentos seguros:** Destinos cotados `> "/dev/null" 2>&1`.
- [ ] **Comentários narrativos eliminados:** Zero linhas óbvias comentando comandos.
- [ ] **Shebang canônico:** `#!/usr/bin/env sh`.
- [ ] **Tratamento de espaços:** Variáveis cotadas (`"${var}"`).
- [ ] **Permissões octais canônicas:** `chmod 0755` para executáveis, `chmod 0644` para bibliotecas.
- [ ] **Latência:** Startup < 64ms.

---

## 🔗 Links Oficiais de Referência & Obras Recomendadas

- **The Open Group (POSIX Standard):** <https://www.opengroup.org/> | Shell Command Language: <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html>
- **The FreeBSD Project:** <https://www.freebsd.org/> | Manual `sh(1)`: <https://man.freebsd.org/sh.1>
- **The OpenBSD Project:** <https://www.openbsd.org/> | Manual `ksh(1)`: <https://man.openbsd.org/ksh.1>
- **Literatura Técnica:**
    - _The UNIX Programming Environment_ (Brian W. Kernighan & Rob Pike, 1984, Prentice Hall).
    - _The Art of UNIX Programming_ (Eric S. Raymond, 2003, Addison-Wesley).
