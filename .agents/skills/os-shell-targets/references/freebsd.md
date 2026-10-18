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

No FreeBSD, o console virtual da base é gerenciado pelo driver `vt(4)`. O controle de pisque do cursor é realizado nativamente pelo utilitário `vidcontrol`:

```sh
vidcontrol -c normal,noblink
```

Essa configuração é persistida no `/etc/rc.conf` via `allscreens_flags="-c normal,noblink"`, garantindo que todas as telas virtuais (`ttyv0` a `ttyv7`) inicializem com cursor estático e tipografia Spleen 12x24 (`font12x24="spleen-12x24"`).
