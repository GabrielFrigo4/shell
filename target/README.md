# 🎨 target/ — Especializações por Sistema Operacional

Esta pasta contém as especializações declarativas por sistema operacional, definindo as variáveis de ambiente, caminhos de pacotes e a inicialização dos prompts visuais para cada shell suportado (`sh`, `bash`, `zsh`).

---

## 📁 Catálogo de Plataformas Suportadas

| Sistema Operacional | Identificador (`uname -s`) | Shells Suportados   | Particularidades da Plataforma                                            |
| :------------------ | :------------------------- | :------------------ | :------------------------------------------------------------------------ |
| **Linux**           | `Linux`                    | `bash`, `zsh`       | GNU Coreutils, `systemd` / OpenRC / runit, temas D-Bus / GTK / Qt         |
| **FreeBSD**         | `FreeBSD`                  | `sh`, `bash`, `zsh` | Baseline POSIX (`/bin/sh` + EditLine), `pkg`, `doas` / `sudo`             |
| **OpenBSD**         | `OpenBSD`                  | `bash`, `zsh`       | Foco em segurança (`pledge`, `unveil`), `doas` nativo, `pkg_add`, X11     |
| **NetBSD**          | `NetBSD`                   | `bash`, `zsh`       | Berço da `libedit`, Almquist `/bin/sh`, ecossistema `pkgsrc` / `pkgin`    |
| **illumos**         | `SunOS`                    | `bash`, `zsh`       | Kernel SVR4 moderno, dualidade `/usr/gnu/bin` vs `/usr/bin`, SMF, ZFS     |
| **macOS**           | `Darwin`                   | `bash`, `zsh`       | Homebrew (`/opt/homebrew` vs `/usr/local`), `pbcopy`/`pbpaste`, BSD utils |
| **Windows**         | `MINGW*`, `MSYS*`          | `bash`, `zsh`       | Runtime MSYS2 / UCRT64, caminhos POSIX para Windows, ConPTY               |
