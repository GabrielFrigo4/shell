# ⚙️ core/ — O Núcleo do Ambiente Shell

> Esta pasta contém os 9 módulos fundamentais do **Universal Shell Environment** (bibliotecas `sourced` com modo `0644`), divididos entre fundação de boot, motor interativo e utilitário declarativo de instalação.

---

## 📁 Componentes Centrais

### Fundação de Boot (carregada primeiro pelo `shell.sh`, `install.sh` e RCs)

- **`detect.sh`**:
    - Motor analítico que sonda SO (`linux`, `freebsd`, `openbsd`, `netbsd`, `illumos`, `macos`, `windows`), distro, família de gerenciador, shell habilitado (ignorando `dash` e NetBSD `/bin/sh`), console bruto `_is_raw_tty`, cache tmpfs e binários CLI modernos (`eza`, `bat`, `rg`, `fd`, `dust`, `procs`, `btm`, `zoxide`).
    - Consulte a documentação completa em **[docs/DETECTION.md](../docs/DETECTION.md)**.
- **`ui.sh`**:
    - Sistema de emissão semântica e interface de terminal (`_ui_step`, `_ui_sub`, `_ui_ok`, `_ui_warn`, `_ui_err`, `_ui_info`, `_ui_banner`) compatível com POSIX sh e `[ -t 1 ]` com fallback sem ANSI em pipes.
- **`elevate.sh`**:
    - Escalonamento defensivo de privilégios `_as_root` com precedência `root > doas > sudo`.
- **`perms.sh`**:
    - Auto-cura de permissões e governança Git (`_self_heal_perms` rápida no boot e `_install_repo_perms` completa no instalador), com suporte nativo a diretórios `.git` e arquivos gitlink de submódulos, preservando `0755` em entrypoints e `0644` nas bibliotecas.
- **`path.sh`**:
    - Manipulação determinística de `$PATH` (`path-front`, `path-back`, `path-dedup`) e lookup de binários sem forks (`_resolve_bin`, `_has_bin`).

### Runtime Interativo & Integração (carregados após `library/*.sh` e `target/{OS}/environment.sh`)

- **`environment.sh`**:
    - Locale soberano UTF-8, detecção de Raw TTY vs TrueColor (`COLORTERM="truecolor"`, `MICRO_TRUECOLOR=1`), política efêmera `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"`, cascata de editores (`$VISUAL`/`$EDITOR`), wrappers inteligentes `_shell_ls` (`l`, `la`, `ll`, `lt`, `lr`, `lar`, `llr`) com detecção automática de TTY vs pipe, `g`/`c`/`b`/`f`/`ff`/`d`/`p`/`pst`/`t`, `zoxide`, `ssh` com propagação `LC_RAW_TTY`, `agy` e aliases universais de controle de versão (`git`/`tog`).
- **`userland.sh`**:
    - Motor dual-mode GNU/BSD (`_apply_userland_mode` / `userland`, `gnu`, `bsd`, `default`): em `default`/`bsd`, preserva ferramentas nativas BSD/illumos evitando diretórios `gnubin` à frente no `$PATH`; em `gnu`, injeta diretórios GNU reais (mantendo `~/.local/bin` na liderança), gera cache de aliases `g*` validados por `--version` e ativa `_SHELL_GNU_LS_BIN`/`gls`.
- **`vault.sh`**:
    - Ponto de integração nativo com o repositório privado [Vault](https://github.com/GabrielFrigo4/vault), com wrappers _lazy_ (`vault-keys`, `vault-status`, etc.), verificação silenciosa de `ssh-agent` e atualizador `update-vault` (`upvt`).

### Motor de Implantação (exclusivo do `install.sh`, ignorado em sessões interativas)

- **`deploy.sh`**:
    - Primitivas declarativas de instalação e vinculação (`_deploy_win_paths`, `_deploy_item`, `_install_extended_shell`) utilizadas pelo `install.sh` para `fish`, `pwsh`, `nu` e `cmd`.

Consulte mais detalhes em **[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)**.
