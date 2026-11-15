# 🖌️ Design do Prompt & Sistema Visual (`theme/`)

O subsistema de temas do **Universal Shell Environment** entrega um prompt informativo, compacto e de carregamento instantâneo, unificando a identidade visual entre Zsh, Bash, POSIX Sh, KornShell (`ksh`) e Fish (`target/common/fish/prompt.fish`).

---

## 🎨 Estrutura Visual do Prompt

O prompt é desenhado em uma ou três linhas dependendo do shell e de `$PROMPT_STYLE`, otimizado para preservar o espaço horizontal útil da tela:

```text
user@hostname:~/projects/myapp (main*) $
```

### Componentes Visuais:

1. **Identificador de Usuário e Host:**
    - Usuário comum: Exibido em verde brilhante nos temas PTY gráficos (e ciano nos temas TTY).
    - Usuário `root`:
        - No console puro TTY: `root@host` (`_user_color`) e `#` (`_prompt_symbol_color`) destacados em vermelho.
        - Nos temas PTY (`pill`, `micro`, `multi`): ícone ` ` (`_user_icon_color`) e chevron `` (`_terminal_color`) destacados em vermelho de alerta, enquanto o nome `root` (`_user_color`) assume tom magenta (`_theme_color_magenta`).
2. **Diretório Atual (`PWD`):**
    - Diretórios abreviados com base no `$HOME` (`~`).
    - Cores de contraste para rápida localização do caminho.
3. **Status de Controle de Versão (Git / Got):**
    - **Zero Forks em Git/Got (`theme/common/git.sh`):** Lê diretamente `.git/HEAD` e `.got/head-ref` em memória com POSIX `read` (fallback para `got info` apenas quando `.got/head-ref` não resolver), mantendo o boot instantâneo mesmo em repositórios grandes.
    - **Símbolo de Estado Limpo / Modificado (`*`):** O sufixo `*` em amarelo indica alterações não comitadas no worktree (`git` / `got`).
4. **Símbolo de Prompt Terminal & Proteção de Cursor:**
    - `$` para usuários comuns e `#` para `root` no TTY; chevron `` no PTY.
    - Em emuladores PTY, o prompt reemite `\e[1 q` (`printf '\x1b[1 q' >&2` no `ksh`); em console bruto Linux VT (`_is_raw_tty`), reemite `\e%G\e[?16;238;0c`.

### Paleta `PROMPT_OS_COLOR` & Padrões por SO

A variável `PROMPT_OS_COLOR` aceita exatamente **7 cores ANSI** (`red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`; padrão: `blue`), configuradas automaticamente pelos arquivos `target/<os>/<shell>/prompt.sh` e `target/common/fish/prompt.fish`:

| Sistema Operacional     | `PROMPT_OS_COLOR` Padrão | Ícone Padrão                            |
| :---------------------- | :----------------------- | :-------------------------------------- |
| **Windows (MSYS2/Win)** | `blue`                   | ` `                                    |
| **macOS**               | `cyan`                   | ` `                                    |
| **Linux**               | `blue`                   | `_detect_distro_icon` (ex.: ` `, ` `) |
| **FreeBSD**             | `red`                    | ` `                                    |
| **OpenBSD**             | `yellow`                 | ` `                                    |
| **NetBSD**              | `yellow`                 | ` `                                    |
| **illumos**             | `yellow`                 | `󰖨 `                                    |

---

## ⚡ Implementação por Shell & Segurança contra Injeção em `PS1`

### 1. Zsh (`theme/zsh.sh`)

- Arquitetura modular com suporte a `$PROMPT_STYLE` (`multi`, `pill`, `micro`).
- **Prevenção contra Injeção em `PS1` (`_theme_ps1_*` & Escape `%`):** Em vez de interpolar valores dinâmicos diretamente em `PS1` reavaliado por `PROMPT_SUBST` ou usar `psvar` (cujo `nicechar()` do Zsh escapa glifos Nerd Font como `\ue62a`), `theme/zsh.sh` escapa `%` ➔ `%%` e vincula `_pwd`, `_branch`, `_user`, `_host`, `_os_name`, `_os_icon` e `_kernel_release` via variáveis globais `_theme_ps1_*` expandidas em um único nível (`[[ -o promptsubst ]]`), neutralizando `$(...)`/`%F{...}` sem corromper ícones PUA.
- No PTY:
    - **`multi` (padrão):** Prompt informativo de 3 linhas com relógio, calendário, pasta, usuário e branch Git/Got.
    - **`pill`:** Prompt de 1 linha com cápsula gráfica (`...`), pasta, usuário e Git/Got.
    - **`micro`:** Prompt minimalista de 1 linha _streamlined_ sem cápsula.
