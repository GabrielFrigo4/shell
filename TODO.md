# 📋 Roadmap & TODO

Lista de tarefas e objetivos para evoluir o ecossistema do **Universal Shell**.

---

## 🎯 Prioridades (Backlog)

- [x] 🖥️ **1. Adicionar Suporte 100% para WSL2**
  - ~~Criar um novo contexto isolado (`--context wsl`), pois o WSL2 possui comportamentos únicos e não se enquadra perfeitamente como _Server_, _Desktop_ ou _Container_.~~
  - ✅ Criado `context/wsl/linux.sh` com integração Windows (explorer, cmd, powershell, clip) e detecção de distro. Adicionado `--context wsl` no `install.sh` e `install-wsl.sh`.

- [x] 🐧 **2. Melhorar o Módulo Linux (Detecção de Distro)**
  - ~~Fazer com que o módulo não se perca entre as diferentes distribuições Linux.~~
  - ~~Detectar se a base é **Arch Linux**, **Debian**, **Ubuntu**, **Fedora**, etc.~~
  - ~~Aplicar essas lógicas de diferenciação e proteção para todos os contextos, tanto `Desktop` quanto `Server`.~~
  - ✅ Criado `detect_distro()` e `detect_distro_family()` em `core/detect.sh`. Todos os contextos Linux agora usam detecção dinâmica.

- [x] 📦 **3. Refatorar Comandos de Atualização e Gerenciamento de Pacotes**
  - ~~Fazer os aliases e comandos de atualização respeitarem os padrões das distros corretamente.~~
  - ~~Desvincular e isolar ferramentas independentes: O `flatpak` e `appimage` devem ser configurados como comandos de atualizações externos/extras.~~
  - ~~Eles não devem ficar presos ou atrelados forçosamente ao alias principal de atualização (`upall`).~~
  - ✅ `upall` agora = apenas gerenciador nativo (`pacman`/`apt`/`dnf`). `upflat` e `upsnap` são extras opcionais, definidos apenas se os binários existirem.

- [x] 🔄 **4. Criar função "Super Upsh" (Atualização Profunda)**
  - ~~Criar o comando `insh` (abreviação de _install shell_) ou `dwsh` (abreviação de _download shell_) ou algo parecido que vá além de apenas um `git pull` (que é o que o `upsh` atual faz).~~
  - ~~A nova função deve atualizar o repositório E rodar o `install.sh` novamente preservando o contexto atual (`--context $SHELL_CONTEXT`), injetando ou corrigindo quaisquer novas configurações ou rotinas que foram baixadas.~~
  - ✅ Implementado como `resh` em `core/functions.sh`.

- [x] 🧹 **5. Padronizar Detecção de Shell**
  - ~~A detecção de shell estava triplicada com implementações diferentes em `install.sh`, `core/environment.sh` e `core/functions.sh`.~~
  - ✅ Criado `core/detect.sh` com funções `detect_os()` e `detect_shell()` centralizadas. Os arquivos runtime agora usam as mesmas funções.

---

> 💡 Quer contribuir? Pegue uma tarefa do TODO e envie um Pull Request!
