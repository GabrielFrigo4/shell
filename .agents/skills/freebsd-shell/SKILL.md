---
name: freebsd-shell
description: >-
  Deep technical reference and runbook for FreeBSD /bin/sh, EditLine (libedit), kernel versioning,
  terminal drivers, and FreeBSD-specific shell environments. Use when maintaining, optimizing,
  or auditing shell scripts and prompt rendering on FreeBSD.
---

# FreeBSD Shell — Architecture, Libedit & Runtime Runbook

Este documento consolida o conhecimento canônico, limitações físicas de baixo nível e padrões de engenharia para o interpretador padrão `/bin/sh` e a biblioteca `libedit` no FreeBSD (com foco em **FreeBSD 14 e FreeBSD 15.1+**).

---

## 1. Papel Arquitetural do `/bin/sh` no FreeBSD

No FreeBSD, o `/bin/sh` **não é apenas um shell de login interativo**:

1. É o shell do superusuário `root` por padrão no sistema base.
2. É o interpretador de todo o subsistema de boot e serviços (`/etc/rc`, `/etc/rc.subr`).
3. Está presente no particionamento raiz (`/bin`), projetado para operar mesmo em modo monousuário (_single-user mode_) ou ambientes de emergência com memória severamente restrita.

Por essa razão, os mantenedores do FreeBSD (_upstream_) impõem rigor estrito contra alocações dinâmicas de heap (`malloc`), reentrância no parser e complexidade desnecessária no `/bin/sh`.

---

## 2. Limites Físicos de Prompt: O Mistério dos 192 Bytes (`PROMPTLEN`)

No código-fonte C do `/bin/sh` (`bin/sh/parser.c`), a função `getprompt()` é responsável por formatar a variável `PS1`.

```c
#define PROMPTLEN 192    /* Ampliado de 128 para 192 na Revisão D37701 */
static char ps[PROMPTLEN];
```

### Regras Inquebráveis de Memória:

- **Teto Rígido de 191 Bytes:** O buffer `ps` é estático e nunca cresce dinamicamente. Qualquer prompt expandido que atinja 192 bytes é **truncado abruptamente** no byte 191 (`ps[i] = '\0'`).
- **Por que quebrava com ~17 operações:**
  - Cada código de cor ANSI delimitado por `\[\e[1;9xm\]` consome cerca de 10 a 11 bytes.
  - $17 \text{ escapes} \times 10 \text{ bytes} = 170 \text{ bytes}$.
  - Somando o texto visível (usuário, host, pasta, branch e delimitadores), o total atinge exatamente 184 a 192 bytes.
  - A 18ª sequência estourava o buffer, truncando o escape no meio e corrompendo a saída do terminal.
- **Regra de Otimização Canônica:** Use sempre a notação de 8 bits `\[\e[9xm\]` em vez de `\[\e[1;9xm\]`. Isso economiza 2 bytes por código de cor (~20 a 28 bytes de folga no prompt total).

---

## 3. Peculiaridades da Biblioteca EditLine (`libedit`)

O `/bin/sh` do FreeBSD utiliza a `libedit` (`contrib/libedit/`) para edição de linha interativa (`sh-complete`, histórico, movimentação do cursor).

### Comportamentos Críticos Identificados:

1. **Delimitador Único de Escapes (`\001`):**
   - Ao contrário da GNU Readline (que usa `\001` para início e `\002` para fim), o `/bin/sh` chama `el_set(el, EL_PROMPT_ESC, getprompt, '\001')`.
   - Tanto `\[` quanto `\]` são convertidos para o mesmo byte `\001`.
2. **Escapes Consecutivos São Descartados:**
   - Em `contrib/libedit/literal.c`, a função `literal_add` amarra a sequência não-imprimível ao _próximo caractere visível_.
   - Se duas sequências `\[...\]` forem posicionadas sem nenhum caractere visível intermediário, `wcwidth` retorna `-1` e a `libedit` descarta silenciosamente o primeiro escape.