- No TTY: Comutação automática para `pill` ou `micro` em ASCII puro.
- Renderização de cores através de `%F{color}...%f` e escapes isolados em `%{...%}`, vinculados ao ciclo `add-zsh-hook precmd _update_prompt`.

### 2. Bash (`theme/bash.sh`)

- Arquitetura modular com suporte a `$PROMPT_STYLE` (`multi`, `pill`, `micro`).
- **Prevenção contra Injeção em `PS1` (`_theme_ps1_*` & `promptvars`):** Quando `shopt -q promptvars` está ativo, valores dinâmicos (`pwd`, `branch`, `user`, `host`, `os_name`, `os_icon`, `kernel`) são vinculados via variáveis protegidas `_theme_ps1_*` (`\${_theme_ps1_*}`), ou sanitizados com escape quando `promptvars` estiver desativado, impedindo execução acidental de backticks/`$()` em nomes de pasta ou branch.
- Atualização controlada via `PROMPT_COMMAND="_update_prompt..."` e escapes delimitados em `\[...\]` para cálculo exato de quebra de linha no Readline.

### 3. KornShell (`theme/ksh.sh` & `target/openbsd/ksh/`)

- Prompt dinâmico via `PS1='$(_ksh_prompt)'` calibrado para OpenBSD `/bin/ksh` (`pdksh`/`oksh`).
- **Escapes Hexadecimais & Delimitadores (`_THEME_ESCAPE` / `_THEME_KSH_DELIM`):** Gera o caractere ESC estritamente via `printf '\x1b'` (zero notação octal) e utiliza o delimitador `printf '\x01'` (`\x01\r`) na ancoragem do `PS1` para `PD KSH`/`OKSH`/`MIRBSD` sem corromper contagem de colunas do cursor.
- **Bindings Emacs Canônicos (`ksh(1)`):** `target/openbsd/ksh/behavior.sh` aplica os comandos reais do `pdksh` (`kill-line`, `kill-to-eol`, `clear-screen`, `delete-word-backward`, `search-history`) com histórico persistente `0600`.
- Suporte completo a `$PROMPT_STYLE` nos estilos `pill`, `micro` e `multi` em PTY, e `pill` e `micro` em TTY.

### 4. Fish (`target/common/fish/prompt.fish`)

- Implementa visual equivalente de 3 linhas (`...`, `┌──...`, `└─`) com `PROMPT_OS_COLOR`, `fish_is_root_user` (usuário magenta + ícone/chevron vermelhos) e detecção direta de OS/distro em `fish_prompt`.

### 5. POSIX Sh (`theme/sh.sh`)

