# 🐚 FreeBSD Shell — Architecture, Libedit & Runtime

No FreeBSD, o `/bin/sh` ocupa uma posição única em todo o ecossistema: é o **único sistema operacional** em que `/bin/sh` é suportado como shell interativo de usuário (`target/freebsd/sh`).

---

## 🏛️ Suporte a `kebab-case` no Parser C

Diferente de Dash e Bash em modo POSIX, o `/bin/sh` do FreeBSD possui uma extensão deliberada no parser C (`bin/sh/parser.c`) que aceita hífens em nomes de funções (`path-front`, `mount-device`), permitindo o carregamento direto das funções públicas em `library/functions.sh`.

---

## 📏 Limite Físico de Prompt: 192 Bytes (`PROMPTLEN`)

No código C do `/bin/sh` (`bin/sh/parser.c`), a função `getprompt()` formata `PS1`:

```c
#define PROMPTLEN 192    /* Ampliado de 128 para 192 na Revisão D37701 */
static char ps[PROMPTLEN];
```

### Regras de Memória em Baixo Nível:

- **Teto Rígido de 191 Bytes:** Qualquer expansão que alcance 192 bytes é truncada no byte 191 (`ps[i] = '\0'`).
- **Conversão de Caracteres pelo Parser C:**
    - `\[` vira 1 byte em C (`\001`).
    - `\]` vira 1 byte em C (`\001`).
    - `\e` vira 1 byte em C (`\x1b`).
- **Glifos UTF-8 Multi-byte (Nerd Fonts):** Ícones ocupam 3 bytes (``, ``) ou 4 bytes (`󰊢`). Reticências (`…`) ocupam 3 bytes, enquanto til (`~`) ocupa 1 byte.
- **Medição Dinâmica em Tempo de Execução (`_calc_c_len`):**
  $$\text{Bytes C} = \text{Bytes UTF-8 Brutos} - \text{ocorrências de } \backslash[ - \text{ocorrências de } \backslash] - \text{ocorrências de } \backslash e$$

---

## ⚙️ Biblioteca EditLine (`libedit`)

1. **Delimitador Único de Escapes (`\001`):** Tanto `\[` quanto `\]` são convertidos para `\001`.
2. **Escapes Consecutivos Descartados:** Se duas sequências `\[...\]` forem colocadas sem caractere visível intermediário, `libedit` descarta a primeira.
3. **Descarte do Último Literal:** O prompt deve sempre encerrar com `${_color_reset}` seguido por um espaço imprimível ` `.
4. **Keybindings Canônicos:** Setas configuradas para `ed-search-prev-history` e `ed-search-next-history`.

---

## 🤖 A Armadilha de `SIGTTIN` em Ambientes Headless

No kernel do FreeBSD (`sys/kern/kern_tty.c`), quando um shell interativo (`bash -i`) tenta chamar `tcsetpgrp()` em segundo plano sem PTY, o kernel emite `SIGTTIN` (sinal 21), suspendendo o processo (`SIGSTOP`).

**Padrão Canônico com `/usr/bin/script`:**

```sh
script -q /dev/null bash -i -c 'echo "Prompt: ${PS1}"'
```
