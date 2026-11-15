# ⚙️ core/ — O Núcleo do Ambiente Shell

> Esta pasta contém a base invariante de inicialização de qualquer sessão do **Universal Shell Environment** (bibliotecas `sourced` com modo `0644`).

---

## 📁 Componentes Centrais

- **`environment.sh`**:
    - Sanitização e priorização determinística do `$PATH` (`~/.local/bin`, `~/.cargo/bin`).
    - Segregação de userland (`--userland=default|bsd|gnu`, comandos `userland`, `gnu`, `bsd`, `default`): em `default`/`bsd`, preserva ferramentas nativas BSD/illumos evitando diretórios `gnubin` à frente no `$PATH`; em `gnu`, injeta diretórios GNU reais (mantendo `~/.local/bin` na frente), gera cache de aliases `g*` validados por `--version` e ativa `_SHELL_GNU_LS_BIN`/`gls`.
    - Habilitação universal de 24-bit TrueColor (`COLORTERM="truecolor"`, `MICRO_TRUECOLOR=1`).
    - Política universal efêmera de cache de bytecode Python: `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"` em todos os contextos.
    - Helpers inteligentes `_shell_ls` (`l`, `la`, `ll`, `lt`, `lr`, `lar`, `llr`) com detecção automática de TTY vs pipe/redirecionamento.
    - Configuração de `$HISTFILE`, `$HISTSIZE` e cascata de seleção de editor padrão (`$VISUAL` e `$EDITOR`).
- **`vault.sh`**:
    - Ponto de integração nativo com o repositório privado [Vault](https://github.com/GabrielFrigo4/vault).
    - Detecta a presença de `${HOME}/.vault/` e carrega silenciosamente variáveis `.env` e chaves SSH (`vault-keys`).

Consulte mais detalhes em **[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)**.