- **Linha de Base FreeBSD 14+/15+ (`sh`):** Suporta expansão de parâmetros no `$PS1`/`$PS2` (`$VAR`, `${VAR}`, `$?`, `$$`) e sequências ANSI canônicas.
- **Teto Físico de Memória (`PROMPTLEN = 192`):** O parser em C do FreeBSD (`bin/sh/parser.c`) aloca um buffer estático de 192 bytes sem alocação dinâmica no heap (`malloc`). Qualquer prompt acima de 191 bytes é truncado pelo sistema.
- **Peculiaridades da `libedit`:** Utiliza delimitador único hexadecimal (`\x01` / `0x01`), descarta literais consecutivos sem caractere imprimível e desincroniza o cursor vertical em multilinhas (`\n`). Por isso, o tema adota rigorosamente **1 linha**.
- **Decisão Arquitetural Upstream:** Os mantenedores do FreeBSD rejeitam intencionalmente parsers reentrantes e hooks arbitrários (`PROMPT_COMMAND`) para preservar a segurança contra injeção de comandos e manter a estabilidade no _single-user mode_.
- **Mini Prompt Gráfico (`! _is_raw_tty`):** Em emuladores modernos, suporta dois layouts de alta densidade via `$PROMPT_STYLE`:
    - **Pílula (`pill` — padrão em FreeBSD 14+):** Exibe pílula inicial unificada de sistema (` 15.1  sh`), pasta (` shell`), usuário (` operator`) e Git/Got (`󰊢 main*` com `*` em amarelo), eliminando delimitadores extras para calibragem estrita entre 170 e 190 bytes no buffer de 192 bytes.
    - **Micro (`micro` — auto-fallback em FreeBSD <= 13 ou `$PROMPT_BUFFER_LIMIT < 192`):** Layout _streamlined_ ultra-leve com ícones diretos sem delimitadores e sem identificador de shell (` 13.2  shell  operator 󰊢 main* `), com o indicador `*` herdando a cor amarela de alteração, calibrado entre 96 e 126 bytes no buffer estático de 128 bytes.
- **Motor de Orçamento Dinâmico de Buffer (Proteção 360°):** Em vez de limites fixos, calcula em tempo real via aritmética nativa POSIX o espaço exato disponível no buffer `ps[PROMPTLEN]`. Aplica travas defensivas de entrada no usuário (`${#_user} <= 10` em `pill` / `<= 8` em `micro`), hostname (`<= 12`) e versão do SO (`<= 5`), deduzindo seus custos exatos e alocando a sobra inteligentemente entre pasta e branch. Permite nomes de pastas longos (até 40+ caracteres) quando fora do Git ou com branch curta, e contrai sob nomes extensos para travar inegociavelmente no teto físico (mesmo que o usuário ou branch tenham centenas de caracteres).
- **Fallback TTY 100% Bold (`_is_raw_tty`):** No console puro `vt`/`syscons`, comuta para prompt ASCII atômico de linha única 100% negrito via persistência ANSI ECMA-48, com orçamento dinâmico operando entre 107 e 190 bytes com salvaguarda absoluta contra overflow e zero forks no PTY.
- **Triggers de Precisão (`_create_trigger cd git got`):** Atualização do status Git/Got e integração com `zoxide` através de wrappers (`cd`, `git`, `got`, `:`) que preservam estritamente o exit code (`$_exit_code`) do comando executado e evitam disparo duplo do hook de `zoxide` (`__zoxide_hook` / `_zoxide_sh_oldpwd`).

#### 🧠 Algoritmo de Partilha Dinâmica (Pasta vs Branch)

Para garantir que o prompt utilize 100% do espaço útil do buffer físico sem risco de truncamento, o [`theme/sh.sh`](../theme/sh.sh) implementa uma alocação em 4 estágios:

1. **Ingresso Protegido (Travas 360°):** Usuário (`<= 12`), hostname (`<= 12`) e versão do SO (`<= 6`) têm tetos defensivos para que nomes de usuário gigantes (ex: LDAP/SSO) não saturem o buffer antes da renderização de pastas.
2. **Cálculo do Orçamento Livre (`_budget`) com Medição Real em C:** Em vez de estimativas estáticas ou números mágicos hardcodados, monta a string de molde estrutural real (`_fixed_string` com ícones, cores, usuário, host, SO e moldura de Git dirty se ativo) e mede em tempo de execução os bytes exatos em C (`_calc_c_len`), deduzindo delimitadores `\[`, `\]` e escapes `\e`. Subtrai a medição real do teto físico (`_prompt_limit - _margin - _c_bytes`), vinculando de forma 100% dinâmica qualquer alteração visual ao orçamento restante disponível.
3. **Árvore de Decisão de Partilha:**
    - **Fora do Git (`_branch=""`):** A pasta herda 100% do orçamento livre (podendo exibir 40+ caracteres intactos).
    - **Dentro do Git ($\text{Pasta} + \text{Branch} \le \text{Orçamento}$):** Nenhuma truncagem é aplicada; ambos são exibidos por extenso.
    - **Dentro do Git ($\text{Pasta} + \text{Branch} > \text{Orçamento}$):**
        - Se a pasta for menor que a metade do orçamento: a pasta é preservada inteira e a branch recebe toda a folga restante.
        - Se a branch for menor que a metade do orçamento (ex: `main`): a branch é preservada inteira e a pasta recebe toda a folga restante.
        - Se ambos forem longos: o orçamento restante é dividido igualmente (meio a meio).
