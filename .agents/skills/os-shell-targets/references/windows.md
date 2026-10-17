# 🪟 Windows Shell Architecture — Native Tripartite & POSIX Runtimes

O ecossistema no Windows é estruturado em duas camadas complementares:

1. **A Suíte Tripartite Nativa:** PowerShell 7 (`pwsh`), NuShell (`nu`) e CMD com Clink (`cmd`).
2. **Os Runtimes POSIX Emulados:** MSYS2 e WSL (`bash` e `zsh`).

---

## 🏛️ A Suíte Tripartite Nativa

| Shell            | Runtime & Motor                 | Arquivos Canônicos                                                                                                 | Destino Físico no Windows                       |
| :--------------- | :------------------------------ | :----------------------------------------------------------------------------------------------------------------- | :---------------------------------------------- |
| **PowerShell 7** | `.NET 9+ / C#`                  | [`profile.ps1`](../../../target/windows/powershell/profile.ps1)                                                    | `$PROFILE` / `Documents\PowerShell\profile.ps1` |
| **NuShell**      | `Rust / Pipelines Estruturados` | [`config.nu`](../../../target/windows/nushell/config.nu), [`env.nu`](../../../target/windows/nushell/env.nu)       | `%APPDATA%\nushell\`                            |
| **CMD + Clink**  | `C / LuaJIT Readline Injector`  | [`profile.lua`](../../../target/windows/cmd/profile.lua), [`profile.cmd`](../../../target/windows/cmd/profile.cmd) | `%LOCALAPPDATA%\clink\`                         |

---

## ⚡ 1. PowerShell 7: Invariante de Aliases Não-Circulares & Reentrância

### A Armadilha da Recursão Case-Insensitive

No PowerShell, nomes de funções, cmdlets e aliases são estritamente **case-insensitive**.
Definir um alias cujo nome seja idêntico ao da função (ex: `New-Alias "clean-system" "Clean-System"`) cria um **alias auto-referencial circular**.

Quando invocado:

1. O interpretador detecta que o alias aponta para o próprio nome.
2. Para evitar loop infinito, o PowerShell suprime o alias e desvia a busca da tabela interna de funções.
3. O interpretador tenta localizar um executável externo no disco (`clean-system.exe`).
4. A execução aborta com erro fatal: `The term 'clean-system' is not recognized as a name of a cmdlet, function, script file, or executable program.`

> [!IMPORTANT]
> **Regra de Ouro:** Funções do PowerShell NUNCA devem ter aliases com o mesmo nome (independentemente de maiúsculas/minúsculas). As funções já são diretamente invocáveis pelo próprio nome.

### Reentrância Idempotente com `Set-Alias`

Aliases devem ser declarados com `Set-Alias -Force -Option AllScope` em vez de `New-Alias`. Isso permite que o perfil seja recarregado múltiplas vezes na mesma sessão sem disparar erros de colisão de identificador (`alias already exists`).

---

## 🦀 2. NuShell: Invariante de Casing de Variáveis de Ambiente & Conversão de PATH

### A Dualidade `Path` vs `PATH` no Windows

- O Windows NT registra internamente a variável de ambiente do sistema como **`Path`** (capital P, lowercase ath) e a Win32 API realiza lookups case-preserving.
- O NuShell trata variáveis em `$env` de forma **case-sensitive**!
- Se um script de inicialização (`env.nu`) apenas manipular `$env.PATH` (all caps), a chave herdada do sistema `$env.Path` permanece congelada.
- Quando comandos externos ou subshells são despachados (ex: `git.exe` chamando helpers), a Win32 API lê `$env.Path`, omitindo os binários recém-injetados (`gh.exe`, `git.exe`, Scoop shims) e gerando falhas silenciosas de execução ou autenticação.

### Solução Canônica no `env.nu`:

```nushell
$env.ENV_CONVERSIONS = {
	"PATH": {
		from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
	}
	"Path": {
		from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
	}
}

let _raw_path = ($env.Path? | default ($env.PATH? | default []))
let _initial_path = if ($_raw_path | describe | str starts-with "list") {
	$_raw_path
} else {
	($_raw_path | split row (char esep))
}

