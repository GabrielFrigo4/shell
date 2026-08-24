# 🐚 Universal Shell Environment

> Configurações, aliases e prompts centralizados para todos os seus ambientes de sistema, mantendo a experiência consistente seja no Desktop, Servidor, Contêiner ou WSL.

### Sistemas Suportados

![Linux](https://img.shields.io/badge/🐧_Linux-Supported-blue)
![FreeBSD](https://img.shields.io/badge/😈_FreeBSD-Supported-red)
![MacOS](https://img.shields.io/badge/🍎_MacOS-Unsupported-lightgrey)
![Windows](https://img.shields.io/badge/🪟_Windows-Supported-purple)

### Contextos de Ambiente

![Desktop](https://img.shields.io/badge/💻-Desktop-cyan)
![Server](https://img.shields.io/badge/🌐-Server-orange)
![Container](https://img.shields.io/badge/📦-Container-yellow)
![WSL](https://img.shields.io/badge/🧩-WSL-blueviolet)

```mermaid
flowchart LR
    subgraph OS ["🖥️ Plataformas"]
        LNX["🐧 Linux"]
        BSD["😈 FreeBSD"]
        WIN["🪟 Windows"]
        MAC["🍎 MacOS (Futuro)"]
    end

    subgraph CTX ["🎯 Contextos"]
        DSK["💻 Desktop"]
        SRV["🌐 Server"]
        CNT["📦 Container"]
        WSL["🧩 WSL"]
    end

    LNX --> DSK
    LNX --> SRV
    LNX --> CNT
    LNX --> WSL

    BSD --> DSK
    BSD --> SRV
    BSD --> CNT

    WIN --> DSK

    MAC -.->|futuro| DSK
```

### Shells Compatíveis

![Bash](https://img.shields.io/badge/📜_bash-100%25-green)
![Zsh](https://img.shields.io/badge/⚡_zsh-100%25-blue)
![Sh](https://img.shields.io/badge/⚙️_sh-100%25-red)

## 🚀 Instalação

Você pode escolher o contexto do ambiente passando o parâmetro `--context` (opções: `desktop`, `server`, `container`, `wsl`).
Por padrão, se não for informado, o script assumirá o contexto `desktop`.

### 🐧 Linux / 😈 FreeBSD / 🍎 MacOS

**1. Clone o repositório:**

```sh
sudo git clone "https://github.com/GabrielFrigo4/Shell" "/usr/local/share/shell"
```

**2. Execute a instalação:**
_Escolha o contexto desejado abaixo e copie o comando do seu shell de preferência:_

**💻 Desktop (Padrão)**

```sh
bash "/usr/local/share/shell/install.sh" --context desktop
# ou
zsh "/usr/local/share/shell/install.sh" --context desktop
# ou
sh "/usr/local/share/shell/install.sh" --context desktop
```

**🌐 Server**

```sh
bash "/usr/local/share/shell/install.sh" --context server
# ou
zsh "/usr/local/share/shell/install.sh" --context server
# ou
sh "/usr/local/share/shell/install.sh" --context server
```

**📦 Container**

```sh
bash "/usr/local/share/shell/install.sh" --context container
# ou
zsh "/usr/local/share/shell/install.sh" --context container
# ou
sh "/usr/local/share/shell/install.sh" --context container
```

**🧩 WSL**

```sh
bash "/usr/local/share/shell/install.sh" --context wsl
# ou
zsh "/usr/local/share/shell/install.sh" --context wsl
# ou
sh "/usr/local/share/shell/install.sh" --context wsl
```

### 🪟 Windows

> 💡 **Ambiente:** No Windows, o projeto funciona utilizando o terminal do **MSYS2**.

**1. Clone o repositório:**

```sh
git clone "https://github.com/GabrielFrigo4/Shell" "${HOME}/.shell"
```

**2. Execute a instalação:**

```sh
bash "${HOME}/.shell/install.sh" --context desktop
# ou
zsh "${HOME}/.shell/install.sh" --context desktop
```

### 🔄 Pós-Instalação

Reinicie o shell ou recarregue o arquivo `RC` manualmente:

```sh
. ~/.bashrc
# ou
. ~/.zshrc
# ou
. ~/.shrc
```

> 💡 **Nota Importante:** O script detecta automaticamente o seu OS, distribuição 🐧 `Linux` e qual 🐚 `Shell` está rodando, e injeta as linhas de `source` no arquivo RC correto de forma inteligente — tanto para o seu usuário atual como para o `root`.

## 🛠️ Gerenciamento do Ambiente

O projeto inclui aliases e funções inteligentes integrados para que você possa manter seu ambiente atualizado, gerenciado e controlado sem esforço, diretamente do terminal:

- 🔄 **`upsh` (Update Shell):** Sincroniza o seu repositório local (`git pull`) e recarrega as configurações atuais sem precisar fechar o terminal.
- ♻️ **`resh` (Reinstall Shell):** Vai além da atualização. Ele baixa as novidades e reexecuta o script `install.sh` preservando o seu contexto atual (ex: `desktop` ou `server`). Ideal para quando há mudanças estruturais profundas no repositório.
- 📡 **`upwf` (Update Wi-Fi):** Sincroniza automaticamente as credenciais de Wi-Fi definidas no ambiente (`WIFI_SSID_*` e `WIFI_PASS_*`) com o gerenciador nativo do sistema (`nmcli` no Linux, `wpa_supplicant` / `wifibox` no FreeBSD, ou `netsh` no Windows).
- 🌐 **`upnet` (Update Network):** Orquestra a inicialização e sincronização completa da rede chamando o `upwf`.
- 📦 **`upsys` (Update System):** Atualiza os pacotes e repositórios nativos do sistema operacional chamando dinamicamente o gerenciador nativo da distribuição (`upapt`, `upman`, `updnf`, `uppkg`, `upzyp`, `upxbps` ou `upapk`).
- 🚀 **`upall` (Update All):** Orquestrador universal de atualização completa. Executa o `upsys` e integra de forma encadeada todos os gerenciadores extras presentes no sistema (`upyay`, `upflat`, `upsnap`).
- ⚡ **`poweroff` & `reboot`:** Atalhos multiplataforma inteligentes que adaptam o comando de desligamento e reinicialização para o sistema correto:
  - 🐧 **Linux:** `sudo shutdown -h now` / `sudo shutdown -r now`
  - 😈 **FreeBSD:** `sudo shutdown -p now` / `sudo shutdown -r now` (utiliza `-p` para desligar a fonte de alimentação)
  - 🪟 **Windows (MSYS2):** `shutdown.exe /s /t 0` / `shutdown.exe /r /t 0`
- 📱 **`mount-device` (`mntdev`, `mdev`):** Monta dispositivos móveis (smartphones Android, tablets, e-readers) via MTP FUSE em `~/Device` com detecção automática de drivers (`jmtpfs` / `simple-mtpfs`), tratamento de erros e abertura automática do gerenciador de arquivos gráfico padrão (`xdg-open` / `gio open`).
- 🔌 **`umount-device` (`umntdev`, `umdev`, `udev`):** Desmonta com segurança o ponto de montagem `~/Device` tratando as particularidades do Linux (`fusermount3` / `fusermount` / `umount`) e do FreeBSD (`umount`).

```mermaid
flowchart TD
    UPALL["🚀 upall<br/><i>(Orquestrador Global)</i>"]
    UPSYS["📦 upsys<br/><i>(Sistema Base)</i>"]

    UPALL --> UPSYS
    UPALL -.->|se instalado| YAY["📦 upyay<br/><i>(Arch AUR)</i>"]
    UPALL -.->|se instalado| FLAT["📦 upflat<br/><i>(Flatpak)</i>"]
    UPALL -.->|se instalado| SNAP["📦 upsnap<br/><i>(Snap)</i>"]

    UPSYS --> DNF["updnf<br/><i>(Fedora / RHEL)</i>"]
    UPSYS --> APT["upapt<br/><i>(Debian / Ubuntu)</i>"]
    UPSYS --> MAN["upman<br/><i>(Arch / MSYS2)</i>"]
    UPSYS --> PKG["uppkg<br/><i>(FreeBSD)</i>"]
    UPSYS --> ZYP["upzyp<br/><i>(OpenSUSE)</i>"]
    UPSYS --> XBPS["upxbps<br/><i>(Void)</i>"]
    UPSYS --> APK["upapk<br/><i>(Alpine)</i>"]
```

## 🔐 Integração com Vault (Segredos Seguros)

Para manter este repositório 100% público e seguro, o sistema possui uma integração nativa com um repositório de cofre privado (Vault).

Se o diretório `~/.vault` for detectado, o shell carregará automaticamente:

- 🔑 **Variáveis e Configurações:** Credenciais, tokens, chaves de API, endereços de servidores e atalhos de conexão privados (`vault.sh`).
- 🛡️ **Chaves SSH:** O alias `vault-keys` detecta o seu `ssh-agent` rodando e adiciona automaticamente todas as suas chaves privadas contidas na pasta do cofre de forma segura e silenciosa.
- 🔄 **`upvt` (Update Vault):** Sincroniza o repositório do seu cofre (`git pull` em `~/.vault`) e recarrega o terminal com as novas variáveis e chaves atualizadas.

## 🧠 Detecção Inteligente

O projeto conta com módulos avançados de reconhecimento em `library/detect.sh` que mapeiam perfeitamente o seu ecossistema:

- **OS e Shell:** Reconhece se você está no 🐧 `Linux`, 😈 `FreeBSD`, 🍎 `MacOS` ou 🪟 `Windows` (via **MSYS2**), e identifica o 🐚 `Shell` rodando (📜 `bash`, ⚡ `zsh`, ⚙️ `sh`).
- **Distribuição Linux e Família:** Ao rodar no 🐧 `Linux` ou no 🧩 `WSL2`, o módulo descobre a distribuição exata (`detect_distro`) e a agrupa pela família do gerenciador de pacotes base (`detect_distro_family` — ex: `debian`, `arch`, `fedora`, `suse`, `void`, `alpine`).
  Isso permite que `upsys` e `upall` chamem os comandos corretos (`upapt`, `upman`, `updnf`, `uppkg`, etc.) automaticamente sob os panos, sem conflitos. Gerenciadores isolados como `flatpak`, `snap` e `yay` (AUR) ganham comandos modulares dedicados (`upflat`, `upsnap`, `upyay`) que são orquestrados dinamicamente pelo `upall`.
- **Desktop Environment & Dark Mode (GTK, Qt, Electron, Java):** Identifica o ambiente gráfico (`detect_desktop_environment` — ex: `kde`, `gnome`, `xfce`, `sway`, `hyprland`), a preferência de esquema de cores do sistema (`detect_color_scheme` — `dark` ou `light` via XDG Portal / D-Bus / GSettings / KDE Globals) e mapeia as variáveis de integração para todos os principais ecossistemas:
  - **GTK:** Mapeia `GTK_THEME` inteligentemente via `detect_gtk_theme` (`Breeze-Dark` no KDE para alinhar ferramentas GTK à paleta do Plasma, integração nativa via GSettings no GNOME sem forçar overrides que degradem o Libadwaita GTK4, e `adw-gtk3-dark`/`Adwaita:dark` em WMs).
  - **Qt:** Mapeia `QT_QPA_PLATFORMTHEME` dinamicamente (`xdgdesktopportal` no GNOME/KDE/Sway/Hyprland, `gtk3` em XFCE/MATE/Cinnamon ou `qt6ct`/`qt5ct` via `detect_qt_platform_theme`) e gerencia `QT_STYLE_OVERRIDE` (`Breeze-Dark`/`Breeze` no KDE via `detect_qt_theme`). Em desktops baseados em GTK, a presença do motor de estilo **Plasma Breeze (Qt6)** e do gerenciador **`qt6ct`** (Qt6 Configuration Tool) garante paletas escuras perfeitas, fontes e ícones coerentes para ferramentas Qt puras (Wireshark, VLC, OBS) e do KDE (Kate, Krita).
  - **Electron (Wayland):** Define `ELECTRON_OZONE_PLATFORM_HINT="auto"` para que apps como VSCode, Discord, Obsidian e Spotify rodem com renderização nítida nativa no Wayland.
  - **Java / Swing:** Exporta `_JAVA_AWT_WM_NONREPARENTING=1` para garantir renderização perfeita de IDEs JetBrains, DBeaver e Ghidra sem telas cinzas.
- **Terminal TrueColor (24-bit RGB):** Exporta globalmente `COLORTERM="truecolor"` e `MICRO_TRUECOLOR=1`, garantindo renderização de 16 milhões de cores em utilitários CLI (`micro`, `bat`, `eza`, `fzf`, `neovim`).

## 📁 Estrutura do Repositório

```mermaid
flowchart TD
    RC["🐚 Arquivo RC (~/.bashrc / ~/.zshrc / ~/.shrc)"] --> LIB["📚 1. library/*.sh"]
    LIB --> CORE["⚙️ 2. core/*.sh"]
    CORE --> TGT["🎨 3. target/{OS}/{SHELL}/prompt.sh"]

    subgraph PROMPT_FLOW ["⚡ Orquestração por Sessão"]
        TGT --> THM["🖌️ theme/{SHELL}.sh"]
        TGT --> ENV["⚙️ target/{OS}/environment.sh"]
        TGT --> CTX_COM["🧩 context/{CONTEXT}/common.sh"]
        TGT --> CTX_OS["🎯 context/{CONTEXT}/{OS}.sh"]
    end
```

- 🎨 **`target/`**: Configurações divididas por Sistema Operacional (🐧 `Linux`, 😈 `FreeBSD`, 🍎 `MacOS`, 🪟 `Windows`). Mantém a experiência visual e comportamental exata 1:1, gerenciando caminhos, variáveis e comandos do SO (como `incus` no Linux e `clear` no FreeBSD).
- 📚 **`library/`**: A biblioteca padrão do projeto. Fornece utilitários de sistema e módulos de inteligência (`detect.sh` e `functions.sh`), garantindo detecção precisa de SO, shell, distribuição, ambiente gráfico e esquemas de cores.
- ⚙️ **`core/`**: O núcleo do projeto. Responsável por inicializar as fundações do ambiente, variáveis essenciais e a integração automática com o [Universal Vault Environment](https://github.com/GabrielFrigo4/Vault) (`vault.sh`).
- 🎯 **`context/`**: O orquestrador de ambientes. Adapta dinamicamente as ferramentas com base no seu escopo atual através de uma camada comum (`common.sh`) e uma camada de SO (`{OS}.sh`):
  - 💻 **`desktop/`**: Ambiente de produtividade gráfica com editores de código (`nvim`, `vim`, `kate`, `vscode`), atalhos de janelas/sessões e integração com `GTK_THEME`.
  - 🌐 **`server/`**: Perfil extremamente enxuto, ágil e focado em estabilidade para servidores remotos e produção.
  - 📦 **`container/`**: Perfil rigorosamente otimizado para microambientes (`LXC`/`Incus` no Linux ou `Jails`/`Bastille` no FreeBSD).
  - 🧩 **`wsl/`**: Ambiente híbrido que integra o Linux do WSL2 diretamente com as ferramentas nativas do Windows (`explorer.exe`, `powershell.exe`, `cmd.exe`, `win32yank.exe`).
- 🖌️ **`theme/`**: A camada de identidade visual. Unifica o prompt, paleta de cores ANSI/Zstyle, ícones Nerd Fonts e branch Git em todos os terminais.