4. **Truncagem Recursiva POSIX (`_trim_string`):** Se uma string precisar ser encurtada, o helper nativo retira caracteres do fim via `${var%?}` com zero subshell e insere o sufixo canônico (`…` no PTY, `~` no TTY).

#### 📊 Matriz de Consumo e Headroom de Buffer no FreeBSD

Medição auditada no buffer estático `char ps[PROMPTLEN]` do FreeBSD `sh` (`bin/sh/parser.c`) após processamento de `getprompt()` (`\[`/`\]` convertidos para `\x01` / `0x01`, `\e` para `0x1b` e glifos UTF-8 com seus 3–4 bytes físicos).

> **Perfil de Referência:** Usuário `operator` (8B) | Host `freebsd` (7B) | SO `15.1` (4B) / `13.2` (4B).

##### 1. Modo PTY (Terminal Gráfico com Nerd Fonts)

| Layout      |       Teto Físico (`PROMPTLEN`)        | Cenário de Uso                   | Ocupação Real em C (`ps[]`) | Espaço Livre (Headroom) | Estado do Motor  |
| :---------- | :------------------------------------: | :------------------------------- | :-------------------------: | :---------------------: | :--------------- |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 🏠 Sem Git (`~`)                 |        **131 bytes**        |      **+61 bytes**      | 🟢 Sem podas     |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 📁 Sem Git (`shell`)             |        **135 bytes**        |      **+57 bytes**      | 🟢 Sem podas     |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 📁 Sem Git (pasta longa)         |        **157 bytes**        |      **+35 bytes**      | 🟢 Podada suave  |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 🌿 Git Limpo (`main`)            |        **159 bytes**        |      **+33 bytes**      | 🟢 Sem podas     |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | ⚡ Git Modificado (`main*`)      |        **167 bytes**        |      **+25 bytes**      | 🟢 Sem podas     |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 🚀 Branch Longa (`feature/...*`) |        **190 bytes**        |      **+2 bytes**       | 🟢 Podada suave  |
|             |                                        |                                  |                             |                         |                  |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 🏠 Sem Git (`~`)                 |        **89 bytes**         |      **+39 bytes**      | 🟢 Sem podas     |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 📁 Sem Git (`shell`)             |        **93 bytes**         |      **+35 bytes**      | 🟢 Sem podas     |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 📁 Sem Git (pasta longa)         |        **110 bytes**        |      **+18 bytes**      | 🟢 Podada suave  |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 🌿 Git Limpo (`main`)            |        **117 bytes**        |      **+11 bytes**      | 🟢 Sem podas     |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | ⚡ Git Modificado (`main*`)      |        **118 bytes**        |      **+10 bytes**      | 🟢 Sem podas     |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 🚀 Branch Longa (`feature/...*`) |        **126 bytes**        |      **+2 bytes**       | 🟢 Podada suave  |
|             |                                        |                                  |                             |                         |                  |
| **`micro`** | **192 bytes** _(FreeBSD 14+ opcional)_ | 🏠 Sem Git (`~`)                 |        **89 bytes**         |     **+103 bytes**      | 🚀 Folga massiva |
| **`micro`** | **192 bytes** _(FreeBSD 14+ opcional)_ | 🌿 Git Limpo (`main`)            |        **117 bytes**        |      **+75 bytes**      | 🚀 Folga massiva |
| **`micro`** | **192 bytes** _(FreeBSD 14+ opcional)_ | ⚡ Git Modificado (`main*`)      |        **118 bytes**        |      **+74 bytes**      | 🚀 Folga massiva |

##### 2. Modo TTY (Console Puro ASCII)

