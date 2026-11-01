# 🖌️ Design do Prompt & Sistema Visual (`theme/`)

O subsistema de temas do **Universal Shell Environment** entrega um prompt informativo, compacto e de carregamento instantâneo, unificando a identidade visual entre Zsh, Bash, POSIX Sh e KornShell (ksh).

---

## 🎨 Estrutura Visual do Prompt

O prompt é desenhado em linha única ou duas linhas dependendo do shell, otimizado para não roubar espaço horizontal útil da tela:

```text
user@hostname:~/projects/myapp (main ✗) $
```

### Componentes Visuais:

1. **Identificador de Usuário e Host:**
    - Usuário comum: Exibido em tom suave (verde nos temas gráficos / ciano no TTY).
    - Usuário `root`: Destacado em vermelho no console puro TTY (`root@host #`) e no tema multilinha PTY `multi` (` root`), servindo como alerta evidente de privilégios; nos temas compactos PTY de 1 linha (`pill` e `micro`), o nome preserva o tom verde harmônico da pílula enquanto o chevron final (``) assume o tom vermelho de alerta.
2. **Diretório Atual (`PWD`):**
    - Diretórios abreviados com base no `$HOME` (`~`).
    - Cores de contraste para rápida localização do caminho.
3. **Status de Controle de Versão (Git / Got):**
    - **Nome da Branch:** Exibido entre parênteses quando o diretório for um repositório versionado.
    - **Símbolo de Estado Limpo (`✓`):** Verde quando não há arquivos modificados ou untracked.
    - **Símbolo de Estado Modificado (`✗` / `*`):** Amarelo/Vermelho quando há alterações pendentes.
4. **Símbolo de Prompt Terminal:**
    - `$` para usuários comuns.
    - `#` para sessões com privilégios de `root`.

---

## ⚡ Implementação por Shell

### 1. Zsh (`theme/zsh.sh`)

- Arquitetura modular com suporte a `$PROMPT_STYLE` (`multi`, `pill`, `micro`).
- No PTY:
    - **`multi` (padrão):** Prompt informativo de 3 linhas com relógio, calendário, pasta, usuário e branch Git.
    - **`pill`:** Prompt de 1 linha com cápsula gráfica (`...`), pasta, usuário e Git.
    - **`micro`:** Prompt minimalista de 1 linha _streamlined_ sem cápsula.
- No TTY: Comutação automática para `pill` ou `micro` em ASCII puro.
- Renderização de cores através do sistema de expansão nativo `%F{color}...%f` e escapes isolados em `%{...%}`.

### 2. Bash (`theme/bash.sh`)

- Arquitetura modular com suporte a `$PROMPT_STYLE` (`multi`, `pill`, `micro`).
- No PTY:
    - **`multi` (padrão):** Prompt de 3 linhas estruturado com árvore ANSI.
    - **`pill`:** Prompt compacto de 1 linha com pílula de sistema e ícones Nerd Fonts.
    - **`micro`:** Prompt minimalista de 1 linha ultra-denso.
- No TTY: Comutação automática para `pill` ou `micro` em ASCII puro.
- Sequências de escape ANSI estritamente delimitadas em `\[...\]` para cálculo perfeito de quebra de linha no Readline.

### 3. KornShell (`theme/ksh.sh`)

- Prompt dinâmico via `PS1='$(_ksh_prompt)'` para OpenBSD pdksh/oksh.
- Suporte a `$PROMPT_STYLE` nos estilos `pill`, `micro` e `multi` em PTY, e `pill` e `micro` em TTY.

### 4. POSIX Sh (`theme/sh.sh`)

- **Linha de Base FreeBSD 14+/15+ (`/bin/sh`):** Suporta expansão de parâmetros no `$PS1`/`$PS2` (`$VAR`, `${VAR}`, `$?`, `$$`) e sequências ANSI canônicas.
- **Teto Físico de Memória (`PROMPTLEN = 192`):** O parser em C do FreeBSD (`bin/sh/parser.c`) aloca um buffer estático de 192 bytes sem alocação dinâmica no heap (`malloc`). Qualquer prompt acima de 191 bytes é truncado pelo sistema.
- **Peculiaridades da `libedit`:** Utiliza delimitador único hexadecimal (`\x01` / `0x01`), descarta literais consecutivos sem caractere imprimível e desincroniza o cursor vertical em multilinhas (`\n`). Por isso, o tema adota rigorosamente **1 linha**.
- **Decisão Arquitetural Upstream:** Os mantenedores do FreeBSD rejeitam intencionalmente parsers reentrantes e hooks arbitrários (`PROMPT_COMMAND`) para preservar a segurança contra injeção de comandos e manter a estabilidade no _single-user mode_.
- **Mini Prompt Gráfico (`! _is_raw_tty`):** Em emuladores modernos, suporta dois layouts de alta densidade via `$PROMPT_STYLE`:
    - **Pílula (`pill` — padrão em FreeBSD 14+):** Exibe pílula inicial unificada de sistema (` 15.1  sh`), pasta (` shell`), usuário (` gabrielf`) e Git (`󰊢 main*` com `*` em amarelo), eliminando delimitadores `` para calibragem estrita entre 170 e 185 bytes no buffer de 192 bytes.
    - **Micro (`micro` — auto-fallback em FreeBSD <= 13 ou `$PROMPT_BUFFER_LIMIT < 192`):** Layout _streamlined_ ultra-leve com ícones diretos sem delimitadores e sem identificador de shell (` 13.2  shell  gabrielf 󰊢 main* `), com o indicador `*` herdando a cor da branch, calibrado entre 96 e 126 bytes no buffer estático de 128 bytes.
- **Motor de Orçamento Dinâmico de Buffer (Proteção 360°):** Em vez de limites fixos, calcula em tempo real via aritmética nativa POSIX o espaço exato disponível no buffer `ps[PROMPTLEN]`. Aplica travas defensivas de entrada no usuário (`${#_user} <= 12`), hostname (`<= 12`) e versão do SO (`<= 6`), deduzindo seus custos exatos e alocando a sobra inteligentemente entre pasta e branch. Permite nomes de pastas longos (até 40+ caracteres) quando fora do Git ou com branch curta, e contrai sob nomes extensos para travar inegociavelmente no teto físico (mesmo que o usuário ou branch tenham centenas de caracteres).
- **Fallback TTY 100% Bold (`_is_raw_tty`):** No console puro `vt`/`syscons`, comuta para prompt ASCII atômico de linha única 100% negrito via persistência ANSI ECMA-48, com orçamento dinâmico operando entre 107 e 190 bytes com salvaguarda absoluta contra overflow e zero forks no PTY.
- **Triggers de Precisão:** Atualização do Git através de wrappers de alto desempenho (`cd`, `git`, `got`, `:`) sem overhead de subshells a cada enter vazio.

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

Medição auditada no buffer estático `char ps[PROMPTLEN]` do FreeBSD `/bin/sh` (`bin/sh/parser.c`) após processamento de `getprompt()` (`\[`/`\]` convertidos para `\x01` / `0x01`, `\e` para `0x1b` e glifos UTF-8 com seus 3–4 bytes físicos).

> **Perfil de Referência:** Usuário `gabrielf` (8B) | Host `freebsd` (7B) | SO `15.1` (4B) / `13.2` (4B).

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
