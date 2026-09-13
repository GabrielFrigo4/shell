# 🎯 Contextos Operacionais do Universal Shell

O **Universal Shell** introduz o conceito de **Contextos de Ambiente** (`SHELL_CONTEXT`). Em vez de forçar a mesma configuração monolítica em uma máquina de desenvolvimento gráfico e em um contêiner de microsserviço de 50MB, o sistema adapta seus recursos dinamicamente.

---

## 🧭 Os 4 Contextos Suportados

| Contexto               | Foco Operacional                                | Consumo / Latência   | Recursos Chave                                                                                                  |
| :--------------------- | :---------------------------------------------- | :------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **`desktop`** (Padrão) | Estação gráfica (Workstation / Laptop)          | Rico (&lt;45ms)      | Editores GUI/CLI, gestão de dispositivos móveis (`mount-device`), atalhos de janelas Wayland/X11, temas GTK/Qt. |
| **`server`**           | Servidores dedicados / VMs headless             | Mínimo (&lt;20ms)    | Ferramentas de rede, logs, aliases enxutos de administração e resiliência via SSH.                              |
| **`container`**        | Contêineres (Incus, LXC, Podman, Docker, Jails) | Ultraleve (&lt;10ms) | Aliases estritamente necessários, sem sobrecarga de daemons ou ferramentas de desktop.                          |
| **`wsl`**              | Windows Subsystem for Linux (WSL2)              | Híbrido (&lt;35ms)   | Interoperabilidade transparente com executáveis do Windows (`cmd`, `powershell`, `clip`, `explorer`).           |

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

---

## 🌐 2. Contexto Server

Projetado para máquinas de produção e servidores residenciais:

- Foco em ferramentas CLI puras (`tmux`, `htop`/`btop`, `journalctl`, `systemctl`, `service`).
- Aliases simplificados para visualização rápida de conexões de rede ativas e uso de disco.
- Desativação de verificações de ambiente gráfico e temas de GUI.

---

## 📦 3. Contexto Container

Projetado para instâncias efêmeras e contêineres de compilação:

- Elimina qualquer dependência de utilitários ausentes em imagens mínimas (como `sudo`, `ip`, `systemd`).
- Shell imediato com suporte a `l`, `ll` e detecção de pacotes base (`apk`, `apt`, `dnf`, `pkg`).

---

## 🧩 4. Contexto WSL

Projetado para o Linux rodando dentro do Windows (WSL2):

- **Camada Comum (`common.sh`):**
  - Mapeia atalhos diretos para executáveis do Windows (`explorer`, `pwsh`, `powershell`, `cmd`).
  - Sincronização de área de transferência bidirecional (`clip`, `paste`) com suporte a `win32yank.exe`, `clip.exe` e PowerShell.
- **Camada Linux Especializada (`linux.sh`):**
  - **Tradução de Caminhos:** `win-path` (converte Linux para Windows) e `wsl-path` (converte Windows para Linux) via `wslpath`.
  - **Navegação:** `cd-win` para saltar diretamente ao perfil de usuário do Windows (`/mnt/c/Users/<user>`).
  - **Abertura de Arquivos:** `open-win` para abrir arquivos Linux com aplicações padrão do Windows.
  - **Resolução de Rede:** Exporta `WSL_HOST_IP` resolvendo o IP do host Windows sem subshells ou forks.
  - **Gestão de Recursos:** `wsl-drop-caches` para liberar cache de memória da VM para o Windows e `wsl-ip` para consultar o IP da VM.