let _cleaned_path = (
	$_initial_path
	| each { |p| $p | str trim | str trim -c '"' }
	| prepend "C:\\Program Files\\GitHub CLI"
	| prepend "C:\\Program Files\\Git\\cmd"
	| where { |p| ($p | is-not-empty) and ($p | path exists) }
	| uniq
)

$env.Path = $_cleaned_path
$env.PATH = $_cleaned_path
```

---

## 🔐 3. Autenticação Git via GitHub CLI (`gh`) & Injeção Dinâmica

O ecossistema opera **estritamente via HTTPS autenticado com o GitHub CLI** (`gh auth setup-git` $\rightarrow$ `helper = !gh auth git-credential`).

> [!CAUTION]
> Chaves SSH para o GitHub são terminantemente vetadas. O gerenciamento de credenciais é 100% baseado em tokens OAuth protegidos no Windows Credential Manager pelo binário `gh`.

### Injeção Dinâmica no NuShell (`upvt`)

Em comandos de atualização de repositórios privados (como o Universal Vault), o NuShell resolve o executável `gh.exe` via `get-gh-cmd` e injeta explicitamente o helper no comando Git via argumento `-c`:

```nushell
let gh_bin = (get-gh-cmd)
if ($gh_bin | is-not-empty) {
	let helper_arg = $"credential.https://github.com.helper=!\"($gh_bin)\" auth git-credential"
	^$git_bin -C $target -c $helper_arg pull --ff-only
} else {
	^$git_bin -C $target pull --ff-only
}
```

Isso elimina qualquer dependência de subshell interativo e garante que o Git acesse o helper com caminho absoluto incondicional.

---

## 🔄 4. Auto-Cura de Perfis Físicos Cross-Shell (`upsh` / `resh`)

Conforme o **Princípio 19 (Autonomia Reentrante)** e o **Princípio 7 (Invariante Zero-Tweaks)**, nenhuma intervenção manual de cópia (`cp`, `Copy-Item`) é admitida.

A execução de `upsh` (`Update-Shell`) ou `resh` a partir de **qualquer shell** (PowerShell, NuShell ou CMD) propaga e atualiza automaticamente os perfis físicos em disco de todos os demais:

- **PowerShell:** Atualiza `$PROFILE` e `profile.ps1` em `Documents\PowerShell\`.
- **NuShell:** Atualiza `config.nu` e `env.nu` em `%APPDATA%\nushell\`.
- **CMD + Clink:** Atualiza `profile.lua` e `profile.cmd` em `%LOCALAPPDATA%\clink\`.

---

## 🧹 5. Higienização Defensiva Pré-Pull na Suíte de Editores (`Update-Editors`)

Ao puxar atualizações remotas de editores rastreados (como Emacs em `~/.emacs.d`), stubs ou artefatos gerados localmente (como `usr/local/`) abortam operações `git pull --ff-only` devido a colisão com arquivos não rastreados (_untracked_).

**Padrão Antifrágil:** Todo atualizador de editores executa limpeza defensiva antes do pull:

```powershell
git -C $target clean -fd usr/local 2>$null
git -C $target pull --ff-only
```

---

## 🌐 6. Paridade UTF-8 no Git (`core.quotepath = false`)

Por padrão, o Git escapa bytes $> 0x7E$ em octal (`\303\247`), corrompendo a legibilidade de caminhos contendo acentuação (`ç`, `ã`, `Área de Trabalho`).
A regra canônica exige:

```sh
git config --global core.quotepath false
```

Garantindo exibição UTF-8 nativa e idêntica entre Linux, FreeBSD e Windows.

---

## ⚡ 7. Runtimes POSIX (MSYS2 & WSL) — Penalidade de Fork

O Windows NT não possui `fork()` nativo. A DLL do MSYS2 emula `fork()` via `CreateProcess()`.

- Cada subshell `$(comando)` custa entre **20ms e 60ms** no MSYS2.
- **Regra:** **Zero subshells no boot interativo do shell**. Use manipulação de parâmetros em memória (`${var##*/}`, `${var%/*}`).
- **Quebras de Linha (CRLF):** Todos os scripts `.sh` e `.md` DEVEM manter finais de linha exclusivamente em formato UNIX (`LF`).
