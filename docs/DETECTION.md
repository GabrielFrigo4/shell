# 🧠 Motores de Inteligência & Detecção (`library/detect.sh`)

O módulo `library/detect.sh` é o cérebro investigativo do **Universal Shell Environment**. Ele sonda o ambiente do hospedeiro em baixo nível, identificando hardware, kernel, distribuições e interfaces visuais sem degradação de desempenho.

---

## 🔍 Módulos de Sondagem

### 1. Sistema Operacional & Shell Ativo

- **`_detect_os`**: Identifica o sistema via `uname -s` e normaliza para: `freebsd`, `dragonfly`, `linux`, `macos`, `windows`, `openbsd`, `netbsd` ou `illumos`.
- **`_detect_shell`**: Identifica se a sessão interativa atual é executada por `zsh`, `bash`, `ksh` ou `sh` (POSIX).
- **`_detect_enabled_shell`**: Retorna o binário de shell canônico respeitando a ordem de precedência: Shell do `chsh`/passwd (se válido e suportado) ➔ `zsh` ➔ `bash` ➔ `ksh` (OpenBSD) ➔ `sh` (FreeBSD) (suporta flag `--name`).

### 2. Distribuições, Derivados & Família de Gerenciadores

- **`_detect_distro`**: Mapeia distribuições e derivados nativos sem acoplamento a um único SO:
    - **Linux:** `fedora`, `arch`, `debian`, `ubuntu` (com detecção de sabores `kubuntu`, `xubuntu`, `lubuntu`), `devuan`, `opensuse`, `void`, `alpine`, `gentoo`, `nixos`, `solus`, `slackware`, `guix`, `openwrt`, `ol` (Oracle), `azurelinux`, `qubes`, etc.
    - **BSD:** `freebsd`, `dragonfly`, `ghostbsd`, `nomadbsd`, `openbsd`, `netbsd`.
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
    - `bsd` ➔ Gerenciadores `pkg` (FreeBSD, DragonFly, GhostBSD, NomadBSD), `pkg_add` (OpenBSD) ou `pkgin` (NetBSD)
    - `illumos` ➔ Gerenciadores `pkg` (IPS em OmniOS/OpenIndiana) ou `pkgin` (SmartOS)
    - `darwin` ➔ Gerenciador `brew` (Homebrew)
- **`_detect_distro_icon`**: Retorna o glifo vetorial oficial Nerd Fonts proporcional em altura (conjunto Font Logos `U+F300`):
    - ` ` (Linux Tux full-scale), ` ` (FreeBSD / GhostBSD / NomadBSD), ` ` (DragonFly BSD), ` ` (OpenBSD), ` ` (NetBSD), ` ` (illumos), `󰖨 ` (Solaris/SunOS), ` ` (macOS Apple), ` ` (Windows).
      Esta inteligência alimenta dinamicamente comandos universais como `update-system`, `clean-system` e `update-all`.

### 3. Ambiente Gráfico, Desktop Environments & Sessão de Janelas

- **`_detect_desktop_environment`**: Analisa variáveis `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION` e processos em execução via `pgrep` para identificar:
    - **11 Desktop Environments Canônicos:** `kde` (Plasma 5/6), `gnome` (GNOME Shell), `mate`, `cinnamon`, `xfce`, `lxqt`, `lxde`, `budgie`, `pantheon`, `deepin`, `cosmic`.
    - **Compositores Wayland & WMs X11 Independentes:** `sway`, `hyprland`, `river`, `labwc`, `cage`, `niri`, `wayfire`, `dwl`, `openbox`, `cwm`, `wm`.
- **`_detect_desktop_theme`**: Resolve o sabor visual canônico percorrendo a hierarquia determinística:
    1. Parâmetro explícito fornecido à função (`kde`, `gnome`, `mate`, `cinnamon`, `xfce`, `lxqt`, `lxde`, `budgie`, `pantheon`, `deepin`, `cosmic`).
    2. Leitura de `$XDG_CURRENT_DESKTOP` e `$DESKTOP_SESSION`.
    3. Inspeção de processos de sessão ativos via `pgrep` (`plasmashell`/`kwin_*`, `gnome-shell`, `mate-session`, `cinnamon`, `xfce4-session`, `lxqt-session`, `lxsession`, `budgie-wm`/`budgie-panel`, `gala`/`wingpanel`, `dde-desktop`/`deepin-wm`, `cosmic-comp`/`cosmic-session`).
    4. Sonda de binários e diretórios de sistema na ordem canônica de precedência: `KDE > GNOME > MATE > Cinnamon > XFCE > LXQt > LXDE > Budgie > Pantheon > Deepin > COSMIC > Fallback (adwaita)`.
