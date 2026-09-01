# 🗺️ Roadmap & Backlog

> Planejamento estratégico, marcos entregues e visão de futuro para a evolução do **Universal Shell**.

---

## 📊 Status do Projeto

| Área | Status | Cobertura |
| :--- | :---: | :--- |
| **🖥️ Plataformas Base** | 🟢 Estável | Linux, FreeBSD, Windows (MSYS2), macOS (base) |
| **🐚 Shells Nativos** | 🟢 Estável | Bash, Zsh, POSIX sh (Linux & FreeBSD) |
| **🎯 Contextos** | 🟢 Estável | Desktop, Server, Container, WSL |
| **🎨 Temas & TTY** | 🟢 Estável | Adaptação dinâmica PTY / Raw TTY em Zsh, Bash e Sh |
| **⚡ Modern CLI** | 🟢 Estável | Cascata inteligente (`eza`, `bat`, `rg`, `fd` > nativos) |
| **🌳 VCS & Prompts** | 🟢 Estável | Git e Got (Game of Trees) |
| **💎 Clean Code** | 🟢 100% | 18 Princípios UNIX & Taxonomia de 3 níveis de biblioteca |

---

## 🎯 Próximos Passos (Backlog Ativo)

### 1. 🍎 Expansão de Plataformas & Shells
- [ ] **Target macOS:** Refinamento nativo para Darwin / macOS (integração com Homebrew, Zsh padrão e atalhos do Finder).
- [ ] **Fish Shell (Exploratório):** Avaliação de suporte opcional ao Fish (`fish_prompt`, funções e completions nativos).

### 2. 🧩 Contextos Avançados
- [ ] **Container (`context/container/`):** Otimizações específicas para Docker, Podman e Jails (desativação de timers pesados e polling de disco).
- [ ] **Servidor (`context/server/`):** Utilitários rápidos para inspeção de portas abertas (`ports`), monitoramento de logs em tempo real (`logs`) e status de serviços (`services`).

### 3. 🧪 Automação & Qualidade (CI/CD)
- [ ] **GitHub Actions:** Pipeline automatizado de linting e validação de sintaxe POSIX (`sh -n`), integridade de finais de linha (`\n`) e regras de permissões octais.

---

> [!TIP]
> Para detalhes sobre convenções de código e diretrizes de contribuição, consulte [PRINCIPLES.md](PRINCIPLES.md).
