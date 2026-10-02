# 🤝 Guia de Contribuição — Universal Shell

> Diretrizes de desenvolvimento, setup inicial da bancada, latência de inicialização e quality gates para o **Universal Shell**.

---

## 🚀 Setup Inicial da Bancada (Primeiros Passos)

Para clonar e configurar o motor do Shell localmente com ganchos e quality gates ativados:

```sh
# 1. Clonar o repositório
git clone "https://github.com/GabrielFrigo4/shell.git" "${HOME}/Documents/Shell"
cd "${HOME}/Documents/Shell"

# 2. Configurar ganchos Git e permissões canônicas
make hooks

# 3. Validar a sintaxe em todos os shells suportados (Zsh, Bash, POSIX sh, ksh)
make test

# 4. Medir a latência de inicialização e benchmark
make bench
```

> [!IMPORTANT]
> O comando `make hooks` configura `core.hooksPath -> .githooks` e aplica permissões canônicas `0755` aos ganchos de pre-commit e commit-msg. Execute-o sempre após um novo clone.

---

## ⚡ Invariantes de Engenharia no Shell

1. **Orçamento de Latência (< 64ms):**
    - A inicialização do Shell e renderização de prompts deve operar estritamente abaixo de **64ms** (com alvo ideal < 16ms) em terminais nativos.
    - Qualquer contribuição que degrade a latência acima do limite será bloqueada pelo `pre-commit` e CI.

2. **Invariante de Clonagem "Out-of-the-Box" (Zero-Tweaks Invariant):**
    - Scripts executáveis autônomos (`shell.sh`, `install.sh`, `benchmark.sh`) e ganchos Git devem ter modo canônico `100755` no Git Index.
    - Módulos de carregamento, prompts e bibliotecas para `source` devem ter modo `100644`.
    - Se cometer um erro de modo no Git Index, corrija com:
        ```sh
        git update-index --chmod=+x caminho/script.sh
        git update-index --chmod=-x caminho/modulo.sh
        ```

3. **Padronização Semântica de UI (`_ui_*`):**
    - Toda emissão interativa de status ou progresso deve utilizar a biblioteca semântica `_ui_*` (`_ui_step`, `_ui_sub`, `_ui_ok`, `_ui_warn`, `_ui_err`, `_ui_info`, `_ui_banner`).
    - Escapes ANSI usam a notação canônica `[ -t 1 ] && echo -n $'\e...'` ou notação hexadecimal (`\x01`, `\x1b`) para bytes de controle. Octais como `\033` não devem ser utilizados.

4. **Multi-Shell & Multi-OS:**
    - Compatibilidade verificada em Linux, FreeBSD (14/15), Windows (MSYS2), macOS, OpenBSD, NetBSD e illumos.
    - Suporte estrito a Zsh, Bash, FreeBSD `/bin/sh` e KornShell (`ksh`).

---

## 🪝 Quality Gates & Validação Local

O repositório possui uma bateria completa de testes:

```sh
make test     # Valida sintaxe em Zsh, Bash, POSIX sh e ksh
make bench    # Executa a suíte de benchmark de latência
make ci       # Executa bateria completa de CI local
```

Ganchos Git em `.githooks/`:

- **`pre-commit`:** Verifica whitespace, modos octais no Git Index (0755 vs 0644), sintaxe multi-shell, aspas em redirecionamentos, Prettier e benchmark de inicialização.
- **`commit-msg`:** Valida formato semântico da mensagem de commit.

---

## 📝 Convenção de Commits Semânticos

As mensagens de commit devem seguir o formato:

```text
<tipo>(<escopo>): <descrição objetiva>
```

Tipos permitidos: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `ci`, `chore`.

---

## 📖 Referências Canônicas

- [README.md](README.md) — Visão geral e arquitetura do motor de terminal
- [PRINCIPLES.md](PRINCIPLES.md) — Princípios de Engenharia e Clean Code
- [AGENTS.md](AGENTS.md) — Briefing para agentes autônomos de IA
- [docs/THEMES.md](docs/THEMES.md) — Engenharia de prompts e calibragem de buffers
