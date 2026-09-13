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

No ecossistema do **Quarteto de Produtividade**, o `/bin/sh` possui papéis distintos e bem delimitados:

1. **Scripts e Bootstrapping (`library/`, `core/`, `install.sh`):**
    - É o **mínimo denominador comum (LCD)** de execução.
    - Onipresente em qualquer ambiente UNIX, FreeBSD base, contêiner Alpine mínimo e instaladores.
    - Inicialização instantânea (< 5ms) com overhead residual mínimo de memória e CPU.
2. **Sessão Interativa (`target/`): Alvos Nativos de Sistema Exclusivos:**
    - No diretório `target/`, os shells nativos do sistema base possuem alvos exclusivos em suas respectivas plataformas:
        - **FreeBSD:** `target/freebsd/sh` (exclusivo para FreeBSD `/bin/sh`).
        - **OpenBSD:** `target/openbsd/ksh` (exclusivo para OpenBSD `/bin/ksh`).
    - Nos demais sistemas operacionais (Linux, macOS, Windows/MSYS2, NetBSD, illumos), as sessões interativas suportam estritamente `bash` e `zsh`.
    - Interpretadores `/bin/sh` estritamente não-interativos (Dash no Debian/Ubuntu, macOS Bash 3.2 em modo POSIX, NetBSD Almquist sh) são shells de sistema/boot e deliberadamente não são alvos interativos deste repositório.

---

## 1.1. A Anatomia do Parser de Identificadores: Por que `kebab-case` Falha em Sh Rígidos

A convenção pública deste repositório utiliza `kebab-case` para funções utilitárias (`path-front`, `mount-device`, `update-all`). O comportamento entre os diferentes interpretadores deriva da gramática formal:

| Interpretador                      | Comportamento com Hífen (`f-f()`) | Mecanismo Interno no Código C Upstream                                                          |
| :--------------------------------- | :-------------------------------- | :---------------------------------------------------------------------------------------------- |
| **FreeBSD `/bin/sh`**              | **Suportado com perfeição** ✅    | `bin/sh/parser.c`: a tokenização de nomes de função aceita `-` como extensão deliberada.        |
| **GNU Bash**                       | **Suportado** ✅                  | `parser.y`: nomes de função aceitam `-` exceto quando ativado o modo POSIX estrito.             |
| **Zsh**                            | **Suportado com perfeição** ✅    | Zsh trata nomes de funções com máxima flexibilidade por padrão.                                 |
| **OpenBSD `/bin/ksh` (pdksh)**     | **Suportado com perfeição** ✅    | `bin/ksh/syn.c`: parser aceita `-` em nomes de função; alvo interativo em `target/openbsd/ksh`. |
| **Dash (Debian/Ubuntu `/bin/sh`)** | **Falha fatal** ❌ (`exit 2`)     | `src/parser.c:goodname()`: rejeita `-` com `Syntax error: Bad function name`.                   |
| **macOS `/bin/sh`**                | **Falha fatal** ❌ (`exit 2`)     | Bash 3.2 invocado como `sh` liga `posixly_correct`; `legal_identifier()` rejeita `-`.           |
| **`bash --posix`**                 | **Falha fatal** ❌ (`exit 2`)     | Ativação de `posixly_correct = 1` no Bash força identificador legal POSIX (sem `-`).            |
| **NetBSD `/bin/sh`**               | **Falha fatal** ❌ (`exit 2`)     | `bin/sh/parser.c:goodname()`: valida estritamente `[a-zA-Z0-9_]`.                               |
| **illumos `/bin/sh` (ksh93)**      | **Falha fatal** ❌ (`exit 3`)     | Parser do AT&T ksh93 rejeita hífens com `invalid function name`.                                |

### Decisão de Engenharia:

Não renomeamos as funções públicas para acomodar shells de script não-interativos. Em vez disso, preservamos a clareza e elegância do `kebab-case` e declaramos formalmente os alvos suportados: **FreeBSD `/bin/sh`** e **OpenBSD `/bin/ksh`** como alvos nativos de sistema exclusivos, e **`bash`** e **`zsh`** universalmente. Em outros SOs, os usuários operam sob `bash` ou `zsh`.

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
| `echo -e` / `echo -E`       | Flags não portáveis (comportamento varia por OS)  | `printf '%s\n'` ou `echo -n $'\e...'` (conforme padrão local)          |
| `type cmd` / `which cmd`    | `type` é opcional e `which` é externo instável    | `command -v cmd > "/dev/null" 2>&1`                                    |
| `select` / `let`            | Builtins exclusivos de shells avançados           | Loops `while`/`case` e aritmética `$(( ... ))`                         |