- **`_detect_color_scheme`**: Consulta a intenção estética (dark/light) via portal D-Bus XDG (`org.freedesktop.appearance.color-scheme`), GSettings (`org.gnome.desktop.interface color-scheme`), `kreadconfig6`/`kreadconfig5` (`ColorScheme`) ou `~/.config/kdeglobals`.
- **`_resolve_gtk_theme` & `_detect_gtk_theme`**: Mapeia o tema GTK coerente (`adw-gtk3-dark`, `Adwaita-dark`, `Breeze-Dark`, `Greybird-dark`, `Mint-Y-Dark`, `Yaru-MATE-dark`, `Clearlooks-Phenix`, `Materia-dark`, `io.elementary.stylesheet.blueberry-dark`, `deepin-dark`, `cosmic-dark`) inspecionando `/usr/share/themes`, `/usr/local/share/themes` e diretórios do usuário.
- **`_detect_qt_theme`**: Resolve `QT_STYLE_OVERRIDE` (`Breeze-Dark`, `Breeze`, `chameleon`) alinhando componentes Qt à paleta global.
- **`_detect_qt_platform_theme`**: Define `QT_QPA_PLATFORMTHEME` (`xdgdesktopportal`, `lxqt`, `deepin`, `gtk3`, `qt6ct`, `qt5ct`) para integração nativa de janelas de diálogo e estilos de widgets.
- **Sessão Wayland vs. X11**: Avalia `$XDG_SESSION_TYPE` e `$WAYLAND_DISPLAY` para determinar a rota gráfica correta.

#### Matriz de Detecção de Ambientes Gráficos & Compositores

