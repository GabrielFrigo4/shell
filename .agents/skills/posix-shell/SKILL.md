---
name: posix-shell
description: >-
  Deep technical reference and runbook for pure POSIX Shell (/bin/sh) portability,
  Almquist shell (ash/dash/FreeBSD sh), strict standards (POSIX.1-2008/2017/2024),
  bashism elimination, buffer constraint handling, and zero-fork in-memory paradigms.
  Use when developing, refactoring, or auditing scripts for universal POSIX compatibility.
---

# POSIX Shell — Portability, Runtime & Engineering Runbook

Este runbook consolida os padrões canônicos, limitações de baixo nível, armadilhas de portabilidade e técnicas de engenharia para o desenvolvimento em **POSIX Shell estrito (`/bin/sh`)**, cobrindo o baseline canônico do FreeBSD `/bin/sh`, Dash (Debian/Ubuntu), BusyBox `ash` (Alpine/Embedded), NetBSD `sh`, OpenBSD `pdksh`/`sh` e POSIX mode no Bash (`bash --posix`).

---

## 1. O Papel do POSIX `/bin/sh` no Ecossistema

No ecossistema do **Quarteto de Produtividade**, o `/bin/sh` é o **mínimo denominador comum (LCD)** de execução:

1. **Onipresença:** Está presente em qualquer ambiente UNIX, FreeBSD base, contêiner Alpine mínimo, instalador de emergência, chroot e init script (`/etc/rc`).
2. **Determinismo:** Não assume a presença de binários GNU, utilitários GNU coreutils ou recursos específicos de shells modernos (Bash, Zsh).
3. **Eficiência de Recursos:** Inicialização instantânea (< 5ms) com overhead residual mínimo de memória e CPU.
4. **Resiliência:** Capaz de rodar no particionamento raiz puro (`/bin`), mesmo em modo monousuário (_single-user mode_).

---

## 2. Bashismos Terminantemente Proibidos

Ao escrever scripts portáveis para `/bin/sh`, as seguintes construções de Bash/Zsh são estritamente vedadas:

| Bashismo Proibido           | Causa da Falha em `/bin/sh`                       | Equivalente Canônico POSIX                                             |
| :-------------------------- | :------------------------------------------------ | :--------------------------------------------------------------------- |
| `[[ $a == $b ]]`            | Erro de sintaxe (palavra reservada não suportada) | `[ "$a" = "$b" ]` ou `case "$a" in "$b") ;; *) ;; esac`                |
| `[ "$a" == "$b" ]`          | Operador `==` inexiste no `test` POSIX            | `[ "$a" = "$b" ]`                                                      |
| `&>` ou `>& file`           | Redirecionamento combinado inválido               | `> file 2>&1`                                                          |
| `function nome() {`         | Palavra reservada `function` inexiste             | `nome() {`                                                             |
| `arr=(a b c)` / `${arr[@]}` | Não há tipos de array indexados no POSIX          | Listas separadas por espaço, `IFS`, ou argumentos posicionais (`"$@"`) |
| `source file.sh`            | Comando builtin inexistente no padrão             | `. file.sh`                                                            |
| `${var//antigo/novo}`       | Expansão de substituição de string não-POSIX      | Sed, `awk`, ou manipulação de sufixo/prefixo (`${var#*pat}`)           |
| `${var:offset:length}`      | Expansão de substring por índice não-POSIX        | `${var%...}`, `${var#...}` ou loop com `${var%?}`                      |
| `<<< "texto"`               | Here-string inexistente no padrão                 | `echo "texto" \| ...` ou `cat <<- 'EOF'`                               |
| `<(cmd)` / `>(cmd)`         | Process substitution não suportada                | Pipes tradicionais ou arquivos temporários com `trap`                  |
| `echo -e` / `echo -E`       | Flags não portáveis (comportamento varia por OS)  | `printf '%s\n'` ou `echo -n $'\e...'` (conforme padrão local)          |
| `type cmd` / `which cmd`    | `type` é opcional e `which` é externo instável    | `command -v cmd > "/dev/null" 2>&1`                                    |
| `select` / `let`            | Builtins exclusivos de shells avançados           | Loops `while`/`case` e aritmética `$(( ... ))`                         |