---

## 3. Manipulação Nativa de Strings (Zero Forks)

Para manter a latência de execução abaixo do teto de 64ms (alvo binário $2^n$, ULTRA < 32ms), manipulações de strings **NUNCA DEVEM USAR SUBSHELLS** (`cut`, `awk`, `sed`, `basename`, `dirname`, `expr`) quando houver alternativa nativa de Parameter Expansion.

### 3.1. Expansões Canônicas POSIX

```sh
# Extrair nome do arquivo (equivalente a basename)
_filename="${_path##*/}"

# Extrair diretório pai (equivalente a dirname)
_dirname="${_path%/*}"
[ "${_dirname}" = "${_path}" ] && _dirname="."

# Remover extensão de arquivo
_base="${_filename%.*}"

# Extrair extensão
_ext="${_filename##*.}"

# Fallback se variável estiver nula ou vazia
_user="${USER:-$(command id -un)}"

# Comprimento de string em caracteres
_len="${#_var}"
```

### 3.2. Algoritmo de Truncagem Recursiva com Sufixo (`_trim_str`)

Quando for necessário podar uma string para caber em um orçamento físico (ex: buffer de prompt):

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

- Executa no processo corrente sem disparar subshells (`$(...)`).
- Utiliza `${_trimmed%?}` para remover o último caractere em $O(n)$ iterações na memória.
- Aplica sufixo elíptico canônico (`…` no PTY, `~` no TTY).

---

## 4. Aritmética Nativa POSIX (`$(( ... ))`)

Toda a aritmética de inteiros deve ocorrer via `$(( ... ))`. Nunca invoque `expr` ou `bc`:

```sh
# Operações básicas
_soma=$(( a + b ))
_sub=$(( a - b ))
_mult=$(( a * b ))
_div=$(( a / b ))
_mod=$(( a % b ))

# Divisão de orçamento de tela meio a meio
_half=$(( _budget / 2 ))
_max_branch=$(( _budget - _half ))

# Comparação e lógica em expressões condicionais
if [ $(( _pwd_len + _branch_len )) -le "${_budget}" ]; then
	_max_pwd="${_pwd_len}"
	_max_branch="${_branch_len}"
fi
```

---

## 5. Programação Defensiva e Redirecionamentos

### 5.1. Redirecionamentos com Aspas Obrigatórias

Sempre envolva destinos de redirecionamento em aspas duplas:

```sh
# Correto:
command -v git > "/dev/null" 2>&1
echo "data" >| "${_target_file}"
cat << 'EOF' > "/tmp/scratch.txt"

# Incorreto:
command -v git > /dev/null 2>&1
```

### 5.2. O Operador `>|` (_Clobber_)

Ao sobrescrever arquivos onde `set -C` (_noclobber_) possa estar ativado no ambiente do usuário, utilize `>|` para forçar a escrita atômica com intenção explícita.

### 5.3. Heredocs com Descarte de TABs (`cat <<- 'EOF'`)

Para manter blocos de texto alinhados com a indentação do código circundante sem vazar espaços para a coluna zero:

```sh
_generate_config() {
	cat <<- 'EOF' > "${_dest_file}"
		# Configuração Canônica
		set -e
		export PATH="/usr/local/bin:${PATH}"
	EOF
}
```

- O hífen em `<<-` descarta todos os caracteres TAB (`\t`) iniciais das linhas e do fechamento `EOF`.
- Aspas ao redor de `'EOF'` impedem interpolação acidental de `$`, `` ` `` e `\`.

### 5.4. Proteção de Terminal (`[ -t 1 ]`)

Sequências de controle ANSI nunca devem poluir saídas redirecionadas:

```sh
[ -t 1 ] && echo -n $'\e[0 q'
```

---

## 6. Gestão de Argumentos e o Poder de `"$@"`

Como o POSIX `/bin/sh` não possui arrays indexados, a lista de argumentos posicionais (`"$@"`) é a única estrutura de dados com garantias canônicas de preservação de espaços:

```sh
# Iterar sobre argumentos sem quebra de espaços:
for _arg in "$@"; do
	echo "Processando: ${_arg}"
done

# Manipular dinamicamente a lista de parâmetros:
set -- "$@" "novo_item"
set -- "--flag" "$@"

