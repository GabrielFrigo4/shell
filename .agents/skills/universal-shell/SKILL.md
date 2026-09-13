---
name: universal-shell
description: >-
  Comprehensive guide and operational runbook for extending, refactoring, and auditing the Universal Shell repository.
  Use when adding new commands, aliases, contexts, targets, or auditing shell scripts for FreeBSD /bin/sh parity,
  defensive guards, and Clean Code standards.
---

# Universal Shell — Development & Architecture Runbook

Este guia detalha o fluxo operacional para estender, refatorar e auditar o repositório **Universal Shell Environment** (`/usr/local/share/shell`), garantindo aderência rigorosa aos 18 Princípios UNIX e às regras de Clean Code.

---

## 1. Mapeamento de Camadas (Onde colocar cada código)

Antes de escrever qualquer código, posicione-o na camada correta do ciclo de vida:

| Camada         | Diretório  | Papel & Responsabilidade                                                                                                                            | Exemplos                                                             |
| :------------- | :--------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------- |
| **Biblioteca** | `library/` | Funções puras reutilizáveis, detecção de ambiente e utilitários globais. Não deve conter aliases.                                                   | `_detect_os`, `_as_root`, `path-front`, `update-all`                 |
| **Núcleo**     | `core/`    | Variáveis essenciais de ambiente, cascatas de editores/ferramentas e integração com o Vault (`vault.sh`).                                           | `editor()`, aliases universais (`u`, `l`, `g`, `c`, `f`)             |
| **Contextos**  | `context/` | Especializações por propósito da máquina (`desktop`, `server`, `container` — WSL unificado com auto-detecção). Dividido em `common.sh` e `<os>.sh`. | Editores gráficos (`open-*`), montagem móvel (`mount-device`), emacs |
| **Targets**    | `target/`  | Especializações por SO (`linux`, `freebsd`, `windows`, `openbsd`, `netbsd`, `illumos`, `macos`). Injeta variáveis e caminhos.                       | `PROMPT_OS_*`, `clear` no FreeBSD, `incus` no Linux                  |
| **Temas**      | `theme/`   | Renderização visual de prompts específicos por shell (`bash.sh`, `zsh.sh`, `sh.sh`).                                                                | Prompt de 2 linhas com Nerd Fonts, fallback TTY bruto, Git/Got       |

---

## 2. Invariantes Arquiteturais Inegociáveis

1. **Linha de Base FreeBSD `/bin/sh` & Target Exclusivo:**
   - O `/bin/sh` do FreeBSD é a referência canônica para scripts compartilhados em `library/`, `core/` e `install.sh`.
   - **Target `/bin/sh` Exclusivo:** O alvo interativo `sh` existe unicamente no FreeBSD (`target/freebsd/sh`). Todos os demais SOs possuem exclusivamente `bash` e `zsh` como alvos interativos.
   - O formato `echo -n $'\e...'` é universalmente suportado em todo o ecossistema (FreeBSD `/bin/sh`, Zsh, Bash e Dash moderno, além do padrão POSIX Issue 8).
   - Use expressamente `echo -n $'\e...'` para sequências de controle de terminal (ex: `alias clear="echo -n $'\e[2J\e[3J\e[H'"`), priorizando a clareza e legibilidade do `$'\e'` sobre o octal arcaico.

2. **Programação Defensiva em Duas Zonas (`command -v`):**
   - **Zone A (Boot-Time):** Use `command -v` no nível top-level APENAS para:
     - Exportar variáveis de ambiente (`GTK_THEME`, `EDITOR`, etc.).
     - Definir aliases de compatibilidade bidirecional (`doas` ↔ `sudo`, `paru` ↔ `yay`).
     - Cascatas canônicas de ferramentas (`eza` > `exa` > `ls`).
   - **Zone B (Runtime — Lazy Evaluation):** Para comandos operacionais do usuário (editores, utilitários, package managers), defina funções incondicionalmente e valide o binário na primeira invocação:
     ```sh
     open-editor() {
         command -v editor > "/dev/null" 2>&1 || { echo "❌ editor not found." >&2; return 127; }
         if [ "$#" -eq 0 ]; then
             command editor .
         else
             command editor "$@"
         fi
     }
     ```

