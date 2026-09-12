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

## 1. Papel do `/bin/sh` no Linux e a Incompatibilidade do Dash

Ao contrário dos BSDs, no Linux o `/bin/sh` não possui uma implementação canônica única:

1. **Debian / Ubuntu:** O `/bin/sh` aponta para o **Dash** (`/bin/dash`).
   - **O Problema do Kebab-Case:** A BNF do parser do Dash rejeita estritamente o caractere hífen (`-`) em identificadores de funções POSIX (ex: `update-all()`, `clean-cache()`, `mount-device()`).
   - **Decisão Arquitetural:** O Dash é **explicitamente descartado** para a sessão interativa do usuário no Universal Shell Environment. Em scripts ou funções de bootstrap, se o interpretador ativo for o Dash, deve-se aplicar guarda de auto-elevação para `bash` ou `zsh`.
2. **Arch Linux / Fedora / openSUSE:** O `/bin/sh` geralmente é um symlink para o **GNU Bash** em modo POSIX (`bash --posix`).
3. **Alpine Linux / Contêineres:** O `/bin/sh` é fornecido pelo **BusyBox ash**, que suporta nomes com hífen mas carece de certos builtins avançados.

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
