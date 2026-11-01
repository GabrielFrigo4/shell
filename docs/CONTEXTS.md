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
- **Pipeline Determinístico de Cursor & DE Priority Cascade:** Cascata canônica de precedência `KDE > GNOME > MATE > Cinnamon > XFCE > LXQt > LXDE > Budgie > Pantheon > Deepin > COSMIC > Fallback (Adwaita -> breeze_cursors -> default)`. Sonda processos em tempo real via `pgrep`, lê variáveis de ambiente (`$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION`) e inspeciona arquivos de configuração (`kcminputrc`, GSettings, session files), sincronizando TTY, X11 (`xrdb`, `xsetroot`) e Wayland (`seat * xcursor_theme`).
- **Harmonização de Variáveis de Ambiente Gráficas (`common.sh`):**
    - `GTK_THEME`: Sincronizado proceduralmente via `_detect_gtk_theme` para temas dark harmônicos (`Breeze-Dark`, `adw-gtk3-dark`, `Adwaita-dark`, `Greybird-dark`, `Mint-Y-Dark`, `Yaru-MATE-dark`, `deepin-dark`, `cosmic-dark`).
    - `QT_STYLE_OVERRIDE`: Configura o estilo de widgets Qt (`Breeze-Dark`, `Breeze`, `chameleon`) evitando descompasso cromático em suítes Qt6/KDE.
    - `QT_QPA_PLATFORMTHEME`: Define a camada de integração de janelas e arquivos Qt (`xdgdesktopportal`, `lxqt`, `deepin`, `gtk3`, `qt6ct`, `qt5ct`).
    - `XCURSOR_THEME` e `XCURSOR_SIZE`: Exporta cursor determinístico e tamanho canônico (`24px`).
    - `XCURSOR_PATH`: Configura a rota universal de busca de ícones e cursores (`~/.local/share/icons`, `~/.icons`, `/usr/local/share/icons`, `/usr/share/icons`).
    - `ELECTRON_OZONE_PLATFORM_HINT="auto"`: Habilita renderização Wayland nativa em softwares Electron (VS Code, Discord, Obsidian), prevenindo distorções no escalonamento fracionário XWayland.
    - `_JAVA_AWT_WM_NONREPARENTING=1`: Previne janelas cinzas vazias em aplicações Java AWT/Swing (JetBrains, DBeaver) executadas sob compositores Wayland e tiling WMs.