| Layout      |       Teto Físico (`PROMPTLEN`)        | Cenário de Uso                   | Ocupação Real em C (`ps[]`) | Espaço Livre (Headroom) | Estado do Motor     |
| :---------- | :------------------------------------: | :------------------------------- | :-------------------------: | :---------------------: | :------------------ |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 🏠 Sem Git (`~`)                 |        **106 bytes**        |      **+86 bytes**      | 🟢 Sem podas        |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 📁 Sem Git (`shell`)             |        **110 bytes**        |      **+82 bytes**      | 🟢 Sem podas        |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 📁 Sem Git (pasta longa)         |        **132 bytes**        |      **+60 bytes**      | 🟢 Sem podas        |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 🌿 Git Limpo (`main`)            |        **138 bytes**        |      **+54 bytes**      | 🟢 Sem podas        |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | ⚡ Git Modificado (`main*`)      |        **146 bytes**        |      **+46 bytes**      | 🟢 Sem podas        |
| **`pill`**  |     **192 bytes** _(FreeBSD 14+)_      | 🚀 Branch Longa (`feature/...*`) |        **162 bytes**        |      **+30 bytes**      | 🟢 Podada suave     |
|             |                                        |                                  |                             |                         |                     |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 🏠 Sem Git (`~`)                 |        **71 bytes**         |      **+57 bytes**      | 🟢 Sem podas        |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 📁 Sem Git (`shell`)             |        **75 bytes**         |      **+53 bytes**      | 🟢 Sem podas        |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 📁 Sem Git (pasta longa)         |        **97 bytes**         |      **+31 bytes**      | 🟢 Sem podas        |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 🌿 Git Limpo (`main`)            |        **103 bytes**        |      **+25 bytes**      | 🟢 Sem podas        |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | ⚡ Git Modificado (`main*`)      |        **104 bytes**        |      **+24 bytes**      | 🟢 Sem podas        |
| **`micro`** |    **128 bytes** _(FreeBSD <= 13)_     | 🚀 Branch Longa (`feature/...*`) |        **120 bytes**        |      **+8 bytes**       | 🟢 Podada com folga |
|             |                                        |                                  |                             |                         |                     |
| **`micro`** | **192 bytes** _(FreeBSD 14+ opcional)_ | 🏠 Sem Git (`~`)                 |        **71 bytes**         |     **+121 bytes**      | 🚀 Folga massiva    |
| **`micro`** | **192 bytes** _(FreeBSD 14+ opcional)_ | ⚡ Git Modificado (`main*`)      |        **104 bytes**        |      **+88 bytes**      | 🚀 Folga massiva    |

---

## 📟 Fallback Resiliente em TTY Bruto

Ao inicializar uma máquina diretamente em um console TTY de emergência (sem servidor gráfico ou driver de fonte carregado) ou em uma conexão de console serial:

- **Detecção de TTY Puro:** Se `$TERM` for `linux`, `vt100` ou similar sem suporte a glifos Nerd Fonts, o tema desativa automaticamente ícones complexos.
- **Substituição de Caracteres:** Glifos Unicode são substituídos por equivalentes ASCII simples (`*`, `!`, `>`), garantindo que o prompt nunca exiba caracteres corrompidos (_mojibake_ ou caixas vazias).

---

## 🖥️ Sistema Visual de Desktop & Paleta Adwaita-Breeze Dark Fusion

Além da experiência de linha de comando no terminal e no console TTY, o ecossistema estende sua identidade visual para sessões de gerenciadores de janela (`wwm`, `xwm`) e quiosques gráficos flutuantes (`wgui`, `xgui`):

### 1. Paleta Cromática Adwaita-Breeze Dark Fusion

A identidade visual equilibra a sobriedade dos tons escuros do Adwaita com o contraste moderno do KDE Breeze:

