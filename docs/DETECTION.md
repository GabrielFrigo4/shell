# 🧠 Motores de Inteligência & Detecção (`core/detect.sh` & `library/desktop/detect.sh`)

Os módulos `core/detect.sh` (SO, shell, distro, cache, Raw TTY e binários CLI modernos) e `library/desktop/detect.sh` (ambientes desktop, esquemas Dark/Light e toolkits gráficos) compõem o cérebro investigativo do **Universal Shell Environment**. Eles sondam o ambiente do hospedeiro em baixo nível sem degradação de desempenho.

---

## 🔍 Módulos de Sondagem

### 1. Sistema Operacional & Shell Ativo

- **`_detect_os`**: Identifica o sistema via `uname -s` e normaliza para: `freebsd`, `linux`, `macos`, `windows`, `openbsd`, `netbsd` ou `illumos`.
- **`_detect_shell`**: Identifica se a sessão interativa atual é executada por `zsh`, `bash`, `ksh`, `fish`, `sh`, `dash`, `ash`, etc.
- **`_detect_enabled_shell`**: Retorna o binário de shell POSIX-compatível canônico respeitando a ordem de precedência: Shell do `chsh`/passwd (se válido e suportado) ➔ `zsh` ➔ `bash` ➔ `ksh` (OpenBSD) ➔ `sh` (exclusivo FreeBSD; `dash` e NetBSD `/bin/sh` (`ash`) são rejeitados e roteados para `zsh`/`bash`). Suporta flag `--name`. Note que o `fish` possui módulo dedicado em `target/common/fish/` via `install.sh -s fish`.

### 2. Distribuições, Derivados & Família de Gerenciadores

- **`_detect_distro`**: Mapeia distribuições e derivados nativos sem acoplamento a um único SO:
    - **Linux:** `fedora`, `arch`, `debian`, `ubuntu` (com detecção de sabores `kubuntu`, `xubuntu`, `lubuntu`), `devuan`, `opensuse`, `void`, `alpine`, `gentoo`, `nixos`, `solus`, `slackware`, `guix`, `openwrt`, `ol` (Oracle), `azurelinux`, `qubes`, etc.
    - **BSD:** `freebsd`, `ghostbsd`, `nomadbsd`, `openbsd`, `netbsd`.
    - **illumos:** `omnios`, `smartos`, `openindiana`, `illumos`.
- **`_detect_distro_family`**: Agrupa os sistemas por sua raiz arquitetural de pacotes e ferramentas de base:
    - `arch` ➔ Gerenciador `pacman` (com detecção de helpers AUR `paru`/`yay`)
    - `debian` ➔ Gerenciador `apt`
    - `fedora` ➔ Gerenciadores `dnf` ou `tdnf` (Azure Linux / Photon)
    - `suse` ➔ Gerenciador `zypper`
    - `void` ➔ Gerenciador `xbps`
    - `alpine` ➔ Gerenciador `apk`
    - `gentoo` ➔ Gerenciador `emerge`
    - `nixos` ➔ Gerenciadores `nixos-rebuild` e `nix`
    - `solus` ➔ Gerenciador `eopkg`
    - `slackware` ➔ Gerenciador `slackpkg`
    - `guix` ➔ Gerenciador `guix`
    - `embedded` ➔ Gerenciador `opkg` (OpenWrt / Entware)
    - `bsd` ➔ Gerenciadores `pkg` (FreeBSD, GhostBSD, NomadBSD), `pkg_add` (OpenBSD) ou `pkgin` (NetBSD)
    - `illumos` ➔ Gerenciadores `pkg` (IPS em OmniOS/OpenIndiana) ou `pkgin` (SmartOS)
    - `darwin` ➔ Gerenciador `brew` (Homebrew)
- **`_detect_distro_icon`**: Retorna o glifo vetorial oficial Nerd Fonts proporcional em altura (conjunto Font Logos `U+F300`):
    - ` ` (Linux Tux full-scale), ` ` (FreeBSD / GhostBSD / NomadBSD), ` ` (OpenBSD), ` ` (NetBSD), ` ` (illumos), `󰖨 ` (Solaris/SunOS), ` ` (macOS Apple), ` ` (Windows).
      Esta inteligência alimenta dinamicamente comandos universais como `update-system`, `clean-system` e `update-all`.

