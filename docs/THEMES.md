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
    - Usuário comum: Exibido em tom suave (azul ou ciano).
    - Usuário `root`: Destacado em vermelho para alertar sobre privilégios de superusuário.
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
- **Peculiaridades da `libedit`:** Utiliza delimitador único (`\001`), descarta literais consecutivos sem caractere imprimível e desincroniza o cursor vertical em multilinhas (`\n`). Por isso, o tema adota rigorosamente **1 linha**.
- **Decisão Arquitetural Upstream:** Os mantenedores do FreeBSD rejeitam intencionalmente parsers reentrantes e hooks arbitrários (`PROMPT_COMMAND`) para preservar a segurança contra injeção de comandos e manter a estabilidade no _single-user mode_.
- **Mini Prompt Gráfico (`! _is_raw_tty`):** Em emuladores modernos, suporta dois layouts de alta densidade via `$PROMPT_STYLE`:
    - **Pílula (`pill` — padrão em FreeBSD 14+):** Exibe pílula inicial unificada de sistema (` 15.1  sh`), pasta (` shell`), usuário (` gabrielf`) e Git (`󰊢 main*` com `*` em amarelo), eliminando delimitadores `❮❯` para calibragem estrita entre 170 e 185 bytes no buffer de 192 bytes.
    - **Micro (`micro` — auto-fallback em FreeBSD <= 13 ou `$PROMPT_BUFFER_LIMIT < 192`):** Layout _streamlined_ ultra-leve com ícones diretos sem delimitadores e sem identificador de shell (` 13.2  shell  gabrielf 󰊢 main* `), com o indicador `*` herdando a cor da branch, calibrado entre 96 e 126 bytes no buffer estático de 128 bytes.
- **Motor de Orçamento Dinâmico de Buffer (Proteção 360°):** Em vez de limites fixos, calcula em tempo real via aritmética nativa POSIX o espaço exato disponível no buffer `ps[PROMPTLEN]`. Aplica travas defensivas de entrada no usuário (`${#_user} <= 12`), hostname (`<= 12`) e versão do SO (`<= 6`), deduzindo seus custos exatos e alocando a sobra inteligentemente entre pasta e branch. Permite nomes de pastas longos (até 40+ caracteres) quando fora do Git ou com branch curta, e contrai sob nomes extensos para travar inegociavelmente no teto físico (mesmo que o usuário ou branch tenham centenas de caracteres).
- **Fallback TTY 100% Bold (`_is_raw_tty`):** No console puro `vt`/`syscons`, comuta para prompt ASCII atômico de linha única 100% negrito via persistência ANSI ECMA-48, com orçamento dinâmico operando entre 107 e 190 bytes com salvaguarda absoluta contra overflow e zero forks no PTY.
- **Triggers de Precisão:** Atualização do Git através de wrappers de alto desempenho (`cd`, `git`, `got`, `:`) sem overhead de subshells a cada enter vazio.

#### 🧠 Algoritmo de Partilha Dinâmica (Pasta vs Branch)

Para garantir que o prompt utilize 100% do espaço útil do buffer físico sem risco de truncamento, o [`theme/sh.sh`](../theme/sh.sh) implementa uma alocação em 4 estágios:

1. **Ingresso Protegido (Travas 360°):** Usuário (`<= 12`), hostname (`<= 12`) e versão do SO (`<= 6`) têm tetos defensivos para que nomes de usuário gigantes (ex: LDAP/SSO) não saturem o buffer antes da renderização de pastas.
2. **Cálculo do Orçamento Livre (`_budget`) com Medição Real em C:** Em vez de estimativas estáticas ou números mágicos hardcodados, monta a string de molde estrutural real (`_fixed_str` com ícones, cores, usuário, host, SO e moldura de Git dirty se ativo) e mede em tempo de execução os bytes exatos em C (`_calc_ui_color_len`), deduzindo delimitadores `\[`, `\]` e escapes `\e`. Subtrai a medição real do teto físico (`_prompt_limit - _margin - _ui_color_bytes`), vinculando de forma 100% dinâmica qualquer alteração visual ao orçamento restante disponível.
3. **Árvore de Decisão de Partilha:**
    - **Fora do Git (`_branch=""`):** A pasta herda 100% do orçamento livre (podendo exibir 40+ caracteres intactos).
    - **Dentro do Git ($\text{Pasta} + \text{Branch} \le \text{Orçamento}$):** Nenhuma truncagem é aplicada; ambos são exibidos por extenso.
    - **Dentro do Git ($\text{Pasta} + \text{Branch} > \text{Orçamento}$):**
        - Se a pasta for menor que a metade do orçamento: a pasta é preservada inteira e a branch recebe toda a folga restante.
        - Se a branch for menor que a metade do orçamento (ex: `main`): a branch é preservada inteira e a pasta recebe toda a folga restante.
        - Se ambos forem longos: o orçamento restante é dividido igualmente (meio a meio).
4. **Truncagem Recursiva POSIX (`_trim_str`):** Se uma string precisar ser encurtada, o helper nativo retira caracteres do fim via `${var%?}` com zero subshell e insere o sufixo canônico (`…` no PTY, `~` no TTY).

#### 📊 Matriz de Consumo e Headroom de Buffer no FreeBSD

Medição auditada no buffer estático `char ps[PROMPTLEN]` do FreeBSD `/bin/sh` (`bin/sh/parser.c`) após processamento de `getprompt()` (`\[`/`\]` convertidos para `\001`, `\e` para `0x1b` e glifos UTF-8 com seus 3–4 bytes físicos).

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
