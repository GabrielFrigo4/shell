# 📜 Princípios de Engenharia & Filosofia do Repositório (Shell)

> *"Rule of Silence: When a program has nothing surprising to say, it should say nothing."*  
> — Eric S. Raymond, *The Art of UNIX Programming* (2003)

O repositório **Universal Shell Environment** é o coração interativo da **Tríade de Produtividade** (`Configuration`, `Shell`, `Vault`). Ele é responsável por prover uma experiência consistente, ágil e prazerosa na linha de comando, independentemente de estarmos em uma máquina Desktop, Servidor, Container Docker/Jail ou WSL, rodando sobre FreeBSD, Linux ou Windows.

Para garantir que o terminal permaneça instantâneo, extensível e agradável no dia a dia, todas as contribuições devem seguir com fidelidade os **17 Princípios UNIX**, as diretrizes de **Clean Code** adaptadas ao ecossistema de shells, e os padrões de performance interativa.

---

## 🏛️ Os 17 Princípios UNIX (*The Art of UNIX Programming*, 2003)

### 1. Regra da Modularidade (*Rule of Modularity*)
> *Escreva partes simples conectadas por interfaces limpas.*
- O Shell é rigidamente dividido em:
  - `core/`: O ciclo de vida base e carregamento do ambiente.
  - `context/`: Especializações de acordo com a máquina (`desktop`, `server`, `container`, `wsl`).
  - `target/`: Especializações de acordo com o sistema operacional (`linux`, `freebsd`, `windows`).
  - `library/`: Funções utilitárias reutilizáveis.
  - `theme/`: Renderização visual de prompts (Bash, Zsh).

### 2. Regra da Clareza (*Rule of Clarity*)
> *Clareza é melhor que esperteza.*
- Aliases e funções devem ter intenção transparente. Um alias complexo de 5 linhas deve virar uma função documentada dentro de `library/functions.sh`.
- Nomes de funções devem ser intuitivos (`upwf` para subir Wi-Fi, `mkcd` para criar pasta e entrar).

### 3. Regra da Composição (*Rule of Composition*)
> *Projete programas para serem conectados a outros programas.*
- Toda função utilitária criada neste repositório deve respeitar o fluxo de pipes do Unix (`|`). As saídas de dados devem ir para `stdout` limpas de caracteres ANSI de cor quando não estiverem conectadas a um terminal interativo (`[ -t 1 ]`).

### 4. Regra da Separação (*Rule of Separation*)
> *Separe a política do mecanismo; separe o motor da interface.*
- O mecanismo de detecção do ambiente (`library/detect.sh`) é completamente separado da política de atalhos e variáveis de ambiente aplicadas (`context/`). O tema visual (`theme/`) apenas lê dados e renderiza, sem executar lógica de negócio pesada.

### 5. Regra da Simplicidade (*Rule of Simplicity*)
> *Projete para a simplicidade; adicione complexidade apenas onde estritamente necessário.*
- Evitamos intencionalmente frameworks monolíticos e lentos (como Oh-My-Zsh padrão com 50 plugins ativados). O Universal Shell provê uma base enxuta, leve e rápida feita à mão, que inicializa em milissegundos.

### 6. Regra da Parcimônia (*Rule of Parsimony*)
> *Escreva um programa grande apenas quando estiver claro por demonstração que nada mais resolverá.*
- Só adicionamos aliases ou funções que realmente usamos no dia a dia. Evite "acumular" coleções de centenas de comandos que nunca serão digitados.

### 7. Regra da Transparência (*Rule of Transparency*)
> *Projete para a visibilidade para tornar inspeção e depuração fáceis.*
- Qualquer função ou alias pode ser inspecionada na hora pelo próprio terminal (`type comando` ou `which comando`).
- As variáveis globais exportadas são prefixadas ou padronizadas para evitar conflitos silenciosos.

### 8. Regra da Robustez (*Rule of Robustness*)
> *A robustez é filha da transparência e da simplicidade.*
- Tratamento defensivo: antes de criar um alias para um utilitário externo (ex: `bat`, `eza`, `fzf`), o shell verifica se o binário realmente existe no sistema (`command -v`), evitando erros de comando inexistente.
- **Degradação Graciosa:** Se o `Vault` não estiver instalado ou montado na máquina, o Shell funciona perfeitamente em modo anônimo, sem travar nem exibir mensagens de erro assustadoras.

### 9. Regra da Representação (*Rule of Representation*)
> *Dobre o conhecimento em dados para que a lógica do programa possa ser estúpida e robusta.*
- Configurações de PATH, variáveis e atalhos são declaradas em listas diretas, evitando bifurcações excessivas de `if/else`.

