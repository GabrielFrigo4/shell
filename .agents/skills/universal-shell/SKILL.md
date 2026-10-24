---
name: universal-shell
description: >-
    Comprehensive guide and operational runbook for extending, refactoring, and auditing the Universal Shell repository.
    Use when adding new commands, aliases, contexts, targets, or auditing shell scripts for FreeBSD /bin/sh parity,
    defensive guards, and Clean Code standards.
---

# Universal Shell — Development & Architecture Runbook

Este guia detalha o fluxo operacional para estender, refatorar e auditar o repositório **Universal Shell Environment** (`/usr/local/share/shell`), garantindo aderência rigorosa aos 22 Princípios de Engenharia UNIX + Clean Code.

---

## 1. Mapeamento de Camadas (Onde colocar cada código)

Antes de escrever qualquer código, posicione-o na camada correta do ciclo de vida:

| Camada         | Diretório  | Papel & Responsabilidade                                                                                                                            | Exemplos                                                             |
| :------------- | :--------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------- |
| **Biblioteca** | `library/` | Funções puras reutilizáveis, detecção de ambiente e utilitários globais. Não deve conter aliases.                                                   | `_detect_os`, `_as_root`, `path-front`, `update-all`, `clean-system` |
| **Núcleo**     | `core/`    | Variáveis essenciais de ambiente, cascatas de editores/ferramentas e integração com o Vault (`vault.sh`).                                           | `editor()`, aliases universais (`u`, `l`, `g`, `c`, `f`)             |
| **Contextos**  | `context/` | Especializações por propósito da máquina (`desktop`, `server`, `container` — WSL unificado com auto-detecção). Dividido em `common.sh` e `<os>.sh`. | Editores gráficos (`open-*`), montagem móvel (`mount-device`), emacs |
| **Targets**    | `target/`  | Especializações por SO (`linux`, `freebsd`, `windows`, `openbsd`, `netbsd`, `illumos`, `macos`). Injeta variáveis e caminhos.                       | `PROMPT_OS_*`, `clear` no FreeBSD, `incus` no Linux                  |
| **Temas**      | `theme/`   | Renderização visual de prompts específicos por shell (`bash.sh`, `zsh.sh`, `sh.sh`, `ksh.sh`).                                                      | Prompt de 2 linhas com Nerd Fonts, fallback TTY bruto, Git/Got       |

---

## 2. Invariantes Arquiteturais Inegociáveis

1. **Linha de Base FreeBSD `/bin/sh` & Alvos Nativos de Sistema Exclusivos:**
    - O `/bin/sh` do FreeBSD é a referência canônica para scripts compartilhados em `library/`, `core/` e `install.sh`.
    - **Alvos Nativos de Sistema Exclusivos:** O alvo interativo `sh` existe unicamente no FreeBSD (`target/freebsd/sh`), e o alvo interativo `ksh` existe unicamente no OpenBSD (`target/openbsd/ksh`). Todos os demais SOs possuem exclusivamente `bash` e `zsh` como alvos interativos.
    - O formato `echo -n $'\e...'` é universalmente suportado em todo o ecossistema (FreeBSD `/bin/sh`, Zsh, Bash e Dash moderno, além do padrão POSIX Issue 8). No OpenBSD `ksh`, sequências de controle adotam bytes octais `\033` (via `printf '\033'`).
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
    - **Nomenclatura Semântica Expressiva (Zero Abreviações Crípticas):** Proibição categórica de variáveis de uma única letra ou abreviações contraídas (`_c`, `_u`, `_ind`, `_sym`, `_del`, `_b`, `_f`, `_ed`, `_mod`). Use sempre nomes explícitos e semânticos (`_user_color`, `_prompt_symbol`, `_indicator`, `_delimiter`, `_module`, `_file`), exceto referências formais da computação (a linguagem `C` em buffers de parser `_calc_c_len` / `_c_bytes`, e acrônimos de sistema consagrados como `_os`, `_ip`, `_pid`).

5. **Delimitadores de Largura Zero em Prompts (`\[...\]` e `\e`):**
    - No FreeBSD `/bin/sh` (`libedit`) e no Bash (`readline`), códigos ANSI dentro de `PS1` DEVEM estar estritamente contidos entre `\[` e `\]` (ex: `_color_red="\[\e[1;91m\]"`).
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
- Implemente o carregamento sob demanda (_Lazy Evaluation_) interceptando o widget da tecla `<Tab>` (`bindkey '^I' _lazy_compinit`). No primeiro toque, o completion é inicializado de forma imperceptível e o widget `expand-or-complete` é restaurado para as próximas chamadas.

13. **Otimização de Prompts e Cores ANSI:**

- Evite o uso repetitivo de `zstyle` em loops de renderização de prompt (`theme/zsh.sh`). Declare e utilize diretamente variáveis locais de cores ANSI.
- Para checar privilégios de root no prompt, utilize a variável nativa `${EUID:-$(id -u)}`, eliminando a invocação do executável externo `id`.

14. **Invariante de Aliases Não-Circulares no PowerShell:**

