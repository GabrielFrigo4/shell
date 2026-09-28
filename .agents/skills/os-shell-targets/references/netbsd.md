# ⚡ NetBSD Shell — Origens da Libedit & Almquist Shell

No ecossistema NetBSD, os alvos interativos suportados são **estritamente `bash` e `zsh`**. Não existe alvo `target/netbsd/sh`.

---

## 🏛️ O Berço Histórico da `libedit` (EditLine)

1. Criada por Christos Zoulas no NetBSD na década de 1990 como alternativa BSD pura à GNU Readline.
2. Todo o código que roda hoje no FreeBSD e macOS provém da árvore de fontes do NetBSD.
3. Tratamento de literais (`literal.c`) e `EL_PROMPT_ESC` obedecem ao padrão NetBSD.

---

## 🐚 O `/bin/sh` Almquist Estrito

- Implementação do Almquist Shell (ash) extensivamente modernizada e rápida.
- A função `goodname()` em `bin/sh/parser.c` valida identificadores com regex estrito `[a-zA-Z0-9_]`, rejeitando hífens (`kebab-case`).
- Por essa razão, é mantido estritamente como shell de boot e scripts, sem alvo interativo.

---

## 📦 Gestão de Pacotes com `pkgsrc` & `pkg_add`

- **`pkg_add` Nativo:** Utilitário base para pacotes `.tgz` (`pkg_add -u <pacote>`).
- **Nomenclatura com Versão:** No `pkgsrc`, pacotes frequentemente incluem a versão no nome (ex: `python312`).
- **Caminho Canônico:** Binários residem em `/usr/pkg/bin` e `/usr/pkg/sbin`. Devem ser adicionados ao `PATH` via `path-front "/usr/pkg/bin"`.
- **Console WSCONS:** O driver de console `WSCONS` opera sob `$TERM=wvt25` e requer o fallback ASCII puro quando em `_is_raw_tty`.
