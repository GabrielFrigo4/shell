---
name: universal-shell
description: >-
  Comprehensive guide and operational runbook for extending, refactoring, and auditing the Universal Shell repository.
  Use when adding new commands, aliases, contexts, targets, or auditing shell scripts for FreeBSD /bin/sh parity,
  defensive guards, and Clean Code standards.
---

# Universal Shell — Development & Architecture Runbook

Este guia detalha o fluxo operacional para estender, refatorar e auditar o repositório **Universal Shell Environment** (`/usr/local/share/shell`), garantindo aderência rigorosa aos 18 Princípios UNIX e às regras de Clean Code.

---

## 1. Mapeamento de Camadas (Onde colocar cada código)

Antes de escrever qualquer código, posicione-o na camada correta do ciclo de vida:

| Camada | Diretório | Papel & Responsabilidade | Exemplos |
| :--- | :--- | :--- | :--- |
| **Biblioteca** | `library/` | Funções puras reutilizáveis, detecção de ambiente e utilitários globais. Não deve conter aliases. | `_detect_os`, `_as_root`, `path-front`, `update-all` |
| **Núcleo** | `core/` | Variáveis essenciais de ambiente, cascatas de editores/ferramentas e integração com o Vault (`vault.sh`). | `editor()`, aliases universais (`u`, `l`, `g`, `c`, `f`) |
| **Contextos** | `context/` | Especializações por propósito da máquina (`desktop`, `server`, `container`, `wsl`). Dividido em `common.sh` e `<os>.sh`. | Editores gráficos (`open-*`), montagem móvel (`mount-device`), emacs |
| **Targets** | `target/` | Especializações pelo Sistema Operacional (`linux`, `freebsd`, `windows`). Injeta variáveis e caminhos específicos. | `PROMPT_OS_*`, `clear` no FreeBSD, `incus` no Linux |
| **Temas** | `theme/` | Renderização visual de prompts específicos por shell (`bash.sh`, `zsh.sh`, `sh.sh`). | Prompt de 2 linhas com Nerd Fonts, fallback TTY bruto, Git/Got |

---

## 2. Invariantes Arquiteturais Inegociáveis

1. **Linha de Base FreeBSD `/bin/sh` & Adoção de `$'\e...'` e `echo -n`:**
   - O `/bin/sh` do FreeBSD é a referência canônica para scripts compartilhados.
   - O formato `echo -n $'\e...'` é universalmente suportado em todo o ecossistema (FreeBSD `/bin/sh`, Zsh, Bash e Dash moderno, além do padrão POSIX Issue 8).
   - Use expressamente `echo -n $'\e...'` para sequências de controle de terminal (ex: `alias clear="echo -n $'\e[2J\e[3J\e[H'"`), priorizando a clareza e legibilidade do `$'\e'` sobre o octal arcaico.

2. **Programação Defensiva (`command -v`):**
   - Nunca defina aliases ou funções de binários externos sem validação prévia:
     ```sh
     command -v <binario> > "/dev/null" 2>&1 && alias <alias>="<binario>"
     ```

3. **Proteção de Terminal (`[ -t 1 ]`):**
   - Sequências de escape ANSI que interagem com o emulador de terminal (como `echo -n $'\e[0 q'` para reset de cursor) DEVEM ser condicionadas a `[ -t 1 ]` para evitar corromper pipes e arquivos de log:
     ```sh
     [ -t 1 ] && echo -n $'\e[0 q'
     ```

4. **Taxonomia Estrita de Nomes:**
   - Funções públicas: `kebab-case` (`open-helix`, `update-wifi`, `mount-device`).
   - Helpers internos e variáveis locais: `_snake_case` (`_detect_os`, `_as_root`, `_branch`).
   - Variáveis globais de ambiente: `SNAKE_CASE` maiúsculo (`SHELL_REPO_DIR`, `SHELL_CONTEXT`).
   - Sem funções gêmeas: declare diretamente a função pública final.

5. **Delimitadores de Largura Zero em Prompts (`\[...\]` e `\e`):**
   - No FreeBSD `/bin/sh` (`libedit`) e no Bash (`readline`), códigos ANSI dentro de `PS1` DEVEM estar estritamente contidos entre `\[` e `\]` (ex: `_c_red="\[\e[1;91m\]"`).
   - Sem `\[...\]`, a `libedit` computa bytes ANSI como colunas físicas ocupadas, quebrando a contagem de quebra de linha e causando sobreposição de caracteres (`\r`) e cursor travado sobre o início do prompt.

---

## 3. Procedimento para Criar um Novo Comando / Editor

Quando criar uma nova função de abertura de editor ou utilitário interativo:

1. **Defina a função canônica com suporte multi-argumento e diretório padrão `.`:***
   ```sh
   if command -v <bin> > "/dev/null" 2>&1; then
   	open-<nome>() {
   		if [ "$#" -eq 0 ]; then
   			command <bin> .
   		else
   			command <bin> "$@"
   		fi
   	}
   	alias o<letra>="open-<nome>"
   fi
   ```
2. **Se a ferramenta alterar o cursor do terminal (como o Helix):**
   Crie um wrapper local que capture o exit status e envie `echo -n $'\e[0 q'` antes de retornar:
   ```sh
   <bin>() {
       command <bin> "$@"
       local _status=$?
       [ -t 1 ] && echo -n $'\e[0 q'
       return ${_status}
   }
   ```
3. **Atualize a documentação em sincronia:**
   - Adicione o comando à tabela correspondente no `README.md`.
   - Adicione a regra/padrão no `PRINCIPLES.md` caso introduza novo conceito.

---

## 4. Checklist de Qualidade e Gates de Validação

Ao concluir qualquer alteração em arquivos `.sh` ou `.md`, execute obrigatoriamente:

```sh
# 1. Verificar espaços residuais, tabs misturados e quebras de linha
git diff --check

# 2. Executar o pre-commit hook oficial
./.githooks/pre-commit

# 3. Validar sintaxe na Matriz Multi-Shell:
# - Bash & Shared Shells:
find . -name "*.sh" -not -path "./.git/*" -not -path "*/zsh/*" -not -name "zsh.sh" -exec bash -n {} +
# - Zsh:
find . -name "*.sh" -not -path "./.git/*" -not -path "*/bash/*" -not -name "bash.sh" -exec zsh -n {} +
# - FreeBSD /bin/sh (executado no FreeBSD nativo ou no runner FreeBSD do CI):
sh -n library/functions.sh && sh -n core/environment.sh && sh -n theme/sh.sh

# 4. Validar permissões octais corretas
find . -type d -exec chmod 0755 {} +
find . -type f -exec chmod 0644 {} +
chmod 0755 install.sh
```
