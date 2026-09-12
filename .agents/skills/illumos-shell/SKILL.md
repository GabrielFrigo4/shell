---
name: illumos-shell
description: >-
  Deep technical reference and runbook for illumos / Solaris shell environments (OpenIndiana, OmniOS, SmartOS).
  Covers /usr/bin vs /usr/gnu/bin path duality, SMF (svcs, svcadm), IPS (pkg), and ZFS/DTrace administrative contexts.
  Use when preparing, maintaining, or auditing illumos-specific shell scripts and portability.
---

# illumos (Solaris) Shell — Architecture, Paths & Runtime Runbook

Este documento consolida o conhecimento canônico, particularidades do subsistema illumos/Solaris e padrões de engenharia para o ecossistema **illumos** (OpenIndiana, OmniOS, SmartOS) no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. O Shell Padrão no illumos: A Transição do Bourne Shell para o Ksh93 / Bash

1. **Histórico do `/bin/sh`:**
   - No Solaris tradicional da Sun Microsystems, o `/bin/sh` era o Bourne shell clássico de 1977 (sem suporte a funções no início e sem aritmética interna).
   - No OpenSolaris e no **illumos moderno**, o `/bin/sh` foi substituído pelo **KSH93** ou symlink para o **Bash**, garantindo suporte a recursos POSIX modernos e funções com hífen.
2. **Bash e Zsh:**
   - Ambos estão amplamente disponíveis nas distribuições illumos modernas através dos repositórios nativos IPS (`pkg install bash zsh`).

---

## 2. A Dualidade de Caminhos: `/usr/bin` vs `/usr/gnu/bin`

No ecossistema Solaris e illumos, os utilitários de sistema em `/usr/bin` preservam a semântica histórica estrita do UNIX System V (SVR4):

- **O Problema:** Ferramentas como `grep`, `sed`, `awk`, `tar` e `find` em `/usr/bin` não aceitam flags comuns do Linux GNU (como `grep -q`, `sed -i`, `tar -z`).
- **A Solução Canônica:** O illumos disponibiliza a suíte GNU completa sob o diretório `/usr/gnu/bin`:
  ```sh
  [ -d "/usr/gnu/bin" ] && path-front "/usr/gnu/bin"
  ```
  Isso garante que scripts compartilhados encontrem versões modernas e ricas das ferramentas sem quebrar utilitários administrativos do sistema.

---

## 3. Gestão de Serviços com SMF (Service Management Facility)

No illumos, não existe `systemd` nem os scripts simples `/etc/rc.d`:

- O gerenciamento de serviços é feito pelo **SMF**, um subsistema transacional com controle de dependências em árvore:
  - Listar serviços: `svcs` (ou `svcs -x` para verificar falhas).
  - Iniciar/Parar: `svcadm enable <serviço>` e `svcadm disable <serviço>`.
  - Reiniciar: `svcadm restart <serviço>`.
- **Integração no Shell:** O alias universal `services` mapeia nativamente para `svcs` no illumos.

---

## 4. Gestão de Pacotes com IPS e Pkgin

Dependendo da distribuição illumos:

1. **OpenIndiana e OmniOS:** Utilizam o **IPS (Image Packaging System)** com o comando unificado `pkg`:
   ```sh
   pkg refresh
   pkg install <pacote>
   pkg update
   ```
2. **SmartOS (Foco em Contêineres e Hipervisor):** Utiliza zonas ZFS e o ecossistema `pkgin` / `pkgsrc` sob `/opt/local/bin`.
