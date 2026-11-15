# 🖌️ theme/ — Temas de Prompt & Identidade Visual

Esta pasta gerencia a arquitetura modular de renderização de prompt e estilos visuais (`0644`, carregados via `source`) do **Universal Shell Environment**, com suporte a **Zsh**, **Bash**, **POSIX Sh** e **KornShell (`ksh`)** nos modos **PTY** (gráfico / Nerd Fonts) e **TTY** (console puro ASCII), em paridade visual com o tema nativo do **Fish** (`target/common/fish/prompt.fish`).

---

## 📁 Arquitetura de Diretórios

A renderização é desacoplada através de helpers compartilhados (`common/`), temas universais (`styles/pty/` e `styles/tty/`) e entrypoints nativos por interpretador:

| Caminho               | Papel                                                                                                 |
| :-------------------- | :---------------------------------------------------------------------------------------------------- |
| `common/colors.sh`    | Paleta ANSI e `PROMPT_OS_COLOR` (`red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`)        |
| `common/git.sh`       | Leitura zero-fork de `.git/HEAD` e `.got/head-ref` (com fallback `got info`)                          |
| `styles/pty/pill.sh`  | Layout PTY Pill (1 linha com cápsula `...`)                                                         |
| `styles/pty/micro.sh` | Layout PTY Micro (1 linha minimalista sem cápsula)                                                    |
| `styles/pty/multi.sh` | Layout PTY Multi (3 linhas informativo)                                                               |
| `styles/tty/pill.sh`  | Layout TTY Pill (1 linha ASCII estruturado)                                                           |
| `styles/tty/micro.sh` | Layout TTY Micro (1 linha ASCII minimalista)                                                          |
| `zsh.sh`              | Entrypoint Zsh com proteção anti-injeção `_theme_ps1_*` + escape `%` (preserva glifos PUA)            |
| `bash.sh`             | Entrypoint Bash com proteção anti-injeção `_theme_ps1_*` + `promptvars`                               |
| `ksh.sh`              | Entrypoint Ksh (`pdksh`/`oksh`) com escapes hex `\x1b` (`_THEME_ESCAPE`) e delimitador `\x01\r`       |
| `sh.sh`               | Entrypoint e motor de buffer do FreeBSD `sh` (`_create_trigger cd git got` preservando `$_exit_code`) |

---

## 🎨 Os 5 Temas Canônicos

O Universal Shell oferece **5 variações visuais** distribuídas entre os modos PTY e TTY:

### 1. PTY — `pill` (Pílula Gráfica de 1 Linha)

- **Visual:** ` 15.1  zsh  shell  operator 󰊢 main*  `
- **Descrição:** Layout compacto de 1 linha com cápsula inicial de sistema operacional e shell, diretório atual, usuário e branch Git/Got com indicador amarelo de dirty status.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `sh` (padrão em FreeBSD 14+).

### 2. PTY — `micro` (Minimalista Gráfico de 1 Linha)

- **Visual:** ` 15.1  shell  operator 󰊢 main*  `
- **Descrição:** Layout _streamlined_ ultra-leve de 1 linha com glifos diretos sem delimitadores de cápsula e sem identificador de shell redundante, maximizando o espaço horizontal útil.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `sh` (padrão em FreeBSD ≤ 13 ou buffer < 192 bytes).

### 3. PTY — `multi` (Multilinha Informativo de 3 Linhas)

- **Visual (Linux):**
    ```text
     44  7.2.11  zsh
    ┌── 22:30:15─ 17/09/26─ shell─  operator 󰊢 main*
    └─
    ```
- **Visual (BSD / Windows / macOS / illumos):**
    ```text
     15.1  zsh
    ┌── 22:30:15─ 17/09/26─ shell─  operator 󰊢 main*
    └─
    ```
- **Descrição:** Prompt de 3 linhas com linhas guia de árvore, relógio, calendário, pasta, usuário e controle de versão, deixando a linha inferior limpa para comandos longos. Em sessões `root` no PTY, o ícone ` ` e o chevron `` ficam em vermelho enquanto o nome `root` assume magenta.
- **Suporte:** Zsh, Bash e Ksh (e paridade em Fish via `target/common/fish/prompt.fish`). _Nota: intencionalmente indisponível no FreeBSD `sh` devido ao limite físico de 192B e bug de cursor multilinha da `libedit`._

### 4. TTY — `pill` (ASCII Estruturado de 1 Linha)

- **Visual:** `operator@freebsd (zsh):[shell] (main*) $ `
- **Descrição:** Prompt ASCII limpo e 100% negrito para consoles VGA, VT100 ou sessões seriais, destacando usuário (`root@host` e `#` em vermelho sob privilégios elevados), host, shell e branch entre delimitadores sem caracteres especiais.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `sh` (padrão em consoles puros).

### 5. TTY — `micro` (ASCII Minimalista de 1 Linha)

- **Visual:** `operator@freebsd:shell (main*) $ `
- **Descrição:** Prompt ASCII de máxima densidade, eliminando o nome do shell e os colchetes para reduzir o consumo de colunas no terminal de emergência.
- **Suporte:** Zsh, Bash, Ksh e FreeBSD `sh`.

---

## ⚡ Configuração Dinâmica & Segurança

Para alternar entre os temas, exporte `PROMPT_STYLE` (`pill`, `micro`, `multi`) ou `PROMPT_OS_COLOR` (`red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`):

```sh
export PROMPT_STYLE="pill"
export PROMPT_OS_COLOR="blue"
```

### Regras de Auto-Fallback & Invariantes:

1. **Fallback TTY & Cursor:** Se o terminal for um console puro (`_is_raw_tty`), o estilo `multi` comuta automaticamente para `pill` (ASCII estruturado) e o prompt assegura cursor estático em bloco sólido (`\e%G\e[?16;238;0c` no Linux VT ou `\e[1 q` em PTYs via `$'\e'` / `printf '\x1b[1 q'`), prevenindo pisque e distorções cromáticas.
2. **Proteção contra Injeção em `PS1`:** Zsh protege campos dinâmicos via `_theme_ps1_*` + escape `%` (`[[ -o promptsubst ]]`), preservando glifos PUA sem `\ue62a`; Bash valida `shopt -q promptvars` e referencia variáveis `_theme_ps1_*` sem reavaliação de nomes de diretórios/branches arbitrários.
3. **OpenBSD `pdksh`/`oksh` & Triggers POSIX `sh`:** `ksh.sh` usa escapes hexadecimais `_THEME_ESCAPE` (`printf '\x1b'`, zero notação octal) e delimitador `\x01\r`; `sh.sh` usa `_create_trigger cd git got` preservando `$_exit_code` e evitando disparo duplo do hook `zoxide`.
4. **Salvaguarda do FreeBSD `sh`:** No `sh`, o estilo `multi` comuta automaticamente para `pill` para proteger o buffer estático de 192 bytes. Se `PROMPT_BUFFER_LIMIT < 192`, comuta automaticamente para `micro`.
5. **Desempenho Zero-I/O:** Leitura direta de `.git/HEAD` e `.got/head-ref` (fallback `got info`) e renderização 100% em memória garantem latência < 32ms (classificação ULTRA).

Consulte a documentação completa em **[docs/THEMES.md](../docs/THEMES.md)**.