### 10. Regra do Menor Espanto (*Rule of Least Surprise*)
> *No design de interfaces, sempre faça a coisa menos surpreendente.*
- O shell não deve alterar o comportamento esperado de comandos fundamentais do Unix (como `rm`, `mv`, `cp`) de maneiras perigosas ou bizarras. Flags padrão de CLI e atalhos canônicos do Readline/Zshline (`Ctrl+A`, `Ctrl+E`, `Ctrl+R`) devem funcionar consistentemente.

### 11. Regra do Silêncio (*Rule of Silence*)
> *Quando um programa não tem nada surpreendente a dizer, ele não deve dizer nada.*
- **Princípio Sagrado da Inicialização:** Ao abrir uma nova aba de terminal ou conexão SSH, o Shell **não deve imprimir texto, mensagens de boas-vindas barulhentas, nem banners lentos**. O prompt deve aparecer instantaneamente e em silêncio absoluto.

### 12. Regra do Reparo (*Rule of Repair*)
> *Quando você precisar falhar, falhe ruidosamente e o mais rápido possível.*
- Se uma função da `library/` receber parâmetros inválidos, ela emite uma mensagem clara no `stderr` e retorna código de saída diferente de 0 imediatamente.

### 13. Regra da Economia (*Rule of Economy*)
> *O tempo do programador é caro; economize-o em preferência ao tempo da máquina.*
- O objetivo central do Universal Shell é economizar micro-segundos mentais e toques de digitação do desenvolvedor todos os dias, com prompts inteligentes que exibem branch git, status de erro e ambiente de forma rápida.

### 14. Regra da Geração (*Rule of Generation*)
> *Evite codificação manual; escreva programas para escrever programas quando puder.*
- Automação do instalador (`install.sh`) para linkar e configurar automaticamente `.bashrc`, `.zshrc` e `.profile` para o usuário de forma automática.

### 15. Regra da Otimização (*Rule of Optimization*)
> *Prototipe antes de polir. Faça funcionar antes de otimizar.*
- No entanto, para o shell interativo, a **latência de inicialização é um requisito funcional**: meça o tempo de startup (ex: `time zsh -i -c exit`) e mantenha-o preferencialmente **abaixo de 50 milissegundos**.

### 16. Regra da Diversidade (*Rule of Diversity*)
> *Desconfie de todas as afirmações de "uma única maneira verdadeira".*
- Compatibilidade universal com múltiplos shells:
  - **Zsh:** Shell primário interativo moderno com autocompletion avançado.
  - **Bash:** Shell padrão universal presente na maioria das distribuições Linux e servidores.
  - **Sh:** Shell POSIX leve e fundamental (FreeBSD `/bin/sh`, Debian `dash`), essencial para inicialização rápida e sistemas embarcados.

### 17. Regra da Extensibilidade (*Rule of Extensibility*)
> *Projete para o futuro, porque ele chegará antes do que você imagina.*
- Facilidade de adicionar um novo contexto (ex: `cloud`, `ci`) ou um novo target de SO sem precisar alterar a base do `core/environment.sh`.

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
   - Use sempre a notação de 4 dígitos em comandos `chmod` (`chmod 0755` para diretórios e scripts executáveis públicos, `chmod 0644` para arquivos de configuração e bibliotecas sourced). O zero inicial deixa explícito que bits especiais (*setuid*, *setgid*, *sticky*) estão zerados.
6. **Portabilidade POSIX vs Extensões Zsh/Bash:**
   - Scripts que declaram `#!/usr/bin/env sh` devem ser estritamente compatíveis com a norma POSIX e com o `/bin/sh` do FreeBSD (sem usar `[[`, sem `function foo()`, sem arrays bash).
   - Recursos específicos do Zsh ficam exclusivamente em arquivos lidos pelo Zsh.
7. **Citações Seguras (Quoting):**
   - Sempre envolva variáveis em aspas duplas: `"${VAR}"` para evitar *word splitting* indesejado e ataques de injeção de caminho.

---

## 🔒 Princípios de Integração com o Ecossistema

1. **Zero Secrets in Public Repository:**
   - Este repositório é público. Nunca adicione chaves, senhas, tokens ou dados pessoais em arquivos deste repositório.
2. **Contrato de Carregamento com o Vault:**
   - O Shell lê segredos exclusivamente via integração com `~/.vault/vault.sh`.
   - Se `~/.vault` existir, ele é integrado de forma transparente e silenciosa. Se não existir, a sessão do terminal continua 100% utilizável sem interrupções.
