---
name: netbsd-shell
description: >-
  Deep technical reference and runbook for NetBSD shell environments, Almquist shell (/bin/sh),
  the upstream birthplace of EditLine (libedit), pkgsrc / pkgin package management, and WSCONS console.
  Use when preparing, maintaining, or auditing NetBSD-specific shell scripts and portability.
---

# NetBSD Shell — Architecture, Libedit Origins & Runtime Runbook

Este documento consolida o conhecimento canônico, particularidades do subsistema NetBSD e padrões de engenharia para o ecossistema **NetBSD** no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. O Berço Histórico da `libedit` (EditLine)

O NetBSD é o **desenvolvedor original e guardião upstream da biblioteca `libedit`**:

1. Criada por Christos Zoulas no NetBSD na década de 1990 como alternativa BSD limpa à biblioteca GNU Readline (que é GPL).
2. Todo o código que hoje roda no FreeBSD (`contrib/libedit/`) e no macOS é importado periodicamente da árvore de fontes do NetBSD.
3. O mecanismo de literais (`literal.c`, `literal_add`), o suporte a `EL_PROMPT_ESC` e a manipulação do buffer de refresh (`refresh.c`) foram projetados sob as convenções do NetBSD.

---

## 2. O `/bin/sh` do NetBSD (Almquist Shell Moderno)

O NetBSD possui uma das implementações de `/bin/sh` mais maduras e puras do mundo UNIX:

1. Baseado no **Almquist Shell (ash)** de Kenneth Almquist, mas extensivamente modernizado ao longo de 30 anos.
2. Possui aritmética interna de 64 bits, controle avançado de jobs e suporte completo a expansão de parâmetros POSIX.
3. É extremamente rápido e leve, servindo como o interpretador de inicialização de todo o sistema operacional em dezenas de arquiteturas de hardware (de x86_64 e ARM a VAX, SPARC e m68k).

---

## 3. Gestão de Pacotes com `pkgsrc` e `pkgin`

O ecossistema de software de terceiros no NetBSD gira em torno do **`pkgsrc`**:

1. **`pkgsrc`:** O sistema de compilação a partir dos fontes mais portável do mundo UNIX (roda em NetBSD, Linux, macOS, Solaris, Illumos e BSDs).
2. **`pkgin`:** O gerenciador binário de pacotes (equivalente ao `apt` ou `pkg`):
   ```sh
   pkgin update
   pkgin install <pacote>
   pkgin upgrade
   ```
3. **Caminho Canônico de Binários:** Pacotes instalados via `pkgsrc` residem tradicionalmente em `/usr/pkg/bin` e `/usr/pkg/sbin`.
   - **Regra:** Em ambientes NetBSD, `/usr/pkg/bin` deve ser inserido no topo do `$PATH` usando `path-front`.

---

## 4. Console WSCONS e Terminais

- O console de texto do NetBSD é gerenciado pelo driver **WSCONS** (`/dev/ttyE0` a `/dev/ttyE7`, `$TERM=wvt25` ou `vt100`).
- Ao operar no console puro (`_is_raw_tty`), o NetBSD requer a mesma disciplina de fallback ASCII simples observada no FreeBSD para evitar glifos quebrados.
