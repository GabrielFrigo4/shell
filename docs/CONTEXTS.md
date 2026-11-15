# 🎯 Contextos Operacionais do Universal Shell

O **Universal Shell** introduz o conceito de **Contextos de Ambiente** (`SHELL_CONTEXT`). Em vez de forçar a mesma configuração monolítica em uma máquina de desenvolvimento gráfico e em um contêiner de microsserviço de 50MB, o sistema adapta seus recursos dinamicamente.

---

## 🧭 Os 3 Contextos Canônicos

| Contexto               | Foco Operacional                                         | Consumo / Latência   | Recursos Chave                                                                                             |
| :--------------------- | :------------------------------------------------------- | :------------------- | :--------------------------------------------------------------------------------------------------------- |
| **`desktop`** (Padrão) | Estação gráfica (Workstation / Laptop / WSL Dev)         | Rico (&lt;45ms)      | Editores GUI/CLI, gestão de dispositivos móveis (`mount-device`), Wayland/X11, temas GTK/Qt e bridges WSL. |
| **`server`**           | Servidores dedicados / VMs headless / WSL Headless       | Mínimo (&lt;20ms)    | Ferramentas de rede, logs, aliases enxutos de administração, resiliência via SSH e tuning de VM WSL.       |
| **`container`**        | Contêineres isolados (Docker, Podman, LXC, Jails, Zones) | Ultraleve (&lt;10ms) | Aliases estritamente necessários, sem sobrecarga de daemons, agnóstico ao hospedeiro.                      |

---

## 🧩 Arquitetura de Duas Camadas por Contexto

Dentro de `context/{CONTEXT}/`, as configurações são divididas em duas etapas:

1. **`common.sh`**: Regras e aliases independentes de plataforma aplicáveis a qualquer máquina naquele contexto.
2. **`{OS}.sh`** (`linux.sh`, `freebsd.sh`, `openbsd.sh`, `netbsd.sh`, `illumos.sh`, `macos.sh`, `windows.sh`): Especializações que dependem do kernel ou ferramentas nativas do sistema operacional hospedeiro.

---

## 💻 1. Contexto Desktop

Projetado para estações de trabalho de desenvolvimento:

