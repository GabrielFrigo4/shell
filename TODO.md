# 📋 Roadmap & TODO

Lista de tarefas, objetivos e marcos para a evolução contínua do ecossistema **Universal Shell**.

---

## ✅ Concluído (Milestones Entregues)

- [x] **Arquitetura Multi-SO & Multi-Shell:** Suporte modular para Linux, FreeBSD, Windows (MSYS2) e shells Bash, Zsh e FreeBSD SH.
- [x] **Elevação de Privilégios Agregada (`_as_root`):** Prioridade inteligente `root` ➔ `doas` ➔ `sudo` em toda a base de código.
- [x] **Soberania do Usuário (Princípio 18):** Respeito estrito a variáveis pré-existentes (`$EDITOR`, `$VISUAL`, `$FILEMANAGER`) e aliases bidirecionais de compatibilidade (`sudo` ⇄ `doas`, `paru` ⇄ `yay`).
- [x] **Editor Universal (`editor` / `e`):** Cascata ampla de editores (Neovim, Helix, Micro, Kakoune, Nano, EE, MG, Vim, MC, VI) com suporte a flags e abertura contextual no diretório atual (`.`).
- [x] **Padronização de Helpers Privados (`_snake_case`):** Isolamento de funções internas para autocompletion limpo e despoluído.
- [x] **Catálogo Completo no README:** Mapa de comandos públicos categorizado com diagramas Mermaid.
- [x] **Conformidade POSIX & Trailing Newlines:** 100% dos arquivos com término estrito em uma única quebra de linha (`\n`).

---

## 🎯 Futuras Melhorias (Backlog & Explorações)

- [ ] **Expansão de Targets:**
  - [ ] Target nativo refinado para 🍎 macOS (Darwin / Homebrew / Zsh).
  - [ ] Suporte opcional a plugins e prompts modernos em 🐟 Fish Shell.
- [ ] **Contextos Especializados:**
  - [ ] `context/container/`: Otimizações específicas para containers Docker/Podman (desativação automática de timers e polling pesado).
  - [ ] `context/server/`: Funções utilitárias para monitoramento de portas, logs em tempo real e status de serviços systemd/rc.d.
- [ ] **Testes Automatizados de CI/CD:**
  - [ ] GitHub Actions workflow para validação contínua de sintaxe (`sh -n`) e integridade de EOF (`\n`).

---

> 💡 Quer contribuir? Pegue uma tarefa do TODO e envie um Pull Request!
