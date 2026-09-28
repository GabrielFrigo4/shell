# ☀️ illumos (Solaris) Shell — Arquitetura de Paths & SMF

No ecossistema **illumos** (OpenIndiana, OmniOS, SmartOS), os alvos interativos suportados em `target/illumos/` são **estritamente `bash` e `zsh`**.

---

## 🐚 A Transição do Bourne Shell para Ksh93 e Bash

1. O `/bin/sh` clássico da Sun Microsystems foi substituído no illumos moderno pelo KSH93 ou symlink para Bash.
2. Como o parser do AT&T KSH93 rejeita estritamente funções em `kebab-case` (`invalid function name`), o `ksh93` não pode ser usado como alvo interativo da suíte.
3. Não existe alvo `target/illumos/sh`.

---

## 📂 A Dualidade de Caminhos: `/usr/bin` vs `/usr/gnu/bin`

Utilitários em `/usr/bin` preservam a semântica histórica do UNIX System V (SVR4) e não suportam flags GNU comuns (`grep -q`, `sed -i`, `tar -z`).

**Solução Canônica:**

```sh
[ -d "/usr/gnu/bin" ] && path-front "/usr/gnu/bin"
```

Isto posiciona as versões GNU à frente no `PATH` sem corromper scripts administrativos internos.

---

## ⚙️ Gestão de Serviços via SMF (Service Management Facility)

- Consulta: `svcs` (ou `svcs -x` para inspecionar falhas).
- Controle: `svcadm enable <serviço>`, `svcadm restart <serviço>`.
- O alias universal `services` aponta nativamente para `svcs` no illumos.
- **Gerenciamento de Pacotes:** `pkg` (IPS) no OpenIndiana e OmniOS; `pkgin`/`pkgsrc` no SmartOS.