| Elemento de UI                         | Código Hex | Papel Visual                                                        |
| :------------------------------------- | :--------: | :------------------------------------------------------------------ |
| **Superfície Base / Fundo**            | `#1e1e22`  | Cor de fundo das barras, bordas inativas e área de desktop          |
| **Painel Ativo / Superfície Elevada**  | `#2b2b30`  | Fundo de botões interativos e títulos de janelas ativas             |
| **Acento Primário (Azul Adwaita)**     | `#3584e4`  | Foco de janela, bordas ativas e botões de ação principal            |
| **Acento de Alerta (Vermelho Breeze)** | `#e01b24`  | Botões de encerramento (`[ Close ]`, `[ Exit ]`) e janelas urgentes |
| **Bordas & Separadores**               | `#38383d`  | Linhas de contenção de containers e separadores de barra            |
| **Texto Secundário / Inativo**         | `#9a9996`  | Rótulos de workspaces inativos e carimbos de data/hora              |
| **Texto de Alto Contraste**            | `#ffffff`  | Tipografia em botões em foco e títulos de janelas ativas            |

### 2. Pipeline Tipográfico (`_resolve_desktop_font`)

Para manter harmonia tipográfica entre Wayland, X11 e terminais emulados, a função `_resolve_desktop_font` inspeciona as fontes disponíveis via `fc-list`:

1. **Prioridade Primária Universal:** `JetBrainsMono Nerd Font` (fonte canônica homologada no ecossistema).
2. **Resolução Contextual por Desktop Environment (DE):**
    - **KDE / Plasma:** Fallback para `Noto Sans`.
    - **GNOME:** Fallback para `Adwaita Sans` ou `Cantarell`.
    - **MATE / Cinnamon / XFCE:** Fallback para `Ubuntu` ou `DejaVu Sans`.
    - **LXQt:** Fallback para `Noto Sans` ou `Sans Serif`.
    - **LXDE:** Fallback para `DejaVu Sans`.
    - **Budgie:** Fallback para `Adwaita Sans`, `Ubuntu` ou `Cantarell`.
    - **Pantheon:** Fallback para `Inter`, `Open Sans` ou `Cantarell`.
    - **Deepin:** Fallback para `Noto Sans`.
    - **COSMIC:** Fallback para `Fira Sans` ou `Cantarell`.
3. **Fallback Seguro Universal:** `Sans`.

| Desktop Environment | Família Tipográfica Primária | Família de Fallback                                                                  |
| :------------------ | :--------------------------- | :----------------------------------------------------------------------------------- |
| **KDE (Plasma)**    | `JetBrainsMono Nerd Font`    | `Noto Sans` $\rightarrow$ `Sans`                                                     |
| **GNOME**           | `JetBrainsMono Nerd Font`    | `Adwaita Sans` $\rightarrow$ `Cantarell` $\rightarrow$ `Sans`                        |
| **MATE**            | `JetBrainsMono Nerd Font`    | `Ubuntu` $\rightarrow$ `DejaVu Sans` $\rightarrow$ `Sans`                            |
| **Cinnamon**        | `JetBrainsMono Nerd Font`    | `Ubuntu` $\rightarrow$ `DejaVu Sans` $\rightarrow$ `Sans`                            |
| **XFCE**            | `JetBrainsMono Nerd Font`    | `Ubuntu` $\rightarrow$ `DejaVu Sans` $\rightarrow$ `Sans`                            |
| **LXQt**            | `JetBrainsMono Nerd Font`    | `Noto Sans` $\rightarrow$ `Sans Serif` $\rightarrow$ `Sans`                          |
| **LXDE**            | `JetBrainsMono Nerd Font`    | `DejaVu Sans` $\rightarrow$ `Sans`                                                   |
| **Budgie**          | `JetBrainsMono Nerd Font`    | `Adwaita Sans` $\rightarrow$ `Ubuntu` $\rightarrow$ `Cantarell` $\rightarrow$ `Sans` |
| **Pantheon**        | `JetBrainsMono Nerd Font`    | `Inter` $\rightarrow$ `Open Sans` $\rightarrow$ `Cantarell` $\rightarrow$ `Sans`     |
| **Deepin**          | `JetBrainsMono Nerd Font`    | `Noto Sans` $\rightarrow$ `Sans`                                                     |
| **COSMIC**          | `JetBrainsMono Nerd Font`    | `Fira Sans` $\rightarrow$ `Cantarell` $\rightarrow$ `Sans`                           |
| **Standalone WMs**  | `JetBrainsMono Nerd Font`    | `Sans`                                                                               |

