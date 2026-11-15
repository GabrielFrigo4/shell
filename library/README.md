# 📚 library/ — Biblioteca Padrão de Funções & Detecção

Esta pasta fornece o runtime compartilhado (`0644`, carregado via `source`) de utilitários POSIX e funções de sondagem em baixo nível do **Universal Shell Environment**.

---

## 📁 Módulos Base (Carregamento Universal)

- **`detect.sh`**:
    - Motor analítico que sonda SO (`linux`, `freebsd`, `openbsd`, `netbsd`, `illumos`, `macos`, `windows`), distro, shell habilitado (ignorando `dash` e NetBSD `/bin/sh`) e console bruto `_is_raw_tty`.
    - Consulte a documentação completa em **[docs/DETECTION.md](../docs/DETECTION.md)**.
- **`detect-desktop.sh`**:
    - Sondagem gráfica desacoplada: desktop environments (11 DEs), esquema Dark/Light (XDG Portal / D-Bus / GSettings / KDE), temas GTK/Qt e detecção de Wayland/X11/cursores.
- **`functions.sh`**:
    - Helpers POSIX canônicos: `path-front`, `path-back`, `path-dedup`, `_is_command`, `_as_root`, navegação segura e utilitários de sessão.
- **`ecosystem.sh`**:
    - Orquestradores e sincronizadores do Quarteto (`update-shell`, `update-editors`, `update-emacs-modes`, `update-profile`, `sync-extensions`, `reinstall-shell`, `clean-cache`, `bench-shell`).
- **`system-update.sh`**:
    - Abstração multi-SO de pacotes (`update-all`, `update-system`, `clean-system`, `update-apt`/`dnf`/`pacman`/`pkg`/`pkg-add`/`pkgin`/`ips`/`brew`, etc.).
- **`network-ports.sh`**:
    - Conectividade, credenciais Wi-Fi e diagnósticos (`update-wifi`, `update-network`, `update-linux`, `ports`, `conns`, controle de energia).
- **`deploy.sh`**:
    - Primitivas de implantação e vinculação de perfis utilizadas pelo instalador e sincronizadores.
- **`hypervisor.sh`**:
    - Orquestrador unificado multiplataforma para Máquinas Virtuais (KVM/Bhyve), Containers (Incus LXC) e Jails (BastilleBSD).
    - Comandos e aliases canônicos:
        - `fb` / `freebsd`: Controla VM KVM (no Linux Host) ou Jail nativa Bastille (no FreeBSD Host).
        - `lx` / `linux`: Controla Container Incus LXC (no Linux Host) ou VM Bhyve Debian (no FreeBSD Host).
        - `ob` / `openbsd`: Controla VM OpenBSD no KVM (Linux) ou Bhyve (FreeBSD).
        - `nb` / `netbsd`: Controla VM NetBSD no KVM (Linux) ou Bhyve (FreeBSD).
    - Subcomandos universais: `start`, `stop`, `restart`, `status`, `console`, `ssh` e execução direta de comandos no convidado.
- **`ui.sh`**:
    - Sistema de emissão semântica e interface de terminal (TUI) resiliente com suporte estrito a POSIX sh (`_ui_step`, `_ui_sub`, `_ui_ok`, `_ui_warn`, `_ui_err`, `_ui_info`, `_ui_banner`) sob `[ -t 1 ]` com fallback sem ANSI em pipes.

---

## 💻 Módulos _Lazy_ (`SHELL_CONTEXT=desktop` Exclusivo)

Os módulos abaixo só são carregados pelo bootstrap (`shell.sh` / `install.sh`) quando `SHELL_CONTEXT=desktop`, mantendo contextos `server` e `container` com overhead zero:

- **`desktop-device.sh`**: Gestão de servidores pessoais/corporativos (`PERSONAL_SERVER_*`, `VENTURE_SERVER_*`), chaves SSH do Vault e montagem MTP/ADB em `~/Device` (`mount-device`, `umount-device`).
- **`desktop-kiosk.sh`**: Lançadores efêmeros multi-TTY (`graphical-launcher` / `gui`, `wgui`, `xgui`) e sessões Emacs OS (`ewm`, `wewm`, `xewm`).
- **`desktop-session.sh`**: Orquestração completa de sessões gráficas (`window-manager` / `wm`, `wwm`, `xwm`), barra `wwm-bar`, pipeline tipográfico `_resolve_desktop_font` e cursores `_setup_cursor_env`.

Todos os scripts desta pasta seguem o padrão **POSIX sh** estrito e rodam sem bashisms.
