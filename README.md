# 🐚 Universal Shell Environment

> Configurações, aliases e prompts centralizados para todos os seus ambientes de sistema, mantendo a experiência consistente seja no Desktop, Servidor, Contêiner ou WSL.

### Sistemas Suportados

![Linux](https://img.shields.io/badge/🐧_Linux-Supported-blue)
![FreeBSD](https://img.shields.io/badge/😈_FreeBSD-Supported-red)
![MacOS](https://img.shields.io/badge/🍎_MacOS-Unsupported-lightgrey)
![MSYS2 (Windows)](https://img.shields.io/badge/🪟_MSYS2-Supported-purple)

### Contextos de Ambiente

![Desktop](https://img.shields.io/badge/💻-Desktop-cyan)
![Server](https://img.shields.io/badge/🌐-Server-orange)
![Container](https://img.shields.io/badge/📦-Container-yellow)
![WSL](https://img.shields.io/badge/🧩-WSL-blueviolet)

### Shells Compatíveis

![Bash](https://img.shields.io/badge/📜_bash-100%25-green)
![Zsh](https://img.shields.io/badge/⚡_zsh-100%25-blue)
![Sh](https://img.shields.io/badge/⚙️_sh-100%25-red)

## 🚀 Instalação

Você pode escolher o contexto do ambiente passando o parâmetro `--context` (opções: `desktop`, `server`, `container`, `wsl`).
Por padrão, se não for informado, o script assumirá o contexto `desktop`.
Você também pode utilizar os scripts de atalho: `install-desktop.sh`, `install-server.sh`, `install-container.sh` e `install-wsl.sh`.

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

### 🪟 MSYS2 (Windows)

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

O projeto inclui aliases inteligentes integrados para que você possa manter seu ambiente atualizado sem esforço, diretamente do terminal:

- 🔄 **`upsh` (Update Shell):** Sincroniza o seu repositório local (`git pull`) e recarrega as configurações atuais sem precisar fechar o terminal.
- ♻️ **`resh` (Reinstall Shell):** Vai além da atualização. Ele baixa as novidades e reexecuta o script `install.sh` preservando o seu contexto atual (ex: `desktop` ou `server`). Ideal para quando há mudanças estruturais profundas no repositório.

## 🔐 Integração com Vault (Segredos Seguros)

Para manter este repositório 100% público e seguro, o sistema possui uma integração nativa com um repositório de cofre privado (Vault).

Se o diretório `~/.vault` for detectado, o shell carregará automaticamente:

- 🔑 **Variáveis e Configurações:** Credenciais, tokens, chaves de API, endereços de servidores e atalhos de conexão privados (`vault.sh`).
- 🛡️ **Chaves SSH:** O alias `vault-keys` detecta o seu `ssh-agent` rodando e adiciona automaticamente todas as suas chaves privadas contidas na pasta do cofre de forma segura e silenciosa.
- 🔄 **`upvt` (Update Vault):** Sincroniza o repositório do seu cofre (`git pull` em `~/.vault`) e recarrega o terminal com as novas variáveis e chaves atualizadas.

## 🧠 Detecção Inteligente

O projeto conta com módulos avançados de reconhecimento em `core/detect.sh` que mapeiam perfeitamente o seu ecossistema:

- **OS e Shell:** Reconhece se você está no 🐧 `Linux`, 😈 `FreeBSD`, 🍎 `MacOS` ou 🪟 `MSYS2`, e identifica o 🐚 `Shell` rodando (📜 `bash`, ⚡ `zsh`, ⚙️ `sh`).
- **Distribuição Linux e Família:** Ao rodar no 🐧 `Linux` ou no 🧩 `WSL2`, o módulo descobre a distribuição exata (`detect_distro`) e a agrupa pela família do gerenciador de pacotes base (`detect_distro_family` — ex: `debian`, `arch`, `fedora`).
  Isso permite que os aliases universais (como `upall` e `upsys`) chamem as ferramentas corretas automaticamente sob os panos (`apt`, `pacman`/`yay`, ou `dnf`), sem sobrepor os comandos ou quebrar scripts. Gerenciadores isolados como `flatpak` e `snap` também são detectados e ganham comandos separados (`upflat` / `upsnap`) apenas se estiverem presentes no sistema.

## 📁 Estrutura do Repositório

- 🎨 **`target/`**: Configurações divididas por Sistema Operacional (🐧 `Linux`, 😈 `FreeBSD`, 🍎 `MacOS`, 🪟 `Windows`). Mantém a experiência visual exata 1:1, independentemente de ser um pinguim, demônio ou janela.
- ⚙️ **`core/`**: Funções e lógicas universais, compatíveis com qualquer sistema POSIX.
- 🎯 **`context/`**: Inicializadores e perfis de ambiente descritos abaixo.
- 💻 **`context/desktop/`**: Com ferramentas ricas e configuração voltada para o uso pessoal (UI, aliases gráficos, etc).
- 🌐 **`context/server/`**: Mais enxuto, direto ao ponto, ideal para servidores em produção.
- 📦 **`context/container/`**: Foco em 📦 `Contêineres` como `LXC` e `Incus` (no 🐧 `Linux`) ou `Jails` e `Bastille` (no 😈 `FreeBSD`), utilizando uma versão otimizada do ambiente servidor.
- 🧩 **`context/wsl/`**: Ambiente híbrido para 🧩 `WSL2`, com integração 🪟 `Windows` (explorer, cmd, powershell, clip) e gerenciamento de pacotes da distro.
- 🖌️ **`theme/`**: Definições dos temas, cores e integrações de prompts como o Oh-My-Zsh ou Oh-My-Bash.
