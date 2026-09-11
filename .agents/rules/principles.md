# Universal Shell — Engineering Rules & Constraints

Essas diretrizes são de aplicação obrigatória para qualquer modificação ou extensão neste repositório (`/usr/local/share/shell`).

> 🏛️ **Hub Orquestrador:** Este repositório faz parte do [Quarteto de Produtividade](https://github.com/GabrielFrigo4/environment), orquestrado pelo repositório **Environment**. Consulte o `ENVIRONMENT.md` e `PRINCIPLES.md` canônicos na raiz do Environment para a arquitetura completa.

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

## 4. Estrutura de Arquivos & Arquitetura de Comentários (Regra do Não-Vazamento)

- **Zero Comentários Narrativos:** O código deve ser autoexplicativo (Princípio do Silêncio). Comentários explicativos inline são expressamente proibidos em scripts, templates e documentações. Separe blocos lógicos exclusivamente por linhas em branco.
- **Camada 1 (Header Banner):** Exclusivo para linhas 2 a 4 de scripts utilitários (`install.sh`, etc.), delimitado por 64 hífens (`# ----------------------------------------------------------------`).
- **Camada 2 (Delimitadores Estruturais de Corpo):**
    - **Módulo / Seção Principal (32 `=`):**
        ```sh
        ### ================================
        ### NOME DO MODULO OU CONTEXTO
        ### ================================
        ```
        Arquivos de contexto usam a terminação da plataforma sem parênteses: `COMMON`, `LINUX`, `FREEBSD`, `WINDOWS`.
    - **Subseções Internas (32 `-`):**
        ```sh
        ### --------------------------------
        ### Nome da Secao
        ### --------------------------------
        ```
- **Regra Estrita do Não-Vazamento:** A régua divisora tem exatamente 32 caracteres separadores (total de 36 colunas com `### `). O texto do título DEVE ser conciso e **JAMAIS vazar além da régua** (máximo de 32 caracteres).
- **Sem Parênteses ou Anotações Redundantes:** O título deve ser limpo e sem anotações secundárias entre parênteses (ex: prefira `### Default Editor` a `### Default Editor (Cascade)` e `### Update Vault` a `### Update Vault (update-vault)`).
- **Não-Enumeração de Títulos:** Evite numerar títulos de seções. Use títulos puramente semânticos.
- **Sem Comentários Ad-Hoc no CI/CD:** Scripts de CI/CD devem usar esses mesmos blocos, sendo vedado o uso de `echo "=== ... ==="` ou separadores improvisados.

## 5. Padrão Universal de READMEs

- **README Raiz:** Portal institucional com título e emoji, blockquote de missão, badges do Quarteto de Produtividade, sistemas suportados, catálogo de primeiro nível e instruções de auditoria/CI.
- **README de Subpastas:** Catálogo tabular obrigatório (`| Arquivo / Receita | Descrição | Plataforma |`) e bloco de execução limpo sem comentários inline.

## 6. Qualidade de Código & Quoting

- Redirecionamentos para `/dev/null` sempre devem ser protegidos por aspas: `> "/dev/null"` e `2> "/dev/null"`.
- Variáveis sempre entre aspas duplas: `"${VAR}"`.
- Scripts executáveis devem usar shebang `#!/usr/bin/env sh`.
- Comandos `chmod` usam 4 dígitos octais: `chmod 0755` e `chmod 0644`.

## 7. Heredocs Indentados, Emissão e Guards Interativos

- **Heredocs Indentados (`cat <<- 'EOF'`):** Em blocos multilinhas e geradores de templates, use SEMPRE `cat <<- 'EOF'`. O hífen `<<-` descarta TABs iniciais (`\t`) das linhas de texto e do próprio delimitador `EOF`, permitindo que o heredoc permaneça perfeitamente alinhado com a indentação da função/condicional circundante sem vazar para a coluna zero. Se não houver interpolação intencional de variáveis, envolva o delimitador entre aspas simples (`'EOF'`).
- **Taxonomia de Emissão:**
    - `echo`: Para linhas simples de texto e escrita atômica em arquivos (`echo "${val}" >| "${file}"`).
    - `echo -n $'\e...'`: Padrão canônico e preferido para sequências ANSI em terminais interativos (`[ -t 1 ]`).
    - `printf`: Exclusivo para relatórios com tabelas e colunas alinhadas com padding (`%-12s %-24s`).
- **Guarda de Interatividade (`INTERACTIVE GUARD`):** Todo arquivo gerado (`.bashrc`, `.zshrc`, `.shrc`) DEVE iniciar com:
    ```sh
    ### ================================
    ### INTERACTIVE GUARD
    ### ================================
    case "$-" in
        *i*) ;;
        *) return ;;
    esac
    ```
    Isso impede que conexões não-interativas (`scp`, `sftp`, `rsync`, Git) quebrem ao receber sequências ANSI ou saídas de terminal.
- **Auto-Correção Eficiente de `$SHELL`:** Em shells aninhados (ex: abrir `bash` a partir do `zsh`), auto-corrija `$SHELL` usando checagem por casamento de padrão em memória:
    ```sh
    _current_sh="${_DETECTED_SHELL:-$(_detect_shell)}"
    case "${SHELL:-}" in
        *"/${_current_sh}") ;;
        *) export SHELL="$(command -v "${_current_sh}" 2> "/dev/null")" ;;
    esac
    unset _current_sh
    ```
- **Invocação pelo Shell Ativo (Active Shell Invocation):** Ao invocar sub-rotinas e instaladores (`install.sh`, `benchmark.sh`) dentro de funções do shell, utilize sempre o executável do shell ativo seguindo a cascata de preferência: `command -v "$(_detect_shell)" || command -v zsh || command -v bash || command -v sh`, NUNCA `sh` cego. No topo de scripts utilitários em Linux, mantenha guard de auto-elevação para `zsh`/`bash` se iniciado sob `/bin/sh` (`dash`).

## 8. Checklist de Validação

Antes de finalizar qualquer alteração:

1. `git diff --check` (deve retornar 0 erros).
2. `./.githooks/pre-commit` (deve passar 100%).
3. Matriz Multi-Shell:
    - Linux: `bash -n` e `zsh -n`.
    - FreeBSD: `sh -n`, `bash -n` e `zsh -n`.
    - macOS: `bash -n` e `zsh -n`.
    - Windows (MSYS2): `bash -n` e `zsh -n`.