3. **Proteção de Terminal (`[ -t 1 ]`):**
   - Sequências de escape ANSI que interagem com o emulador de terminal (como `echo -n $'\e[0 q'` para reset de cursor) DEVEM ser condicionadas a `[ -t 1 ]` para evitar corromper pipes e arquivos de log:
     ```sh
     [ -t 1 ] && echo -n $'\e[0 q'
     ```

4. **Taxonomia Estrita de Nomes:**
   - Funções públicas: `kebab-case` (`open-helix`, `update-wifi`, `mount-device`).
   - Helpers internos e variáveis locais: `_snake_case` (`_detect_os`, `_as_root`, `_branch`).
   - Variáveis globais de ambiente: `SNAKE_CASE` maiúsculo (`SHELL_REPO_DIR`, `SHELL_CONTEXT`).
   - Sem funções gêmeas: declare diretamente a função pública final.

5. **Delimitadores de Largura Zero em Prompts (`\[...\]` e `\e`):**
   - No FreeBSD `/bin/sh` (`libedit`) e no Bash (`readline`), códigos ANSI dentro de `PS1` DEVEM estar estritamente contidos entre `\[` e `\]` (ex: `_c_red="\[\e[1;91m\]"`).
   - Sem `\[...\]`, a `libedit` computa bytes ANSI como colunas físicas ocupadas, quebrando a contagem de quebra de linha e causando sobreposição de caracteres (`\r`) e cursor travado sobre o início do prompt.

6. **Heredocs Indentados com `cat <<- 'EOF'`:**
   - Em geradores de templates e blocos multilinhas, use SEMPRE `cat <<- 'EOF'` (ou `cat <<- EOF`).
   - O hífen `<<-` descarta TABs iniciais (`\t`) do corpo e do delimitador `EOF`, mantendo a indentação visual perfeita com o bloco circundante sem forçar texto para a coluna zero.
7. **Taxonomia de Emissão (`echo` vs `printf` vs `echo -n`):**
   - `echo`: Padrão para emissão de linhas simples de texto e escrita atômica em arquivos (`echo "${val}" >| "${file}"`).
   - `echo -n $'\e...'`: Padrão canônico e preferido para sequências ANSI em terminais interativos (`[ -t 1 ]`).
   - `printf`: Exclusivo para alinhamento de colunas e tabelas (`scripts/benchmark.sh`).
8. **Guarda de Interatividade e Auto-Correção de `$SHELL`:**
   - Todo RC gerado deve iniciar com `case "$-" in *i*) ;; *) return ;; esac`.
   - Auto-correção de `$SHELL` deve usar casamento de padrão em memória (`case "${SHELL:-}" in *"/${_current_sh}") ;; ...`).
9. **Execução pelo Shell Ativo (Active Shell Invocation):**
   - Ao disparar sub-scripts a partir de funções do shell (`install.sh`, `benchmark.sh`), execute sempre através da cascata canônica: `command -v "$(_detect_shell)" || command -v zsh || command -v bash || command -v sh`.
   - NUNCA use `sh <script>` hardcoded: em Linux, `/bin/sh` pode ser `dash`, que rejeita a taxonomia canônica `kebab-case`. Em scripts utilitários, garanta guard de auto-elevação para `zsh`/`bash` no topo.

10. **Engenharia de Performance e Boot Ultra-Rápido (< 20ms):**
   - **Zero Subshells no Boot-Time:** É expressamente vedado o uso de `find`, `sed`, `awk`, `grep`, `dd` e `ps` no carregamento interativo de qualquer shell. Cada fork de processo externo custa entre 2ms e 7ms.
   - **Globbing Nativo:** Varreduras de arquivos de configuração, temas e chaves devem usar exclusivamente loops com globbing nativo (`for _f in "${DIR}"/*/*.env; do [ -f "${_f}" ] && . "${_f}"; done`).
   - **Expansão de Parâmetros com Fallback:** Sempre utilize `${VAR:-$(fallback)}` para que a captura de saída por subshell ocorra apenas se a variável não tiver sido carregada do cache.

