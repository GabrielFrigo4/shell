# 🗺️ Roadmap & Backlog

> Planejamento estratégico, status operacional e visão de futuro para a evolução do **Universal Shell**.

---

## 📊 Status do Projeto

| Área                         |   Status   | Cobertura                                                                                |
| :--------------------------- | :--------: | :--------------------------------------------------------------------------------------- |
| **🖥️ Plataformas Base**      | 🟢 Estável | Linux, FreeBSD, Windows (MSYS2), macOS (base)                                            |
| **🐚 Shells Nativos**        | 🟢 Estável | Zsh, Bash, POSIX sh (Linux & FreeBSD) com detecção e paridade universal                  |
| **🎯 Contextos**             | 🟢 Estável | Desktop, Server, Container, WSL com carregamento modular sob demanda                     |
| **🎨 Temas Puros & TTY**     | 🟢 Estável | Motores em `theme/` dedicados à renderização visual e adaptação dinâmica PTY / Raw TTY   |
| **⚙️ Shell Configs Comuns**  | 🟢 Estável | Centralização em `target/common/` (`zsh.sh`, `bash.sh`, `sh.sh`) para histórico e opções |
| **🛡️ Segurança & Proteção**  | 🟢 Estável | Rigor `noclobber` padronizado (`set -o noclobber`, `setopt NO_CLOBBER`, `set -C`)        |
| **⚡ Motor de Cache & Boot** | 🟢 Estável | Cache consolidado (`cache.env` + `tmpfs`) com boot < 22ms (Bash) e < 35ms (Zsh)          |

| **📦 Instalador Multi-Shell** | 🟢 Estável | Detecção automática em lote de shells e templates standalone puros (`SHELL_FRAMEWORK=0`) |
| **⚡ Modern CLI** | 🟢 Estável | Cascata inteligente (`eza`, `bat`, `rg`, `fd` > nativos) |
| **🌳 VCS & Prompts** | 🟢 Estável | Git e Got (Game of Trees) com status de modificação em tempo real |
| **💎 Clean Code & Princípios** | 🟢 100% | 18 Princípios UNIX, comentários simétricos de 36 colunas e Zero Warnings |
| **🧪 Automação & CI/CD** | 🟢 Estável | Git Hooks locais (`.githooks/pre-commit`) + GitHub Actions multi-OS |

---

## 🔮 Visão de Futuro & Próximas Frentes

Novas frentes e refinamentos mapeados para futuras iterações do ecossistema:

### 🧪 Testes & Integração Contínua

- [ ] **Matriz Expandida de CI:** Execução automatizada de testes de paridade no GitHub Actions rodando runners nativos de Linux, FreeBSD (via VM/Jail Action) e macOS.
- [ ] **Métricas Contínuas de Latência:** Adicionar asserções estritas de tempo de boot (< 35ms) em rotinas de CI em pull requests.

### 🌐 Conectividade & Ferramentas

- [ ] **Expansão de Contexto Cloud/Remoto:** Avaliar perfil dedicado para conexões remotas em SSH com largura de banda restrita (detecção via `SSH_CLIENT` / `SSH_TTY`).
- [ ] **Aliases Avançados para Ferramentas Modernas:** Integração opcional com ferramentas Rust adicionais (`dust`, `procs`, `bottom`/`btm`) mantendo o Princípio da Cascata de Fallback.

---

> [!TIP]
> Para detalhes sobre convenções de código e diretrizes de engenharia, consulte o [PRINCIPLES.md](PRINCIPLES.md).
