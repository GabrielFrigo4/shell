# 🎨 target/ — Especializações por Sistema Operacional

Esta pasta contém as especializações declarativas por sistema operacional, definindo as variáveis de ambiente, caminhos de pacotes e a inicialização dos prompts visuais para cada shell suportado (`zsh`, `bash`, `sh`).

---

## 📁 Catálogo de Plataformas Suportadas

| Sistema Operacional | Identificador (`uname -s`) | Shells Suportados   | Particularidades da Plataforma                                            |
| :------------------ | :------------------------- | :------------------ | :------------------------------------------------------------------------ |
| **FreeBSD**         | `FreeBSD`                  | `zsh`, `bash`, `sh` | Baseline POSIX (`/bin/sh` + EditLine), `pkg`, `doas` / `sudo`             |
| **Linux**           | `Linux`                    | `zsh`, `bash`       | GNU Coreutils, `systemd` / OpenRC / runit, temas D-Bus / GTK / Qt         |
| **macOS**           | `Darwin`                   | `zsh`, `bash`       | Homebrew (`/opt/homebrew` vs `/usr/local`), `pbcopy`/`pbpaste`, BSD utils |
| **Windows**         | `MINGW*`, `MSYS*`          | `zsh`, `bash`       | Runtime MSYS2 / UCRT64, caminhos POSIX para Windows, ConPTY               |
| **OpenBSD**         | `OpenBSD`                  | `zsh`, `bash`       | Foco em segurança (`pledge`, `unveil`), `doas` nativo, `pkg_add`, X11     |
| **NetBSD**          | `NetBSD`                   | `zsh`, `bash`       | Berço da `libedit`, Almquist `/bin/sh`, ecossistema `pkgsrc` / `pkgin`    |
| **illumos**         | `SunOS`                    | `zsh`, `bash`       | Kernel SVR4 moderno, dualidade `/usr/gnu/bin` vs `/usr/bin`, SMF, ZFS     |
