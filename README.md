# 🐚 Universal Shell Environment

> Configurações, aliases e prompts centralizados para todos os seus ambientes de sistema, mantendo a experiência consistente seja no Desktop, Servidor ou Contêiner.

![Bash](https://img.shields.io/badge/bash-100%25-green)
![Zsh](https://img.shields.io/badge/zsh-100%25-blue)
![MSYS2](https://img.shields.io/badge/MSYS2-Supported-purple)
![Linux](https://img.shields.io/badge/Linux-Supported-orange)
![FreeBSD](https://img.shields.io/badge/FreeBSD-Supported-red)
![WSL2](https://img.shields.io/badge/WSL2-Supported-cyan)

---

## 🚀 Instalação

Você pode escolher o contexto do ambiente passando o parâmetro `--context` (opções: `desktop`, `server`, `container`, `wsl`).
Por padrão, se não for informado, o script assumirá o contexto `desktop`.
Você também pode utilizar os scripts de atalho: `install-desktop.sh`, `install-server.sh`, `install-container.sh` e `install-wsl.sh`.

### 🐧 Linux / 😈 FreeBSD / 🍎 MacOS

```sh
sudo git clone "https://github.com/GabrielFrigo4/Shell" "/usr/local/share/shell"

# Execute usando o seu shell de preferência:
bash "/usr/local/share/shell/install.sh" --context desktop
# ou
zsh "/usr/local/share/shell/install.sh" --context desktop
# ou
sh "/usr/local/share/shell/install.sh" --context desktop
```

### 🪟 MSYS2 (Windows)

```sh
git clone "https://github.com/GabrielFrigo4/Shell" "${HOME}/.shell"

# Execute usando o seu shell de preferência:
bash "${HOME}/.shell/install.sh" --context desktop
# ou
zsh "${HOME}/.shell/install.sh" --context desktop
```

### 🔄 Pós-Instalação

Reinicie o shell ou recarregue o arquivo `RC` manualmente:

```sh
. ~/.shrc
# ou
. ~/.bashrc
# ou
. ~/.zshrc
```

> 💡 **Nota Importante:** O script detecta automaticamente o seu OS, distribuição Linux e qual shell está rodando, e injeta as linhas de `source` no arquivo RC correto de forma inteligente — tanto para o seu usuário atual como para o `root`.

---

## 🧠 Detecção Inteligente

O projeto conta com módulos avançados de reconhecimento em `core/detect.sh` que mapeiam perfeitamente o seu ecossistema:
- **OS e Shell:** Reconhece se você está no Linux, FreeBSD ou Windows (MSYS2), e identifica o shell rodando (`bash`, `zsh`, `sh`, etc.).
- **Distribuição Linux e Família:** Ao rodar no Linux ou no WSL2, o módulo descobre a distribuição exata (`detect_distro`) e a agrupa pela família do gerenciador de pacotes base (`detect_distro_family` — ex: `debian`, `arch`, `fedora`). 
Isso permite que os aliases universais (como `upall` e `upsys`) chamem as ferramentas corretas automaticamente sob os panos (`apt`, `pacman`/`yay`, ou `dnf`), sem sobrepor os comandos ou quebrar scripts. Gerenciadores isolados como `flatpak` e `snap` também são detectados e ganham comandos separados (`upflat` / `upsnap`) apenas se estiverem presentes no sistema.

---

## 📁 Estrutura do Repositório

- 🎨 **`target/`**: Configurações divididas por Sistema Operacional (Windows, Linux, FreeBSD). Mantém a experiência visual exata 1:1, independentemente de ser um pinguim, demônio ou janela.
- ⚙️ **`core/`**: Funções e lógicas universais, compatíveis com qualquer sistema POSIX.
- 🎯 **`context/`**: Inicializadores e perfis de ambiente:
  - 🖥️ **Desktop**: Com ferramentas ricas e configuração voltada para o uso pessoal (UI, aliases gráficos, etc).
  - 📡 **Server**: Mais enxuto, direto ao ponto, ideal para servidores em produção.
  - 📦 **Container**: Foco em contêineres e jails (LXC, Incus, Bastille), utilizando uma versão otimizada do ambiente servidor.
  - 🪟 **WSL**: Ambiente híbrido para WSL2, com integração Windows (explorer, cmd, powershell, clip) e gerenciamento de pacotes da distro.
- 🖌️ **`theme/`**: Definições dos temas, cores e integrações de prompts como o Oh-My-Zsh ou Oh-My-Bash.