---

## 3. Manipulação Nativa de Strings (Zero Forks)

Para manter a latência de execução abaixo do teto de 50ms, manipulações de strings **NUNCA DEVEM USAR SUBSHELLS** (`cut`, `awk`, `sed`, `basename`, `dirname`, `expr`) quando houver alternativa nativa de Parameter Expansion.

### 3.1. Expansões Canônicas POSIX

```sh
# Extrair nome do arquivo (equivalente a basename)
_filename="${_path##*/}"

# Extrair diretório pai (equivalente a dirname)
_dirname="${_path%/*}"
[ "${_dirname}" = "${_path}" ] && _dirname="."

# Remover extensão de arquivo
_base="${_filename%.*}"

# Extrair extensão
_ext="${_filename##*.}"

# Fallback se variável estiver nula ou vazia
_user="${USER:-$(command id -un)}"

# Comprimento de string em caracteres
_len="${#_var}"
```

### 3.2. Algoritmo de Truncagem Recursiva com Sufixo (`_trim_str`)

Quando for necessário podar uma string para caber em um orçamento físico (ex: buffer de prompt):

```sh
_trim_str() {
	_trimmed="$1"
	if [ "${#_trimmed}" -gt "$2" ]; then
		local _target=$(( $2 - 1 ))
		while [ "${#_trimmed}" -gt "${_target}" ]; do
			_trimmed="${_trimmed%?}"
		done
		_trimmed="${_trimmed}$3"
	fi
}
```

- Executa no processo corrente sem disparar subshells (`$(...)`).
- Utiliza `${_trimmed%?}` para remover o último caractere em $O(n)$ iterações na memória.
- Aplica sufixo elíptico canônico (`…` no PTY, `~` no TTY).

---

## 4. Aritmética Nativa POSIX (`$(( ... ))`)

Toda a aritmética de inteiros deve ocorrer via `$(( ... ))`. Nunca invoque `expr` ou `bc`:

```sh
# Operações básicas
_soma=$(( a + b ))
_sub=$(( a - b ))
_mult=$(( a * b ))
_div=$(( a / b ))
_mod=$(( a % b ))

# Divisão de orçamento de tela meio a meio
_half=$(( _budget / 2 ))
_max_branch=$(( _budget - _half ))

# Comparação e lógica em expressões condicionais
if [ $(( _pwd_len + _branch_len )) -le "${_budget}" ]; then
	_max_pwd="${_pwd_len}"
	_max_branch="${_branch_len}"
fi
```

---

## 5. Programação Defensiva e Redirecionamentos

### 5.1. Redirecionamentos com Aspas Obrigatórias

Sempre envolva destinos de redirecionamento em aspas duplas:

```sh
# Correto:
command -v git > "/dev/null" 2>&1
echo "data" >| "${_target_file}"
cat << 'EOF' > "/tmp/scratch.txt"

# Incorreto:
command -v git > /dev/null 2>&1
```

### 5.2. O Operador `>|` (_Clobber_)

Ao sobrescrever arquivos onde `set -C` (_noclobber_) possa estar ativado no ambiente do usuário, utilize `>|` para forçar a escrita atômica com intenção explícita.

### 5.3. Heredocs com Descarte de TABs (`cat <<- 'EOF'`)

Para manter blocos de texto alinhados com a indentação do código circundante sem vazar espaços para a coluna zero:

```sh
_generate_config() {
	cat <<- 'EOF' > "${_dest_file}"
		# Configuração Canônica
		set -e
		export PATH="/usr/local/bin:${PATH}"
	EOF
}
```

