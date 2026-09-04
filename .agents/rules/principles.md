# Universal Shell — Engineering Rules & Constraints

Essas diretrizes são de aplicação obrigatória para qualquer modificação ou extensão neste repositório (`/usr/local/share/shell`).

## 1. Linha de Base de Portabilidade (FreeBSD `/bin/sh`) & Sequências de Escape
- O shell nativo do FreeBSD (`/bin/sh`) é a régua máxima e baseline de portabilidade para scripts compartilhados em `library/`, `core/` e `install.sh`.
- **Adoção Universal de `$'\e...'` e `echo -n`:** O formato `echo -n $'\e...'` é suportado em todos os shells do ecossistema (FreeBSD `/bin/sh`, Zsh, Bash e até no Dash moderno, além de formalizado no POSIX Issue 8). É o padrão canônico preferido para sequências de controle de terminal (`alias clear="echo -n $'\e[2J\e[3J\e[H'"`), eliminando a necessidade de notação críptica em octal (`\033`) do `printf`.
- **Delimitadores de Largura Zero em Prompts (`\[...\]`):** No FreeBSD `/bin/sh` (`libedit`) e no Bash (`readline`), códigos ANSI dentro de `PS1` DEVEM estar entre `\[` e `\]` (ex: `_c_red="\[\e[1;91m\]"`). Sem isso, o editor conta bytes ANSI como colunas visíveis, quebrando o cálculo de linhas e o cursor.
- Recursos do Zsh e Bash permanecem estritamente em `zsh/` e `bash/`.

## 2. Programação Defensiva Obrigatória
- NUNCA defina um alias ou wrapper de ferramenta externa sem antes verificar se o executável existe:
  ```sh
  command -v <bin> > "/dev/null" 2>&1 && alias <nome>="<bin>"
  ```
- Sempre proteja chamadas de manipulação do terminal ou cursor (`echo -n $'\e[0 q'`) verificando se o descritor 1 é um TTY:
  ```sh
  [ -t 1 ] && echo -n $'\e[0 q'
  ```

## 3. Convenção Estrita de Nomenclatura
- **`kebab-case` (público):** Comandos destinados ao uso interativo (`mount-device`, `update-all`, `open-helix`, `path-front`). Suportados pelo FreeBSD `/bin/sh`, Bash e Zsh. Definidos diretamente, sem wrappers redundantes. Interpretadores que rejeitam hífen em funções por rigidez POSIX (como `dash`) não são alvo de execução deste repositório.
- **`_snake_case` (privado):** Funções internas de bootstrapping e variáveis locais temporárias (`_as_root`, `_detect_os`, `_pwd`). Mantém o autocompletion limpo.
- **`SNAKE_CASE` (maiúsculo):** Constantes e variáveis de ambiente globais (`PATH`, `SHELL_REPO_DIR`, `SHELL_CONTEXT`).

## 4. Estrutura de Arquivos, Comentários & Regra do Não-Vazamento
- **Único Tipo de Comentário Permitido:** O código deve ser autoexplicativo (Princípio do Silêncio). Comentários explicativos inline são expressamente proibidos. Apenas blocos delimitadores estruturais são tolerados.
- **Cabeçalho de Módulo / Seção Principal (32 `=`):**
  ```sh
  ### ================================
  ### NOME DO MODULO (ESPECIFICADOR)
  ### ================================
  ```
  Arquivos de contexto devem conter a tag da plataforma: `(COMMON)`, `(LINUX)`, `(FREEBSD)`, `(WINDOWS)`.
- **Subseções Internas (32 `-`):**
  ```sh
  ### --------------------------------
  ### Nome da Secao
  ### --------------------------------
  ```
- **Regra Estrita do Não-Vazamento:** A régua divisora tem exatamente 32 caracteres separadores (total de 36 colunas com `### `). O texto do título DEVE ser conciso e **JAMAIS vazar além da régua** (máximo de 32 caracteres).
- **Não-Enumeração de Títulos:** Evite numerar títulos de seções (`1. Passo`, `2. Passo`). Numeração só é tolerada se for intrínseca à identidade ou dependência do conceito; caso contrário, use títulos puramente semânticos.
- **Sem Comentários Ad-Hoc no CI/CD:** Scripts embutidos no CI/CD devem usar esses mesmos blocos, sendo vedado o uso de `echo "=== ... ==="` ou separadores improvisados.
- Não adicione anotações operacionais como `(Defensive)` nos comentários principais.

## 5. Qualidade de Código & Quoting
- Redirecionamentos para `/dev/null` sempre devem ser protegidos por aspas: `> "/dev/null"` e `2> "/dev/null"`.
- Variáveis sempre entre aspas duplas: `"${VAR}"`.
- Scripts executáveis devem usar shebang `#!/usr/bin/env sh`.
- Comandos `chmod` usam 4 dígitos octais: `chmod 0755` e `chmod 0644`.

## 6. Checklist de Validação
Antes de finalizar qualquer alteração:
1. `git diff --check` (deve retornar 0 erros).
2. `./.githooks/pre-commit` (deve passar 100%).
3. Matriz Multi-Shell:
   - Linux: `bash -n` e `zsh -n`.
   - FreeBSD: `sh -n`, `bash -n` e `zsh -n`.
   - macOS: `bash -n` e `zsh -n`.
   - Windows (MSYS2): `bash -n` e `zsh -n`.