- **Editores e IDEs:** Suporte completo à cascata de editores gráficos e de terminal (`code`, `codium`, `antigravity-ide`, `zed`, `kate`, `nvim`, `hx`, `micro`).
- **Dispositivos Móveis:** Comandos `mount-device` (`mntdev`) e `umount-device` (`umdev`) para montagem FUSE automática de smartphones Android via MTP (GNOME GVfs, KDE KIO-FUSE, GSConnect ou ADB).
- **Gerenciadores de Janelas:** Funções `start-session`, `start-way` e `start-xorg` para inicialização direta de ambientes gráficos (GNOME, Plasma, Hyprland, Sway) a partir de TTYs.
- **Pipeline Determinístico de Cursor, Ícones & DE Priority Cascade:** Cascata canônica de precedência `KDE > GNOME > MATE > Cinnamon > XFCE > LXQt > LXDE > Budgie > Pantheon > Deepin > COSMIC > Fallback (Adwaita -> breeze_cursors/breeze-dark -> default)`. Sonda processos em tempo real via `pgrep`, lê variáveis de ambiente (`$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION`) e inspeciona arquivos de configuração (`kcminputrc`, GSettings, session files), sincronizando TTY, X11 (`xrdb`, `xsetroot`, `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`), GSettings (`org.gnome.desktop.interface icon-theme`) e Wayland (`seat * xcursor_theme`).
- **Harmonização de Variáveis de Ambiente Gráficas (`common.sh` & `session.sh`):**
    - `GTK_THEME`: Resolvido dinamicamente em tempo de execução via `_detect_gtk_theme` acompanhando o modo **light** ou **dark** do DE mestre (`adw-gtk3`/`adw-gtk3-dark`, `Breeze`/`Breeze-Dark`, `Greybird`/`Greybird-dark`, `Mint-Y`/`Mint-Y-Dark`, `Yaru-MATE`/`Yaru-MATE-dark`, `deepin`/`deepin-dark`, `cosmic`/`cosmic-dark`). Sessões Full DE não recebem pinning estático em `~/.config/environment.d/10-theme.conf` ou arquivos de startup, permitindo alternância imediata Light/Dark nativa; gerenciadores independentes (`wwm`, `xwm`, `wgui`, `xgui`) herdam e exportam o estado atual completo do DE mestre.
    - `SAL_USE_VCLPLUGIN="gtk3"`, `GTK_APPLICATION_PREFER_DARK_THEME` (`0` ou `1` dinâmico em WMs independentes) & `settings.ini` (`~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`): Asseguram renderização nativa e paridade imediata de tema e ícones no LibreOffice e toolkits GTK entre X11 e Wayland.
    - `gtk-icon-theme-name`: Sincronização procedural de ícones (`breeze`/`breeze-dark`, `Adwaita`, `elementary`, `bloom`, `cosmic`) entre GSettings e `settings.ini`, garantindo paridade entre sessões X11 (`xgui`/`xwm`/`xewm`) e Wayland (`wgui`/`wwm`/`wewm`).
    - `QT_STYLE_OVERRIDE`: Configura o estilo de widgets Qt (`Breeze-Dark`, `Breeze`, `chameleon`) em sessões independentes quando apropriado.
    - `QT_QPA_PLATFORMTHEME`: Define a camada de integração de janelas e arquivos Qt (`xdgdesktopportal`, `lxqt`, `deepin`, `gtk3`, `qt6ct`, `qt5ct`) via `10-theme.conf`.
    - `XCURSOR_THEME` e `XCURSOR_SIZE`: Exporta cursor determinístico coerente com o DE mestre (`breeze_cursors`/`Adwaita`, `24px`).
    - `XCURSOR_PATH`: Configura a rota universal de busca de ícones e cursores (`~/.local/share/icons`, `~/.icons`, `/usr/local/share/icons`, `/usr/share/icons`).
    - `ELECTRON_OZONE_PLATFORM_HINT="auto"`: Habilita renderização Wayland nativa em softwares Electron (VS Code, Discord, Obsidian), prevenindo distorções no escalonamento fracionário XWayland.
    - `_JAVA_AWT_WM_NONREPARENTING=1`: Previne janelas cinzas vazias em aplicações Java AWT/Swing (JetBrains, DBeaver) executadas sob compositores Wayland e tiling WMs.
