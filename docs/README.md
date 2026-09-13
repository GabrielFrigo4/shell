# 📚 Documentação Técnica — Universal Shell Environment

Bem-vindo ao índice da documentação técnica e arquitetural do **Universal Shell Environment**, o componente de runtime interativo do [Quarteto de Produtividade](https://github.com/GabrielFrigo4/setup).

---

## 🧭 Guias e Referências Arquiteturais

| Documento                              | Descrição                                                                                                                                                         |
| :------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Ciclo de boot da sessão, cascata de sourcing (`library/` ➔ `core/` ➔ `target/` ➔ `theme/`), princípios de latência mínima (&lt;50ms) e regra do silêncio.         |
| **[CONTEXTS.md](CONTEXTS.md)**         | Especificação dos 3 contextos de ambiente (`desktop`, `server`, `container` — com auto-detecção WSL), variáveis exportadas e otimizações por carga de trabalho.   |
| **[DETECTION.md](DETECTION.md)**       | Mecânica dos motores de inteligência de `library/detect.sh` (SO, distros Linux, desktop environments, esquemas de cor via D-Bus/XDG Portal, TrueColor e Wayland). |
| **[THEMES.md](THEMES.md)**             | Contrato visual dos prompts (Zsh, Bash, POSIX sh), paleta de cores ANSI, suporte a Nerd Fonts, integração Git/Got e fallback 1:1 em TTY bruto.                    |
| **[ALIASES.md](ALIASES.md)**           | Dicionário exaustivo de comandos públicos (`kebab-case`), atalhos de navegação, cascata de editores, atualizadores de pacotes e variáveis globais.                |

---

## 🏛️ Invariantes do Ecossistema

Para entender a governança compartilhada entre os 4 repositórios, consulte:

- **[ENVIRONMENT.md](../ENVIRONMENT.md)**: Manifesto de papéis, privilégios, ciclo de boot e links federados.
- **[PRINCIPLES.md](../PRINCIPLES.md)**: Os 18 princípios de engenharia de software e diretrizes Clean Code aplicados ao shell.
