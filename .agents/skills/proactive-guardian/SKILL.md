---
name: proactive-guardian
description: >-
  Proactive code health guardian and autonomous quality enforcement.
  Use to continuously audit code against the 18 UNIX Principles, Clean Code rules,
  defensive guards, naming taxonomies, and actively suggest or apply fixes.
---

# Proactive Guardian — Autonomous Code Health & Quality Enforcement

Esta skill define as diretrizes operacionais para atuação **proativa** de qualidade no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

O agente nunca deve agir de forma passiva diante de violações de princípios, más práticas de shell script ou código legado inconsistente. Se um desvio for detectado, o agente deve assumir a responsabilidade de auditar, propor e corrigir.

---

## 1. Filosofia de Ação Proativa

1. **Ação Direta no Escopo da Tarefa:**
   - Se o arquivo que você está editando contém violações das regras do [PRINCIPLES.md](file:///usr/local/share/shell/PRINCIPLES.md) (como redirecionamento sem aspas, `printf` arcaico, falta de `[ -t 1 ]` ou wrapper gêmeo redundante), **corrija imediatamente de forma limpa** no mesmo ciclo, sem precisar que o usuário aponte.
2. **Sugestão Construtiva Fora do Escopo Direto:**
   - Se identificar inconformidades em arquivos adjacentes ou na arquitetura durante a análise, informe proativamente o usuário:
     - Aponte o arquivo e a linha exata.
     - Explique qual princípio ou regra do projeto foi violado.
     - Demonstre o diff ou a solução recomendada.

---

## 2. Checklist de Auditoria Proativa Contínua

Sempre que ler, editar ou inspecionar qualquer script `.sh`, valide silenciosamente os seguintes invariantes:

### A. Quoting e Segurança
- [ ] **Redirecionamentos Nulos:** Todo redirecionamento para `dev/null` DEVE ter aspas: `> "/dev/null"` e `2> "/dev/null"`. Redirecionamentos crus `> /dev/null` devem ser corrigidos imediatamente.
- [ ] **Variáveis Protegidas:** Expansões de variáveis devem estar entre aspas duplas: `"${VAR}"`.
- [ ] **Shebang Canônico:** Todo script executável de entrada deve usar `#!/usr/bin/env sh`.

### B. Manipulação de Terminal e Cursor
- [ ] **Guarda `[ -t 1 ]`:** Toda emissão de controle de cursor (ex: `echo -n $'\e[0 q'`) ou manipulação de tela interativa deve verificar se o descritor 1 é um TTY interativo (`[ -t 1 ]`).
- [ ] **Adoção Universal de `$'\e...'` e `echo -n`:** Substituir imediatamente `printf '\033...'` críptico por `echo -n $'\e...'` para sequências de controle de tela (como `clear`).

### C. Prompts e Largura de Coluna (libedit / readline)
- [ ] **Delimitadores `\[` e `\]`:** Em prompts de `sh` ([theme/sh.sh](file:///usr/local/share/shell/theme/sh.sh)) e `bash` ([theme/bash.sh](file:///usr/local/share/shell/theme/bash.sh)), todo e qualquer código ANSI DEVE estar delimitado por `\[` e `\]` (`_c_color="\[\e[1;91m\]"`).
- [ ] Prompts sem `\[` e `\]` provocam quebra de cálculo de colunas no `libedit` do FreeBSD, causando sobreposição de linhas e cursor deslocado. Corrija na hora.

### D. Taxonomia Estrita de Nomenclatura & Clean Code
- [ ] **Funções Públicas:** Nomes em `kebab-case` (`open-helix`, `path-front`, `update-all`).
- [ ] **Funções Privadas e Variáveis Locais:** Nomes em `_snake_case` com prefixo `_` (`_as_root`, `_detect_os`, `_pwd`).
- [ ] **Sem Funções Gêmeas:** Nunca permita funções duplicadas (como criar um helper privado `_foo` só para chamar um alias/função pública `foo` sem lógica adicional). Declare a função pública diretamente.
### E. Comentários Estruturais & Regra do Não-Vazamento
- [ ] **Sem Comentários Inline:** O código deve ser autoexplicativo. Comentários explicativos triviais inline são proibidos e devem ser removidos.
- [ ] **Padrão Canônico (32 `=` ou `-`):** Seções principais devem usar `### ================================` e subseções `### --------------------------------`.
- [ ] **Regra do Não-Vazamento:** O título interno DEVE ter no máximo 32 caracteres e JAMAIS vazar além da régua divisora.
- [ ] **Não-Enumeração Arbitrária:** Títulos de seções não devem ser numerados (evitar '1.', '2.'), a menos que a ordem numérica seja intrínseca à identidade do conceito.
- [ ] **Sem Separadores Ad-Hoc:** Eliminar `echo "=== ... ==="` em scripts de CI/CD ou instaladores, convertendo-os para o padrão estrutural limpo.

---

## 3. Fluxo de Entrega com Qualidade

Antes de dar uma resposta como concluída após aplicar melhorias:
1. Execute `git diff --check` (deve ter 0 erros).
2. Execute `./.githooks/pre-commit` (deve passar 100%).
3. Mantenha os princípios do repositório como a mais alta autoridade de código.
