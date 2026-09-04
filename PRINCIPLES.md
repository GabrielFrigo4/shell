# 📜 Princípios de Engenharia & Filosofia do Repositório (Shell)

> _"Rule of Silence: When a program has nothing surprising to say, it should say nothing."_<br>
> — Eric S. Raymond, _The Art of UNIX Programming_ (2003)

O repositório **Universal Shell Environment** é o coração interativo da **Tríade de Produtividade** (`Configuration`, `Shell`, `Vault`). Ele é responsável por prover uma experiência consistente, ágil e prazerosa na linha de comando, independentemente de estarmos em uma máquina Desktop, Servidor, Container Docker/Jail ou WSL, rodando sobre FreeBSD, Linux ou Windows.

Para garantir que o terminal permaneça instantâneo, extensível e agradável no dia a dia, todas as contribuições devem seguir com fidelidade os **18 Princípios de Engenharia** (17 Princípios UNIX de Eric S. Raymond + Regra da Soberania do Usuário), as diretrizes de **Clean Code** adaptadas ao ecossistema de shells, e os padrões de performance interativa.

---

## 🏛️ Os 18 Princípios de Design (17 Princípios UNIX + Soberania do Usuário)

### 1. Regra da Modularidade (_Rule of Modularity_)

> _Escreva partes simples conectadas por interfaces limpas._

- O Shell é rigidamente dividido em:
  - `core/`: O ciclo de vida base e carregamento do ambiente.
  - `context/`: Especializações de acordo com a máquina (`desktop`, `server`, `container`, `wsl`).
  - `target/`: Especializações de acordo com o sistema operacional (`linux`, `freebsd`, `windows`).
  - `library/`: Funções utilitárias reutilizáveis.
  - `theme/`: Renderização visual de prompts (Bash, Zsh, Sh).

### 2. Regra da Clareza (_Rule of Clarity_)

> _Clareza é melhor que esperteza._

- Aliases e funções devem ter intenção transparente. Um alias complexo de 5 linhas deve virar uma função documentada dentro de `library/functions.sh`.
- Nomes de funções devem ser intuitivos e descritivos em `kebab-case` (`update-wifi` para sincronizar Wi-Fi, `update-all` para atualização global), com aliases curtos correspondentes para máxima velocidade interativa (`upwf`, `upall`, `u`).

### 3. Regra da Composição (_Rule of Composition_)

> _Projete programas para serem conectados a outros programas._

- Toda função utilitária criada neste repositório deve respeitar o fluxo de pipes do Unix (`|`). As saídas de dados devem ir para `stdout` limpas de caracteres ANSI de cor quando não estiverem conectadas a um terminal interativo (`[ -t 1 ]`).

### 4. Regra da Separação (_Rule of Separation_)

> _Separe a política do mecanismo; separe o motor da interface._

- O mecanismo de detecção do ambiente (`library/detect.sh`) é completamente separado da política de atalhos e variáveis de ambiente aplicadas (`context/`). O tema visual (`theme/`) apenas lê dados e renderiza, sem executar lógica de negócio pesada.

### 5. Regra da Simplicidade (_Rule of Simplicity_)

> _Projete para a simplicidade; adicione complexidade apenas onde estritamente necessário._

- Evitamos intencionalmente frameworks monolíticos e lentos (como Oh-My-Zsh padrão com 50 plugins ativados). O Universal Shell provê uma base enxuta, leve e rápida feita à mão, que inicializa em milissegundos.

### 6. Regra da Parcimônia (_Rule of Parsimony_)

> _Escreva um programa grande apenas quando estiver claro por demonstração que nada mais resolverá._

- Só adicionamos aliases ou funções que realmente usamos no dia a dia. Evite "acumular" coleções de centenas de comandos que nunca serão digitados.

### 7. Regra da Transparência (_Rule of Transparency_)

> _Projete para a visibilidade para tornar inspeção e depuração fáceis._

- Qualquer função ou alias pode ser inspecionada na hora pelo próprio terminal (`type comando` ou `which comando`).
- As variáveis globais exportadas são prefixadas ou padronizadas para evitar conflitos silenciosos.

### 8. Regra da Robustez (_Rule of Robustness_)

> _A robustez é filha da transparência e da simplicidade._

