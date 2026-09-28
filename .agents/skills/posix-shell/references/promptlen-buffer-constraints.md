# 🛑 Limitações Físicas de Memória em Buffers (`PROMPTLEN`)

> Análise detalhada dos limites de memória estática do kernel e da Almquist shell no FreeBSD.

---

## 1. Buffers Estáticos de Prompt

No FreeBSD `/bin/sh` e derivados da Almquist shell:

- **FreeBSD <= 13:** Buffer estático de **128 bytes** (`ps[128]`).
- **FreeBSD 14 e 15+:** Buffer estático de **192 bytes** (`ps[192]`).
- **Teto Físico de Memória:** O prompt formatado é truncado no kernel em `PROMPTLEN - 1`.

---

## 2. A Mecânica Interna do Parser C (`bin/sh/parser.c:getprompt()`)

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

---

## 3. Matriz Auditada de Custos Reais em C (`_base_cost` & `_git_frame`)

| Layout        | Teto Alvo | Custo Base C (`_base_cost`) | Moldura Git C (`_git_frame`) |   Indicador Dirty   | Margem (`_margin`) |
| :------------ | :-------: | :-------------------------: | :--------------------------: | :-----------------: | :----------------: |
| **TTY micro** |   128B    |           **55B**           |           **24B**            |      `*` (+1B)      |         2B         |
| **TTY pill**  |   192B    |           **90B**           |           **24B**            | `\[\e[93m\]*` (+8B) |         2B         |
| **PTY micro** |   128B    |           **76B**           |           **20B**            |      `*` (+1B)      |         2B         |
| **PTY pill**  |   192B    |          **118B**           |           **20B**            | `\[\e[93m\]*` (+8B) |         2B         |
