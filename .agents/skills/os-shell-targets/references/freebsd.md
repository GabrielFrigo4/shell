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
4. **Tab Completion Nativo (`sh-complete` vs `rl_complete` em `bin/sh/histedit.c`):**
    - O `/bin/sh` do FreeBSD registra sua função interna de autocompletar comandos (`$PATH`, builtins, aliases, funções) e arquivos sob o nome **`sh-complete`** (`el_set(el, EL_ADDFN, "sh-complete", ...)`).
    - O identificador `rl_complete` não existe na tabela do `/bin/sh` e jamais deve ser usado (emite `bind: Invalid command 'rl_complete'`).
    - Como `bind -e` (em `~/.editrc`) e `set -o emacs` (em `sh.sh`) resetam a tabela de teclas para o padrão Emacs (`^I -> ed-insert`), deve-se declarar `sh:bind "^I" sh-complete` após `bind -e` no `~/.editrc` e `bind "^I" sh-complete` no `behavior.sh`.
5. **Mecânica de 2-Tabs em Ambiguidade (`contrib/libedit/filecomplete.c`):**
    - Em `fn_complete2()`, a listagem de múltiplos candidatos (`what_to_do = '?'`) exige `el->el_state.lastcmd == el->el_state.thiscmd` (segundo `<Tab>` consecutivo). No primeiro `<Tab>` ambíguo, o `libedit` expande o maior prefixo comum e invoca `el_beep(el)`.
6. **Silenciamento Zero-Byte do Beep via `settc bl "$<0>"` (`terminal.c` & `lib_tputs.c`):**
    - Em `terminal_beep()`, o `libedit` avalia `#define GoodStr(a) (t_str[a] != NULL && t_str[a][0] != '\0')`. Se `settc bl ""` for usado, `GoodStr(T_bl)` é falso e o `else` emite `'\007'` (`^G`) de qualquer forma.
    - Ao definir **`settc bl "$<0>"`** no `~/.editrc`, `GoodStr(T_bl)` torna-se verdadeiro e delega para `tputs("$<0>", 1, terminal_putc)`. O parser `tputs` do `ncurses` interpreta `$<0>` como especificação de delay de `0ms` e emite **zero bytes** no descritor de saída, silenciando 100% o alerta sonoro sem injetar caracteres na linha.

---

## 🤖 A Armadilha de `SIGTTIN` em Ambientes Headless

No kernel do FreeBSD (`sys/kern/kern_tty.c`), quando um shell interativo (`bash -i`) tenta chamar `tcsetpgrp()` em segundo plano sem PTY, o kernel emite `SIGTTIN` (sinal 21), suspendendo o processo (`SIGSTOP`).

**Padrão Canônico com `/usr/bin/script`:**

```sh
script -q /dev/null bash -i -c 'echo "Prompt: ${PS1}"'
```

---

## 😈 Derivados & Downstreams

- **GhostBSD & NomadBSD:** Detectados sob a família `bsd`, preservando compatibilidade com `pkg` (`update-pkg`) e glifo ` ` (`U+F30C`, `nf-linux-freebsd`).
- **DragonFly BSD:** Identificado isoladamente como `dragonfly` (DPorts/pkg) com glifo ` ` (`U+EEF8`).

---

## 🔒 Modo Monousuário & Invariante de `/bin/sh`

No FreeBSD, a inicialização em modo monousuário (_Single-User Mode_ — acionada via flag `-s` do bootloader ou prompt do loader) **executa incondicionalmente o `/bin/sh` diretamente pelo kernel/init (`/sbin/init`)**, independentemente do shell configurado para o usuário ou root em `/etc/passwd` (`pw usermod -s`) ou da variável `shell_target`.

### Fundamentos Arquiteturais:

1. **Raiz Somente-Leitura (`ro`):** O sistema de arquivos raiz (`/`) é montado em modo somente-leitura.
2. **Ausência de Filesystems Secundários:** Partições e datasets ZFS como `/usr` e `/usr/local` ainda não estão montados. Interpretadores de terceiros em `/usr/local/bin/zsh` ou `/usr/local/bin/bash` são fisicamente inacessíveis.
3. **Bypass de PAM e Login:** O subsistema de autenticação PAM e o processo `login` não entram em execução. O kernel não lê `/etc/profile` nem dotfiles do usuário (`~/.profile`), entregando um ambiente de recuperação estático e minimalista sob o `/bin/sh` da base.

---

## 🌉 Virtualização Bhyve vs Linux Bare-Metal (`bhyve.sh`)

- **Papel de `bhyve.sh` no FreeBSD:** Em estações de trabalho FreeBSD, o script `Shell/target/freebsd/bhyve.sh` atua como ponte de despacho transparente para executar o agente de IA (`agy`) e toolchains GNU pesadas isoladas em uma máquina virtual Debian convidada no Bhyve (`192.168.8.2`), conectada via NFSv3 ao `/home/gabrielf` com paridade de UID/GID 1001.
- **Ausência Proposital no Linux (`kvm.sh` inexistente):** No Linux, o sistema executa nativamente em bare-metal, tendo acesso direto ao kernel Linux e ao ambiente GNU. Não há necessidade de scripts de ponte de virtualização no `target/linux/`.

---

## 🖥️ Consoles Virtuais `vt(4)` & Cursor Estático

No FreeBSD, o console virtual da base é gerenciado pelo driver `vt(4)` (com emulador terminal `teken`).

Diferente do Linux (que exige parametrizações ativas de softcursor e `cursor_blink=0` no kernel para cessar o pisque), o **driver `vt(4)` do FreeBSD adota um cursor em bloco sólido estático por concepção arquitetural**:

- A rotina de renderização no kernel (`sys/dev/vt/vt_core.c`) desenha diretamente um bloco invertido estático no framebuffer, sem temporizador ou thread de pisque.
- O utilitário legado `vidcontrol -c normal,noblink` pertencia ao driver arcaico `sc(4)` dos anos 90 e é obsoleto no `vt(4)` (retornando erro de ioctl).
- A persistência no `/etc/rc.conf` configura apenas a fonte Spleen 12x24 via:

```sh
allscreens_flags="-f spleen-12x24"
```

Para aplicar em runtime sem reiniciar, reinicia-se o serviço canônico: `service syscons restart`.
