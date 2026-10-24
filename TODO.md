# 🗺️ Roadmap & Status — Universal Shell

> **Status:** 🟢 **100% Operacional & Estável — Zero Pendências Ativas**
> Todos os requisitos de arquitetura, latência (<16ms/64ms), shells nativos e alternativos foram integralmente concluídos.

---

## 📊 Matriz de Maturidade

| Área                    |   Status    | Cobertura / Estado                                                                                           |
| :---------------------- | :---------: | :----------------------------------------------------------------------------------------------------------- |
| **Plataformas Base**    | 🟢 Estável  | Linux, FreeBSD, DragonFly BSD, OpenBSD, NetBSD, illumos, macOS, Windows (MSYS2)                              |
| **Shells Nativos**      | 🟢 Estável  | Zsh, Bash, POSIX sh (FreeBSD), KornShell (OpenBSD)                                                           |
| **Shells Alternativos** | 🟢 Estável  | PowerShell 7+, NuShell, CMD (Clink), Fish Shell (`fish.fish`)                                                |
| **Latência & Boot**     | 🟢 Estável  | Latência rigorosamente < 16ms / 64ms em todas as plataformas                                                 |
| **Módulos Comuns**      | 🟢 Estável  | Simetria plana em `target/common/` (`bash.sh`, `fish.fish`, `ksh.sh`, `sh.sh`, `zsh.sh`)                     |
| **Resiliência TTY**     | 🟢 Estável  | Detecção de console puro, locale soberano UTF-8 e rendering adaptativo pill/micro                            |
| **Paridade Windows**    | 🟢 Estável  | Executáveis defensivos (winget/scoop/choco), PowerShell 5.1/7 e NuShell                                      |
| **UI & Semântica**      | 🟢 Estável  | Padrão `_ui_*` com ANSI POSIX puro via `printf`                                                              |
| **Display Server Core** | 🟢 Estável  | Arquitetura `_dispatch_display_server` com simetria `-wayland` e `-x11`                                      |
| **Lançadores Gráficos** | 🟢 Estável  | `graphical-launcher` (`gui`), `graphical-launcher-wayland` (`wgui`), `graphical-launcher-x11` (`xgui`)       |
| **Sessões Emacs OS**    | 🟢 Estável  | `emacs-window-manager` (`ewm`), `emacs-window-manager-wayland` (`wewm`), `emacs-window-manager-x11` (`xewm`) |
| **Sessões de Desktop**  | 🟢 Estável  | `window-manager` (`wm`/`win`), `window-manager-wayland` (`wwm`/`way`), `window-manager-x11` (`xwm`/`x11`)    |
| **Restauração Console** | 🟢 Estável  | VT bounce defensivo com `vidcontrol -s` no FreeBSD pós-compositor                                            |
| **Quality Gates**       | 🟢 Aprovado | 100% aprovado em `make test` e `make bench`                                                                  |

---

## 🛡️ Atributos Entregues

- **Despachante Universal de Display Server (`_dispatch_display_server`):** Desacoplamento completo entre comandos universais por extenso (`window-manager`, `graphical-launcher`, `emacs-window-manager`) e backends específicos via sufixos (`-wayland` e `-x11`), permitindo alternância transparente e autocompletion semântico agrupado.
- **Detecção Antifrágil de Backends (`_has_wayland` & `_has_x11`):** Verificação dupla combinando arquivos descritores FreeDesktop XDG (`/usr/share/wayland-sessions/`, `/usr/share/xsessions/`) e varredura categorizada no `$PATH` (`_micro`, `_desktops`, `_tilings`), imune a falsos positivos de `/dev/dri`.
- **Inicialização Multi-SO de Wayland (`_exec_wayland`) & X11 (`_exec_x11`):** Suporte nativo e adaptativo ao FreeBSD (ConsoleKit2 + dbus-launch), distribuições Linux com systemd (detecção e preservação íntegra de `/run/user/$UID/bus`, resolvendo crashes em targets do GNOME no TTY) e ambientes OpenBSD/Alpine/Devuan (`dbus-run-session` / `dbus-launch`), com resolução universal de terminais virtuais (`vtN`) no Linux (`/dev/tty*`), FreeBSD (`/dev/ttyv*`) e OpenBSD wscons (`/dev/ttyC*`).
- **Simetria Completa de Nomes & Aliases sem Conflitos:** Suíte ergonômica de atalhos (`wm`, `win`, `wwm`, `way`, `xwm`, `xorg`, `x11`, `gui`, `wgui`, `xgui`, `ewm`, `wewm`, `xewm`) sem colisões com comandos do sistema (como `wg` do WireGuard).
- **Lançador Gráfico Efêmero Multi-TTY (`graphical-launcher`):** Isolamento de processos gráficos avulsos por TTY com cascata Wayland (`sway > river > labwc > cage`) e Xorg (`xinit`), padrão `foot`/`xterm`.
- **Sessões Soberanas de Emacs OS (`emacs-window-manager`):** Execução dedicada em Wayland nativo (EAF / aweww) e X11 legado (EXWM via XELB) com auto-seleção universal.
- **Restauração de Console Antifrágil (VT Bounce):** Redesenho instantâneo via `vidcontrol -s` em consoles FreeBSD `/dev/ttyv*` após o término de compositores.
- **Suíte Tripartite Windows:** Paridade operacional completa entre PowerShell 7, NuShell e CMD (Clink).
- **Eliminação de Aliases Circulares:** Erradicação de recursão case-insensitive no PowerShell (`Clean-System`) e garantia de reentrância via `Set-Alias -Force -Option AllScope`.
- **Sincronização Dual de PATH no NuShell:** Resolução de inconsistência Win32 `Path` vs NuShell `$env.PATH` e configuração de `$env.ENV_CONVERSIONS`.
- **Autenticação Git HTTPS & Paridade nos Loaders do Vault:** Paridade completa em todos os loaders do ecossistema com filtragem universal de arquivos de template e injeção dinâmica de autenticação HTTPS via GitHub CLI.
- **Paridade Google Antigravity CLI (`agy`):** Aliases completos (`agyc`, `agya`, `agyca`, etc.) sincronizados entre PowerShell, NuShell e CMD.
- **Auto-Cura Reentrante de Perfis Físicos:** Sincronização cruzada automática entre perfis de PowerShell, NuShell e Clink via `upsh` e `resh` sem qualquer comando manual.
- **Higienização Pré-Pull de Editores:** Limpeza defensiva de stubs locais (`usr/local/`) em `Update-Editors` antes de merges fast-forward.
- **Paridade UTF-8 no Git:** Configuração universal `core.quotepath = false` contra sequências octais de escape em caracteres acentuados.
- **Zero Pendências:** Toda a suíte de scripts, ganchos e documentações está concluída e auditada.
- **Sincronização:** Total alinhamento com os 22 Princípios de Engenharia UNIX do Universal Environment.