### 3. Pipeline de Cursor & Precedência Canônica (`_setup_cursor_env`)

A exportação de `XCURSOR_THEME`, `XCURSOR_SIZE` (`24px`) e `XCURSOR_PATH` obedece rigorosamente à cascata de prioridade:
`KDE > GNOME > MATE > Cinnamon > XFCE > LXQt > LXDE > Budgie > Pantheon > Deepin > COSMIC > Fallback (Adwaita -> breeze_cursors -> default)`.

| Desktop Environment    | Tema de Cursor Primário                                          | Fonte de Configuração / Fallback                          |
| :--------------------- | :--------------------------------------------------------------- | :-------------------------------------------------------- |
| **KDE (Plasma)**       | `breeze_cursors`                                                 | `~/.config/kcminputrc` (cursorTheme, cursorSize)          |
| **GNOME**              | `Adwaita`                                                        | GSettings (`org.gnome.desktop.interface cursor-theme`)    |
| **MATE**               | `Adwaita`                                                        | GSettings (`org.mate.peripherals-mouse cursor-theme`)     |
| **Cinnamon**           | `Adwaita`                                                        | GSettings (`org.cinnamon.desktop.interface cursor-theme`) |
| **XFCE**               | `Adwaita`                                                        | `xfconf-query` / `~/.icons/Adwaita`                       |
| **LXQt**               | `breeze_cursors`                                                 | `~/.config/lxqt/session.conf` / `breeze_cursors`          |
| **LXDE**               | `Adwaita`                                                        | `~/.config/lxsession/LXDE/desktop.conf`                   |
| **Budgie**             | `Adwaita`                                                        | GSettings (`org.gnome.desktop.interface cursor-theme`)    |
| **Pantheon**           | `Adwaita`                                                        | GSettings (`org.gnome.desktop.interface cursor-theme`)    |
| **Deepin**             | `Adwaita`                                                        | `com.deepin.dde.appearance cursor-theme` / `Adwaita`      |
| **COSMIC**             | `Adwaita`                                                        | Configurações COSMIC / `Adwaita`                          |
| **Fallback Universal** | `Adwaita` $\rightarrow$ `breeze_cursors` $\rightarrow$ `default` | Diretórios XDG / `/usr/share/icons`                       |

### 4. Matriz de Harmonização de Temas GTK & Qt

Sincroniza proceduralmente `SAL_USE_VCLPLUGIN="gtk3"`, `GTK_APPLICATION_PREFER_DARK_THEME=1` e `gtk-icon-theme-name` (`Adwaita` / `breeze-dark`) em `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini` e GSettings, garantindo fidelidade de ícones e widgets 100% idêntica no LibreOffice e aplicações GTK entre sessões X11 (`xgui`, `xwm`, `xewm`) e Wayland (`wgui`, `wwm`, `wewm`).

