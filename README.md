# 🐚 Universal Shell Environment

> Configurações, aliases e prompts centralizados para todos os seus ambientes de sistema, mantendo a experiência consistente seja no Desktop, Servidor, Contêiner ou WSL. Componente de runtime interativo do **Quarteto de Produtividade**.

---

### 🏛️ O Quarteto de Produtividade

[![Setup](https://img.shields.io/badge/📦_Setup-Sistema_%26_Cookbook-blue)](https://github.com/GabrielFrigo4/setup)
[![Shell](https://img.shields.io/badge/🐚_Shell-Terminal_Runtime-purple)](https://github.com/GabrielFrigo4/shell)
[![Vault](https://img.shields.io/badge/🔐_Vault-Cofre_Privado-red)](https://github.com/GabrielFrigo4/vault)
[![Profile](https://img.shields.io/badge/🎨_Profile-Dotfiles_%26_IA-green)](https://github.com/GabrielFrigo4/profile)

> 📖 **Arquitetura Unificada do Ecossistema:** Conheça a matriz completa de responsabilidades, ciclo de boot e segregação de privilégios em [ENVIRONMENT.md](ENVIRONMENT.md).
> 📜 **Princípios de Engenharia:** Conheça os 18 princípios UNIX e boas práticas Clean Code em [PRINCIPLES.md](PRINCIPLES.md).

---

### 🖥️ Sistemas, Contextos & Shells

![Linux](https://img.shields.io/badge/🐧_Linux-Supported-blue)
![FreeBSD](https://img.shields.io/badge/😈_FreeBSD-Supported-red)
![macOS](https://img.shields.io/badge/🍎_macOS-Supported-blue)
![Windows](https://img.shields.io/badge/🪟_Windows_%28MSYS2%29-Supported-purple)
![Bash](https://img.shields.io/badge/📜_bash-100%25-green)
![Zsh](https://img.shields.io/badge/⚡_zsh-100%25-blue)
![Sh](https://img.shields.io/badge/⚙️_sh-100%25-red)
![Dash](https://img.shields.io/badge/💨_dash-Incompatível_POSIX-lightgrey)
![Fish](https://img.shields.io/badge/🐟_fish-Incompatível_POSIX-lightgrey)
[![CI](https://github.com/GabrielFrigo4/shell/actions/workflows/ci.yml/badge.svg)](https://github.com/GabrielFrigo4/shell/actions/workflows/ci.yml)

```mermaid
flowchart LR
    subgraph OS ["🖥️ Plataformas"]
        LNX["🐧 Linux"]
        BSD["😈 FreeBSD"]
        WIN["🪟 Windows (MSYS2)"]
        MAC["🍎 macOS"]
    end

    subgraph CTX ["🎯 Contextos"]
        DSK["💻 Desktop"]
        SRV["🌐 Server"]
        CNT["📦 Container"]
        WSL["🧩 WSL"]
    end

    LNX --> DSK & SRV & CNT & WSL
    BSD --> DSK & SRV & CNT
    WIN --> DSK
    MAC --> DSK
```

#### 🐚 Matriz de Suporte a Shells

| Shell             |    Status     | Detalhes & Decisão de Arquitetura                                                                         |
| :---------------- | :-----------: | :-------------------------------------------------------------------------------------------------------- |
| **Bash (`bash`)** |    🟢 100%    | Suporte universal nativo em Linux, macOS, BSD e Windows. Template Oh-My-Bash otimizado.                   |
| **Zsh (`zsh`)**   |    🟢 100%    | Shell primário interativo moderno. Template Oh-My-Zsh com `zcompile` e `ZSH_DISABLE_COMPFIX`.             |
| **Sh (`sh`)**     |    🟢 100%    | Shell POSIX leve e fundamental (FreeBSD `/bin/sh`). Prompt puro sem overhead de frameworks.               |
| **Dash (`dash`)** | ❌ Descartado | **Incompatibilidade POSIX:** BNF estrita proíbe nomes `kebab-case` (`-`) em funções (`update-all`, etc.). |
| **Fish (`fish`)** | ❌ Descartado | **Incompatibilidade POSIX:** Sintaxe própria incompatível com `source` em arquivos `.sh` e `export`.      |

---

## 🚀 Instalação Rápida

O instalador é **multi-shell automático**: ao ser executado, ele detecta os shells suportados instalados na máquina e configura todos eles em lote:

- **Linux:** configura automaticamente `zsh` e `bash` (caso instalados).
- **FreeBSD:** configura automaticamente `zsh`, `bash` e `sh` (caso instalados).
- **macOS:** configura automaticamente `zsh` e `bash` (caso instalados).
- **Windows (MSYS2):** configura `zsh` e `bash` (caso instalados).

> 💡 **Novo shell instalado depois?** Se você instalar um novo shell posteriormente (ex: `sudo pacman -S zsh` ou `pkg install zsh`), basta executar `reinstall-shell` (ou reexecutar o `install.sh`) e ele configurará o novo shell automaticamente!

### 🐧 Linux / 😈 FreeBSD / 🍎 macOS

```sh
sudo git clone "https://github.com/GabrielFrigo4/shell" "/usr/local/share/shell"
sh "/usr/local/share/shell/install.sh" --context desktop
```

### 🪟 Windows (MSYS2)

```sh
git clone "https://github.com/GabrielFrigo4/shell" "${HOME}/.shell"
sh "${HOME}/.shell/install.sh" --context desktop
```

### ⚙️ Opções do Instalador

| Opção         |      Atalho      | Valores                                 |   Padrão   | Descrição                                                                    |
| :------------ | :--------------: | :-------------------------------------- | :--------: | :--------------------------------------------------------------------------- |
| `--context`   |       `-c`       | `desktop`, `server`, `container`, `wsl` | `desktop`  | Perfil de contexto do ambiente.                                              |
| `--shell`     |       `-s`       | `all`, `zsh`, `bash`, `sh`              |   `all`    | Instala em todos os shells instalados ou em um alvo específico.              |
| `--framework` | `--oh-my-shell`  | Flag booleana                           | Desativado | Habilita frameworks externos de terceiros (Oh-My-Bash / Oh-My-Zsh).          |
| `--pure`      | `--no-framework` | Flag booleana                           |  Ativado   | Modo padrão: templates standalone nativos, zero overhead e boot instantâneo. |

---

## ⚡ Comandos Mais Usados

| Comando / Alias                       | Ação                                                                   | Destino               |
| :------------------------------------ | :--------------------------------------------------------------------- | :-------------------- |
| `update-all` / `upall` / `u`          | **Orquestrador Global:** Atualiza SO + AUR + Flatpak + Snap.           | Universal             |
| `update-system` / `upsys`             | Atualiza pacotes do sistema operacional nativo.                        | Universal             |
| `update-shell` / `upsh`               | Atualiza o repositório do shell (`git pull`), limpa cache e recarrega. | Universal             |
| `reinstall-shell` / `resh`            | Reexecuta o instalador em todos os shells instalados no SO.            | Universal             |
| `clean-cache` / `ccache`              | Limpa o cache em memória e tmpfs de todos os detectores do ambiente.   | Universal             |
| `update-vault` / `upvt`               | Sincroniza segredos (`~/.vault`) e recarrega chaves SSH.               | Universal             |
| `bench-shell` / `bsh` / `shell-bench` | Mede a latência de inicialização dos shells e módulos isolados.        | Universal             |
| `update-wifi` / `upwf`                | Sincroniza credenciais Wi-Fi configuradas com o SO.                    | Linux, BSD, Windows   |
| `update-network` / `upnet`            | Valida conectividade e sincroniza credenciais de rede.                 | Universal             |
| `editor [alvo]` / `e`                 | Abre o editor padrão configurado na cascata de prioridade.             | `$VISUAL` / `$EDITOR` |
| `open-neovim` / `on`                  | Abre o Neovim no alvo especificado (padrão: `.`).                      | `nvim`                |
| `open-helix` / `oh` / `h`             | Abre o Helix no alvo especificado (padrão: `.`).                       | `hx`                  |
| `open-code` / `oc`                    | Abre o VS Code no alvo especificado (padrão: `.`).                     | `code` / `vscode`     |
| `mount-device` / `mntdev` / `mdev`    | Monta celular em `~/Device` via GVfs/KIO-FUSE/GSConnect/ADB.           | Desktop               |
| `umount-device` / `umdev` / `udev`    | Desmonta e desconecta `~/Device` com segurança.                        | Desktop               |
| `ports` / `p`                         | Inspeciona portas de rede em escuta (`ss` > `netstat` > `sockstat`)    | Servidor / Desktop    |
| `services` / `svc`                    | Inspeciona status dos serviços (`systemctl` > `service` > `rc-status`) | Servidor / Desktop    |
| `l`, `ll`, `la`, `lt`                 | Listagem moderna com ícones e status git (`eza`/`exa`/`ls`).           | Universal             |
| `g <termo>`                           | Busca inteligente de texto em arquivos (`rg` > `grep`).                | Universal             |
| `c <arquivo>` / `b`                   | Visualizador formatado com syntax highlighting (`bat` > `cat`).        | Universal             |
| `f <alvo>` / `ff`                     | Localizador ultrarrápido de arquivos (`fd` > `find`).                  | Universal             |

> 📖 **Consulte o catálogo completo de atalhos e variáveis em [docs/ALIASES.md](docs/ALIASES.md).**

---

## 📚 Documentação Técnica Completa

Para aprofundar na arquitetura, comportamentos por contexto e motores de detecção:

- 🏛️ **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**: Ciclo de vida da sessão interativa, cascata de sourcing e orçamento de latência (&lt;50ms).
- 🎯 **[docs/CONTEXTS.md](docs/CONTEXTS.md)**: Especificação dos perfis `desktop`, `server`, `container` e `wsl`.
- 🧠 **[docs/DETECTION.md](docs/DETECTION.md)**: Reconhecimento de SOs, famílias de distros Linux, dark mode (D-Bus/XDG Portal) e integração GTK/Qt/Electron.
- 🖌️ **[docs/THEMES.md](docs/THEMES.md)**: Contratos visuais dos prompts (Bash, Zsh, Sh), paleta ANSI e fallback para TTYs puros.
- 🗺️ **[docs/ALIASES.md](docs/ALIASES.md)**: Dicionário exaustivo de comandos públicos, atalhos e variáveis de ambiente.

---

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

- 📚 **[library/](library/README.md)**: Biblioteca padrão com utilitários POSIX (`functions.sh`) e módulos analíticos (`detect.sh`).
- ⚙️ **[core/](core/README.md)**: Fundações do ambiente (`environment.sh`) e integração com segredos (`vault.sh`).
- 🎯 **[context/](context/README.md)**: Orquestrador de perfis operacionais (`desktop`, `server`, `container`, `wsl`).
- 🖌️ **[theme/](theme/README.md)**: Motores de renderização de prompts (Bash, Zsh, Sh).
- 🎨 **`target/`**: Configurações específicas por sistema operacional (`Linux`, `FreeBSD`, `MacOS`, `Windows`).

---

## 🧪 Quality Gates & Ganchos Git (.githooks)

Para habilitar a validação multi-shell, benchmark de latência e verificação de Markdown antes de cada commit:

```sh
chmod 0755 .githooks/pre-commit
git config core.hooksPath .githooks
```

Para executar o pre-commit hook manualmente:

```sh
./.githooks/pre-commit
```
