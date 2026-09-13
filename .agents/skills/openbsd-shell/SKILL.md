---
name: openbsd-shell
description: >-
    Deep technical reference and runbook for OpenBSD shell environments, Public Domain Korn Shell (pdksh / ksh),
    target/openbsd/ksh architecture, security primitives (pledge, unveil), package management (pkg_add), and doas.
    Use when preparing, maintaining, or auditing OpenBSD-specific shell scripts and ksh runtime.
---

# 🐡 OpenBSD Shell — Architecture, Korn Shell (`ksh`) & Security Runbook

Este documento consolida o conhecimento canônico, particularidades de segurança proativa e padrões de engenharia para o ecossistema **OpenBSD** no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. O Shell Padrão do OpenBSD: Public Domain Korn Shell (`ksh`)

No OpenBSD, tanto para usuários regulares quanto para o `root`, o interpretador padrão do sistema base é o **Korn Shell (`/bin/ksh`)**, baseado no original `pdksh` e continuamente aprimorado pela equipe do OpenBSD:

1. **Compatibilidade com POSIX & Extensão `kebab-case`:**
    - O `ksh` do OpenBSD é amplamente aderente ao padrão POSIX com traços próprios do Korn Shell (Ksh88).
    - **Suporte Nativo a `kebab-case`:** O parser aceita funções com hífen (`path-front()`, `update-all()`), permitindo carregar diretamente a suíte `library/functions.sh` sem renomeação.
2. **Edição de Linha Embutida & Keybindings:**
    - O `ksh` possui modos de edição próprios (`set -o emacs` ou `set -o vi`), sem depender da GNU Readline.
    - Os keybindings no modo emacs utilizam a sintaxe canônica `bind 'seq'=action` (ex: `bind '^[[A'=up-history`, `bind '^R'=search-history`).
    - A invocação do comando `bind` exige terminal TTY interativo e deve ser guardada defensivamente com `if [ -t 1 ] && case "$-" in *i*) true;; *) false;; esac; then ... fi`.
3. **Comportamento do Prompt (`$PS1`):**
    - No OpenBSD `ksh` moderno, sequências não-imprimíveis (como códigos de cores ANSI) são delimitadas por `\[` (desativa contagem de largura de coluna) e `\]` (reativa contagem).
    - Como o `ksh` do OpenBSD não expande ANSI-C quoting (`$'\e'`), o escape ESC deve ser emitido via byte octal `\033` (ex: `_esc="$(printf '\033')"`).
    - O prompt é reavaliado dinamicamente a cada comando quando variáveis ou funções são escapadas no `PS1` com `\$` (ex: `PS1='$(_ksh_prompt)'`).
4. **Target Interativo Exclusivo (`target/openbsd/ksh`):**
    - O OpenBSD possui suporte nativo de primeira classe ao Korn Shell como alvo interativo exclusivo (`target/openbsd/ksh`).
    - Não existe alvo `target/openbsd/sh`, pois `/bin/sh` no OpenBSD é um hardlink para `/bin/ksh`.
    - A tríade de shells suportados no OpenBSD é **`zsh`, `bash` e `ksh`**.

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

---

## 🔗 Links Oficiais de Referência & Obras Recomendadas

- **OpenBSD Project:** <https://www.openbsd.org/> | FAQ: <https://www.openbsd.org/faq/>
- **KornShell Portals:** <http://www.kornshell.com/> | <http://www.kornshell.org/>
- **OpenBSD Manual Pages:**
    - `ksh(1)`: <https://man.openbsd.org/ksh.1>
    - `pledge(2)`: <https://man.openbsd.org/pledge.2>
    - `unveil(2)`: <https://man.openbsd.org/unveil.2>
    - `doas(1)`: <https://man.openbsd.org/doas.1>
    - `pkg_add(1)`: <https://man.openbsd.org/pkg_add.1>
- **OpenBSD Ports & Packages Search:**
    - Web Search (OpenPorts Indexer): <https://openports.pl/>
    - CVSweb Oficial da Ports Tree: <https://cvsweb.openbsd.org/ports/>
    - Guia Oficial & Busca CLI (`pkg_info -aQ`): <https://www.openbsd.org/faq/faq15.html#PkgFind>
- **Literatura Técnica:**
    - _The KornShell Command and Programming Language_ (Morris I. Bolsky & David G. Korn, 2ª ed., 1995, Prentice Hall PTR).
    - _The Art of UNIX Programming_ (Eric S. Raymond, 2003, Addison-Wesley).