| Desktop Environment | Tema GTK Canônico                         | Estilo de Widget Qt (`QT_STYLE_OVERRIDE`) | Plataforma Qt (`QT_QPA_PLATFORMTHEME`)                         |
| :------------------ | :---------------------------------------- | :---------------------------------------- | :------------------------------------------------------------- |
| **KDE (Plasma)**    | `Breeze-Dark`                             | `Breeze-Dark` / `Breeze`                  | `xdgdesktopportal`                                             |
| **GNOME**           | `adw-gtk3-dark` / GSettings               | _(Padrão via Platform Theme)_             | `qt6ct` $\rightarrow$ `qt5ct` $\rightarrow$ `xdgdesktopportal` |
| **MATE**            | `Yaru-MATE-dark` / `BlackMATE`            | _(Padrão via Platform Theme)_             | `gtk3`                                                         |
| **Cinnamon**        | `Mint-Y-Dark`                             | _(Padrão via Platform Theme)_             | `gtk3`                                                         |
| **XFCE**            | `Greybird-dark`                           | _(Padrão via Platform Theme)_             | `gtk3`                                                         |
| **LXQt**            | `Breeze-Dark` / `Arc-Dark`                | `Breeze-Dark` / `Breeze`                  | `lxqt`                                                         |
| **LXDE**            | `Clearlooks-Phenix` / `Arc-Dark`          | _(Padrão via Platform Theme)_             | `gtk3`                                                         |
| **Budgie**          | `Materia-dark` / `Arc-Dark`               | _(Padrão via Platform Theme)_             | `qt6ct` $\rightarrow$ `qt5ct` $\rightarrow$ `xdgdesktopportal` |
| **Pantheon**        | `io.elementary.stylesheet.blueberry-dark` | _(Padrão via Platform Theme)_             | `qt6ct` $\rightarrow$ `qt5ct` $\rightarrow$ `xdgdesktopportal` |
| **Deepin**          | `deepin-dark`                             | `chameleon`                               | `deepin`                                                       |
| **COSMIC**          | `cosmic-dark`                             | _(Padrão via Platform Theme)_             | `qt6ct` $\rightarrow$ `qt5ct` $\rightarrow$ `xdgdesktopportal` |
| **Standalone WMs**  | `adw-gtk3-dark`                           | _(Padrão via Platform Theme)_             | Wayland: `qt6ct`/`qt5ct`/`xdgdesktopportal` \| X11: `gtk3`     |

### 5. Componentes Visuais de Sessão & Quiosque

- **Barra Interativa `wwm-bar` (GTK3 / Swaybar) com Botões Pílula GTK4/Qt6:** No gerenciador Wayland nativo (`wwm`), a barra superior opera via GTK3 nativo (`wwm-bar`) com fallback transparente para streaming JSON da `swaybar` (`"click_events": true`). Adota botões estilo pílula inspirados nas diretrizes de GTK4 e Qt6 sem colchetes (`Web Browser`, `Terminal`, `Files`, `Emacs`, `Menu`, `Close`, `Exit`), com resposta imediata e feedback dinâmico de `:hover` (`#3584e4` em ferramentas, `#e01b24` nos botões de encerramento). Incorpora gestão dinâmica de workspaces (`1..N`) com botões dedicados de criação (`+`, que descobre o menor índice vago) e destruição (`−`, que move janelas do workspace focado para um adjacente e descarta a área).
- **Menu Dinâmico & Ergonomia SSD no `xwm`:** No ambiente X11 com Openbox, um parser procedural em AWK varre os arquivos `.desktop` do sistema em `/usr/share/applications`, `/usr/local/share/applications` e Flatpak, agrupando as aplicações em categorias canônicas: Desenvolvimento (`dev`), Rede (`net`), Escritório (`office`), Multimídia (`media`) e Sistema (`sys`). Além disso, o `xwm` implementa suporte completo a decorações server-side (SSD) com redimensionamento fluido em todas as 4 bordas e 4 cantos (`Top`, `Bottom`, `Left`, `Right`, `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`), permitindo arrastar bordas com o mouse sem depender de combinações modais de teclado (`Alt + Right Click`).
- **Abas Dinâmicas no `xgui` e `wgui` com Paridade 100% ($\ge 2$ Janelas):** Nos quiosques flutuantes sob Wayland e X11, o monitoramento de janelas ativas atua em tempo real:
    - **Janela Única (`_count < 2`):** Interface imersiva de aplicação única com bordas ocultas (`border none` / `layout splith`).
    - **Múltiplas Janelas (`_count >= 2`):** Assim que uma segunda janela, caixa de diálogo ou visualizador modal é aberto, o `wgui` (Wayland) aciona abas no Sway e o `xgui` (X11) instancia a barra superior `xgui-tabbar` (GTK3 dock de 28px).
    - **Paridade Estética e Tipográfica 1:1:** O `xgui-tabbar` replica fielmente as dimensões e pesos visuais do `wgui`, utilizando tipografia em `10pt Bold`, fundo da aba focada em tom elevado `#2b2b30` com borda azul `#3584e4` (com realce no topo de 2px), abas desfocadas em tom base `#1e1e22` com bordas `#38383d`, texto secundário em `#9a9996` e iluminação em `:hover` (`#ffffff`), colapsando instantaneamente quando o número de janelas cai para uma.
