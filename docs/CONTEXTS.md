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
- **Pipeline Determinístico de Cursor:** Hierarquia `KDE > GNOME > MATE > Cinnamon > XFCE > LXQt > Fallback` verificando binários reais de DE, sincronizada entre TTY, X11 (`xrdb`, `xsetroot`) e Wayland (`seat * xcursor_theme`).
- **Paleta Adwaita-Breeze Dark Fusion:** Unificação estética dos componentes de desktop e quiosques (`wwm`, `xwm`, `wgui`, `xgui`), combinando base neutra escura (`#1e1e22`), superfícies ativas de painéis e títulos (`#2b2b30`), realce azul Adwaita (`#3584e4`), alertas e botões de encerramento em vermelho Breeze (`#e01b24`), bordas de contenção (`#38383d`) e tipografia secundária (`#9a9996`).
- **Pipeline Tipográfico `_resolve_desktop_font`:** Resolução procedural de fontes via `fc-list` com prioridade primária para `JetBrainsMono Nerd Font`, seguida de resolução adaptativa conforme o ambiente de desktop (`Noto Sans` no Plasma/KDE, `Adwaita Sans` ou `Cantarell` no GNOME, `Ubuntu` ou `DejaVu Sans` no MATE/Cinnamon/XFCE) e fallback seguro para `Sans`.
- **Sessão Wayland (`wwm`) & Botões Clicáveis na Swaybar:** Compositor Sway integrado com barra de status inferior interativa operando via protocolo de streaming JSON (`"click_events": true`). Apresenta botões visuais com realce de bordas para navegador (`[ Web Browser ]`), terminal (`[ Terminal ]`), gerenciador de arquivos (`[ Files ]`), editor (`[ Emacs ]`), lançador (`[ Menu ]`), fechamento da janela focada (`[ Close ]` / `swaymsg kill`), encerramento de sessão (`[ Exit ]` / `swaymsg exit`) e relógio dinâmico (`time`).
- **Sessão X11 (`xwm`) & Menu Dinâmico Categorizado:** Gerenciador Openbox com geração procedimental em AWK de menus XML a partir dos arquivos `.desktop` do sistema (`/usr/share/applications`, `/usr/local/share/applications`, Flatpak), distribuindo automaticamente aplicativos em Desenvolvimento (`dev`), Rede (`net`), Escritório (`office`), Multimídia (`media`) e Sistema (`sys`).
- **Quiosque Wayland (`wgui`) & Abas Auto-Ocultáveis:** Lançador gráfico flutuante com daemon em segundo plano (`wgui-tabwatch`). Quando há duas ou mais janelas abertas (`_count >= 2`), ativa automaticamente organização em abas com borda visível (`layout tabbed, border normal 1`); quando resta apenas uma janela ativa, colapsa as abas instantaneamente para modo imersivo sem bordas (`layout splith, border none`).
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