### 3. Ambiente Gráfico, Desktop Environments & Sessão de Janelas

- **`_detect_desktop_environment`**: Analisa variáveis `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION` e processos em execução via `pgrep` para identificar:
    - **11 Desktop Environments Canônicos:** `kde` (Plasma 5/6), `gnome` (GNOME Shell), `mate`, `cinnamon`, `xfce`, `lxqt`, `lxde`, `budgie`, `pantheon`, `deepin`, `cosmic`.
    - **Compositores Wayland & WMs X11 Independentes:** `sway`, `hyprland`, `river`, `labwc`, `cage`, `niri`, `wayfire`, `dwl`, `hikari`, `weston`, `openbox`, `cwm`, `dwm`, `fvwm3`, `fvwm`, `fluxbox`, `icewm`, `jwm`, `pekwm`, `twm`, `matchbox-window-manager`, `wm`.
- **`_detect_desktop_theme`**: Resolve o sabor visual canônico percorrendo a hierarquia determinística:
    1. Parâmetro explícito fornecido à função (`kde`, `gnome`, `mate`, `cinnamon`, `xfce`, `lxqt`, `lxde`, `budgie`, `pantheon`, `deepin`, `cosmic`).
    2. Leitura de `$XDG_CURRENT_DESKTOP` e `$DESKTOP_SESSION`.
    3. Inspeção de processos de sessão ativos via `pgrep` (`plasmashell`/`kwin_*`, `gnome-shell`, `mate-session`, `cinnamon`, `xfce4-session`, `lxqt-session`, `lxsession`, `budgie-wm`/`budgie-panel`, `gala`/`wingpanel`, `dde-desktop`/`deepin-wm`, `cosmic-comp`/`cosmic-session`).
    4. Sonda de binários e diretórios de sistema na ordem canônica de precedência: `KDE > GNOME > MATE > Cinnamon > XFCE > LXQt > LXDE > Budgie > Pantheon > Deepin > COSMIC > Fallback (adwaita)`.
- **`_detect_color_scheme`**: Consulta dinamicamente a intenção estética em tempo real (`dark` ou `light`, sem fixar cache obsoleto em disco) via portal D-Bus XDG (`org.freedesktop.appearance.color-scheme`), `kreadconfig6`/`kreadconfig5`/`~/.config/kdeglobals`, GSettings (`org.gnome.desktop.interface color-scheme`, tratando `'default'` com tema não-escuro como `light`) e chaves nativas COSMIC/XFCE/Cinnamon/MATE.
- **`_resolve_gtk_theme` & `_detect_gtk_theme`**: Mapeia o tema GTK coerente para ambos os modos **light** e **dark** do DE mestre (`adw-gtk3` / `adw-gtk3-dark`, `Breeze` / `Breeze-Dark`, `Greybird` / `Greybird-dark`, `Mint-Y` / `Mint-Y-Dark`, `Yaru-MATE` / `Yaru-MATE-dark`, `Clearlooks-Phenix`, `Materia` / `Materia-dark`, `io.elementary.stylesheet.blueberry` / `io.elementary.stylesheet.blueberry-dark`, `deepin` / `deepin-dark`, `cosmic` / `cosmic-dark`) inspecionando `/usr/share/themes`, `/usr/local/share/themes` e diretórios do usuário.
- **`_detect_qt_theme`**: Resolve `QT_STYLE_OVERRIDE` (`"Breeze"` para KDE/LXQt como nome de QStyle válido no Qt6, ou `"chameleon"` no Deepin) alinhando componentes Qt à paleta global.
- **`_detect_qt_platform_theme`**: Define `QT_QPA_PLATFORMTHEME` (`xdgdesktopportal`, `lxqt`, `deepin`, `gtk3`, `qt6ct`, `qt5ct`) para integração nativa de janelas de diálogo e estilos de widgets.
- **Sessão Wayland vs. X11**: Avalia `$XDG_SESSION_TYPE` e `$WAYLAND_DISPLAY` para determinar a rota gráfica correta.