# Delegar para binário real:
open-editor() {
	if [ "$#" -eq 0 ]; then
		command editor .
	else
		command editor "$@"
	fi
}
```

---

## 7. Variáveis Locais em Funções

Embora `local` não faça parte do padrão formal POSIX Issue 7 (sendo adicionado como extensão no POSIX.1-2024 Issue 8), o builtin `local` é implementado em praticamente todos os interpretadores modernos (`dash`, FreeBSD `/bin/sh`, NetBSD `/bin/sh`, BusyBox `ash`, Bash, Zsh).

### Regras de Ouro para `local`:

1. **Declare no topo da função:**
    ```sh
    _minha_funcao() {
        local _var1 _var2 _ret=0
        # ...
    }
    ```
2. **Nunca atribua comandos no mesmo comando `local` se precisar checar o status de saída:**
    ```sh
    # Perigoso: o status de saída capturado é do builtin local, não do subshell!
    local _res="$(comando_falho)"
    echo "$?" # Imprime 0!

    # Canônico e seguro:
    local _res
    _res="$(comando_falho)"
    _status=$?
    ```

---

## 8. Limitações Físicas de Memória em Buffers (`PROMPTLEN`)

No FreeBSD `/bin/sh` e derivados da Almquist shell:

- **FreeBSD <= 13:** Buffer estático de **128 bytes** (`ps[128]`).
- **FreeBSD 14 e 15+:** Buffer estático de **192 bytes** (`ps[192]`).
- **Teto Físico de Memória:** O prompt formatado é truncado no kernel em `PROMPTLEN - 1`.

### 8.1. A Mecânica Interna do Parser C (`bin/sh/parser.c:getprompt()`)

A contagem de caracteres na string do shell (`wc -c`) **NÃO REFLETE** os bytes ocupados no buffer C:

1. **Conversão de Escapes ANSI:**
    - `\[` (2 caracteres no script) $\longrightarrow$ vira **1 byte** no buffer C (`\001`).
    - `\]` (2 caracteres no script) $\longrightarrow$ vira **1 byte** no buffer C (`\001`).
    - `\e` (2 caracteres no script) $\longrightarrow$ vira **1 byte** no buffer C (`\033` ESC).
    - _Consequência:_ Uma cor como `\[\e[95m\]` (9 caracteres) ocupa apenas **7 bytes reais em C**. Calcular custos via `wc -c` gera dezenas de "bytes fantasmas" que estrangulam o orçamento útil.
2. **Glifos Multi-byte UTF-8 (Nerd Fonts):**
    - Glifos de ícones (``, ``, ``, ``) ocupam **3 bytes** cada em UTF-8.
    - O ícone do Git (`󰊢`) ocupa **4 bytes**.
    - O caractere de reticências (`…`) ocupa **3 bytes**, enquanto o til (`~`) ocupa apenas **1 byte**. Sob restrição severa (128B), o sufixo de poda deve ser estritamente `~` (1B) para manter a equivalência 1 caractere = 1 byte.

### 8.2. Matriz Auditada de Custos Reais em C (`_base_cost` & `_git_frame`)

| Layout        | Teto Alvo | Custo Base C (`_base_cost`) | Moldura Git C (`_git_frame`) |   Indicador Dirty   | Margem (`_margin`) |
| :------------ | :-------: | :-------------------------: | :--------------------------: | :-----------------: | :----------------: |
| **TTY micro** |   128B    |           **55B**           |           **24B**            |      `*` (+1B)      |         2B         |
| **TTY pill**  |   192B    |           **90B**           |           **24B**            | `\[\e[93m\]*` (+8B) |         2B         |
| **PTY micro** |   128B    |           **76B**           |           **20B**            |      `*` (+1B)      |         2B         |
| **PTY pill**  |   192B    |          **118B**           |           **20B**            | `\[\e[93m\]*` (+8B) |         2B         |

---

## 9. Impressões Digitais Nativas de Shells (Zero-Fork Detection)

Para inicialização com latência mínima (< 64ms, ULTRA < 32ms), a identificação do interpretador em tempo de execução deve priorizar variáveis nativas e builtins em memória antes de recorrer a forks de processos externos (`ps`, `sed`, `awk`):

| Interpretador              | Expressão Canônica (Zero Fork)                                | Mecanismo Interno                                                                                                              |
| :------------------------- | :------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------- |
| **Linux (Qualquer Shell)** | `[ -r "/proc/$$/comm" ] && read -r _name < "/proc/$$/comm"`   | Leitura atômica via builtin `read` do nome exato do executável ou symlink no kernel Linux (0.01ms, zero subprocessos)          |
| **Zsh**                    | `[ -n "${ZSH_VERSION:-}" ]`                                   | Variável de sistema gerada no startup                                                                                          |
| **Bash**                   | `[ -n "${BASH_VERSION:-}" ]`                                  | Variável de sistema gerada no startup                                                                                          |
| **NetBSD `/bin/sh`**       | `[ -n "${NETBSD_SHELL:-}" ]`                                  | Variável unexportable / read-only nativa do NetBSD                                                                             |
| **PDKsh / OpenBSD / MKsh** | `[ -n "${KSH_VERSION:-}" ]`                                   | Variável de sistema nativa                                                                                                     |
| **KornShell 93**           | `[ -n "${.sh.version:-}" ]`                                   | Árvore de parâmetros especiais do AT&T ksh93                                                                                   |
| **Yash**                   | `[ -n "${YASH_VERSION:-}" ]`                                  | Variável de sistema nativa                                                                                                     |
| **FreeBSD `/bin/sh`**      | `[ -z "${BASH_VERSION:-}" ] && builtin : 2> "/dev/null"`      | O comando `builtin` é exclusivo do `/bin/sh` do FreeBSD entre os shells POSIX mínimos (Dash e NetBSD retornam `127 not found`) |
| **Dash**                   | `case "${0##*/}" in dash\|*dash*)` ou ausência de `builtin :` | Parser estrito POSIX (rejeita hífens e builtin)                                                                                |
| **BusyBox `ash`**          | `case "${0##*/}" in busybox\|*busybox*)`                      | Builtin `help` nativo (`type help` retorna builtin) ou binário unificado                                                       |

### 9.1. Imunidade a Cascatas e Proibição de Cache em Disco Compartilhado

Ao operar em ambientes onde múltiplos interpretadores podem ser abertos de forma aninhada (`zsh -> bash -> zsh -> sh`):

1. **Nunca grave a identidade do shell em cache no disco (`cache.env`):** Arquivos compartilhados causam contaminação cruzada imediata quando um shell filho é aberto a partir de outro shell pai diferente.
2. **Isolamento de Memória do Processo:** A variável de cache `_DETECTED_SHELL` deve ser mantida como variável interna não-exportada do shell corrente. Ao criar um processo filho, este executará sua própria detecção nativa ultrarrápida (< 0.05ms) sem herdar o estado do pai.

---

## 10. Checklist de Qualidade para Scripts POSIX

Antes de concluir qualquer alteração em arquivos `.sh` portáveis:

- [ ] **Sintaxe validada:** Executou `sh -n <arquivo>` sem erros.
- [ ] **Sem bashismos:** Verificado contra arrays, `[[`, `==`, `source`, `&>`.
- [ ] **Redirecionamentos seguros:** Destinos com aspas duplas (`> "/dev/null" 2>&1`).
- [ ] **Comentários narrativos eliminados:** Zero linhas óbvias comentando comandos executáveis.
- [ ] **Shebang canônico:** Scripts autônomos iniciam com `#!/usr/bin/env sh`.
- [ ] **Tratamento de espaços:** Todas as variáveis em comandos cotadas (`"${var}"`).
- [ ] **Permissões octais canônicas:** 4 dígitos aplicados (`chmod 0755` para scripts executáveis, `chmod 0644` para bibliotecas/temas).
- [ ] **Pre-commit aprovado:** Boot latency < 64ms e zero alertas de formatação.

---

## 🔗 Links Oficiais de Referência & Obras Recomendadas

- **The Open Group (POSIX Standard):** <https://www.opengroup.org/> | Especificações Base Issue 7: <https://pubs.opengroup.org/onlinepubs/9699919799/>
- **POSIX Shell Command Language (`sh`):** <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html>
- **The FreeBSD Project:** <https://www.freebsd.org/> | Manual `sh(1)`: <https://man.freebsd.org/sh.1>
- **The OpenBSD Project:** <https://www.openbsd.org/> | Manual `ksh(1)`: <https://man.openbsd.org/ksh.1>
- **KornShell Portals:** <http://www.kornshell.com/> | <http://www.kornshell.org/>
- **Literatura Técnica:**
    - _The UNIX Programming Environment_ (Brian W. Kernighan & Rob Pike, 1984, Prentice Hall).
    - _The Art of UNIX Programming_ (Eric S. Raymond, 2003, Addison-Wesley).
    - _The KornShell Command and Programming Language_ (Morris I. Bolsky & David G. Korn, 2ª ed., 1995, Prentice Hall PTR).
