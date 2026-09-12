# 🖌️ Design do Prompt & Sistema Visual (`theme/`)

O subsistema de temas do **Universal Shell Environment** entrega um prompt informativo, compacto e de carregamento instantâneo, unificando a identidade visual entre Bash, Zsh e POSIX Sh.

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

- Utiliza o módulo nativo `vcs_info` do Zsh.
- Renderização de cores através do sistema de expansão `%F{color}...%f`.
- Suporte a Zstyle nativo para autocompletion colorido e menu interativo.

### 2. Bash (`theme/bash.sh`)

- Utiliza sequências de escape ANSI embutidas entre `\[` e `\]` para garantir que o Bash calcule corretamente a largura da linha e evite quebras de texto ao navegar pelo histórico.
- Helper assíncrono ou atômico para leitura rápida de branch Git via `git symbolic-ref` / `git rev-parse`.

### 3. POSIX Sh (`theme/sh.sh`)

- **Linha de Base FreeBSD 15.1 (`/bin/sh`):** Suporta expansão de parâmetros no `$PS1`/`$PS2` (`$VAR`, `${VAR}`, `$?`, `$$`) e sequências ANSI canônicas.
- **Teto Físico de Memória (`PROMPTLEN = 192`):** O parser em C do FreeBSD (`bin/sh/parser.c`) aloca um buffer estático de 192 bytes sem alocação dinâmica no heap (`malloc`). Qualquer prompt acima de 191 bytes é truncado pelo sistema.
- **Peculiaridades da `libedit`:** Utiliza delimitador único (`\001`), descarta literais consecutivos sem caractere imprimível e desincroniza o cursor vertical em multilinhas (`\n`). Por isso, o tema adota rigorosamente **1 linha**.
- **Decisão Arquitetural Upstream:** Os mantenedores do FreeBSD rejeitam intencionalmente parsers reentrantes e hooks arbitrários (`PROMPT_COMMAND`) para preservar a segurança contra injeção de comandos e manter a estabilidade no _single-user mode_.
- **Mini Prompt Gráfico (`! _is_raw_tty`):** Em emuladores modernos, exibe pílula do sistema com versão (` 15.1`), pasta (``), usuário dinâmico (``) e Git (`󰊢`), calibrado estritamente entre 177 e 188 bytes no pior caso.
- **Motor de Orçamento Dinâmico de Buffer:** Em vez de limites fixos, calcula em tempo real via aritmética nativa POSIX o espaço exato disponível no buffer `ps[192]`. Deduz o tamanho do usuário (`${#_user}`) e presença do Git, alocando inteligentemente o orçamento restante entre pasta e branch. Permite nomes de pastas longos (até 40+ caracteres) quando fora do Git ou com branch curta, e encolhe proporcionalmente sob nomes extensos para travar no teto físico de 191 bytes.
- **Fallback TTY 100% Bold (`_is_raw_tty`):** No console puro `vt`/`syscons`, comuta para prompt ASCII atômico de linha única 100% negrito via persistência ANSI ECMA-48, com orçamento dinâmico operando entre 150 e 190 bytes com salvaguarda absoluta contra overflow.
- **Triggers de Precisão:** Atualização do Git através de wrappers de alto desempenho (`cd`, `git`, `got`, `:`) sem overhead de subshells a cada enter vazio.

---

## 📟 Fallback Resiliente em TTY Bruto

Ao inicializar uma máquina diretamente em um console TTY de emergência (sem servidor gráfico ou driver de fonte carregado) ou em uma conexão de console serial:

- **Detecção de TTY Puro:** Se `$TERM` for `linux`, `vt100` ou similar sem suporte a glifos Nerd Fonts, o tema desativa automaticamente ícones complexos.
- **Substituição de Caracteres:** Glifos Unicode são substituídos por equivalentes ASCII simples (`*`, `!`, `>`), garantindo que o prompt nunca exiba caracteres corrompidos (_mojibake_ ou caixas vazias).