#### Matriz de Detecção de Ambientes Gráficos & Compositores

| Ambiente / Compositor | Categoria          | Assinatura de Processos (`pgrep`)               | Provas de Binários / Diretórios                                                                 | Tema GTK Canônico (Light / Dark)                       | Qt Platform Theme                      | Cursor Padrão                | Fonte Padrão                 |
| :-------------------- | :----------------- | :---------------------------------------------- | :---------------------------------------------------------------------------------------------- | :----------------------------------------------------- | :------------------------------------- | :--------------------------- | :--------------------------- |
| **KDE (Plasma)**      | Full DE            | `plasmashell`, `kwin_wayland`, `kwin_x11`       | `plasmashell`, `startplasma-wayland`, `/usr/share/plasma`, `/usr/local/share/plasma`            | `Breeze` / `Breeze-Dark`                               | `xdgdesktopportal`                     | `breeze_cursors`             | `Noto Sans`                  |
| **GNOME**             | Full DE            | `gnome-shell`                                   | `gnome-shell`, `gnome-session`, `/usr/share/gnome-shell`, `/usr/local/share/gnome-shell`        | `adw-gtk3` / `adw-gtk3-dark` / GSettings               | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita`                    | `Adwaita Sans` / `Cantarell` |
| **MATE**              | Full DE            | `mate-session`                                  | `mate-session`, `/usr/share/mate`, `/usr/local/share/mate`                                      | `Yaru-MATE` / `Yaru-MATE-dark`, `BlackMATE`            | `gtk3`                                 | `Adwaita`                    | `Ubuntu` / `DejaVu Sans`     |
| **Cinnamon**          | Full DE            | `cinnamon`                                      | `cinnamon`, `cinnamon-session`, `/usr/share/cinnamon`, `/usr/local/share/cinnamon`              | `Mint-Y` / `Mint-Y-Dark`                               | `gtk3`                                 | `Adwaita`                    | `Ubuntu` / `DejaVu Sans`     |
| **XFCE**              | Full DE            | `xfce4-session`                                 | `xfce4-session`, `/usr/share/xfce4`, `/usr/local/share/xfce4`                                   | `Greybird` / `Greybird-dark`                           | `gtk3`                                 | `Adwaita`                    | `Ubuntu` / `DejaVu Sans`     |
| **LXQt**              | Full DE            | `lxqt-session`                                  | `lxqt-session`, `/usr/share/lxqt`, `/usr/local/share/lxqt`                                      | `Breeze` / `Breeze-Dark`, `Arc-Dark`                   | `lxqt`                                 | `breeze_cursors`             | `Noto Sans` / `Sans Serif`   |
| **LXDE**              | Full DE            | `lxsession`                                     | `lxsession`, `startlxde`, `/usr/share/lxde`, `/usr/local/share/lxde`                            | `Clearlooks-Phenix`, `Arc-Dark`                        | `gtk3`                                 | `Adwaita`                    | `DejaVu Sans` / `Sans`       |
| **Budgie**            | Full DE            | `budgie-wm`, `budgie-panel`                     | `budgie-desktop`, `budgie-wm`, `/usr/share/budgie-desktop`, `/usr/local/share/budgie-desktop`   | `Materia` / `Materia-dark`, `Arc-Dark`                 | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita`                    | `Adwaita Sans` / `Ubuntu`    |
| **Pantheon**          | Full DE            | `gala`, `wingpanel`                             | `gala`, `wingpanel`, `/usr/share/pantheon`, `/usr/local/share/pantheon`                         | `io.elementary.stylesheet.blueberry` (`-dark`)         | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `elementary` / `Adwaita`     | `Inter` / `Open Sans`        |
| **Deepin**            | Full DE            | `dde-desktop`, `deepin-wm`                      | `dde-desktop`, `dde-session`, `/usr/share/dde`, `/usr/local/share/dde`                          | `deepin` / `deepin-dark`                               | `deepin`                               | `bloom` / `Adwaita`          | `Noto Sans`                  |
| **COSMIC**            | Full DE            | `cosmic-comp`, `cosmic-session`                 | `cosmic-session`, `cosmic-comp`, `/usr/share/cosmic`, `/usr/local/share/cosmic`                 | `cosmic` / `cosmic-dark`                               | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `cosmic` / `Adwaita`         | `Fira Sans` / `Cantarell`    |
| **WMs Wayland**       | Wayland Compositor | `sway`, `hyprland`, `labwc`, `river`, `niri`... | `sway`, `Hyprland`, `labwc`, `river`, `niri`, `wayfire`, `dwl`, `hikari`, `weston`, `cage`      | Paridade Light/Dark com DE mestre (`adw-gtk3*` padrão) | `qt6ct` / `qt5ct` / `xdgdesktopportal` | Herda DE mestre (`Adwaita`*) | `JetBrainsMono Nerd Font`    |
| **WMs X11**           | X11 Window Manager | `openbox`, `cwm`, `fvwm3`, `fluxbox`...         | `openbox`, `cwm`, `fvwm3`, `fvwm`, `fluxbox`, `icewm`, `jwm`, `pekwm`, `dwm`, `twm`, `matchbox` | Paridade Light/Dark com DE mestre (`adw-gtk3*` padrão) | `gtk3`                                 | Herda DE mestre (`Adwaita`*) | `JetBrainsMono Nerd Font`    |

