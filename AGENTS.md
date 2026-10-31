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
3. **Nomenclatura Expressiva & Zero Abreviações Crípticas:** `kebab-case` público, `_snake_case` privado, `SNAKE_CASE` constantes. Nomes de variáveis DEVEM ser autoexplicativos (proibido `_c` para color, `_u` para user, `_ind`, `_sym`, `_del`, `_ed`, `_f`, etc.; permitido designações técnicas formais como linguagem C e acrônimos universais IP, OS, PID).
4. **Proteção de terminal:** `[ -t 1 ]` antes de sequências ANSI em pipes.
5. **Taxonomia Tripartite de Comentários:** O código adota estritamente três categorias: 1. Comentários de Sistema = PERMITIDOS (shebangs, pragmas); 2. Comentários Estruturais de 64/32 colunas = PERMITIDOS (cabeçalhos de 64 `-`, seções de 32 colunas `### ===` e `### ---` com títulos em MAIÚSCULO, réguas de 64 `=` em `.gitignore` com títulos em MAIÚSCULO, sem vazamento); 3. Comentários Explicativos/Narrativos = PROIBIDOS em código, configs E blocos de código dentro de Markdowns.
6. **Prompts com `\[...\]`:** Códigos ANSI em `PS1` DEVEM estar entre delimitadores de largura zero.
7. **Hermetismo de Produção & Invariante `rm -rf .agents`:** Repositório 100% autônomo. Zero acoplamento de código de produção, carregadores ou aliases a `.agents/` ou `skills/` (o Shell funciona plenamente se `.agents/` for deletado).
8. **Bancada de Desenvolvimento vs. Runtimes de Produção & Pipeline de Propagação:** Em produção, o Universal Shell reside e opera soberanamente em `/usr/local/share/shell` (ou `~/.local/share/shell` rootless). NUNCA configure o sistema operacional ou crie symlinks que apontem para o clone de desenvolvimento (`~/Documents/Environment/Shell`). Toda modificação DEVE ser implementada na bancada, validada via testes locais (`make test`, `make ci`), comitada e enviada via `git push`. A sincronização no clone de produção ocorre exclusivamente via `git pull` ou comando `upsh`.
9. **Ciclo Canônico de Propagação & Banimento de Cópia Manual:** Evite copiar arquivos avulsos (`cp`, `rsync`) para `/usr/local/share/shell`, mesmo em testes rápidos ou diagnósticos. A working tree de produção DEVE permanecer 100% limpa a todo momento (Invariante Zero-Dirty).
10. **Emissão Semântica de UI (`_ui_*`):** Toda saída interativa de status, rotinas de rede, instaladores e funções utilitárias DEVE utilizar a biblioteca semântica `_ui_*` (`_ui_step`, `_ui_sub`, `_ui_ok`, `_ui_warn`, `_ui_err`, `_ui_info`, `_ui_banner`), sendo proibido `echo` ad-hoc com emojis soltos.
11. **Invariante de Clonagem "Out-of-the-Box" (Zero-Tweaks Git Invariant):** O Shell deve funcionar imediatamente após um simples `git clone`. Modos octais no Git Index DEVEM ser rigorosamente `0755` para executáveis/scripts/hooks e `0644` para configurações e documentação.
12. **Governança de Roadmap (TODO.md):** O repositório mantém seu [TODO.md](TODO.md) atualizado com a Matriz de Status e Backlog de Frentes, sincronizado com o badge no `README.md`.
13. **Refatoração Sem Legado / Soberania Monousuário (Clean-Break / Zero-Cruft Invariant):** O ecossistema é estritamente pessoal, governado e operado por um único desenvolvedor soberano (Gabriel Frigo). Evite manter resíduos de retrocompatibilidade, shims temporários, wrappers obsoletos, seções de compatibilidade legada ou aliases de transição ao renomear variáveis, comandos, funções, diretórios ou arquivos, salvo se expressamente ordenado pelo usuário. Toda refatoração deve ser atômica, direta, definitiva e limpa (_clean break_), expurgando o identificador antigo integralmente da base de código.
14. **Ambiente Híbrido Host/Guest (FreeBSD Workstation + Bhyve Linux Runtime):** Em estações FreeBSD, o agente de IA (`agy`) opera isolado dentro de uma máquina virtual Debian no Bhyve (`192.168.8.2`), conectada via NFSv3 à `/home/gabrielf` do host com paridade de UID/GID 1001. O agente executa comandos em ambiente Linux nativo (kernel 6.12/GNU), porém seus arquivos de trabalho residem fisicamente no ZFS do FreeBSD. Ao despachar comandos no terminal, utilize ferramentas Linux disponíveis no guest ou faça a demarcação correta ao editar scripts específicos de cada sistema operacional.
15. **Simetria de Escopo & Não-Assimetria de Subgrupo na Documentação:** Se um comportamento, protocolo ou invariante pertence a todo um grupo de componentes, documente-o no nível do grupo (documento de arquitetura, README do módulo pai ou especificação geral), evitando a criação de falsas assimetrias. Um sub-membro só deve receber documentação específica se implementar o comportamento de forma mais especializada, detalhada ou otimizada.

