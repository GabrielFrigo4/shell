# 📚 library/ — Biblioteca Padrão de Funções & Detecção

Esta pasta fornece o runtime compartilhado de utilitários POSIX e funções de sondagem em baixo nível do **Universal Shell Environment**.

---

## 📁 Módulos da Biblioteca

- **`detect.sh`**:
    - Motor analítico que sonda SO, distribuição Linux, shell interativo, ambiente de desktop (KDE, GNOME, Sway, Hyprland), esquema de cores (Dark/Light) e temas de toolkits (GTK, Qt).
    - Consulte a documentação completa em **[docs/DETECTION.md](../docs/DETECTION.md)**.
- **`functions.sh`**:
    - Helpers POSIX canônicos: `path-front`, `path-back`, `path-dedup`, `_is_command`, `_as_root`.
    - Orquestradores de pacotes (`update-all`, `update-system`, `update-aur`, `update-flatpak`).
    - Funções de controle de energia (`reboot`, `poweroff`).

Todos os scripts desta pasta seguem o padrão **POSIX sh** estrito e rodam sem bashisms.
