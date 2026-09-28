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

- **Console TTY Puro (`_is_raw_tty`):** Fontes VGA limitadas a 256/512 glifos; prompt comuta automaticamente para ASCII sem Nerd Fonts.
- **PTY Gráfico:** Alacritty, Kitty, Foot, WezTerm com suporte pleno a 24-bit TrueColor e Nerd Fonts v3.