- No PowerShell, nomes de funções e aliases são case-insensitive. Criar um alias com o mesmo nome da função (ex: `New-Alias "clean-system" "Clean-System"`) cria um loop circular auto-referencial que suprime a função e tenta executar um binário `.exe` inexistente no PATH. Funções nunca devem ter aliases homônimos. Aliases de atalho devem usar `Set-Alias -Force -Option AllScope` para garantir reentrância sem colisões.

15. **Invariante Dual `Path` / `PATH` & Injeção de Helpers no NuShell:**

- O Windows NT armazena caminhos em `Path`, enquanto NuShell é case-sensitive em `$env`. No NuShell no Windows, configure `$env.ENV_CONVERSIONS` para ambas as chaves e sincronize `$env.Path` e `$env.PATH`. Em comandos de atualização Git (`upvt`), injete o helper explicitamente via `-c credential.https://github.com.helper=!"(get-gh-cmd)" auth git-credential` para imunidade a subprocessos.

16. **Auto-Cura Reentrante de Perfis Físicos Cross-Shell:**

- Em conformidade com o Princípio 19 (Autonomia Reentrante) e Princípio 7 (Zero-Tweaks), `upsh` e `resh` executados em qualquer shell no Windows (PowerShell, NuShell, CMD) sincronizam atomicamente os perfis físicos em disco de todos os demais (`Documents\PowerShell`, `%APPDATA%\nushell`, `%LOCALAPPDATA%\clink`), sem qualquer intervenção manual.

17. **Ciclo Sagrado de Propagação & Invariante de Produção Imaculada (Zero-Dirty):**

- O clone de produção `/usr/local/share/shell` (ou `~/.local/share/shell`) é estritamente downstream e atualizado exclusivamente via `git pull` ou comando `upsh`.
- É TERMINANTEMENTE PROIBIDO copiar arquivos avulsos (`cp`, `rsync`) da bancada para a produção, mesmo durante testes rápidos ou diagnósticos. Modificações manuais tornam a working tree de produção suja (`dirty`), quebrando a soberania do DVCS e impedindo atualizações limpas.
- Toda modificação deve ser desenvolvida e validada na bancada (`~/Documents/Environment/Shell`), comitada e enviada via `git push`. A árvore de produção deve manter `git status` 100% limpo em todo momento.

18. **Padrão Display Server Dispatcher & Tripartite Session Lifecycle:**

- Funções gráficas interativas adotam nomes canônicos por extenso (`window-manager`, `graphical-launcher`, `emacs-window-manager`) e despacham via `_dispatch_display_server <alvo>` para as variantes com sufixo (`<alvo>-wayland` e `<alvo>-x11`).
- Aliases ergonômicos (`wm`, `win`, `wwm`, `way`, `xwm`, `xorg`, `x11`, `gui`, `wgui`, `xgui`, `ewm`, `wewm`, `xewm`) apontam para as funções correspondentes sem duplicar código.
- A inicialização Wayland em `_exec_wayland` é tripartite: FreeBSD usa `ck-launch-session dbus-launch`; Linux com systemd detecta e preserva `/run/user/$(id -u)/bus` sem novo `dbus-run-session` (evitando corrupção de alvos de sessão como `gnome-session@gnome.target`); Linux sem systemd ou outros BSDs usam fallback isolado de `dbus-run-session`.

---

## 3. Procedimento para Criar um Novo Comando / Editor

Quando criar uma nova função de abertura de editor ou utilitário interativo:

1. **Defina a função canônica com suporte multi-argumento e diretório padrão `.`:\***
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
   Crie um wrapper local que capture o exit status e execute a auto-cura de cursor antes de retornar, diferenciando console TTY puro de emuladores PTY gráficos:
    ```sh
    <bin>() {
        command <bin> "$@"
        _status=$?
        if [ -t 1 ]; then
            if _is_raw_tty; then
                echo -n $'\e%G\e[?16;238;0c'
            else
                echo -n $'\e[0 q'
            fi
        fi
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

---

## 🔗 Links Oficiais de Referência & Obras Recomendadas

- **The FreeBSD Project:** <https://www.freebsd.org/> | Manual `sh(1)`: <https://man.freebsd.org/sh.1>
- **The OpenBSD Project:** <https://www.openbsd.org/> | Manual `ksh(1)`: <https://man.openbsd.org/ksh.1>
- **KornShell Portals:** <http://www.kornshell.com/> | <http://www.kornshell.org/>
- **Zsh Official:** <https://www.zsh.org/>
- **The Open Group (POSIX):** <https://www.opengroup.org/> | Especificações Base: <https://pubs.opengroup.org/onlinepubs/9699919799/>
- **Game of Trees (Got):** <https://gameoftrees.org/> | Manual: <https://gameoftrees.org/manual.html>
- **Literatura Técnica:**
    - _The Art of UNIX Programming_ (Eric S. Raymond, 2003, Addison-Wesley).
    - _Clean Code: A Handbook of Agile Software Craftsmanship_ (Robert C. Martin, 2008, Prentice Hall).
    - _The UNIX Programming Environment_ (Brian W. Kernighan & Rob Pike, 1984, Prentice Hall).
