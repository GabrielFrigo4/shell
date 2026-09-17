# 🐚 Universal Shell — AI Agent Briefing

> Configurações, aliases e prompts centralizados para todos os ambientes de sistema, mantendo a experiência consistente seja no Desktop, Servidor, Contêiner ou WSL. Componente de runtime interativo do **Quarteto de Produtividade**.

---

## 🧭 Identidade e Papel

O **Shell** é o **motor interativo de terminal** do ecossistema. Fornece prompts ultra-rápidos (< 64ms, ULTRA < 32ms), aliases universais, funções POSIX e cascatas de ferramentas. Suporta:

- **Shells:** Zsh, Bash, ksh (OpenBSD) e POSIX `sh` (FreeBSD `/bin/sh` como baseline exclusivo de sh)
- **Contextos:** `desktop`, `server`, `container` (com extensões WSL automáticas)
- **Plataformas:** Linux, FreeBSD, OpenBSD, NetBSD, illumos, macOS, Windows (MSYS2)

---

## ⚠️ Regras Críticas para Agentes de IA

1. **Baseline FreeBSD `/bin/sh`:** Scripts compartilhados DEVEM ser compatíveis com o `/bin/sh` do FreeBSD.
2. **Programação defensiva (`command -v`):** Nunca defina aliases sem verificar se o binário existe.
3. **Nomenclatura:** `kebab-case` público, `_snake_case` privado, `SNAKE_CASE` constantes.
4. **Proteção de terminal:** `[ -t 1 ]` antes de sequências ANSI em pipes.
5. **Zero comentários narrativos:** Blocos lógicos separados por linhas em branco.
6. **Prompts com `\[...\]`:** Códigos ANSI em `PS1` DEVEM estar entre delimitadores de largura zero.
7. **Hermetismo de Produção & Invariante `rm -rf .agents`:** Repositório 100% autônomo. Zero acoplamento de código de produção, carregadores ou aliases a `.agents/` ou `skills/` (o Shell funciona plenamente se `.agents/` for deletado).
8. **Bancada de Desenvolvimento vs. Runtimes de Produção:** Em produção, o Universal Shell reside e opera soberanamente em `/usr/local/share/shell` (ou `~/.local/share/shell` rootless). NUNCA configure o sistema operacional ou crie symlinks que apontem para o clone de desenvolvimento (`~/Documents/Environment/Shell`). O provisionamento oficial é realizado via `install.sh` do próprio Shell ou via `make install` no Environment.

---

## 🛡️ Regra da Proatividade e Correção Contínua (Boy Scout Rule)

O agente de IA **DEVE SER ATIVAMENTE PROATIVO** na manutenção e aplicação dos padrões canônicos deste repositório.

Se durante a execução de qualquer tarefa (seja criação de novas features, correções pontuais, refatorações ou investigação) o agente identificar qualquer linha de código, script, Makefile ou documentação fora dos padrões estabelecidos, **NÃO DEVE HESITAR NEM IGNORAR**:

1. **Notificar concisamente** o usuário sobre a divergência encontrada.
2. **Corrigir imediatamente a inconformidade**, aplicando o padrão canônico correspondente:
    - **Comentários Narrativos:** Eliminar imediatamente comentários óbvios que apenas narram código executável.
    - **Banners Estruturais:** Ajustar réguas para exatamente 64 hífens no topo ou 32 caracteres com `### ` no corpo.
    - **Portabilidade POSIX:** Substituir bashismos (`[[ ]]`, `&>`, arrays, `source`) por sintaxe estrita POSIX `/bin/sh`.
    - **Shebang Universal:** Garantir sempre `#!/usr/bin/env sh` ou `#!/usr/bin/env python3`.
    - **Sequências ANSI:** Substituir octais crípticos (` `) e `printf` desnecessário por `[ -t 1 ] && echo -n $'\e...'`.
    - **Redirecionamento Seguro:** Envolver destinos em aspas duplas (ex: `> "/dev/null" 2>&1`).
    - **Makefiles:** Assegurar cabeçalho `.POSIX: .SILENT:`, `MAKEFLAGS += --no-print-directory -s`, alinhamento estético de variáveis e zero `@` redundante.
    - **Permissões Canônicas:** Aplicar 4 dígitos octais (`chmod 0755`, `chmod 0644`, `chmod 0700`, `chmod 0600`).

## 📖 Referências Obrigatórias

Antes de qualquer modificação neste ecossistema, consulte:

- **[ENVIRONMENT.md](ENVIRONMENT.md)**: Arquitetura do Quarteto de Produtividade
- **[PRINCIPLES.md](PRINCIPLES.md)**: Os 21 Princípios de Engenharia UNIX + Clean Code
- **[.agents/rules/principles.md](.agents/rules/principles.md)**: Regras específicas do Shell
- **[.agents/skills/](.agents/skills/)**: Runbooks operacionais (`universal-shell`, `posix-shell`, `proactive-guardian`, `deep-investigation`) e runbooks por SO (`freebsd-shell`, `linux-shell`, `macos-shell`, `windows-shell`, `openbsd-shell`, `netbsd-shell`, `illumos-shell`)