11. **Detecção Resiliente de Shell em Cascata (Multi-Shell):**
   - A detecção de shell ativo (`_detect_shell`) deve ser determinística, rápida (< 0.1ms) e tolerante a shells aninhados (`zsh` -> `bash` -> `zsh` -> `sh`).
   - Priorize a leitura direta de `/proc/$$/comm` (via builtin `read`, sem pipes ou subshell) e a checagem de variáveis nativas do interpretador (`$ZSH_VERSION`, `$BASH_VERSION`, `$KSH_VERSION`, `$FISH_VERSION`, `$NU_VERSION`, `$YASH_VERSION`, `$NETBSD_SHELL`).
   - **Proibição de Cache em Disco Compartilhado para Shells:** A variável `_DETECTED_SHELL` DEVE existir estritamente em memória do processo corrente. NUNCA a grave em arquivo de cache compartilhado no disco (`cache.env`), sob pena de contaminar subshells de tipos diferentes abertos em cascata.

12. **Lazy Completion no Zsh (`_lazy_compinit`):**
   - A inicialização da engine de completion do Zsh (`compinit`) NÃO deve rodar sincronicamente no boot, pois adiciona de 5ms a 7ms de latência.
   - Implemente o carregamento sob demanda (*Lazy Evaluation*) interceptando o widget da tecla `<Tab>` (`bindkey '^I' _lazy_compinit`). No primeiro toque, o completion é inicializado de forma imperceptível e o widget `expand-or-complete` é restaurado para as próximas chamadas.

13. **Otimização de Prompts e Cores ANSI:**
   - Evite o uso repetitivo de `zstyle` em loops de renderização de prompt (`theme/zsh.sh`). Declare e utilize diretamente variáveis locais de cores ANSI.
   - Para checar privilégios de root no prompt, utilize a variável nativa `${EUID:-$(id -u)}`, eliminando a invocação do executável externo `id`.

---

## 3. Procedimento para Criar um Novo Comando / Editor

Quando criar uma nova função de abertura de editor ou utilitário interativo:

1. **Defina a função canônica com suporte multi-argumento e diretório padrão `.`:***
   ```sh
   if command -v <bin> > "/dev/null" 2>&1; then
       open-<nome>() {
           if [ "$#" -eq 0 ]; then
               command <bin> .
           else
               command <bin> "$@"
           fi
       }
       alias o<letra>="open-<nome>"
   fi
   ```
2. **Se a ferramenta alterar o cursor do terminal (como o Helix):**
   Crie um wrapper local que capture o exit status e envie `echo -n $'\e[0 q'` antes de retornar:
   ```sh
   <bin>() {
       command <bin> "$@"
       local _status=$?
       [ -t 1 ] && echo -n $'\e[0 q'
       return ${_status}
   }
   ```
3. **Atualize a documentação em sincronia:**
   - Adicione o comando à tabela correspondente no `README.md`.
   - Adicione a regra/padrão no `PRINCIPLES.md` caso introduza novo conceito.

---

## 4. Checklist de Qualidade e Gates de Validação

Ao concluir qualquer alteração em arquivos `.sh` ou `.md`, execute obrigatoriamente:

```sh
git diff --check

./.githooks/pre-commit

find . -name "*.sh" -not -path "./.git/*" -not -path "*/zsh/*" -not -name "zsh.sh" -exec bash -n {} +

find . -name "*.sh" -not -path "./.git/*" -not -path "*/bash/*" -not -name "bash.sh" -exec zsh -n {} +

sh -n library/functions.sh && sh -n core/environment.sh && sh -n theme/sh.sh

find . -type d -exec chmod 0755 {} +
find . -type f -exec chmod 0644 {} +
chmod 0755 install.sh
```
