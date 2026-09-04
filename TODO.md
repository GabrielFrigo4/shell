# 🗺️ Roadmap & Backlog

> Planejamento estratégico, marcos entregues e visão de futuro para a evolução do **Universal Shell**.

---

## 📊 Status do Projeto

| Área                     |   Status   | Cobertura                                                           |
| :----------------------- | :--------: | :------------------------------------------------------------------ |
| **🖥️ Plataformas Base**  | 🟢 Estável | Linux, FreeBSD, Windows (MSYS2), macOS (base)                       |
| **🐚 Shells Nativos**    | 🟢 Estável | Bash, Zsh, POSIX sh (Linux & FreeBSD)                               |
| **🎯 Contextos**         | 🟢 Estável | Desktop, Server, Container, WSL                                     |
| **🎨 Temas & TTY**       | 🟢 Estável | Adaptação dinâmica PTY / Raw TTY em Zsh, Bash e Sh                  |
| **⚡ Modern CLI**        | 🟢 Estável | Cascata inteligente (`eza`, `bat`, `rg`, `fd` > nativos)            |
| **🌳 VCS & Prompts**     | 🟢 Estável | Git e Got (Game of Trees)                                           |
| **💎 Clean Code**        |  🟢 100%   | 18 Princípios UNIX & Taxonomia de 3 níveis de biblioteca            |
| **🧪 Automação & CI/CD** | 🟢 Estável | Git Hooks locais (`.githooks/pre-commit`) + GitHub Actions multi-OS |

---

## 🎯 Próximos Passos (Backlog Ativo)

### 🍎 Expansão de Plataformas & Shells

- [ ] **Fish Shell (Exploratório):** Avaliação de suporte opcional ao Fish (`fish_prompt`, funções e completions nativos).

### 🧩 Contextos Avançados

- [ ] **Container (`context/container/`):** Otimizações específicas para Docker, Podman e Jails (desativação de timers pesados e polling de disco).
- [ ] **Servidor (`context/server/`):** Utilitários rápidos para inspeção de portas abertas (`ports`), monitoramento de logs em tempo real (`logs`) e status de serviços (`services`).

---

> [!TIP]
> Para detalhes sobre convenções de código e diretrizes de contribuição, consulte [PRINCIPLES.md](PRINCIPLES.md).
