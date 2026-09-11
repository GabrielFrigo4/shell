# 🧠 Motores de Inteligência & Detecção (`library/detect.sh`)

O módulo `library/detect.sh` é o cérebro investigativo do **Universal Shell Environment**. Ele sonda o ambiente do hospedeiro em baixo nível, identificando hardware, kernel, distribuições e interfaces visuais sem degradação de desempenho.

---

## 🔍 Módulos de Sondagem

### 1. Sistema Operacional & Shell Ativo

- **`_detect_os`**: Identifica o sistema via `uname -s` e normaliza para: `Linux`, `FreeBSD`, `Darwin` ou `MSYS` (Windows).
- **`_detect_shell`**: Identifica se a sessão interativa atual é executada por `bash`, `zsh` ou `sh` (POSIX).
- **`_detect_enabled_shell`**: Retorna o primeiro binário de shell válido e instalado respeitando a cascata de preferência `$(_detect_shell) || zsh || bash || sh` (suporta flag `--name`).

### 2. Distribuição Linux & Família de Gerenciador de Pacotes

- **`_detect_distro`**: Lê `/etc/os-release` para identificar a distribuição específica (`fedora`, `arch`, `debian`, `ubuntu`, `opensuse`, `void`, `alpine`).
- **`_detect_distro_family`**: Agrupa as distros pela sua raiz arquitetural:
    - `fedora` ➔ Gerenciador `dnf`
    - `arch` ➔ Gerenciador `pacman` (com detecção de helpers AUR `paru`/`yay`)
    - `debian` ➔ Gerenciador `apt`
    - `suse` ➔ Gerenciador `zypper`
    - `freebsd` ➔ Gerenciador `pkg`
      Esta classificação alimenta dinamicamente comandos universais como `update-system` e `update-all`.

### 3. Ambiente Gráfico & Sessão de Janelas

- **`_detect_desktop_environment`**: Analisa variáveis `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION` e processos em execução para identificar:
    - `kde` (Plasma 5/6)
    - `gnome` (GNOME Shell)
    - `xfce`, `sway`, `hyprland`, `cosmic`
- **Sessão Wayland vs. X11**: Avalia `$XDG_SESSION_TYPE` e `$WAYLAND_DISPLAY` para determinar a rota gráfica correta.

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
