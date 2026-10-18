# 📚 library/ — Biblioteca Padrão de Funções & Detecção

Esta pasta fornece o runtime compartilhado de utilitários POSIX e funções de sondagem em baixo nível do **Universal Shell Environment**.

---

## 📁 Módulos da Biblioteca

- **`detect.sh`**:
    - Motor analítico que sonda SO, distribuição Linux, shell interativo, ambiente de desktop (KDE, GNOME, Sway, Hyprland), esquema de cores (Dark/Light) e temas de toolkits (GTK, Qt).
    - Consulte a documentação completa em **[docs/DETECTION.md](../docs/DETECTION.md)**.
- **`functions.sh`**:
    - Helpers POSIX canônicos: `path-front`, `path-back`, `path-dedup`, `_is_command`, `_as_root`.
    - Orquestradores e atualizadores universais (`update-all`, `update-system`, `update-shell`, `update-editors`, `update-profile`, `update-git`, `update-aur`, etc.).
    - Funções de controle de energia (`reboot`, `poweroff`).
- **`hypervisor.sh`**:
    - Orquestrador unificado multiplataforma para Máquinas Virtuais (KVM/Bhyve), Containers (Incus LXC) e Jails (BastilleBSD).
    - Comandos e aliases canônicos:
        - `fb` / `freebsd`: Controla VM KVM (no Linux Host) ou Jail nativa Bastille (no FreeBSD Host).
        - `lx` / `linux`: Controla Container Incus LXC (no Linux Host) ou VM Bhyve Debian (no FreeBSD Host).
        - `ob` / `openbsd`: Controla VM OpenBSD no KVM (Linux) ou Bhyve (FreeBSD).
        - `nt` / `netbsd`: Controla VM NetBSD no KVM (Linux) ou Bhyve (FreeBSD).
    - Subcomandos universais: `start`, `stop`, `restart`, `status`, `console`, `ssh` e execução direta de comandos no convidado.
- **`ui.sh`**:
    - Sistema de emissão semântica e interface de terminal (TUI) resiliente com suporte estrito a POSIX sh.
    - Detecção automática de TTY interativo (`_ui_has_color` sob `[ -t 1 ]`) com fallback gracioso para texto plano sem sequências ANSI em pipelines e redirecionamentos.
    - Paleta semântica canônica de emissão:
        - `_ui_step <msg>`: Marcador de etapa primária com prefixo `==>` em Ciano.
        - `_ui_sub <msg>`: Marcador de sub-etapa com prefixo `  ↳` em Azul (fallback: ` ->`).
        - `_ui_ok <msg>`: Confirmação de sucesso com prefixo `  ✅` em Verde (fallback: ` OK`).
        - `_ui_warn <msg>`: Alerta não-bloqueante com prefixo ` ⚠️` em Amarelo (fallback: ` WARN`).
        - `_ui_err <msg>`: Notificação de falha direcionada a `stderr` com prefixo `  ❌` em Vermelho (fallback: ` FAIL`).
        - `_ui_info <msg>`: Nota informativa com prefixo ` ℹ️` em Magenta (fallback: ` INFO`).
        - `_ui_banner <título>`: Banner delimitador estrutural com réguas duplas de 64 caracteres `=` em Ciano.

Todos os scripts desta pasta seguem o padrão **POSIX sh** estrito e rodam sem bashisms.
