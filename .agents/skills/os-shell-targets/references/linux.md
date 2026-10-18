# 🐧 Linux Shell — Runtimes, Distribuições & Integração Gráfica

No Linux, os alvos interativos suportados em `target/linux/` são **estritamente `bash` e `zsh`**. Não existe alvo `target/linux/sh` e o benchmark de `sh` é desativado.

---

## 🚫 Rejeição de `kebab-case` pelos Parsers `/bin/sh`

1. **Debian / Ubuntu (`/bin/dash`):** A BNF do Dash rejeita formalmente hífens em nomes de funções com `Syntax error: Bad function name`.
2. **Arch / Fedora / openSUSE (`bash --posix`):** Quando invocado como `sh`, o Bash ativa `posixly_correct = 1` e sua função `legal_identifier()` rejeita hífens com `not a valid identifier`.
3. Portanto, em scripts utilitários executados via `sh`, aplicamos auto-elevação imediata para `zsh` ou `bash`.

---

## 📦 Cascatas Canônicas de Gerenciadores de Pacotes

A ferramenta `update-all` segue a precedência nativa das famílias de distribuição:

```text
Arch Linux:     paru > yay > pacman
Debian/Ubuntu:  nala > apt-get > apt
Fedora/RHEL:    dnf > rpm-ostree > yum
Alpine:         apk
openSUSE:       zypper
Void Linux:     xbps-install
Universal:      flatpak > snap
```

---

## 🎨 Detecção Dinâmica de Tema Escuro / Claro

- **XDG Desktop Portal (Wayland/Flatpak):** Consulta via D-Bus ao schema `org.freedesktop.appearance.color-scheme` (`1` = Dark, `2` = Light).
- **GNOME:** `gsettings get org.gnome.desktop.interface color-scheme`.
- **KDE Plasma:** Leitura de `~/.config/kdeglobals`.

---

## 🖥️ Consoles Virtuais vs Emuladores Gráficos

- **PTY Gráfico:** Alacritty, Kitty, Foot, WezTerm com suporte pleno a 24-bit TrueColor e Nerd Fonts v3.
- **Console TTY Puro (`_is_raw_tty`):** Fontes bitmap de console (VGA/PSF) limitadas a 256/512 glifos; prompt comuta automaticamente para ASCII sem Nerd Fonts.

### 📐 Arquitetura de 512 Glifos & Auto-Cura de Cursor Estático

Em consoles virtuais Linux (`/dev/tty[1-6]`), fontes de alta legibilidade como a Spleen 12x24 (`spleen-12x24.psfu`) operam com 512 glifos. Nessa arquitetura:

1. **Deslocamento de Atributos no Kernel (`drivers/tty/vt/vt.c`):** O bit de seleção de página (`vc_hi_font_mask = 0x0100`) reorganiza os atributos de vídeo. O primeiro plano (_foreground_) passa a ocupar os bits 9-11 e o fundo (_background_) os bits 13-15.
2. **O Bug Histórico de Cor Ciano:** A macro `#define CUR_BG 0x7000` (bits 12-14) no Linux VT assume a disposição de 256 glifos. Ao usar flags como `CUR_ALWAYS_BG` (32) ou `CUR_INVERT_FG_BG` (64) — presentes na sequência legada `\e[?112c` —, o kernel inverte o bit 12 (intensidade) e os bits 13-14 (azul + verde), deixando o vermelho inalterado, colorindo o cursor de ciano.
3. **A Sequência Canônica de Auto-Cura (`\e%G\e[?16;238;0c`):**
    - `\e%G`: Seleciona e rearma o interpretador UTF-8 do console, recuperando a renderização mesmo após saídas corrompidas de binários na tela.
    - `\e[?16;238;0c`: Configura o softcursor com `p1=16` (`CUR_SW` isolado, sem invocar as flags quebradas de fundo), `p2=238` (`0xee = 11101110b`, máscara XOR precisa que inverte simultaneamente bits 13-15 e bits 9-11) e `p3=0`. Produz um bloco sólido branco puro com texto preto sob o cursor.
4. **Contrato de Auto-Cura do Shell:** O Shell injeta essa sequência na inicialização (`core/environment.sh`), em prompts interativos (`theme/bash.sh`, `theme/zsh.sh`) e no wrapper de encerramento de editores modais (`hx()` em `context/desktop/common.sh`), restaurando imediatamente o cursor caso o editor tenha emitido DECSCUSR para alterar o formato para barra ou linha piscante.