- O hífen em `<<-` descarta todos os caracteres TAB (`\t`) iniciais das linhas e do fechamento `EOF`.
- Aspas ao redor de `'EOF'` impedem interpolação acidental de `$`, `` ` `` e `\`.

### 5.4. Proteção de Terminal (`[ -t 1 ]`)

Sequências de controle ANSI nunca devem poluir saídas redirecionadas:

```sh
[ -t 1 ] && echo -n $'\e[0 q'
```

---

## 6. Gestão de Argumentos e o Poder de `"$@"`

Como o POSIX `/bin/sh` não possui arrays indexados, a lista de argumentos posicionais (`"$@"`) é a única estrutura de dados com garantias canônicas de preservação de espaços:

```sh
# Iterar sobre argumentos sem quebra de espaços:
for _arg in "$@"; do
	echo "Processando: ${_arg}"
done

# Manipular dinamicamente a lista de parâmetros:
set -- "$@" "novo_item"
set -- "--flag" "$@"

# Delegar para binário real:
open-editor() {
	if [ "$#" -eq 0 ]; then
		command editor .
	else
		command editor "$@"
	fi
}
```

---

## 7. Variáveis Locais em Funções

Embora `local` não faça parte do padrão formal POSIX Issue 7 (sendo adicionado como extensão no POSIX.1-2024 Issue 8), o builtin `local` é implementado em praticamente todos os interpretadores modernos (`dash`, FreeBSD `/bin/sh`, NetBSD `/bin/sh`, BusyBox `ash`, Bash, Zsh).

### Regras de Ouro para `local`:

1. **Declare no topo da função:**
   ```sh
   _minha_funcao() {
       local _var1 _var2 _ret=0
       # ...
   }
   ```
2. **Nunca atribua comandos no mesmo comando `local` se precisar checar o status de saída:**
   ```sh
   # Perigoso: o status de saída capturado é do builtin local, não do subshell!
   local _res="$(comando_falho)"
   echo "$?" # Imprime 0!

   # Canônico e seguro:
   local _res
   _res="$(comando_falho)"
   _status=$?
   ```

---

## 8. Limitações Físicas de Memória em Buffers (`PROMPTLEN`)

No FreeBSD `/bin/sh` e derivados da Almquist shell:

- **FreeBSD <= 13:** Buffer estático de **128 bytes** (`ps[128]`).
- **FreeBSD 14 e 15+:** Buffer estático de **192 bytes** (`ps[192]`).
- **Teto Físico de Memória:** O prompt formatado é truncado em `PROMPTLEN - 1`.
- **Prevenção via Arquitetura:**
  - Delegue o limite de buffer à plataforma (`target/freebsd/sh/prompt.sh` exporta `PROMPT_BUFFER_LIMIT`).
  - O tema (`theme/sh.sh`) adota `local _prompt_limit="${PROMPT_BUFFER_LIMIT:-192}"` e chaveia para layout `micro` quando o limite for inferior a 192 bytes.
  - Elimine delimitadores e escapes redundantes para manter margem física livre.

---

## 9. Checklist de Qualidade para Scripts POSIX

Antes de concluir qualquer alteração em arquivos `.sh` portáveis:

- [ ] **Sintaxe validada:** Executou `sh -n <arquivo>` sem erros.
- [ ] **Sem bashismos:** Verificado contra arrays, `[[`, `==`, `source`, `&>`.
- [ ] **Redirecionamentos seguros:** Destinos com aspas duplas (`> "/dev/null" 2>&1`).
- [ ] **Comentários narrativos eliminados:** Zero linhas óbvias comentando comandos executáveis.
- [ ] **Shebang canônico:** Scripts autônomos iniciam com `#!/usr/bin/env sh`.
- [ ] **Tratamento de espaços:** Todas as variáveis em comandos cotadas (`"${var}"`).
- [ ] **Permissões octais canônicas:** 4 dígitos aplicados (`chmod 0755` para scripts executáveis, `chmod 0644` para bibliotecas/temas).
- [ ] **Pre-commit aprovado:** Boot latency < 50ms e zero alertas de formatação.
