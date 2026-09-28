# 🔍 A Anatomia do Parser de Identificadores: Por que `kebab-case` Falha em Sh Rígidos

> Análise formal da gramática de nomes de funções entre interpretadores de shell.

---

A convenção pública deste repositório utiliza `kebab-case` para funções utilitárias (`path-front`, `mount-device`, `update-all`). O comportamento deriva da gramática formal:

| Interpretador                      | Comportamento com Hífen (`f-f()`) | Mecanismo Interno no Código C Upstream                                                          |
| :--------------------------------- | :-------------------------------- | :---------------------------------------------------------------------------------------------- |
| **FreeBSD `/bin/sh`**              | **Suportado com perfeição** ✅    | `bin/sh/parser.c`: a tokenização de nomes de função aceita `-` como extensão deliberada.        |
| **GNU Bash**                       | **Suportado** ✅                  | `parser.y`: nomes de função aceitam `-` exceto quando ativado o modo POSIX estrito.             |
| **Zsh**                            | **Suportado com perfeição** ✅    | Zsh trata nomes de funções com máxima flexibilidade por padrão.                                 |
| **OpenBSD `/bin/ksh` (pdksh)**     | **Suportado com perfeição** ✅    | `bin/ksh/syn.c`: parser aceita `-` em nomes de função; alvo interativo em `target/openbsd/ksh`. |
| **Dash (Debian/Ubuntu `/bin/sh`)** | **Falha fatal** ❌ (`exit 2`)     | `src/parser.c:goodname()`: rejeita `-` com `Syntax error: Bad function name`.                   |
| **macOS `/bin/sh`**                | **Falha fatal** ❌ (`exit 2`)     | Bash 3.2 invocado como `sh` liga `posixly_correct`; `legal_identifier()` rejeita `-`.           |
| **`bash --posix`**                 | **Falha fatal** ❌ (`exit 2`)     | Ativação de `posixly_correct = 1` no Bash força identificador legal POSIX (sem `-`).            |
| **NetBSD `/bin/sh`**               | **Falha fatal** ❌ (`exit 2`)     | `bin/sh/parser.c:goodname()`: valida estritamente `[a-zA-Z0-9_]`.                               |
| **illumos `/bin/sh` (ksh93)**      | **Falha fatal** ❌ (`exit 3`)     | Parser do AT&T ksh93 rejeita hífens com `invalid function name`.                                |

### Decisão de Engenharia:

Não renomeamos as funções públicas para acomodar shells de script não-interativos. Em vez disso, preservamos a clareza e elegância do `kebab-case` e declaramos formalmente os alvos suportados: **FreeBSD `/bin/sh`** e **OpenBSD `/bin/ksh`** como alvos nativos de sistema exclusivos, e **`bash`** e **`zsh`** universalmente. Em outros SOs, os usuários operam sob `bash` ou `zsh`.