---

## 🛡️ Regra da Proatividade e Correção Contínua (Boy Scout Rule)

O agente de IA atua de forma proativa na manutenção e aplicação dos padrões canônicos deste repositório.

Ao identificar linhas ou artefatos fora dos padrões estabelecidos:

1. **Notificar concisamente** o usuário sobre o ajuste realizado.
2. **Corrigir a inconformidade**, aplicando o padrão correspondente:
    - **Taxonomia Tripartite de Comentários:** Eliminar comentários explicativos óbvios em código, configs e blocos de código em Markdowns, preservando exclusivamente comentários de sistema e delimitadores estruturais (64/32 colunas).
    - **Banners Estruturais:** Ajustar réguas para exatamente 64 hífens no topo ou 32 caracteres com `### ` no corpo (ou 64 `=` em `.gitignore`), com títulos sempre em MAIÚSCULO.
    - **Portabilidade POSIX:** Substituir bashismos (`[[ ]]`, `&>`, arrays, `source`) por sintaxe estrita POSIX `/bin/sh`.
    - **Shebang Universal:** Garantir sempre `#!/usr/bin/env sh` ou `#!/usr/bin/env python3`.
    - **Sequências ANSI & Escapes:** Não use octais (`\033`, `\001`) para caracteres ou escapes. Use `[ -t 1 ] && echo -n $'\e...'` ou notação hexadecimal (`\x01`, `\x1b`). Octal é exclusivo para permissões POSIX (`chmod 0755`, `chmod 0644`, `umask`).
    - **Redirecionamento Seguro:** Envolver destinos em aspas duplas (ex: `> "/dev/null" 2>&1`).
    - **Makefiles:** Assegurar cabeçalho `.POSIX: .SILENT:`, `MAKEFLAGS += --no-print-directory -s`, alinhamento estético de variáveis e zero `@` redundante.
    - **Permissões Canônicas:** Aplicar 4 dígitos octais (`chmod 0755`, `chmod 0644`, `chmod 0700`, `chmod 0600`).
    - **Invariante Out-of-the-Box:** Garantir modos octais corretos no Git Index e auto-cura em tempo de execução sem requerer intervenção manual pós-clone.
    - **Emissão Semântica de UI:** Substituir `echo` avulsos com emojis pelas rotinas canônicas `_ui_*`.
    - **Antifragilidade & Resiliência:** Resolução ativa de caminhos em cascata, auto-cura de permissões (0600 em chaves/segredos) e validação defensiva de pré-requisitos.
    - **Curadoria Cognitiva:** Capturar decisões estruturais e regras tácitas em skills locais compactas (`.agents/skills/`), mantendo-as atualizadas e expurgando ruído obsoleto.
    - **Refatoração Sem Legado:** Expurgar aliases obsoletos, variáveis mortas e shims de compatibilidade em renomeações.
    - **Elevação Antifrágil & Shift Seguro:** Usar o bloco explícito `if [ "$(id -u)" -ne 0 ]` para resolução de `ELEVATE` (evitando término fatal sob `set -e` como root) e proteger todo comando `shift` com validação prévia de parâmetros (`[ "$#" -ge N ] && shift N`).
    - **Simetria de Documentação:** Mover regras ou invariantes universais documentadas erroneamente em sub-membros específicos para o documento de arquitetura do grupo correspondente, eliminando falsas assimetrias.

---

## 🚀 Comandos de Verificação Rápida (Quality Gates)

| Comando         | Finalidade Operacional                                                     |
| :-------------- | :------------------------------------------------------------------------- |
| `make help`     | Exibe o catálogo interativo de comandos disponíveis                        |
| `make test`     | Executa bateria de testes de portabilidade e prompts nos shells suportados |
| `make bench`    | Mede o tempo de boot e latência de renderização do prompt (< 64ms)         |
| `make format`   | Formata código-fonte e documentações com Prettier                          |
| `make prettier` | Formata arquivos Markdown com Prettier                                     |
| `make install`  | Instala o Shell no runtime de produção (`/usr/local/share/shell`)          |
| `make hooks`    | Configura e ativa os ganchos Git em `.githooks/`                           |
| `make ci`       | Executa suite completa de integração contínua (`test`)                     |

---

## 📖 Referências Obrigatórias

Antes de qualquer modificação neste ecossistema, consulte:

- **[ENVIRONMENT.md](ENVIRONMENT.md)**: Arquitetura do Quarteto de Produtividade
- **[PRINCIPLES.md](PRINCIPLES.md)**: Os 22 Princípios de Engenharia UNIX + Clean Code
- **[TODO.md](TODO.md)**: Planejamento estratégico e matriz de status operacional
- **[.agents/rules/principles.md](.agents/rules/principles.md)**: Regras específicas do Shell
- **[.agents/skills/](.agents/skills/)**: Runbook operacional do Shell
