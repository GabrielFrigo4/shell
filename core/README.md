# ⚙️ core/ — O Núcleo do Ambiente Shell

Esta pasta contém a base invariante de inicialização de qualquer sessão do **Universal Shell Environment**.

---

## 📁 Componentes Centrais

- **`environment.sh`**:
  - Sanitização e priorização do `$PATH`.
  - Habilitação universal de 24-bit TrueColor (`COLORTERM="truecolor"`, `MICRO_TRUECOLOR=1`).
  - Configuração de `$HISTFILE`, `$HISTSIZE` e variáveis de histórico resiliente.
  - Cascata de seleção de editor de texto padrão (`$VISUAL` e `$EDITOR`).
- **`vault.sh`**:
  - Ponto de integração nativo com o repositório privado [Vault](https://github.com/GabrielFrigo4/vault).
  - Detecta a presença de `${HOME}/.vault/` e carrega silenciosamente variáveis `.env` e chaves SSH (`vault-keys`).

Consulte mais detalhes em **[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)**.
