# 📜 Princípios de Engenharia & Filosofia do Universal Shell

> _"Rule of Separation: Separate policy from mechanism; separate engine from interface."_<br>
> — Eric S. Raymond, _The Art of UNIX Programming_ (2003)

O **Shell** é o motor interativo de terminal do **Quarteto de Produtividade** (`Setup`, `Shell`, `Vault`, `Profile`), orquestrado pelo ecossistema **[Environment](https://github.com/GabrielFrigo4/environment)**. Ele é responsável por fornecer uma experiência de linha de comando ultra-rápida (latência de boot < 50ms), modular, resiliente e consistente em qualquer contexto: Desktop, Servidor, Contêiner ou WSL.

> [!IMPORTANT]
> **A Regra de Ouro do Agente de IA:** Ao entrar em qualquer diretório de repositório, o agente DEVE SEMPRE ler os arquivos `AGENTS.md`, `PRINCIPLES.md` e `.agents/` daquele repositório antes de realizar qualquer alteração.

---

## 🏛️ Os 18 Princípios de Design (17 Princípios UNIX + Soberania do Usuário)

### 1. Regra da Modularidade (_Rule of Modularity_)

> _Escreva partes simples conectadas por interfaces limpas._

- A arquitetura do Shell é estritamente decomposta em camadas ortogonais:
    - `library/`: Funções puras e utilitários compartilhados em POSIX shell.
    - `core/`: Orquestração de inicialização, cache e variáveis globais.
    - `target/`: Especializações declarativas por sistema operacional (`linux/`, `freebsd/`, `windows/`, `macos/`).
    - `context/`: Especializações por ambiente operacional (`desktop/`, `server/`, `container/`, `wsl/`).
    - `theme/`: Renderização de prompts ultra-rápidos para cada shell (`sh`, `bash`, `zsh`).

### 2. Regra da Clareza (_Rule of Clarity_)

> _Clareza é melhor que esperteza._

- Funções priorizam legibilidade absoluta. Nomes em `kebab-case` público (`update-all`, `clean-cache`, `open-helix`) e `_snake_case` privado (`_detect_os`, `_as_root`).

### 3. Regra da Composição (_Rule of Composition_)

> _Projete programas para serem conectados a outros programas._

- Utilitários do Shell leem de `stdin` e escrevem em `stdout`. Toda saída não-interativa é livre de códigos de cor ou sequências ANSI quando canalizada em pipes.

### 4. Regra da Separação (_Rule of Separation_)

> _Separe a política do mecanismo; separe o motor da interface._

- O **Shell** é o motor interativo de execução em tempo real. Ele não instala pacotes (responsabilidade do **Setup**), não armazena senhas (responsabilidade do **Vault**) e não impõe arquivos estáticos de aplicativos (responsabilidade do **Profile**).

### 5. Regra da Simplicidade (_Rule of Simplicity_)

> _Projete para a simplicidade; adicione complexidade apenas onde estritamente necessário._

- Latência de inicialização agressiva (< 50ms). Evitamos frameworks pesados e plugins desnecessários.

### 6. Regra da Parcimônia (_Rule of Parsimony_)

> _Escreva um programa grande apenas quando estiver claro por demonstração que nada mais resolverá._

- Aliases e funções só são definidos se representarem ganhos reais de ergonomia ou segurança. Se um comando nativo é suficiente, ele é utilizado sem invólucros.

### 7. Regra da Transparência (_Rule of Transparency_)

> _Projete para a visibilidade para tornar inspeção e depuração fáceis._

- Estrutura de diretórios legível e autoexplicativa. Comandos de benchmark (`make bench`) e diagnóstico integrados.

### 8. Regra da Robustez (_Rule of Robustness_)

> _A robustez é filha da transparência e da simplicidade._

- **Baseline FreeBSD `/bin/sh`:** Todo script compartilhado é validado contra o interpretador padrão do FreeBSD.
- **Programação Defensiva:** NUNCA definir aliases ou funções de ferramentas externas sem verificar a presença do binário via `command -v <cmd> > "/dev/null" 2>&1`.

### 9. Regra da Representação (_Rule of Representation_)

> _Dobre o conhecimento em dados para que a lógica do programa possa ser estúpida e robusta._

- Mapeamentos de temas, contextos e plataformas estruturados em tabelas e listas declarativas.

### 10. Regra do Menor Espanto (_Rule of Least Surprise_)

> _No design de interfaces, sempre faça a coisa menos surpreendente._

- Respeito aos padrões FHS e convenções canônicas de terminal Unix. Códigos de saída universais (`0` para sucesso, diferente de zero para falhas).

### 11. Regra do Silêncio (_Rule of Silence_)

> _Quando um programa não tem nada surpreendente a dizer, ele não deve dizer nada._

- A inicialização do shell em novas sessões de terminal é completamente silenciosa. Mensagens apenas em erros reais em `stderr`.

### 12. Regra do Reparo (_Rule of Repair_)

> _Quando você precisar falhar, falhe ruidosamente e o mais rápido possível._

- Funções abortam imediatamente com retorno de erro caso dependências críticas falhem, emitindo diagnósticos claros.

### 13. Regra da Economia (_Rule of Economy_)

> _O tempo do programador é caro; economize-o em preferência ao tempo da máquina._

- Aliases universais e cascatas de editores inteligentes economizam segundos a cada interação no terminal.

### 14. Regra da Geração (_Rule of Generation_)

> _Evite codificação manual; escreva programas para escrever programas quando puder._

- Automações para medição de latência, sincronização e auditoria em `scripts/`.

### 15. Regra da Otimização (_Rule of Optimization_)

> _Prototipe antes de polir. Faça funcionar antes de otimizar._

- Primeiro assegurar conformidade POSIX; depois medir e polir para manter o tempo de boot rigorosamente abaixo de 50ms.

### 16. Regra da Diversidade (_Rule of Diversity_)

> _Desconfie de todas as afirmações de "uma única maneira verdadeira"._

- Suporte nativo e intencional a:
    - **Sistemas:** FreeBSD, Linux (Fedora, Debian, Arch), macOS e Windows (MSYS2).
    - **Shells:** FreeBSD `/bin/sh`, Zsh e Bash.

### 17. Regra da Extensibilidade (_Rule of Extensibility_)

> _Projete para o futuro, porque ele chegará antes do que você imagina._

- Novos contextos ou sistemas operacionais são adicionados como novos módulos em `target/` ou `context/` sem alterar os núcleos compartilhados.

### 18. Regra da Soberania do Usuário (_Rule of User Sovereignty_)

> _Honre a escolha explícita e deliberada do usuário antes de impor padrões genéricos._

- Respeito absoluto ao shell padrão escolhido pelo usuário.
- Preferência explícita pelo `doas` sobre o `sudo` quando disponível (`doas > sudo`).

---

## 🧼 Princípios de Clean Code para o Shell

1. **Shebang Universal:** `#!/usr/bin/env sh` no topo de scripts executáveis.
2. **Quoting Defensivo & Variáveis:**
    - Sempre utilize `${var}` e `"${var}"` com chaves.
    - Redirecionamentos protegidos: `> "/dev/null"` e `2> "/dev/null"`.
3. **Taxonomia de Emissão:**
    - `echo "${msg}"`: Texto simples e escrita atômica em arquivos.
    - `echo -n $'\e...'`: Padrão canônico para sequências ANSI interativas com proteção `[ -t 1 ]`.
    - `printf`: Exclusivo para relatórios tabulares, colunas formatadas e padding (`%-16s %s\n`).
4. **Delimitadores de Largura Zero em Prompts:** Códigos ANSI em `PS1` DEVEM usar `\[...\]` para evitar quebra de cursor.
5. **Permissões Canônicas:** 4 dígitos octais (`chmod 0755` para executáveis, `chmod 0644` para módulos e configs).
6. **Arquitetura de Comentários (A Tríade Sem Vazamento):**
    - **Camada 1 (Header Banner):** Linhas 2-4 com exatamente 64 hífens (`# ----------------------------------------------------------------`).
    - **Camada 2 (Seções Estruturais):** Réguas de 32 caracteres (`### ================================` e `### --------------------------------`). Título $\le$ 32 caracteres.
    - **Camada 3 (Zero Comentários Narrativos):** Código autoexplicativo, blocos separados por linhas em branco.