- **Despachante Universal de Abertura Inteligente (`o` / `open` em `common.sh`):** Roteamento contextual nativo via `open-smart`: para documentos de leitura (PDF, EPUB, DjVu), bancos relacionais SQLite (`.sqlite`, `.sqlite3`, `.db`), arquivos compactados (`.zip`, `.tar.*`, `.7z`), código-fonte e texto, despacha instantaneamente para o Emacs (`emacsclient` ou `emacs &`). Para URLs e arquivos de escritório pesados, aciona o manipulador nativo da plataforma (`open`, `cygstart`, `xdg-open` ou `gio open`).
- **Paleta Adwaita-Breeze Adaptativa (Light/Dark Parity):** Unificação cromática e tipográfica dos componentes de desktop e quiosques (`wwm`, `xwm`, `wgui`, `xgui`) sincronizada com o modo atual do DE mestre: base escura (`#1e1e22`, painéis `#2b2b30`, borda `#38383d`, texto `#ffffff`, secundário `#9a9996`) ou clara (`#f6f5f4`, painéis `#ffffff`, borda `#cdc7c2`, texto `#241f31`, secundário `#5e5c64`), ambas com realce azul Adwaita (`#3584e4`) e destaque de encerramento Breeze (`#e01b24`).
- **Barras Unificadas (`wwm-bar` & `xgui-tabbar`), VSync Xorg & Isolamento de Logs:** `wwm-bar` (32px em `wwm`/`xwm`) e `xgui-tabbar` (32px em `xgui` com auto-maximização em janela única e fallback `python3-xlib` -> `wmctrl`/`xdotool`) exibem abas clicáveis ao vivo de todas as janelas em qualquer compositor Wayland ou WM X11 suportado (`sway`, `labwc`, `river`, `hyprland`, `niri`, `wayfire`, `dwl`, `hikari`, `weston`, `openbox`, `cwm`, `fvwm3`/`fvwm`, `fluxbox`, `icewm`, `jwm`, `pekwm`, `dwm`, `twm`, `matchbox`). Em sessões X11 standalone, `vblank_mode=3`, `__GL_SYNC_TO_VBLANK=1` e `picom --backend glx|xrender --vsync --no-use-damage -b` eliminam tearing; sessões Full DE ignoram `picom` para não colidir com o compositor nativo. Todo stdout/stderr de sessões, compositores, WMs e barras é redirecionado para `${XDG_STATE_HOME:-~/.local/state}/shell/logs/` sem vazamento em TTY, e o fallback entre candidatos/backends ocorre exclusivamente em indisponibilidade pré-launch (`127`), jamais após logout.
- **Isolamento Multi-TTY de D-Bus:** Servidores gráficos e quiosques (`wwm`, `xwm`, `wgui`, `xgui`, `ewm`, `exwm`) operam em barramentos D-Bus privados (`dbus-run-session`), prevenindo vazamento de janelas para sessões ativas em outros TTYs.
- **Extensão WSL (`wsl.sh`):** Se executado sob WSL (`_is_wsl`), incorpora automaticamente atalhos do Windows (`explorer`, `pwsh`, `powershell`, `cmd`), sincronização de clipboard (`clip`, `paste`), navegação rápida (`cd-win`), tradução de caminhos (`win-path`, `wsl-path`) e inicialização de arquivos (`open-win`).
- **Política Python Efêmera (XDG Cache):** Herda `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"` de `core/environment.sh` e `context/desktop/common.sh` (com suporte nativo equivalente em Fish, PowerShell, NuShell e CMD), mantendo repositórios de trabalho 100% livres de pastas `__pycache__` enquanto centraliza bytecode otimizado fora do projeto.
- **Carregamento sob Demanda (`library/desktop-*.sh`):** Os módulos `desktop-device.sh`, `desktop-kiosk.sh` e `desktop-session.sh` são carregados exclusivamente quando `SHELL_CONTEXT=desktop`, mantendo contextos `server` e `container` leves e instantâneos.

---

## 🌐 2. Contexto Server

Projetado para máquinas de produção e servidores residenciais:

- Foco em ferramentas CLI puras (`tmux`, `htop`/`btop`, `journalctl`, `systemctl`, `service`).
- Aliases simplificados para visualização rápida de conexões de rede ativas e uso de disco.
- Desativação de verificações de ambiente gráfico e temas de GUI.
- **Sessões Remotas SSH (`_is_ssh`):** Detecção transparente de conexões remotas via `SSH_CLIENT` / `SSH_TTY`, ativando exportação de `REMOTE_SESSION=1`, atalho de inspeção de IP de conexão (`who-remote` / `myip`) e preservação estrita de largura de banda.
- **Extensão WSL (`wsl.sh`):** Se executado sob WSL (`_is_wsl`), incorpora resolução de rede do host Windows (`WSL_HOST_IP`), liberação de memória RAM da VM para o host (`wsl-drop-caches`) e consulta de IP (`wsl-ip`).
- **Cache Centralizado Python:** Define `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"` para que daemons e serviços de produção (Django, FastAPI, workers Gunicorn/Celery) tenham boot instantâneo com zero sobrecarga de CPU, mantendo os diretórios das aplicações 100% livres de `__pycache__`.

---

## 📦 3. Contexto Container

Projetado para instâncias efêmeras e contêineres de compilação:

- Elimina qualquer dependência de utilitários ausentes em imagens mínimas (como `sudo`, `ip`, `systemd`).
- Shell imediato com suporte a `l`, `ll` e detecção de pacotes base (`apk`, `apt`, `dnf`, `pkg`).
- Isolamento estrito e portabilidade absoluta: agnóstico ao sistema hospedeiro (não acoplado ao Windows, macOS ou nuvem).
- **Política Python Efêmera Isolada:** Define `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"` redirecionando eventual compilação de bytecode para o cache XDG do usuário sem sujar árvores de código ou volumes montados.
