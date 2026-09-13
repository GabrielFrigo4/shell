# 🖌️ theme/ — Temas de Prompt & Identidade Visual

Esta pasta gerencia os motores de renderização de prompt e estilos visuais do **Universal Shell Environment**.

---

## 📁 Motores de Renderização

- **`bash.sh`**:
  - Prompt moderno em Bash com escapes ANSI isolados em `\[...\]` para cálculo correto de quebra de linha.
  - Renderização do branch Git ativo e status de modificação.
- **`zsh.sh`**:
  - Prompt nativo em Zsh utilizando `vcs_info`, Zstyles e menu completion interativo com cores.
- **`sh.sh`**:
  - Prompt minimalista e portátil para `/bin/sh` (POSIX puro), compatível com FreeBSD e consoles seriais.

Consulte a documentação completa em **[docs/THEMES.md](../docs/THEMES.md)**.