3. **Descarte do Último Literal:**
   - Se o prompt terminar em um escape ANSI sem um caractere visível subsequente (`!p[1]`), a `libedit` aciona a cláusula `// XXX: We lose the last literal` e o descarta.
   - **Regra:** O prompt deve sempre encerrar com `${_c_reset}` seguido por um espaço imprimível ` `.
4. **Multilinhas (`\n`) no Redraw:**
   - Em `contrib/libedit/refresh.c`, a função `re_putc` insere quebras de linha virtuais, mas não incrementa a coordenada vertical `r_cursor.v`.
   - Prompts multilinhas longos no `sh` desincronizam a posição do cursor ao navegar pelo histórico (Up/Down). Por isso, **prompts de 1 linha são canonicamente recomendados no `sh`**.

---

## 4. Evolução Técnica: FreeBSD 14 vs FreeBSD 15.1+

| Recurso                                    | FreeBSD 13 e Anteriores |      FreeBSD 14      |          FreeBSD 15.1+ (Atual)          |
| :----------------------------------------- | :---------------------: | :------------------: | :-------------------------------------: |
| **`PROMPTLEN`**                            |        128 bytes        |      192 bytes       |                192 bytes                |
| **Delimitadores `\[` e `\]`**              |      Não suportado      | Suportado (`D37701`) |                Suportado                |
| **Escapes canônicos (`\u`, `\w`, `\e`)**   |      Não suportado      |      Suportado       |                Suportado                |
| **Data/Hora `\D{fmt}`**                    |      Não suportado      |      Suportado       |                Suportado                |
| **Expansão de parâmetros `$VAR` em `PS1`** |      Não suportado      |    Não suportado     |  **Suportado** (`f9e79fac`, PR 46441)   |
| **Subshell dinâmico `$(cmd)` em `PS1`**    |      Não suportado      |    Não suportado     | Não suportado (rejeitado por segurança) |
| **Hooks `PROMPT_COMMAND` / `precmd`**      |       Inexistente       |     Inexistente      |               Inexistente               |

### Por que o FreeBSD não implementa `PROMPT_COMMAND` ou parser reentrante:

- Na discussão oficial do commit `f9e79fac` (PR 46441), o mantenedor Jilles Tjoelker destacou que a expansão localizada em `getprompt()` atende ao POSIX Issue 8 sem a complexidade perigosa de tornar o parser reentrante.
- No GNU Bash, prompts dinâmicos reentrantes geraram histórico de vulnerabilidades críticas de injeção de comandos (como vertentes do _Shellshock_).
- O FreeBSD preserva o `/bin/sh` estritamente minimalista. Usuários que necessitam de hooks contínuos são direcionados para o Zsh ou Bash.

---

## 5. Padrões de Projeto Canônicos do Repositório

### Triggers de Precisão (Substitutos de `PROMPT_COMMAND`):

Como o `sh` não executa funções a cada enter vazio, usamos funções wrapper com custo zero:

```sh
_create_trigger() {
for _cmd in "$@"; do
eval "
${_cmd}() {
command ${_cmd} \"\$@\"
local _ret=\$?
_update_prompt
return \${_ret}
}
"
done
}
_create_trigger cd git got
alias :="_update_prompt; command :"
```

### Separação TTY Bruto vs Terminal Gráfico:

- **`_is_raw_tty` (Console `vt`/`syscons`):** Prompt ASCII atômico de 1 linha sem caracteres especiais.
- **Gráfico (`! _is_raw_tty`):** Mini prompt Nerd Fonts de 1 linha com consumo calibrado em **~168 bytes** (deixando margem de segurança de >24 bytes até o teto de 192).

---

## 6. Procedimento para Atualizar Este Conhecimento

Ao analisar novas versões do FreeBSD (ex: FreeBSD 16-CURRENT):

1. Inspecione o repositório oficial: `https://github.com/freebsd/freebsd-src`
2. Verifique commits recentes em `bin/sh/parser.c` e `contrib/libedit/`.
3. Busque por menções a `PROMPTLEN` ou `EL_PROMPT`.
4. Atualize esta tabela e os temas em sincronia caso o teto seja expandido.
