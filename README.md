# 🐚 Universal Shell Environment

> Configurações, aliases e prompts centralizados para todos os seus ambientes de sistema, mantendo a experiência consistente seja no Desktop, Servidor ou Contêiner.

![Bash](https://img.shields.io/badge/bash-100%25-green)
![Zsh](https://img.shields.io/badge/zsh-100%25-blue)
![MSYS2](https://img.shields.io/badge/MSYS2-Supported-purple)
![Linux](https://img.shields.io/badge/Linux-Supported-orange)
![FreeBSD](https://img.shields.io/badge/FreeBSD-Supported-red)

---

## 🚀 Instalação

Você pode escolher o contexto do ambiente passando o parâmetro `--context` (opções: `desktop`, `server`, `container`).
Por padrão, se não for informado, o script assumirá o contexto `desktop`.
Você também pode utilizar os scripts de atalho: `install-desktop.sh`, `install-server.sh` e `install-container.sh`.

### 🐧 Linux / 😈 FreeBSD / 🍎 MacOS

```sh
sudo git clone "https://github.com/GabrielFrigo4/Shell" "/usr/local/share/shell"
sh "/usr/local/share/shell/install.sh" --context desktop
```

### 🪟 MSYS2 (Windows)

```sh
git clone "https://github.com/GabrielFrigo4/Shell" "${HOME}/.shell"
sh "${HOME}/.shell/install.sh" --context desktop
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

> 💡 **Nota Importante:** O script detecta automaticamente o seu OS e qual shell está rodando, e injeta as linhas de `source` no arquivo RC correto de forma inteligente — tanto para o seu usuário atual como para o `root`.

---

## 📁 Estrutura do Repositório

- 🎨 **`target/`**: Configurações divididas por Sistema Operacional (Windows, Linux, FreeBSD). Mantém a experiência visual exata 1:1, independentemente de ser um pinguim, demônio ou janela.
- ⚙️ **`core/`**: Funções e lógicas universais, compatíveis com qualquer sistema POSIX.
- 🎯 **`context/`**: Inicializadores e perfis de ambiente:
  - 🖥️ **Desktop**: Com ferramentas ricas e configuração voltada para o uso pessoal (UI, aliases gráficos, etc).
  - 📡 **Server**: Mais enxuto, direto ao ponto, ideal para servidores em produção.
  - 📦 **Container**: Foco em contêineres e jails (LXC, Incus, Bastille), utilizando uma versão idêntica ou otimizada do ambiente servidor.
- 🖌️ **`theme/`**: Definições dos temas, cores e integrações de prompts como o Oh-My-Zsh ou Oh-My-Bash.
