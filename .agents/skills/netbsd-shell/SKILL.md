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
4. **Shell Estritamente Não-Interativo no Ecossistema:**
    - A função `goodname()` em `bin/sh/parser.c` valida identificadores com rigor estrito `[a-zA-Z0-9_]`, rejeitando funções com hífen (`kebab-case`).
    - Por essa razão, o NetBSD **não possui alvo `target/netbsd/sh`** e não avalia `sh` em benchmarks. Os alvos interativos suportados para NetBSD são **estritamente `bash` e `zsh`**.

---

## 3. Gestão de Pacotes com `pkgsrc`, `pkgin` e `pkg_add`

O ecossistema de software de terceiros no NetBSD gira em torno do **`pkgsrc`**:

1. **`pkgsrc`:** O sistema de compilação a partir dos fontes mais portável do mundo UNIX (roda em NetBSD, Linux, macOS, Solaris, illumos e BSDs).
2. **`pkg_add` vs. `pkgin` em Ambientes Base & CI:**
    - O utilitário nativo embutido no sistema base para manipulação direta de pacotes binários compactados (`.tgz`) é o **`pkg_add`** (`/usr/sbin/pkg_add`).
    - Em imagens mínimas de VMs e instâncias de CI, o `pkgin` frequentemente não vem instalado por padrão. Portanto, a automação canônica deve checar e priorizar `pkg_add -I` com fallback para `pkgin`:
    ```sh
    if command -v pkg_add > "/dev/null" 2>&1; then
        pkg_add -I zsh bash python312
    elif command -v pkgin > "/dev/null" 2>&1; then
        pkgin -y install zsh bash python312
    fi
    ```
3. **Nomenclatura de Pacotes no pkgsrc (O Caso do Python):**
    - No `pkgsrc`, interpretadores Python não usam nomes genéricos como `python3`. Eles são versionados estritamente na forma `python312`, `python311`, `python313`, etc.
    - Nos repositórios binários oficiais pré-compilados do NetBSD (`cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/x86_64/10.0/All/`), o pacote estável padrão é o **`python312-3.12.x.tgz`**. Versões experimentais como 3.14 existem no código-fonte do pkgsrc (`lang/python314`), mas pacotes binários prontos seguem o ciclo de releases estáveis.
4. **Caminho Canônico de Binários & Symlinks:**
    - Binários do `pkgsrc` residem estritamente em `/usr/pkg/bin` e `/usr/pkg/sbin`.
    - Ao instalar `python312`, o binário gerado é `/usr/pkg/bin/python3.12`. Para compatibilidade com scripts agnósticos que buscam `python3`, deve-se criar o symlink:
    ```sh
    [ -x "/usr/pkg/bin/python3.12" ] && [ ! -x "/usr/pkg/bin/python3" ] && \
        ln -sf /usr/pkg/bin/python3.12 /usr/pkg/bin/python3
    ```
    - **Regra:** `/usr/pkg/bin` deve ser sempre inserido no topo do `$PATH` usando `path-front`.

---

## 4. Console WSCONS e Terminais

- O console de texto do NetBSD é gerenciado pelo driver **WSCONS** (`/dev/ttyE0` a `/dev/ttyE7`, `$TERM=wvt25` ou `vt100`).
- Ao operar no console puro (`_is_raw_tty`), o NetBSD requer a mesma disciplina de fallback ASCII simples observada no FreeBSD para evitar glifos quebrados.

---

## 🔗 Links Oficiais de Referência & Obras Recomendadas

- **The NetBSD Project:** <https://www.netbsd.org/> | Documentação: <https://www.netbsd.org/docs/>
- **NetBSD Manual Pages:**
    - `sh(1)`: <https://man.netbsd.org/sh.1>
    - `editline(3)`: <https://man.netbsd.org/editline.3>
- **The NetBSD Packages Collection (pkgsrc):** <https://www.pkgsrc.org/> | Pkgin: <https://pkgin.net/>
- **NetBSD pkgsrc Package Search:** <https://pkgsrc.se/> | pkgsrc Current: <https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc/>
- **Literatura Técnica:**
    - _The Design and Implementation of the 4.4BSD Operating System_ (Marshall Kirk McKusick, Keith Bostic, Michael J. Karels & John S. Quarterman, 1996, Addison-Wesley).
    - _The Art of UNIX Programming_ (Eric S. Raymond, 2003, Addison-Wesley).