| Ambiente / Compositor | Categoria          | Assinatura de Processos (`pgrep`)         | Provas de Binários / Diretórios                                                               | Tema GTK Canônico                         | Qt Platform Theme                      | Cursor Padrão                | Fonte Padrão                 |
| :-------------------- | :----------------- | :---------------------------------------- | :-------------------------------------------------------------------------------------------- | :---------------------------------------- | :------------------------------------- | :--------------------------- | :--------------------------- |
| **KDE (Plasma)**      | Full DE            | `plasmashell`, `kwin_wayland`, `kwin_x11` | `plasmashell`, `startplasma-wayland`, `/usr/share/plasma`, `/usr/local/share/plasma`          | `Breeze-Dark`                             | `xdgdesktopportal`                     | `breeze_cursors`             | `Noto Sans`                  |
| **GNOME**             | Full DE            | `gnome-shell`                             | `gnome-shell`, `gnome-session`, `/usr/share/gnome-shell`, `/usr/local/share/gnome-shell`      | `adw-gtk3-dark` / GSettings               | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita`                    | `Adwaita Sans` / `Cantarell` |
| **MATE**              | Full DE            | `mate-session`                            | `mate-session`, `/usr/share/mate`, `/usr/local/share/mate`                                    | `Yaru-MATE-dark`, `BlackMATE`             | `gtk3`                                 | `Adwaita`                    | `Ubuntu` / `DejaVu Sans`     |
| **Cinnamon**          | Full DE            | `cinnamon`                                | `cinnamon`, `cinnamon-session`, `/usr/share/cinnamon`, `/usr/local/share/cinnamon`            | `Mint-Y-Dark`                             | `gtk3`                                 | `Adwaita`                    | `Ubuntu` / `DejaVu Sans`     |
| **XFCE**              | Full DE            | `xfce4-session`                           | `xfce4-session`, `/usr/share/xfce4`, `/usr/local/share/xfce4`                                 | `Greybird-dark`                           | `gtk3`                                 | `Adwaita`                    | `Ubuntu` / `DejaVu Sans`     |
| **LXQt**              | Full DE            | `lxqt-session`                            | `lxqt-session`, `/usr/share/lxqt`, `/usr/local/share/lxqt`                                    | `Breeze-Dark`, `Arc-Dark`                 | `lxqt`                                 | `breeze_cursors`             | `Noto Sans` / `Sans Serif`   |
| **LXDE**              | Full DE            | `lxsession`                               | `lxsession`, `startlxde`, `/usr/share/lxde`, `/usr/local/share/lxde`                          | `Clearlooks-Phenix`, `Arc-Dark`           | `gtk3`                                 | `Adwaita`                    | `DejaVu Sans` / `Sans`       |
| **Budgie**            | Full DE            | `budgie-wm`, `budgie-panel`               | `budgie-desktop`, `budgie-wm`, `/usr/share/budgie-desktop`, `/usr/local/share/budgie-desktop` | `Materia-dark`, `Arc-Dark`                | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita`                    | `Adwaita Sans` / `Ubuntu`    |
| **Pantheon**          | Full DE            | `gala`, `wingpanel`                       | `gala`, `wingpanel`, `/usr/share/pantheon`, `/usr/local/share/pantheon`                       | `io.elementary.stylesheet.blueberry-dark` | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita`                    | `Inter` / `Open Sans`        |
| **Deepin**            | Full DE            | `dde-desktop`, `deepin-wm`                | `dde-desktop`, `dde-session`, `/usr/share/dde`, `/usr/local/share/dde`                        | `deepin-dark`                             | `deepin`                               | `Adwaita`                    | `Noto Sans`                  |
| **COSMIC**            | Full DE            | `cosmic-comp`, `cosmic-session`           | `cosmic-session`, `cosmic-comp`, `/usr/share/cosmic`, `/usr/local/share/cosmic`               | `cosmic-dark`                             | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita`                    | `Fira Sans` / `Cantarell`    |
| **Sway**              | Wayland Compositor | `sway`                                    | `sway`, `swaymsg`                                                                             | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **Hyprland**          | Wayland Compositor | `hyprland`, `Hyprland`                    | `Hyprland`, `hyprctl`                                                                         | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **River**             | Wayland Compositor | `river`                                   | `river`, `riverctl`                                                                           | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **Labwc**             | Wayland Compositor | `labwc`                                   | `labwc`                                                                                       | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **Cage**              | Wayland Compositor | `cage`                                    | `cage`                                                                                        | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **Niri**              | Wayland Compositor | `niri`                                    | `niri`, `niri-msg`                                                                            | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **Wayfire**           | Wayland Compositor | `wayfire`                                 | `wayfire`                                                                                     | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **DWL**               | Wayland Compositor | `dwl`                                     | `dwl`                                                                                         | `adw-gtk3-dark`                           | `qt6ct` / `qt5ct` / `xdgdesktopportal` | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **Openbox**           | X11 Window Manager | `openbox`                                 | `openbox`                                                                                     | `adw-gtk3-dark`                           | `gtk3`                                 | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |
| **CWM**               | X11 Window Manager | `cwm`                                     | `cwm`                                                                                         | `adw-gtk3-dark`                           | `gtk3`                                 | `Adwaita` / `breeze_cursors` | `JetBrainsMono Nerd Font`    |

---

## 🎨 Harmonização Visual Automática (Dark Mode & Toolkits)

O Universal Shell detecta a intenção estética do sistema operacional e alinha toolkits heterogêneos para evitar incoerências visuais:

### 1. Detecção Universal de Dark Mode (`_detect_color_scheme`)

- Consulta em sequência:
    1. **XDG Desktop Portal via D-Bus**: `org.freedesktop.appearance.color-scheme` (Padrão moderno em GNOME 42+, KDE Plasma 6 e compositores Wayland).
    2. **GSettings**: `org.gnome.desktop.interface color-scheme` ('prefer-dark').
    3. **KDE Globals**: Leitura direta de `kdeglobals` em busca de esquemas escuros (`BreezeDark`).

### 2. GTK Toolkit (`GTK_THEME`)

