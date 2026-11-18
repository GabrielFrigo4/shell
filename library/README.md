# 📚 library/ — Biblioteca Padrão de Funções & Dispatchers

Esta pasta fornece o runtime modular compartilhado (`0644`, carregado via `source`) do **Universal Shell Environment**, organizado no padrão **Dispatcher na raiz + Subpasta coesa** para carregamento direto e _lazy_.

---

## 📁 Dispatchers de Domínio (Raiz de `library/`)

- **`functions.sh`** ➔ `library/functions/`
    - **`functions/git.sh`**: Sincronização resiliente multi-repositório (`update-git` / `upgit`, `push-git` / `psgit`, `_git_pull_resilient` com resolução de `.git` gitlink em submódulos e proteção `0700`/`0600` no `Vault`) e integração híbrida Git/Game of Trees (`vcs-status`, `vcs-diff`, `got-init`).
    - **`functions/utils.sh`**: Utilitários POSIX de sessão (`clean-cache`, `take-dir`, `cd-git-root`, `hist-search`, `extract-archive`).
- **`system.sh`** ➔ `library/system/`
    - **`system/packages.sh`**: Abstração multi-SO de gerenciadores de pacotes (`update-system`, `update-pacman`/`apt`/`dnf`/`tdnf`/`zypper`/`xbps`/`apk`/`pkg`/`pkg-add`/`pkgin`/`ips`/`brew`/`mas`/`aur`/`flatpak`/`snap`/`emerge`/`nix`/`eopkg`/`slackpkg`/`guix`/`opkg`).
    - **`system/network.sh`**: Conectividade, credenciais Wi-Fi (`update-wifi`, `update-network`), atualização da árvore FreeBSD Ports (`update-ports`) e VM Bhyve Linux (`update-linux` / `uplx` / `updeb`).
    - **`system/lifecycle.sh`**: Orquestração e ciclo de energia (`update-all` / `upall`, `clean-system`, `poweroff`, `reboot`).
- **`ecosystem.sh`** ➔ `library/ecosystem/`
    - **`ecosystem/shell.sh`**: Auto-atualização, reinstalação e benchmark do Shell (`update-shell`, `reinstall-shell`, `bench-shell`).
    - **`ecosystem/profile.sh`**: Sincronização do Profile e extensões de IDE (`update-profile`, `sync-extensions`).
    - **`ecosystem/editors.sh`**: Atualizadores da Suíte de Editores (`update-editors`, `update-emacs-modes`, gerenciamento automático de junction `.vim` no Windows).
- **`hypervisor.sh`** ➔ `library/hypervisor/`
    - **`hypervisor/common.sh`**: Helpers comuns de transporte SSH/TTY, KVM (`virsh`), Bhyve (`vm`), BastilleBSD (`bastille`) e Incus (`incus`).
    - **`hypervisor/managers.sh`**: Orquestradores multiplataforma por SO (`freebsd`/`fb`, `linux`/`lx`, `openbsd`/`ob`, `netbsd`/`nb`).

---

## 💻 Dispatcher Desktop (`SHELL_CONTEXT=desktop` Exclusivo)

O dispatcher **`desktop.sh`** só é carregado pelo bootstrap (`shell.sh`, `install.sh` e RCs) quando `SHELL_CONTEXT=desktop`, mantendo contextos `server` e `container` com overhead zero:

- **Carregamento Direto (`library/desktop/`):**
    - **`desktop/detect.sh`**: Sondagem gráfica desacoplada de Desktop Environments (11 DEs), esquema Dark/Light (XDG Portal / D-Bus / GSettings / KDE), temas GTK/Qt, cursores e pipelines Wayland/X11.
    - **`desktop/theme.sh`**: Propagação leve de tema de sessão (`_propagate_session_theme_env`) e aplicação contextual (`_desktop_apply_theme_context`) sem disparar o parse de `desktop/session.sh` no boot.
    - **`desktop/emacs.sh`**: Gerenciamento completo de socket/daemon Emacs (`EMACS_SOCKET_NAME`, `_emacs_*`, `emacs-*` e aliases `ek..esh`).
    - **`desktop/apps.sh`**: Restauração defensiva de cursor (`_restore_tty_cursor`), wrappers de editores TUI/GUI (`nvim`, `hx`, `micro`, `open-kate`..`open-zed`), aplicativos desktop e abridor inteligente (`open-smart` / `open` / `o`).
- **Carregamento _Lazy_ (`library/desktop/`):**
    - **`desktop/device.sh`**: Gestão de servidores pessoais/corporativos (`personal-server`, `venture-server`), chaves SSH do Vault e montagem MTP/ADB em `~/Device` (`mount-device`, `umount-device`).
    - **`desktop/kiosk.sh`**: Lançadores efêmeros multi-TTY (`graphical-launcher` / `gui`, `wgui`, `xgui`) e sessões Emacs OS (`ewm`, `wewm`, `xewm`).
    - **`desktop/session.sh`**: Orquestração completa de sessões gráficas (`window-manager` / `wm`, `wwm`, `xwm`), barra `wwm-bar`, pipeline tipográfico `_resolve_desktop_font` e cursores `_setup_cursor_env`.

Todos os scripts desta pasta seguem o padrão **POSIX sh** estrito e rodam sem bashisms.
