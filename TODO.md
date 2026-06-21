# 📋 Roadmap & TODO

Lista de tarefas e objetivos para evoluir o ecossistema do **Universal Shell**.

---

## 🎯 Prioridades (Backlog)

- [ ] 🖥️ **1. Adicionar Suporte 100% para WSL2**
  - Criar um novo contexto isolado (`--context wsl`), pois o WSL2 possui comportamentos únicos e não se enquadra perfeitamente como _Server_, _Desktop_ ou _Container_.

- [ ] 🐧 **2. Melhorar o Módulo Linux (Detecção de Distro)**
  - Fazer com que o módulo não se perca entre as diferentes distribuições Linux.
  - Detectar se a base é **Arch Linux**, **Debian**, **Ubuntu**, **Fedora**, etc.
  - Aplicar essas lógicas de diferenciação e proteção para todos os contextos, tanto `Desktop` quanto `Server`.

- [ ] 📦 **3. Refatorar Comandos de Atualização e Gerenciamento de Pacotes**
  - Fazer os aliases e comandos de atualização respeitarem os padrões das distros corretamente:
    - _Debian_ usa `apt`.
    - _Ubuntu_ usa `apt` + `snap`.
  - Desvincular e isolar ferramentas independentes: O `flatpak` e `appimage` devem ser configurados como comandos de atualizações externos/extras.
  - Eles não devem ficar presos ou atrelados forçosamente ao alias principal de atualização (`upall`).

- [ ] 🔄 **4. Criar função "Super Upsh" (Atualização Profunda)**
  - Criar o comando `insh` (abreviação de _install shell_) ou `dwsh` (abreviação de _download shell_) ou algo parecido que vá além de apenas um `git pull` (que é o que o `upsh` atual faz).
  - A nova função deve atualizar o repositório E rodar o `install.sh` novamente preservando o contexto atual (`--context $SHELL_CONTEXT`), injetando ou corrigindo quaisquer novas configurações ou rotinas que foram baixadas.

---

> 💡 Quer contribuir? Pegue uma tarefa do TODO e envie um Pull Request!