---

## 🎨 Harmonização Visual Automática (Light/Dark Parity & Toolkits)

O Universal Shell detecta a intenção estética em tempo real do sistema operacional e alinha toolkits heterogêneos para evitar incoerências visuais:

### 1. Detecção Universal de Esquema de Cores (`_detect_color_scheme`)

- Consulta em sequência dinâmica (sem persistir cache obsoleto em disco):
    1. **XDG Desktop Portal via D-Bus** (quando `$DBUS_SESSION_BUS_ADDRESS` ativo): `org.freedesktop.appearance.color-scheme` (GNOME 42+, KDE Plasma 6 e compositores Wayland).
    2. **KDE Globals**: `kreadconfig6`/`kreadconfig5` (`ColorScheme`) e leitura direta de `~/.config/kdeglobals`.
    3. **GSettings**: `org.gnome.desktop.interface color-scheme` (`'prefer-dark'`, `'prefer-light'` ou `'default'` tratado como `light` quando o tema GTK ativo não é escuro).

### 2. GTK Toolkit (`GTK_THEME` & `10-theme.conf`)

- Em **Sessões Full DE** (`gnome`, `kde`, etc.): Preserva gestão dinâmica nativa sem fixar `GTK_THEME` ou `GTK_APPLICATION_PREFER_DARK_THEME` em `~/.config/environment.d/10-theme.conf` ou arquivos de startup, mantendo apenas `QT_QPA_PLATFORMTHEME` e `SAL_USE_VCLPLUGIN="gtk3"` e sincronizando `gsettings set org.gnome.desktop.interface gtk-theme` no GNOME.
- Em **Window Managers & Quiosques Independentes** (`wwm`, `xwm`, `wgui`, `xgui`): Exporta em tempo de sessão o tema Light ou Dark correspondente ao DE mestre (`adw-gtk3`/`adw-gtk3-dark`, `Breeze`/`Breeze-Dark`, etc.), `GTK_APPLICATION_PREFER_DARK_THEME` (`0`/`1`), `ADW_DEBUG_COLOR_SCHEME`, ícones, cursor e configuração alinhada no `xsettingsd` e `settings.ini`.

### 3. Qt Toolkit (`QT_QPA_PLATFORMTHEME` & `QT_STYLE_OVERRIDE`)