- Tratamento defensivo: antes de criar um alias para um utilitário externo (ex: `bat`, `eza`, `fzf`), o shell verifica se o binário realmente existe no sistema (`command -v`), evitando erros de comando inexistente.
- **Degradação Graciosa:** Se o `Vault` não estiver instalado ou montado na máquina, o Shell funciona perfeitamente em modo anônimo, sem travar nem exibir mensagens de erro assustadoras.

### 9. Regra da Representação (_Rule of Representation_)

> _Dobre o conhecimento em dados para que a lógica do programa possa ser estúpida e robusta._

- Configurações de PATH, variáveis e atalhos são declaradas em listas diretas, evitando bifurcações excessivas de `if/else`.

### 10. Regra do Menor Espanto (_Rule of Least Surprise_)

> _No design de interfaces, sempre faça a coisa menos surpreendente._

- O shell não deve alterar o comportamento esperado de comandos fundamentais do Unix (como `rm`, `mv`, `cp`) de maneiras perigosas ou bizarras. Flags padrão de CLI e atalhos canônicos do Readline/Zshline (`Ctrl+A`, `Ctrl+E`, `Ctrl+R`) devem funcionar consistentemente.

### 11. Regra do Silêncio (_Rule of Silence_)

> _Quando um programa não tem nada surpreendente a dizer, ele não deve dizer nada._

- **Princípio Sagrado da Inicialização:** Ao abrir uma nova aba de terminal ou conexão SSH, o Shell **não deve imprimir texto, mensagens de boas-vindas barulhentas, nem banners lentos**. O prompt deve aparecer instantaneamente e em silêncio absoluto.

### 12. Regra do Reparo (_Rule of Repair_)

> _Quando você precisar falhar, falhe ruidosamente e o mais rápido possível._

- Se uma função da `library/` receber parâmetros inválidos, ela emite uma mensagem clara no `stderr` e retorna código de saída diferente de 0 imediatamente.

### 13. Regra da Economia (_Rule of Economy_)

> _O tempo do programador é caro; economize-o em preferência ao tempo da máquina._

- O objetivo central do Universal Shell é economizar micro-segundos mentais e toques de digitação do desenvolvedor todos os dias, com prompts inteligentes que exibem branch git, status de erro e ambiente de forma rápida.

### 14. Regra da Geração (_Rule of Generation_)

> _Evite codificação manual; escreva programas para escrever programas quando puder._

- Automação do instalador (`install.sh`) para linkar e configurar automaticamente `.bashrc`, `.zshrc` e `.profile` para o usuário de forma automática.

### 15. Regra da Otimização (_Rule of Optimization_)

> _Prototipe antes de polir. Faça funcionar antes de otimizar._

- No entanto, para o shell interativo, a **latência de inicialização é um requisito funcional**: meça o tempo de startup (ex: `time zsh -i -c exit`) e mantenha-o preferencialmente **abaixo de 50 milissegundos**.

### 16. Regra da Diversidade (_Rule of Diversity_)

> _Desconfie de todas as afirmações de "uma única maneira verdadeira"._

- Compatibilidade universal com múltiplos shells:
  - **Zsh:** Shell primário interativo moderno com autocompletion avançado.
  - **Bash:** Shell padrão universal presente na maioria das distribuições Linux e servidores.
  - **Sh:** Shell POSIX leve e fundamental (FreeBSD `/bin/sh`, Debian `dash`), essencial para inicialização rápida e sistemas embarcados.

### 17. Regra da Extensibilidade (_Rule of Extensibility_)

> _Projete para o futuro, porque ele chegará antes do que você imagina._

- Facilidade de adicionar um novo contexto (ex: `cloud`, `ci`) ou um novo target de SO sem precisar alterar a base do `core/environment.sh`.

### 18. Regra da Soberania do Usuário (_Rule of User Sovereignty_)

> _Honre a escolha explícita e deliberada do usuário antes de impor padrões genéricos._