- **Paleta Adwaita-Breeze Dark Fusion:** Unificação estética dos componentes de desktop e quiosques (`wwm`, `xwm`, `wgui`, `xgui`), combinando base neutra escura (`#1e1e22`), superfícies ativas de painéis e títulos (`#2b2b30`), realce azul Adwaita (`#3584e4`), alertas e botões de encerramento em vermelho Breeze (`#e01b24`), bordas de contenção (`#38383d`) e tipografia secundária (`#9a9996`).
- **Pipeline Tipográfico `_resolve_desktop_font`:** Resolução procedural de fontes via `fc-list` com prioridade primária para `JetBrainsMono Nerd Font`, seguida de resolução adaptativa conforme o ambiente de desktop (`Noto Sans` no Plasma/KDE/LXQt/Deepin, `Adwaita Sans` ou `Cantarell` no GNOME/Budgie, `Inter` ou `Open Sans` no Pantheon, `Fira Sans` no COSMIC, `Ubuntu` ou `DejaVu Sans` no MATE/Cinnamon/XFCE/LXDE) e fallback seguro para `Sans`.
- **Sessão Wayland (`wwm`) & Botões Interativos com Feedback `:hover`:** Compositor Sway integrado com barra de status inferior interativa operando via streaming JSON (`"click_events": true`). Apresenta botões visuais com realce de bordas e contraste dinâmico de hover (`#3584e4` / `#e01b24`) para navegador (`[ Web Browser ]`), terminal (`[ Terminal ]`), gerenciador de arquivos (`[ Files ]`), editor (`[ Emacs ]`), lançador (`[ Menu ]`), fechamento da janela focada (`[ Close ]` / `swaymsg kill`), encerramento de sessão (`[ Exit ]` / `swaymsg exit`) e relógio dinâmico (`time`).
- **Sessão X11 (`xwm`) & Redimensionamento Completo SSD:** Gerenciador Openbox com suporte completo a Server-Side Decorations (SSD) para redimensionamento fluido por bordas e cantos (`Top`, `Bottom`, `Left`, `Right`, `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`), permitindo arrasto direto pelo mouse sem requerer atalhos modais de teclado. Acompanhado de geração procedimental em AWK de menus XML a partir dos arquivos `.desktop` do sistema (`/usr/share/applications`, `/usr/local/share/applications`, Flatpak), distribuindo automaticamente aplicativos em Desenvolvimento (`dev`), Rede (`net`), Escritório (`office`), Multimídia (`media`) e Sistema (`sys`).
- **Quiosques Gráficos (`wgui` / `xgui`) & Abas Dinâmicas (`>= 2` janelas):** Lançadores gráficos flutuantes efêmeros com monitoramento de janelas ativas. Em janela única (`_count < 2`), operam em modo imersivo sem bordas (`border none`). Ao abrir duas ou mais janelas (`_count >= 2`), acionam automaticamente abas tabuladas com bordas estilizadas (`layout tabbed, border normal 1`) com base em `#1e1e22`, `#2b2b30` e acento `#3584e4`, colapsando de volta para tela limpa quando as janelas secundárias forem fechadas.
- **Isolamento Multi-TTY de D-Bus:** Servidores gráficos e quiosques (`wwm`, `xwm`, `wgui`, `xgui`, `ewm`, `exwm`) operam em barramentos D-Bus privados (`dbus-run-session`), prevenindo vazamento de janelas para sessões ativas em outros TTYs.
- **Extensão WSL (`wsl.sh`):** Se executado sob WSL (`_is_wsl`), incorpora automaticamente atalhos do Windows (`explorer`, `pwsh`, `powershell`, `cmd`), sincronização de clipboard (`clip`, `paste`), navegação rápida (`cd-win`), tradução de caminhos (`win-path`, `wsl-path`) e inicialização de arquivos (`open-win`).
- **Política Python Zero-Cruft:** Exporta `PYTHONDONTWRITEBYTECODE=1` para manter o código dos projetos, árvores Git e a home 100% limpos de pastas `__pycache__` durante desenvolvimento.

---

## 🌐 2. Contexto Server

Projetado para máquinas de produção e servidores residenciais:

- Foco em ferramentas CLI puras (`tmux`, `htop`/`btop`, `journalctl`, `systemctl`, `service`).
- Aliases simplificados para visualização rápida de conexões de rede ativas e uso de disco.
- Desativação de verificações de ambiente gráfico e temas de GUI.
- **Sessões Remotas SSH (`_is_ssh`):** Detecção transparente de conexões remotas via `SSH_CLIENT` / `SSH_TTY`, ativando exportação de `REMOTE_SESSION=1`, atalho de inspeção de IP de conexão (`who-remote` / `myip`) e preservação estrita de largura de banda.
- **Extensão WSL (`wsl.sh`):** Se executado sob WSL (`_is_wsl`), incorpora resolução de rede do host Windows (`WSL_HOST_IP`), liberação de memória RAM da VM para o host (`wsl-drop-caches`) e consulta de IP (`wsl-ip`).
- **Cache Centralizado Python:** Define `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-$HOME/.cache}/cpython"` para que daemons e serviços de produção (Django, FastAPI, workers Gunicorn/Celery) tenham boot instantâneo com zero sobrecarga de CPU, mantendo os diretórios das aplicações 100% livres de `__pycache__`.

---

## 📦 3. Contexto Container

Projetado para instâncias efêmeras e contêineres de compilação:

- Elimina qualquer dependência de utilitários ausentes em imagens mínimas (como `sudo`, `ip`, `systemd`).
- Shell imediato com suporte a `l`, `ll` e detecção de pacotes base (`apk`, `apt`, `dnf`, `pkg`).
- Isolamento estrito e portabilidade absoluta: agnóstico ao sistema hospedeiro (não acoplado ao Windows, macOS ou nuvem).
- **Política Python Efêmera:** Exporta `PYTHONDONTWRITEBYTECODE=1` para prevenir escrita de bytecode na camada mutável (_overlayfs_) do contêiner.