- Garante diálogo nativo de arquivos e renderização coerente em aplicativos Qt:
    - No GNOME/KDE: Utiliza `xdgdesktopportal` (ou `kde` no Plasma / `qt6ct` em WMs).
    - Em ambientes com Qt6 configuration tool: Integra com `qt6ct` ou `qt5ct`.
    - Define `QT_STYLE_OVERRIDE="Breeze"` em sessões standalone KDE/LXQt (QStyle válido no Qt6; o esquema claro/escuro é herdado via `qt6ct`/`kdeglobals`/portal, sem usar `"Breeze-Dark"` como nome de estilo).

### 4. Electron Wayland Nativo

- Exporta globalmente `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- Aplicativos baseados em Electron (VS Code, Discord, Obsidian, Slack, Spotify) renderizam via protocolo Wayland nativo, eliminando borrões causados por escalonamento Fracionário no XWayland.

### 5. Java / AWT em Tiling Window Managers

- Exporta `_JAVA_AWT_WM_NONREPARENTING=1` para evitar janelas cinzas e vazias em IDEs JetBrains, DBeaver e aplicações Java quando rodando sob Sway, Hyprland ou Wayland.

### 6. TrueColor (24-bit RGB)

- Exporta `COLORTERM="truecolor"` e `MICRO_TRUECOLOR=1`.
- Habilita suporte universal a 16,7 milhões de cores em todos os editores e linters modernos.

---

## 📟 Detecção, Linhagem & Propagação de Raw TTY (`_is_raw_tty` & `_has_raw_tty_ancestor`)

Para preservar a legibilidade e evitar caracteres corrompidos (_mojibake_ de fontes ausentes) em consoles puros do kernel, sessões SSH/Bhyve e subshells aninhados:

### 1. Critérios de Identificação & Linhagem de Console Puro

As funções `_is_raw_tty()` e `_has_raw_tty_ancestor()` em `core/detect.sh` avaliam a cascata e a linhagem de processos:

1. **Variáveis de Ambiente Independentes:** Checa `RAW_TTY`, `LC_RAW_TTY` e `UNIVERSAL_RAW_TTY` de forma isolada (`1`, `true`, `yes`).
2. **Emulação do Terminal (`$TERM`):** `linux`, `dumb`, `vt100`, `cons25*`, `wvt25*`.
3. **Dispositivo de Console (`command tty`):**
    - Linux: `/dev/tty[0-9]*`
    - FreeBSD: `/dev/ttyv*` (`vt(4)`)
    - OpenBSD / NetBSD: `/dev/ttyC*`, `/dev/ttyE*` (`wscons`)
    - Console mestre: `/dev/console`
4. **Linhagem TTY com Fronteiras Gráficas (`_has_raw_tty_ancestor`):** Sobe a árvore de processos ancestrais para propagar o modo Raw TTY automaticamente em subshells abertos dentro de `:terminal` (Vim/NeoVim), `eat`, `vterm` ou `term` (Emacs TTY), interrompendo a subida ao cruzar fronteiras gráficas (sessões Wayland/X11, emuladores PTY gráficos ou Emacs GUI).

### 2. Propagação Transparente via SSH & Bhyve

- **Filtro do OpenSSH (`AcceptEnv`):** Servidores SSH descartam variáveis de usuário não autorizadas por padrão. O padrão universal aceito é `AcceptEnv LANG LC_*`.
- **Túnel de Variáveis:** O wrapper nativo `ssh()` em `core/environment.sh` e o launcher `target/freebsd/bhyve.sh` transmitem a variável prefixada `LC_RAW_TTY=1` via `-o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1`.
- **Injeção de Ambiente em Comandos:** Em sessões interativas sem PTY (`lx`), o prefixo remoto `export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1;` é executado antes do `exec ${SHELL:-/bin/zsh} -l`.

### 3. Comutação Dinâmica de Prompt

- **Emulador Gráfico / PTY (`! _is_raw_tty`):** Prompt gráfico multi-linha de alta fidelidade com glifos Nerd Fonts e dados contextuais (git branch, relógio, data).
- **Console Puro / TTY (`_is_raw_tty`):** Comuta automaticamente para o tema `pill` (ASCII limpo de linha única `<USER>@host (sh):[dir] $ `), operando em 100% negrito via ECMA-48 sem forks e sem dependência de glifos UTF-8 complexos.
