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
- **Extensão WSL (`wsl.sh`):** Se executado sob WSL (`_is_wsl`), incorpora automaticamente atalhos do Windows (`explorer`, `pwsh`, `powershell`, `cmd`), sincronização de clipboard (`clip`, `paste`), navegação rápida (`cd-win`), tradução de caminhos (`win-path`, `wsl-path`) e inicialização de arquivos (`open-win`).

---

## 🌐 2. Contexto Server

Projetado para máquinas de produção e servidores residenciais:

- Foco em ferramentas CLI puras (`tmux`, `htop`/`btop`, `journalctl`, `systemctl`, `service`).
- Aliases simplificados para visualização rápida de conexões de rede ativas e uso de disco.
- Desativação de verificações de ambiente gráfico e temas de GUI.
- **Sessões Remotas SSH (`_is_ssh`):** Detecção transparente de conexões remotas via `SSH_CLIENT` / `SSH_TTY`, ativando exportação de `REMOTE_SESSION=1`, atalho de inspeção de IP de conexão (`who-remote` / `myip`) e preservação estrita de largura de banda.
- **Extensão WSL (`wsl.sh`):** Se executado sob WSL (`_is_wsl`), incorpora resolução de rede do host Windows (`WSL_HOST_IP`), liberação de memória RAM da VM para o host (`wsl-drop-caches`) e consulta de IP (`wsl-ip`).

---

## 📦 3. Contexto Container

Projetado para instâncias efêmeras e contêineres de compilação:

- Elimina qualquer dependência de utilitários ausentes em imagens mínimas (como `sudo`, `ip`, `systemd`).
- Shell imediato com suporte a `l`, `ll` e detecção de pacotes base (`apk`, `apt`, `dnf`, `pkg`).
- Isolamento estrito e portabilidade absoluta: agnóstico ao sistema hospedeiro (não acoplado ao Windows, macOS ou nuvem).
