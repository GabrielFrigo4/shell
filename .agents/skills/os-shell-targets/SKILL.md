---
name: os-shell-targets
description: >-
    Deep technical reference and runbook for operating system shell targets in the Universal Shell Environment.
    Covers architecture, interactive target matrix, zero-fork prompt engines, and platform runtimes for FreeBSD,
    OpenBSD, Linux, macOS, illumos, NetBSD, Windows MSYS2, and pure POSIX sh.
---

# 🌐 Alvos de Shell Multiplataforma & Arquitetura de Runtimes

Este runbook orienta a concepção, manutenção e auditoria de especializações por sistema operacional no **Universal Shell Environment** (`/usr/local/share/shell`), estruturado sob a arquitetura de **Tier 2 (Extended)**.

---

## 🏛️ Matriz Canônica de Alvos Interativos (`target/<os>/<shell>`)

Nem todo shell é suportado como alvo interativo em todos os sistemas operacionais. O ecossistema adota uma especialização cirúrgica por SO:

| Sistema Operacional | Alvos Interativos Suportados (`target/`) | Justificativa Arquitetural                                                                            |
| :------------------ | :--------------------------------------: | :---------------------------------------------------------------------------------------------------- |
| **FreeBSD**         |         `zsh`, `bash`, **`sh`**          | **Único SO com `sh` interativo**. Parser C aceita `kebab-case`. Buffer restrito a 192 bytes.          |
| **OpenBSD**         |         `zsh`, `bash`, **`ksh`**         | **Único SO com `ksh` interativo**. Parser pdksh com `kebab-case`. Largura zero delimitada por `\x01`. |
| **Linux**           |              `zsh`, `bash`               | `/bin/sh` (Dash ou Bash `--posix`) rejeita `kebab-case` e não é interativo de usuário.                |
| **macOS**           |              `zsh`, `bash`               | Zsh padrão; `/bin/sh` é Bash 3.2 obsoleto com `posixly_correct` que rejeita hífens.                   |
| **illumos**         |              `zsh`, `bash`               | `/bin/sh` (Ksh93) rejeita hífens em funções. Suíte GNU em `/usr/gnu/bin`.                             |
| **NetBSD**          |              `zsh`, `bash`               | `/bin/sh` ash puro rejeita hífens (`goodname()`). Berço histórico da `libedit`.                       |
| **Windows (MSYS2)** |              `zsh`, `bash`               | Camada de emulação POSIX sobre NT. Penalidade severa de `fork()` (20-60ms). Zero subshells no boot.   |

---

## 👑 Hierarquia de Ergonomia de Shells

Em benchmarks, testes automatizados e documentações, a ordem de precedência deve respeitar estritamente a conveniência de interface:

1. **`zsh`:** Topo da ergonomia, auto-completar visual e renderização de prompts complexos.
2. **`bash`:** Padrão corporativo universal e compatibilidade retroativa sólida.
3. **`sh` / `ksh`:** Shells nativos do base system exclusivos de FreeBSD (`sh`) e OpenBSD (`ksh`).

---

## 📚 Módulos Especializados da Subpasta references/

Consulte as especificações detalhadas de baixo nível em cada arquivo:

- **[freebsd.md](references/freebsd.md):** Target interativo `/bin/sh`, limite estático de 192B (`PROMPTLEN`), motor `_calc_c_len`, `libedit` e a armadilha do sinal `SIGTTIN` em CI headless (`script -q /dev/null`).
- **[openbsd.md](references/openbsd.md):** Target interativo `/bin/ksh` (pdksh), ausência de `$''`, delimitadores de largura zero hexadecimais `\x01`, `pledge`, `unveil` e `doas`.
- **[linux.md](references/linux.md):** Dash e Bash-posix rejeitando `kebab-case`, hierarquia de pacotes por família (Arch, Debian, Fedora), detecção dinâmica de dark mode e console Linux.
- **[macos.md](references/macos.md):** Congelamento GPLv3 do Bash 3.2, transição para Zsh, prefixos Homebrew (`/opt/homebrew` vs `/usr/local`) e divergências de coreutils BSD.
- **[illumos.md](references/illumos.md):** Ksh93, dualidade `/usr/bin` vs `/usr/gnu/bin`, supervisão transacional SMF (`svcs`/`svcadm`) e empacotamento IPS.
- **[netbsd.md](references/netbsd.md):** Almquist shell estrito, histórico da `libedit` (Christos Zoulas), empacotamento com `pkgsrc`/`pkgin` e console WSCONS.
- **[windows.md](references/windows.md):** MSYS2 e WSL, custo de emulação de `fork()`, utilitário `cygpath`, higiene estrita contra CRLF (`\r\n`) e terminal ConPTY.
- **[posix.md](references/posix.md):** Baseline comum `/bin/sh`, análise comparativa de parsers e `kebab-case`, manipulação de strings sem subshells (zero forks) e eliminação de bashismos.

---

## 🔗 Referências Oficiais & Upstream

- [FreeBSD Source Repository (bin/sh)](https://github.com/freebsd/freebsd-src)
- [OpenBSD Source Repository (bin/ksh)](https://cvsweb.openbsd.org/src/bin/ksh/)
- [MSYS2 Project](https://www.msys2.org/)
- [NetBSD pkgsrc](https://www.pkgsrc.org/)
- [illumos Documentation](https://illumos.org/docs/)
