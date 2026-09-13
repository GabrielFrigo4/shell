# 🗺️ Roadmap & Backlog

> Planejamento estratégico, status operacional e visão de futuro para a evolução do **Universal Shell**.

---

## 📊 Status do Projeto

| Área                           |   Status   | Cobertura                                                                                  |
| :----------------------------- | :--------: | :----------------------------------------------------------------------------------------- |
| **🖥️ Plataformas Base**        | 🟢 Estável | Linux, FreeBSD, OpenBSD, NetBSD, illumos, macOS, Windows (MSYS2)                           |
| **🐚 Shells Nativos**          | 🟢 Estável | Zsh, Bash (todos os SOs), POSIX sh (exclusivo FreeBSD) e KornShell ksh (exclusivo OpenBSD) |
| **🎯 Contextos**               | 🟢 Estável | Desktop, Server, Container (com auto-detecção WSL sob demanda)                             |
| **🎨 Temas Puros & TTY**       | 🟢 Estável | Motores em `theme/` dedicados à renderização visual e adaptação dinâmica PTY / Raw TTY     |
| **⚙️ Shell Configs Comuns**    | 🟢 Estável | Centralização em `target/common/` (`zsh.sh`, `bash.sh`, `sh.sh`, `ksh.sh`)                 |
| **🛡️ Segurança & Proteção**    | 🟢 Estável | Rigor `noclobber` padronizado (`setopt NO_CLOBBER`, `set -o noclobber`, `set -C`)          |
| **⚡ Motor de Cache & Boot**   | 🟢 Estável | Cache consolidado (`cache.env` + `tmpfs`) com boot < 20ms (Zsh) e < 16ms (Bash)            |
| **📦 Instalador Multi-Shell**  | 🟢 Estável | Detecção automática em lote de shells e templates standalone puros (`SHELL_FRAMEWORK=0`)   |
| **⚡ Modern CLI**              | 🟢 Estável | Cascata inteligente (`eza`, `bat`, `rg`, `fd`, `dust`, `procs`, `btm` > nativos)           |
| **📦 Atualizador Global**      | 🟢 Estável | Orquestrador `update-all`/`update-system` para 11 gerenciadores em 7 SOs (Linux, BSDs, Mac) |
| **🌳 VCS & Prompts**           | 🟢 Estável | Git e Got (Game of Trees) com status de modificação em tempo real                          |
| **💎 Clean Code & Princípios** |  🟢 100%   | 18 Princípios UNIX, comentários simétricos de 36 colunas e Zero Warnings                   |
| **🧪 Automação & CI/CD**       | 🟢 Estável | Git Hooks locais (`.githooks/pre-commit`) + GitHub Actions multi-OS (8 matrizes completas) |
| **⚡ Latência & Benchmarking** | 🟢 Estável | Medição contínua no CI (< 64ms) com metas ULTRA (< 32ms) em FreeBSD, OpenBSD, NetBSD e +   |

---

## 🔮 Visão de Futuro & Próximas Frentes

Novas frentes e refinamentos mapeados para futuras iterações do ecossistema:

### 🐚 Shells & Desempenho

### 🧪 Testes & Integração Contínua

### 🌐 Conectividade & Ferramentas

---

> [!TIP]
> Para detalhes sobre convenções de código e diretrizes de engenharia, consulte o [PRINCIPLES.md](PRINCIPLES.md).