- No **KDE Plasma**: Mapeia `GTK_THEME="Breeze-Dark"` para que ferramentas em GTK adotem a paleta e bordas coerentes com o Plasma.
- No **GNOME**: Preserva a gestão nativa via Libadwaita sem forçar overrides que quebrem o design dos aplicativos GTK4.
- Em **Window Managers Independentes** (Sway / Hyprland): Mapeia para `adw-gtk3-dark` ou `Adwaita:dark`.

### 3. Qt Toolkit (`QT_QPA_PLATFORMTHEME` & `QT_STYLE_OVERRIDE`)

- Garante diálogo nativo de arquivos e renderização coerente em aplicativos Qt:
    - No GNOME/KDE: Utiliza `xdgdesktopportal`.
    - Em ambientes com Qt6 configuration tool: Integra com `qt6ct` ou `qt5ct`.
    - Define `QT_STYLE_OVERRIDE="Breeze-Dark"` quando apropriado.

### 4. Electron Wayland Nativo

- Exporta globalmente `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- Aplicativos baseados em Electron (VS Code, Discord, Obsidian, Slack, Spotify) renderizam via protocolo Wayland nativo, eliminando borrões causados por escalonamento Fracionário no XWayland.

### 5. Java / AWT em Tiling Window Managers

- Exporta `_JAVA_AWT_WM_NONREPARENTING=1` para evitar janelas cinzas e vazias em IDEs JetBrains, DBeaver e aplicações Java quando rodando sob Sway, Hyprland ou Wayland.

### 6. TrueColor (24-bit RGB)

- Exporta `COLORTERM="truecolor"` e `MICRO_TRUECOLOR=1`.
- Habilita suporte universal a 16,7 milhões de cores em todos os editores e linters modernos.

---

## 📟 Detecção & Propagação de Raw TTY (`_is_raw_tty`)

Para preservar a legibilidade e evitar caracteres corrompidos (_mojibake_ de fontes ausentes) em consoles puros do kernel ou sessões SSH/Bhyve:

### 1. Critérios de Identificação de Console Puro

A função `_is_raw_tty()` em `library/detect.sh` avalia a cascata:

1. **Variáveis de Ambiente Independentes:** Checa `RAW_TTY`, `LC_RAW_TTY` e `UNIVERSAL_RAW_TTY` de forma isolada (`1`, `true`, `yes`).
2. **Emulação do Terminal (`$TERM`):** `linux`, `dumb`, `vt100`, `cons25*`, `wvt25*`.
3. **Dispositivo de Console (`command tty`):**
    - Linux: `/dev/tty[0-9]*`
    - FreeBSD: `/dev/ttyv*` (`vt(4)`)
    - OpenBSD / NetBSD: `/dev/ttyC*`, `/dev/ttyE*` (`wscons`)
    - Console mestre: `/dev/console`

### 2. Propagação Transparente via SSH & Bhyve

- **Filtro do OpenSSH (`AcceptEnv`):** Servidores SSH descartam variáveis de usuário não autorizadas por padrão. O padrão universal aceito é `AcceptEnv LANG LC_*`.
- **Túnel de Variáveis:** O wrapper nativo `ssh()` em `core/environment.sh` e o launcher `target/freebsd/bhyve.sh` transmitem a variável prefixada `LC_RAW_TTY=1` via `-o SendEnv=LC_RAW_TTY -o SetEnv=LC_RAW_TTY=1`.
- **Injeção de Ambiente em Comandos:** Em sessões interativas sem PTY (`lx`), o prefixo remoto `export RAW_TTY=1 LC_RAW_TTY=1 UNIVERSAL_RAW_TTY=1;` é executado antes do `exec ${SHELL:-/bin/zsh} -l`.

### 3. Comutação Dinâmica de Prompt

- **Emulador Gráfico / PTY (`! _is_raw_tty`):** Prompt gráfico multi-linha de alta fidelidade com glifos Nerd Fonts e dados contextuais (git branch, relógio, data).
- **Console Puro / TTY (`_is_raw_tty`):** Comuta automaticamente para o tema `pill` (ASCII limpo de linha única `gabriel@host (sh):[dir] $ `), operando em 100% negrito via ECMA-48 sem forks e sem dependência de glifos UTF-8 complexos.