- **Cascata de Preferência Consciente:** Ferramentas modernas e minimalistas instaladas ativamente pelo usuário têm prioridade de execução sobre padrões legados em atalhos interativos (ex: `doas > sudo`, `paru > yay`, `nvim/hx/micro > nano`, `eza > exa > ls`, `rg > grep`, `bat > cat`, `fd > find`), com detecção inteligente de consoles TTY brutos para evitar poluição visual de ícones.
- **Não-Invasividade:** O Shell nunca sobrescreve variáveis de ambiente previamente definidas pelo usuário (`$EDITOR`, `$VISUAL`, `$PAGER`, `$FILEMANAGER`), utilizando sempre o padrão defensivo `${VAR:-default}` ou verificando se a variável já está preenchida (`[ -z "${VAR}" ]`).
- **Compatibilidade Transparente:** Quando uma ferramenta preferida substituir outra, prover mapeamentos/aliases bidirecionais para que hábitos de digitação não quebrem o fluxo diário de trabalho.

---

## 🧼 Clean Code no Shell Scripting

1. **Funções Pequenas e Focadas:**
   - Funções em scripts de shell devem ter no máximo 15-20 linhas e resolver um único problema.
2. **DRY (Don't Repeat Yourself):**
   - Não repita código de detecção de SO ou manipulação de strings em múltiplos arquivos. Use as funções centralizadas em `library/`.
3. **Escopo Limpo de Variáveis:**
   - Em funções de shell (Bash/Zsh), use sempre a palavra-chave `local` para variáveis internas temporárias, evitando poluir o escopo global da sessão interativa do usuário.
4. **Shebang Padrão Absoluto (`#!/usr/bin/env sh`):**
   - Todo script executável de shell neste repositório DEVE iniciar com `#!/usr/bin/env sh`.
   - Evita caminhos rígidos como `#!/bin/sh` ou `#!/usr/bin/bash`, garantindo portabilidade entre FreeBSD, Linux e macOS.
5. **Permissões em 4 Dígitos Octais:**
   - Use sempre a notação de 4 dígitos em comandos `chmod` (`chmod 0755` para diretórios e scripts executáveis públicos, `chmod 0644` para arquivos de configuração e bibliotecas sourced). O zero inicial deixa explícito que bits especiais (_setuid_, _setgid_, _sticky_) estão zerados.
6. **Linha de Base FreeBSD `/bin/sh` & Adoção Universal de `$'\e...'` e `echo -n`:**
   - O **FreeBSD `/bin/sh`** é a régua máxima e a linha de base canônica de portabilidade para os scripts compartilhados do projeto. Não nivelamos o projeto por restrições arcaicas ou minimalismo desnecessário.
   - **Adoção Universal de ANSI-C Quoting (`$''`) e `echo -n`:** O padrão `echo -n $'\e...'` é suportado em todos os shells do nosso ecossistema — FreeBSD `/bin/sh`, Bash, Zsh e até pelo Dash moderno (além de padronizado no POSIX Issue 8). Ele é expressamente o padrão preferido para sequências de controle de tela e atalhos interativos como `clear` (`alias clear="echo -n $'\e[2J\e[3J\e[H'"`), eliminando a necessidade de octal críptico (`\033`) em prol de máxima legibilidade e clareza Clean Code.
   - **Delimitadores de Largura Zero em Prompts (`\[...\]` e `\e`):** No FreeBSD `/bin/sh` com edição interativa (`set -o emacs`), a biblioteca `libedit` (Editline) gerencia a linha de comando. Toda sequência de escape ANSI inserida no `$PS1` DEVE ser obrigatoriamente delimitada por `\[` e `\]` (`_c_red="\[\e[1;91m\]"`). Sem esses marcadores, a `libedit` contabiliza cada byte de escape como caractere visível de largura 1, quebrando a contagem de colunas físicas e provocando sobreposição de linhas (`\r`) e cursor congelado no início do texto.
   - **Extensões de Nomenclatura no FreeBSD `/bin/sh` vs `dash`:** O parser em C do `/bin/sh` no FreeBSD suporta hífens em nomes de função (`kebab-case`). Em contraste, interpretadores como o `dash` do Debian/Ubuntu aplicam a restrição estrita da BNF POSIX IEEE 1003.1 (que aceita apenas `[a-zA-Z_][a-zA-Z0-9_]*`, falhando com `Bad function name`). A régua de compatibilidade do projeto é o ecossistema FreeBSD/Bash/Zsh, e não o `dash`.
   - Scripts que declaram `#!/usr/bin/env sh` devem manter compatibilidade com essa base do FreeBSD `sh` (sem `[[`, sem `function foo()`, sem arrays associativos de bash).
   - Recursos específicos do Zsh e Bash ficam estritamente em seus respectivos targets (`zsh/`, `bash/`).
7. **Detecção Interativa de Terminal (`[ -t 1 ]`):**
   - Toda emissão de sequências de escape ANSI (cores, posicionamento ou reset de cursor como `[ -t 1 ] && echo -n $'\e[0 q'`) deve ser estritamente condicionada ao descritor de arquivo 1 (`stdout`) conectado a um terminal interativo (`[ -t 1 ]`).
   - Evita corromper arquivos ou pipelines quando saídas forem redirecionadas para arquivos de log ou comandos externos (`cmd > file` ou `cmd | grep`).
8. **Citações Seguras (Quoting):**
   - Sempre envolva variáveis em aspas duplas: `"${VAR}"` para evitar _word splitting_ indesejado e ataques de injeção de caminho.
   - **Aspas Obrigatórias em Redirecionamentos:** SEMPRE use aspas ao redirecionar para o `/dev/null`: `> "/dev/null"` e `2> "/dev/null"` (nunca `> /dev/null` sem aspas).
9. **Elevação de Privilégios Agregada (`_as_root` & `doas > sudo`):**
   - Nunca chame `sudo` diretamente de forma rígida (_hardcoded_) em scripts ou instaladores.
   - Utilize sempre o helper `_as_root` da `library/functions.sh`, que respeita se a sessão já é `root`, prioriza `doas` (minimalismo e segurança) e faz fallback transparente para `sudo`.
10. **Respeito a Variáveis Pré-Existentes:**
    - Variáveis de preferências do usuário (como `$EDITOR`, `$VISUAL`, `$FILEMANAGER`) só devem ser atribuídas se estiverem vazias ou não-declaradas, respeitando o arquivo `.profile` e o `Vault` do desenvolvedor.
11. **Convenção Estrita de Nomenclatura & Sem Funções Gêmeas:**
    - **`kebab-case` (ou termo simples) = Funções / Comandos Públicos:** Utilitários e atalhos destinados à invocação interativa pelo usuário no terminal (ex: `path-front`, `path-back`, `path-dedup`, `mount-device`, `umount-device`, `editor`, `update-shell`, `update-all`). Definidas **diretamente como públicas**, suportadas nativamente no FreeBSD `/bin/sh`, Bash e Zsh, sem camadas artificiais de indireção.
    - **`_snake_case` (prefixo `_`) = Helpers Privados & Variáveis Locais:** Funções internas de bootstrapping/infraestrutura e variáveis temporárias de escopo local (ex: `_as_root`, `_detect_os`, `_git_branch`, `_target`, `_file`, `_pass`). Mantém o autocompletion do usuário 100% limpo e sem poluição.
    - **`KEBAB-CASE` = Funções Públicas de Valor Constante (Getters):** Funções públicas que retornam um valor fixo/imutável ou constante de sistema.
    - **`SNAKE_CASE` (Maiúsculo) = Constantes e Variáveis de Ambiente Globais:** Variáveis públicas acessíveis pelo ambiente e lidas por outros processos/linguagens (ex: `PATH`, `SHELL_REPO_DIR`, `SHELL_CONTEXT`, `EMACS_SOCKET_NAME`).
    - **`_SNAKE_CASE` (Maiúsculo com `_`) = Constantes Privadas de Módulo:** Constantes internas de infraestrutura com escopo restrito a módulos (ex: `_TRIGGERS_CACHE`, `_IGNORE_LIST_BASE`, `_IGNORE_LIST`).
    - **`snake_case` (Minúsculo sem `_`) = Variáveis Públicas:** Variáveis mutáveis públicas expostas para configuração interativa pelo usuário.
    - **Sem Gêmeos ou Wrappers Artificiais:** Não crie funções duplicadas (ex: um helper `_foo` só para criar um alias/função pública `foo` que não faz nada a mais). Ou a funcionalidade é **100% pública** (declarada uma única vez), ou é **100% privada** (com prefixo `_`).
12. **Agnosticismo de Controle de Versão (VCS Agnosticism — Git & Got):**
    - Todos os shells (**Bash**, **Zsh**, **Linux SH** e **FreeBSD SH**) e temas do repositório devem suportar de forma transparente tanto o **Git** quanto o **Got (Game of Trees)**.
    - A detecção de branch e estado _dirty_ deve ser de tempo constante ($O(1)$) e **nunca** invocar binários externos se os diretórios de controle (`.git` ou `.got`) não existirem, garantindo latência zero em diretórios normais.
13. **Taxonomia e Contratos de Funções de Biblioteca (`library/`):**
    - **Getters de Inspeção (`_detect_*`):** Funções em `library/detect.sh` que retornam uma string no `stdout` representando a entidade ou binário identificado (ex: `_detect_os`, `_detect_distro`, `_detect_color_scheme`, `_detect_eza`, `_detect_privilege_escalator`). Retornam vazio caso não encontrem.
    - **Predicados Booleanos (`_is_*` / `_has_*`):** Funções que realizam testes lógicos e retornam código de saída numérico (`return 0` para verdadeiro, `return 1` para falso) sem emitir saída no `stdout` (ex: `_is_raw_tty`, `_is_generic_editor`).
    - **Executores Operacionais (`_as_*` / `_run_*`):** Funções que realizam ações e executam comandos do sistema operacional (`"$@"`), residindo exclusivamente em `library/functions.sh` (ex: `_as_root`).
14. **Padrão Exclusivo de Comentários Estruturais & Proibição de Comentários Inline:**
    - **Código Autoexplicativo (Princípio do Silêncio):** Comentários explicativos inline ("aqui verifica x", "faz loop em y") são **expressamente proibidos**. O código deve expressar sua intenção através de nomes limpos, funções focadas e arquitetura modular.
    - **Único Formato de Comentário Permitido:** O único comentário aceito em arquivos de script e workflows de CI/CD são os **blocos delimitadores visuais estruturais** de dois níveis.
    - **Hierarquia de Dois Níveis:**
      - **Seção Principal (Módulo / Suíte / Contexto):** Três hashes seguidos de espaço e exatamente 32 sinais de igual (`=`). Título em CAIXA ALTA. Fechamento com régua idêntica à abertura:
        ```sh
        ### ================================
        ### NOME DO MODULO OU CONTEXTO
        ### ================================
        ```
      - **Subseção (Passo / Bloco Lógico):** Três hashes seguidos de espaço e exatamente 32 hífens (`-`). Título em Capital Case. Fechamento com régua idêntica à abertura:
        ```sh
        ### --------------------------------
        ### Nome da Secao
        ### --------------------------------
        ```
    - **Regra do Não-Vazamento (Boundary Rule):** A linha delimitadora possui exatamente 36 colunas (`### ` + 32 caracteres separadores). O texto do título DEVE ser conciso e **JAMAIS vazar ou ultrapassar** o comprimento da régua delimitadora (máximo de 32 caracteres no texto do título). Títulos que vazam quebram a estética simétrica e violam o padrão de qualidade do repositório.
    - **Sem Parênteses ou Anotações Redundantes:** O título do bloco deve ser conciso e sem anotações secundárias entre parênteses (ex: prefira `### Default Editor` a `### Default Editor (Cascade)` e `### Update Vault` a `### Update Vault (update-vault)`).
    - **Regra da Não-Enumeração de Títulos:** Evite numerar títulos de seções e subseções (ex: prefira `### FreeBSD /bin/sh` a `### 1. FreeBSD /bin/sh`). A enumeração deve ser evitada em geral, sendo tolerada apenas quando a numeração for um requisito estritamente intrínseco à identidade, protocolo ou dependência direta do conceito (onde a omissão do número destruiria o significado do processo). Em qualquer outro caso, use sempre títulos puramente semânticos.
    - **Padronização em Workflows de CI/CD:** Scripts embutidos no CI/CD (`.github/workflows/ci.yml`) devem seguir rigorosamente este mesmo padrão estrutural, sendo estritamente vedado o uso de separadores arbitrários ou improvisados (como `echo "=== ... ==="`).

---

## 🔒 Princípios de Integração com o Ecossistema

1. **Zero Secrets in Public Repository:**
   - Este repositório é público. Nunca adicione chaves, senhas, tokens ou dados pessoais em arquivos deste repositório.
2. **Contrato de Carregamento com o Vault:**
   - O Shell lê segredos exclusivamente via integração com `~/.vault/vault.sh`.
   - Se `~/.vault` existir, ele é integrado de forma transparente e silenciosa. Se não existir, a sessão do terminal continua 100% utilizável sem interrupções.
