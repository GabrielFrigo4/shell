---
name: openbsd-shell
description: >-
  Deep technical reference and runbook for OpenBSD shell environments, Public Domain Korn Shell (pdksh / ksh),
  security mitigation primitives (pledge, unveil), package management (pkg_add), and doas privilege escalation.
  Use when preparing, maintaining, or auditing OpenBSD-specific shell scripts and portability.
---

# OpenBSD Shell — Architecture, Security Primitives & Runtime Runbook

Este documento consolida o conhecimento canônico, particularidades de segurança proativa e padrões de engenharia para o ecossistema **OpenBSD** no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. O Shell Padrão do OpenBSD: Public Domain Korn Shell (`ksh`)

No OpenBSD, tanto para usuários regulares quanto para o `root`, o interpretador padrão é o **Korn Shell (`/bin/ksh`)**, baseado no original `pdksh`:

1. **Compatibilidade com POSIX:**
   - O `ksh` do OpenBSD é amplamente aderente ao padrão POSIX, mas com traços próprios do Korn Shell (Ksh88).
   - Suporta funções com sintaxe padrão `nome() { ... }` (e aceita `kebab-case` nativamente).
2. **Edição de Linha Embutida:**
   - O `ksh` possui modos de edição próprios (`set -o emacs` ou `set -o vi`), sem depender da `libedit` ou GNU Readline.
3. **Comportamento do Prompt (`$PS1`):**
   - O `ksh` do OpenBSD suporta escapes específicos (`!`, `\h`, `\u`), mas **não suporta delimitadores `\[...\]` do Bash**.
   - Para caracteres não-imprimíveis (cores ANSI), o `ksh` clássico do OpenBSD pode exigir isolamento via escape octal `\001` ou substituição cuidadosa para não desalinhar a contagem de colunas na linha de comando.

---

## 2. Primitivas de Segurança de Baixo Nível: `pledge(2)` e `unveil(2)`

O OpenBSD é mundialmente reconhecido pelo foco intransigente em segurança proativa:

1. **`pledge(2)`:**
   - Limita as chamadas de sistema que um processo pode realizar após a inicialização (ex: `stdio`, `rpath`, `wpath`, `cpath`, `inet`, `dns`, `proc`, `exec`).
   - Se um utilitário do shell tentar acessar a rede sem ter feito pledge de `inet`, o kernel encerra o processo imediatamente com `SIGABRT`.
2. **`unveil(2)`:**
   - Restringe a visão da árvore de arquivos apenas aos diretórios expressamente declarados.
3. **Impacto em Scripts:**
   - Utilitários nativos do sistema base operam sob restrições estritas de pledge. Scripts e funções devem evitar operações desnecessárias de sistema que possam colidir com políticas de processos filhos.

---

## 3. Gestão de Privilégios com `doas`

No OpenBSD, o `sudo` foi completamente removido do sistema base em favor do **`doas`** (`/usr/bin/doas`):

- O arquivo de configuração é `/etc/doas.conf` (com sintaxe limpa como `permit persist :wheel`).
- **Padrão do Repositório:** A cascata `_as_root` em `library/functions.sh` valida prioritariamente a existência de `doas` antes de recorrer ao `sudo`.

---

## 4. Gestão de Pacotes (`pkg_add` e `pkg_delete`)

- O OpenBSD não possui `apt` nem `pacman`. O sistema utiliza ferramentas diretas:
  - Instalação: `doas pkg_add <pacote>`
  - Atualização do sistema: `doas syspatch` (patches binários do SO) e `doas pkg_add -u` (pacotes).
  - Mirror padrão: definido em `/etc/installurl`.
