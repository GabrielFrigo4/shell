---
name: linux-shell
description: >-
  Deep technical reference and runbook for Linux shell environments, distribution families (Arch, Debian, Fedora, Alpine),
  service managers (systemd, OpenRC, runit), D-Bus dark mode, and terminal virtualization.
  Use when maintaining, developing, or auditing Linux-specific shell behaviors and package cascades.
---

# Linux Shell — Architecture, Distributions & Runtime Runbook

Este documento consolida o conhecimento canônico, particularidades de distribuições e padrões de engenharia para o ecossistema **Linux** no repositório **Universal Shell Environment** (`/usr/local/share/shell`).

---

## 1. Papel do `/bin/sh` no Linux e Exclusividade de Bash e Zsh

No Linux, os alvos interativos suportados em `target/linux/` são **estritamente `bash` e `zsh`**. Não existe alvo `target/linux/sh` e o benchmark de `sh` é desativado no Linux.

As implementações de `/bin/sh` no Linux são tratadas estritamente como shells não-interativos de sistema/boot:

1. **Debian / Ubuntu (`/bin/dash`):**
   - A BNF do parser do Dash rejeita estritamente hífens (`-`) em identificadores de funções POSIX com `Syntax error: Bad function name` (exit 2).
   - Incompatível com o design de comandos públicos em `kebab-case` (`path-front`, `update-all`).
   - Em scripts como `install.sh`, aplica-se guarda de auto-elevação imediata para `zsh` ou `bash`.
2. **Arch Linux / Fedora / openSUSE (`bash --posix`):**
   - O `/bin/sh` é um symlink para o GNU Bash. Quando invocado como `sh`, a variável interna `posixly_correct` é forçada para `1`.
   - A função `legal_identifier()` do Bash passa a rejeitar hífens (`legal_identifier: 'path-front': not a valid identifier`), falhando na importação de bibliotecas compartilhadas.
3. **Alpine Linux / Contêineres (BusyBox `ash`):**
   - Embora o BusyBox ash suporte hífens, carece de recursos interativos modernos e é restrito a contêineres mínimos.

---

## 2. Cascatas Canônicas de Gerenciadores de Pacotes

No Linux, o comando orquestrador `update-all` e os utilitários de sistema devem respeitar a ordem de precedência nativa das famílias de distribuição:

```
Arch Linux:     paru > yay > pacman
Debian/Ubuntu:  nala > apt-get > apt
Fedora/RHEL:    dnf > rpm-ostree > yum
Alpine:         apk
openSUSE:       zypper
Void Linux:     xbps-install
Universal:      flatpak > snap
```

### Regras de Execução:

- Nunca use `sudo` hardcoded. Utilize a abstração `_as_root` de `library/functions.sh` (`doas` > `sudo` > `su -c`).
- Valide sempre se o binário existe em tempo de execução (`command -v`).

---

## 3. Detecção de Dark Mode & Integração Gráfica

Em ambientes desktop Linux, a detecção de tema escuro/claro não é um arquivo estático:

1. **Padrão XDG Desktop Portal (Moderno / Wayland & Flatpak):**
   - Consulta D-Bus ao schema `org.freedesktop.appearance.color-scheme`.
   - Valor `1` = Dark, `2` = Light, `0` = Default.
2. **GNOME / Cinnamon:**
   - `gsettings get org.gnome.desktop.interface color-scheme` (`'prefer-dark'`).
3. **KDE Plasma:**
   - Inspeção de `kdeglobals` em `~/.config/kdeglobals` (`[Colors:Window] BackgroundNormal`).

---

## 4. Consoles Virtuais vs Emuladores Gráficos

- **Console Puro TTY (`_is_raw_tty`):**
  - Terminais virtuais do kernel Linux (`/dev/tty1` a `/dev/tty6`, `$TERM=linux`).
  - Fontes de console VGA limitadas a 256 ou 512 glifos (sem Nerd Fonts).
  - O prompt comuta automaticamente para ASCII puro de linha única.
- **Emuladores Gráficos (PTYs):**
  - Alacritty, Kitty, Foot, WezTerm, GNOME Terminal, Konsole.
  - Suporte completo a Nerd Fonts v3, 24-bit TrueColor (`\e[38;2;R;G;Bm`) e OSC 52 para clipboard.
