# 🖌️ theme/ — Temas de Prompt & Identidade Visual

Esta pasta gerencia a arquitetura modular de renderização de prompt e estilos visuais do **Universal Shell Environment**, com suporte a **Zsh**, **Bash**, **POSIX Sh** e **KornShell (ksh)** nos modos **PTY** (gráfico / Nerd Fonts) e **TTY** (console puro ASCII).

---

## 📁 Arquitetura de Diretórios

A renderização é desacoplada através de helpers compartilhados (`common/`), temas universais (`styles/pty/` e `styles/tty/`) e entrypoints nativos por interpretador:

```text
theme/
├── common/
│   ├── colors.sh            # Paleta de cores com isolamento de largura zero
│   └── git.sh               # Leitura ultra-rápida de Git/Got (zero forks)
├── styles/
│   ├── pty/
│   │   ├── pill.sh          # Layout PTY Pill (1 linha com cápsula gráfica)
│   │   ├── micro.sh         # Layout PTY Micro (1 linha minimalista)
│   │   └── multi.sh         # Layout PTY Multi (3 linhas informativo)
│   └── tty/
│       ├── pill.sh          # Layout TTY Pill (1 linha ASCII estruturado)
│       └── micro.sh         # Layout TTY Micro (1 linha ASCII minimalista)
├── bash.sh                  # Entrypoint e despachante do Bash
├── zsh.sh                   # Entrypoint e despachante do Zsh
├── ksh.sh                   # Entrypoint e despachante do Ksh
└── sh.sh                    # Entrypoint e motor de buffer do FreeBSD /bin/sh
```

---

## 🎨 Os 5 Temas Canônicos

O Universal Shell oferece **5 variações visuais** distribuídas entre os modos PTY e TTY:

### 1. PTY — `pill` (Pílula Gráfica de 1 Linha)

- **Visual:** ` 15.1  zsh  shell  gabrielf 󰊢 main*  `
- **Descrição:** Layout compacto de 1 linha com cápsula inicial de sistema operacional e shell, diretório atual, usuário e branch Git com indicador amarelo de dirty status.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `/bin/sh` (padrão em FreeBSD 14+).

### 2. PTY — `micro` (Minimalista Gráfico de 1 Linha)

- **Visual:** ` 15.1  shell  gabrielf 󰊢 main*  `
- **Descrição:** Layout _streamlined_ ultra-leve de 1 linha com glifos diretos sem delimitadores de cápsula e sem identificador de shell redundante, maximizando o espaço horizontal útil.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `/bin/sh` (padrão em FreeBSD ≤ 13 ou buffer < 192 bytes).

### 3. PTY — `multi` (Multilinha Informativo de 3 Linhas)

- **Visual:**
    ```text
     15.1─ zsh
    ┌──❮ 22:30:15❯─❮ 17/09/26❯─❮ shell❯─ ❮ gabrielf❯ ❮󰊢 main*❯
    └─
    ```
- **Descrição:** Prompt de 3 linhas com linhas guia de árvore, relógio, calendário, pasta, usuário e controle de versão, deixando a linha inferior limpa para comandos longos.
- **Suporte:** Zsh, Bash e Ksh (padrão em Zsh e Bash). _Nota: intencionalmente indisponível no FreeBSD `/bin/sh` devido ao limite físico de 192B e bug de cursor multilinha da `libedit`._

### 4. TTY — `pill` (ASCII Estruturado de 1 Linha)

- **Visual:** `gabrielf@freebsd (zsh):[shell] (main*) $ `
- **Descrição:** Prompt ASCII limpo e 100% negrito para consoles VGA, VT100 ou sessões seriais, destacando usuário, host, shell e branch entre delimitadores sem caracteres especiais.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `/bin/sh` (padrão em consoles puros).

### 5. TTY — `micro` (ASCII Minimalista de 1 Linha)

- **Visual:** `gabrielf@freebsd:shell (main*) $ `
- **Descrição:** Prompt ASCII de máxima densidade, eliminando o nome do shell e os colchetes para reduzir o consumo de colunas no terminal de emergência.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `/bin/sh`.

---

## ⚡ Configuração Dinâmica (`$PROMPT_STYLE`)

Para alternar entre os temas, basta exportar a variável `PROMPT_STYLE` no seu ambiente (`~/.profile`, `~/.bashrc` ou `~/.zshrc`):

```sh
# Ativar tema compacto de 1 linha com pílula
export PROMPT_STYLE="pill"

# Ativar tema ultra-minimalista de 1 linha
export PROMPT_STYLE="micro"

# Ativar tema completo de 3 linhas (Bash, Zsh e Ksh)
export PROMPT_STYLE="multi"
```

### Regras de Auto-Fallback:

1. **Fallback TTY:** Se o terminal for um console puro (`_is_raw_tty`), o estilo `multi` comuta automaticamente para `pill` (ASCII estruturado).
2. **Salvaguarda do FreeBSD `/bin/sh`:** No `/bin/sh`, o estilo `multi` comuta automaticamente para `pill` para proteger o buffer estático de 192 bytes. Se o limite físico do buffer for inferior a 192 bytes (`PROMPT_BUFFER_LIMIT < 192`), comuta automaticamente para `micro`.
3. **Desempenho Zero-I/O:** O carregamento do arquivo de tema em disco ocorre apenas na inicialização ou quando a variável `PROMPT_STYLE` for alterada. Renderizações subsequentes ocorrem 100% em memória, garantindo latência < 32ms (classificação ULTRA).

Consulte a documentação completa em **[docs/THEMES.md](../docs/THEMES.md)**.
