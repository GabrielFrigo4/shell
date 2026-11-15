# Universal Shell — Engineering Rules & Constraints

Essas diretrizes são de aplicação obrigatória para qualquer modificação ou extensão neste repositório (`/usr/local/share/shell`).

> 🏛️ **Hub Orquestrador:** Este repositório faz parte do [Quarteto de Produtividade](https://github.com/GabrielFrigo4/environment), orquestrado pelo repositório **Environment**. Consulte o `ENVIRONMENT.md` e `PRINCIPLES.md` canônicos na raiz do Environment para a arquitetura completa.

## 0. O Triângulo Dourado: Estabilidade, Eficiência e Conveniência

Toda alteração de código, adição de alias, refatoração ou otimização no repositório DEVE preservar rigorosamente o equilíbrio entre os três pilares do projeto:

1. **🛡️ Estabilidade:** Imunidade a regressões e corner cases. Proibido persistir tipo ou estado de shell em disco compartilhado (`cache.env`) que possa quebrar processos aninhados (`zsh -> bash -> ksh -> sh`). Resiliência em Raw TTYs, rigor `noclobber` e total ausência de efeitos colaterais.
2. **⚡ Eficiência:** Boot sub-20ms. Proibido invocar processos ou subshells desnecessários no caminho crítico (`id -un`, `which`, `expr`). Otimização agressiva de buffers e renderizações.
3. **✨ Conveniência:** Experiência moderna, fluida e ergonômica (autocompletion visual por menu com seleção Tab/setas, busca reversa por histórico, dark mode e orquestrador unificado `update-all`). Nenhuma otimização deve degradar a usabilidade interativa.

---

## 1. Linha de Base de Portabilidade & Alvos Exclusivos (`sh` e `ksh`)

- O shell nativo do FreeBSD (`sh`) é a régua máxima e baseline de portabilidade para scripts compartilhados em `library/`, `core/` e `install.sh`.
- **Exclusividade e Não-Coexistência:** Nos targets interativos (`target/`), o alvo `sh` existe exclusivamente para o FreeBSD e o alvo `ksh` exclusivamente para o OpenBSD (`ksh` e `sh` nunca coexistem no mesmo SO). Todos os demais sistemas suportam estritamente `zsh` e `bash` como alvos POSIX/Bourne interativos, além do **Fish** (`target/common/fish/`) como runtime modular multiplataforma e dos shells estendidos do Windows (`pwsh`, `nu`, `cmd`). Interpretadores incompatíveis como `dash` e NetBSD `sh` são excluídos de alvos interativos.
- **Política Canônica de Escapes ANSI (`$'\e'` e Fallback `printf '\x1b'`):**
    - O formato `$'\e...'` (`echo -n $'\e...'`) é o padrão primário adotado em Bash, Zsh e FreeBSD `sh`.
    - Para OpenBSD `ksh` (`pdksh`) e `Makefile` (onde `$'\e'` não é garantido), adote `printf '\x1b...'` como fallback POSIX portátil em notação hexadecimal (`_esc=$'\e'; [ "${#_esc}" -ne 1 ] && _esc="$(printf '\x1b')"`).
    - **Proibição Absoluta de Octais:** É estritamente vedado o uso de escapes octais em código, scripts, Makefiles ou documentações; utilize exclusivamente `$'\e'` ou notação hexadecimal `\x1b`.
- **Delimitadores de Largura Zero em Prompts:** No FreeBSD `sh` (`libedit`) e no Bash (`readline`), códigos ANSI dentro de `PS1` DEVEM estar entre `\[` e `\]` (ex: `_color_red="\[\e[1;91m\]"`). No Zsh, utilize `%{...%}`. No OpenBSD `ksh` (`pdksh`), delimite bytes invisíveis com `\x01` (`printf '\x01'`). Sem esses delimitadores, o editor de linha conta bytes ANSI como colunas visíveis, quebrando o cálculo de linhas e o cursor.
- Recursos específicos do Zsh, Bash e Fish permanecem estritamente isolados em `zsh/`, `bash/` e `target/common/fish/`.

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

- **`kebab-case` (público):** Comandos destinados ao uso interativo (`mount-device`, `update-all`, `open-helix`, `path-front`). Suportados por Zsh, Bash e FreeBSD `sh`. Definidos diretamente, sem wrappers redundantes. Interpretadores que rejeitam hífen em funções por rigidez POSIX (como `dash`) não são alvo de execução deste repositório.
- **`_snake_case` (privado):** Funções internas de bootstrapping e variáveis locais temporárias (`_as_root`, `_detect_os`, `_pwd`). Mantém o autocompletion limpo.
- **`SNAKE_CASE` (maiúsculo):** Constantes e variáveis de ambiente globais (`PATH`, `SHELL_REPO_DIR`, `SHELL_CONTEXT`).
- **Nomenclatura Expressiva & Proibição de Abreviações Crípticas:** Variáveis e funções internas DEVEM ser descritivas e autoexplicativas (`_user_color`, `_prompt_symbol`, `_indicator`, `_delimiter`, `_target_length`, `_remaining_string`, `_module`, `_editor`, `_file`). Evite o uso de abreviações crípticas de uma ou duas letras para conceitos comuns (`_c` para cor, `_u` para usuário, `_ind`, `_sym`, `_del`, `_b`, `_f`, `_ed`, `_mod`).
- **Exceções Técnicas Formais:** Termos que representam formalmente entidades da ciência da computação são plenamente aceitos (ex: a linguagem `C` em buffers como `_calc_c_len` e `_c_bytes` que interagem com o parser C do FreeBSD `sh`, além de acrônimos canônicos de sistemas e redes como `_os`, `_ip`, `_pid`, `_ppid`).

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
        ### NOME DA SECAO
        ### --------------------------------
        ```
- **Regra Estrita do Não-Vazamento:** A régua divisora tem exatamente 32 caracteres separadores (total de 36 colunas com `### `). O texto do título DEVE ser escrito em **MAIÚSCULAS**, ser conciso e **JAMAIS vazar além da régua** (máximo de 32 caracteres após `### `).
- **Sem Parênteses ou Anotações Redundantes:** O título deve ser limpo e sem anotações secundárias entre parênteses (ex: prefira `### DEFAULT EDITOR` a `### DEFAULT EDITOR (CASCADE)` e `### UPDATE VAULT` a `### UPDATE VAULT (UPDATE-VAULT)`).
- **Não-Enumeração de Títulos:** Evite numerar títulos de seções. Use títulos puramente semânticos.
- **Sem Comentários Ad-Hoc no CI/CD:** Scripts de CI/CD devem usar esses mesmos blocos, sendo vedado o uso de `echo "=== ... ==="` ou separadores improvisados.

## 5. Padrão Universal de READMEs

- **README Raiz:** Portal institucional com título e emoji, blockquote de missão, badges do Quarteto de Produtividade, sistemas suportados, catálogo de primeiro nível e instruções de auditoria/CI.
- **README de Subpastas:** Catálogo tabular obrigatório (`| Arquivo / Receita | Descrição | Plataforma |`) e bloco de execução limpo sem comentários inline.

## 6. Qualidade de Código, Quoting & Regra `4a` de Permissões

- Redirecionamentos para `/dev/null` sempre devem ser protegidos por aspas: `> "/dev/null"` e `2> "/dev/null"`.
- Variáveis sempre entre aspas duplas: `"${VAR}"`.
- Scripts executáveis devem usar shebang `#!/usr/bin/env sh`.
- **Regra `4a` (Permissões Octais Canônicas no Git Index e Filesystem):**
    - **`0755` (`--chmod=+x`) SOMENTE para entrypoints executáveis com shebang:** `.githooks/*`, `shell.sh`, `init.sh`, `install.sh`, `benchmark.sh` e utilitários em `.scripts/*` que iniciem com `#!` (como `.scripts/emacs-client`).
    - **`0644` (`--chmod=-x`) para todas as bibliotecas sourced e arquivos de configuração/documentação:** `core/`, `library/`, `context/`, `target/`, `theme/`, além de `.md`, `.fish`, `.nu`, `.ps1`, `.cmd`, `.reg`, `.lua`, `.yml`, `.json`, `.toml` e arquivos de governança.
- **Carregamento Lazy de `desktop-*.sh` & `--userland=gnu` Antifrágil:**
    - Os módulos `library/desktop-*.sh` (`desktop-device.sh`, `desktop-kiosk.sh`, `desktop-session.sh`) são carregados condicionalmente apenas quando `SHELL_CONTEXT="desktop"` (zero overhead em `server` e `container`), e `desktop-kiosk.sh` carrega `desktop-session.sh` sob demanda via `_kiosk_ensure_session`.
    - O modo `--userland=gnu` (`install.sh --userland [default|gnu|bsd]` e função `userland` em `core/environment.sh`) é estritamente opt-in e antifrágil: nos modos `default` e `bsd`, diretórios `gnubin` nunca poluem a frente do `$PATH` (no illumos, `/usr/gnu/bin` permanece ao final via `path-back`), sendo promovidos e cacheados em `${XDG_CACHE_HOME:-${HOME}/.cache}/shell/gnu_aliases_<os>.sh` somente quando `gnu` é explicitamente ativado.

## 7. Heredocs Indentados, Emissão e Guards Interativos

- **Heredocs Indentados (`cat <<- 'EOF'`):** Em blocos multilinhas e geradores de templates, use SEMPRE `cat <<- 'EOF'`. O hífen `<<-` descarta TABs iniciais (`\t`) das linhas de texto e do próprio delimitador `EOF`, permitindo que o heredoc permaneça perfeitamente alinhado com a indentação da função/condicional circundante sem vazar para a coluna zero. Se não houver interpolação intencional de variáveis, envolva o delimitador entre aspas simples (`'EOF'`).
- **Taxonomia de Emissão:**
    - `echo`: Para linhas simples de texto e escrita atômica em arquivos (`echo "${val}" >| "${file}"`).
    - `echo -n $'\e...'`: Padrão primário em Bash, Zsh e FreeBSD `sh` para sequências ANSI em terminais interativos (`[ -t 1 ]`), usando `printf '\x1b...'` como fallback POSIX portátil para OpenBSD `ksh` (`pdksh`) e `Makefile`.
    - `printf`: Exclusivo para relatórios com tabelas, alinhamento com padding (`%-12s %-24s`) e escapes hexadecimais portáteis (`\x1b`, `\x01`).
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
- **Invocação pelo Shell Ativo (Active Shell Invocation):** Ao invocar sub-rotinas e instaladores (`install.sh`, `benchmark.sh`) dentro de funções do shell, utilize sempre o executável do shell ativo seguindo a cascata de preferência: `command -v "$(_detect_shell)" || command -v zsh || command -v bash || command -v sh`, NUNCA `sh` cego. No topo de scripts utilitários em Linux, mantenha guard de auto-elevação para `zsh`/`bash` se iniciado sob `sh` (`dash`).

## 8. Ordem Canônica de Prevalência e Enumeração de Shells

Em qualquer enumeração, pipeline de CI/CD, script de benchmark, Makefile ou documentação, a ordem DEVE SEMPRE respeitar a hierarquia canônica de ergonomia e arquitetura:

1. **`zsh`** (topo da cadeia de ergonomia, autocompletion por menu e produtividade interativa)
2. **`bash`** (padrão corporativo universal e compatibilidade retroativa)
3. **`sh`** (FreeBSD `sh` como base system exclusivo) ou **`ksh`** (OpenBSD `/bin/ksh` como base system exclusivo)
4. **`fish`** (`target/common/fish/`, runtime modular multiplataforma via `config.fish`, `ui.fish`, `prompt.fish`, `aliases.fish`)

## 9. Checklist de Validação

Antes de finalizar qualquer alteração:

1. `git diff --check` (deve retornar 0 erros).
2. `git ls-files --stage` (Regra `4a`: `100755` apenas para entrypoints com `#!`; `100644` para libs sourced e configs).
3. `./.githooks/pre-commit` (deve passar 100%).
4. Matriz Multi-Shell (sempre na ordem `zsh` -> `bash` -> `sh`/`ksh` -> `fish`):
    - Linux, NetBSD, macOS, Windows (MSYS2), illumos: `zsh -n` e `bash -n` (mais `fish -n target/common/fish/*.fish` quando disponível).
    - FreeBSD: `zsh -n`, `bash -n` e `sh -n`.
    - OpenBSD: `zsh -n`, `bash -n` e `ksh -n`.
    - Entrypoints POSIX (`sh -n`): `shell.sh`, `init.sh`, `install.sh`, `benchmark.sh`, `.scripts/emacs-client`, `.githooks/pre-commit`, `.githooks/commit-msg`.
