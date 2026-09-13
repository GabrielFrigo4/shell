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
- **A Conversão do Parser C (`bin/sh/parser.c:getprompt()`):**
  A contagem de caracteres na string do shell (`wc -c`) **NÃO REFLETE** os bytes ocupados no buffer C:
  - `\[` (2 caracteres no script) $\longrightarrow$ vira **1 byte** no buffer C (`\001`).
  - `\]` (2 caracteres no script) $\longrightarrow$ vira **1 byte** no buffer C (`\001`).
  - `\e` (2 caracteres no script) $\longrightarrow$ vira **1 byte** no buffer C (`\033` ESC).
  - _Consequência:_ Uma cor como `\[\e[95m\]` (9 caracteres) ocupa apenas **7 bytes reais em C**. Calcular custos via `wc -c` gera dezenas de "bytes fantasmas" que estrangulam o orçamento útil.
- **Glifos Multi-byte UTF-8 (Nerd Fonts):**
  - Glifos de ícones (``, ``, ``, ``) ocupam **3 bytes** cada em UTF-8.
  - O ícone do Git (`󰊢`) ocupa **4 bytes**.
  - O caractere de reticências (`…`) ocupa **3 bytes**, enquanto o til (`~`) ocupa apenas **1 byte**. Sob restrição severa (128B), o sufixo de poda deve ser estritamente `~` (1B) para manter a equivalência 1 caractere = 1 byte.
- **Medição Dinâmica em C em Tempo de Execução (`_calc_c_len`):**
  - Para eliminar completamente números mágicos ou custos fixos hardcodados no script, o tema monta o molde estrutural real da moldura (`_fixed_str` contendo usuário, host, SO, cores, ícones e moldura do Git ativo) e calcula seus bytes reais em C dinamicamente via a relação canônica:
    $$\text{Bytes C} = \text{Bytes UTF-8 Brutos} - \text{ocorrências de } \backslash[ - \text{ocorrências de } \backslash] - \text{ocorrências de } \backslash e$$
  - Essa medição consome apenas ~1.3ms e vincula qualquer alteração visual (novas cores, troca de ícone, usuário com nome longo, estado sujo do Git) diretamente à calibragem de bytes, alocando a sobra matemática exata para o diretório e a branch.
- **Parametrização Dinâmica (`PROMPT_BUFFER_LIMIT`):** Como `PROMPTLEN` é uma macro estática em C sem reflexão em tempo de execução para scripts, o motor dinâmico adota chaveamento nativo por versão do FreeBSD (128 bytes para FreeBSD <= 13 e 192 bytes para FreeBSD >= 14) e permite override dinâmico via variável `$PROMPT_BUFFER_LIMIT` (ex: `PROMPT_BUFFER_LIMIT=256`), garantindo que compilações customizadas ou futuras ampliações upstream sejam aproveitadas sem alterar o código do tema.

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
5. **Keybindings Canônicos e Busca de Histórico por Prefixo:**
   - A invocação do builtin `bind` em subshells ou scripts não interativos falha com `bind: line editing is disabled`. Deve ser estritamente guardada com `if case "$-" in *i*) true;; *) false;; esac; then ... fi`.
   - Para restaurar a ergonomia de frameworks modernos (Oh-My-Zsh / Oh-My-Bash) sem peso externo, remapeamos as setas para busca por prefixo digitado:
     - `^[[A` e `^[OA`: `ed-search-prev-history` (sobe no histórico filtrando pelo comando digitado).
     - `^[[B` e `^[OB`: `ed-search-next-history` (desce no histórico filtrando pelo comando digitado).
     - `^R`: `em-inc-search-prev` (busca incremental reversa no histórico).
     - `^W` e `\e^?`: `ed-delete-prev-word` (deleta a palavra anterior).
     - `\e[1;5C` / `\e[1;5D`: `em-next-word` / `ed-prev-word` (navegação por palavras com Ctrl+Setas).

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

- **`_is_raw_tty` (Console `vt`/`syscons`):** Prompt ASCII atômico de 1 linha 100% negrito via persistência ANSI ECMA-48, operando com orçamento dinâmico entre 150 e 190 bytes (salvaguarda total contra overflow).
- **Gráfico (`! _is_raw_tty`):** Mini prompt Nerd Fonts de 1 linha que opera em dois modos via `$PROMPT_STYLE`:
  - **Layout `pill` (192 bytes — FreeBSD 14+):** Consumo calibrado estritamente entre 170 e 185 bytes com pílulas visuais (` ❮ ❯ `).
  - **Layout `micro` (128 bytes — FreeBSD <= 13 ou fallback):** Consumo calibrado estritamente entre 96 e 126 bytes com ícones contínuos _streamlined_ sem delimitadores redundantes (` 13.2  dir  user 󰊢 branch `).
- **Motor de Orçamento Dinâmico de Buffer (Proteção 360°):** Como o buffer estático `ps[192]` do FreeBSD não cresce dinamicamente, o motor calcula em tempo real o espaço exato disponível no buffer `ps[192]`. Aplica travas defensivas de entrada no usuário (`${#_user} <= 12`), hostname (`<= 12`) e versão do SO (`<= 6`), deduzindo seus custos exatos e alocando a sobra inteligentemente entre diretório e branch via expansão recursiva POSIX nativa `_trim_str` (zero subshells / zero forks). Permite caminhos longos quando há espaço e contrai proporcionalmente sob pressão extrema para travar no teto físico inegociável de 191 bytes, mesmo com entradas anômalas de centenas de caracteres.

---

## 6. Procedimento para Atualizar Este Conhecimento

Ao analisar novas versões do FreeBSD (ex: FreeBSD 16-CURRENT):

1. Inspecione o repositório oficial: `https://github.com/freebsd/freebsd-src`
2. Verifique commits recentes em `bin/sh/parser.c` e `contrib/libedit/`.
3. Busque por menções a `PROMPTLEN` ou `EL_PROMPT`.
4. Atualize esta tabela e os temas em sincronia caso o teto seja expandido.
