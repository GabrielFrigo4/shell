# 🎯 context/ — Orquestração por Contexto de Uso

Esta pasta gerencia as especializações dinâmicas (`0644`, carregadas via `source`) do **Universal Shell Environment** de acordo com a carga de trabalho ativa da máquina (`SHELL_CONTEXT`).

---

## 📁 Estrutura dos 3 Contextos Canônicos

- 💻 **`desktop/`**: Estação de trabalho gráfica (Linux, FreeBSD, OpenBSD, NetBSD, illumos, macOS, Windows MSYS2) orquestrada pelo dispatcher `library/desktop.sh` (`desktop/{detect,theme,emacs,apps}.sh` diretos + `desktop/{device,kiosk,session}.sh` _lazy_ exclusivos de `SHELL_CONTEXT=desktop`), integrando variáveis de toolkit via `_desktop_apply_theme_context`, `target/common/session.sh`, aliases leves (`r`, `delta`), extensão WSL (`wsl.sh`) e cache Python isolado (`PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"`).
- 🌐 **`server/`**: Máquinas de produção e servidores dedicados com aliases para administração de rede, serviços (`systemctl`, `svcs`, `rcctl`, `service`), logs (`journalctl`, `/var/log/messages`), extensão headless para WSL (`wsl.sh`) e cache centralizado Python (`PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"`).
- 📦 **`container/`**: Ambientes de contêineres que compartilham o kernel hospedeiro (Linux namespaces/cgroups, FreeBSD Jails, Solaris/illumos Zones) com carregamento ultraleve (sem carregar `library/desktop.sh`), comandos mínimos e cache Python efêmero em `PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME:-${HOME}/.cache}/pycache"`.

---

## ⚙️ Contrato de Arquitetura em Duas Camadas

Dentro de cada contexto:

1. **`common.sh`**: Sourced primeiro. Exporta aliases e variáveis genéricas do contexto, independentes do sistema operacional.
2. **`{OS}.sh`** (ex: `linux.sh`, `freebsd.sh`, `openbsd.sh`, `netbsd.sh`, `illumos.sh`, `macos.sh`, `windows.sh`): Sourced em seguida. Adiciona comandos ou wrappers que utilizam binários exclusivos daquele kernel ou plataforma.

Consulte mais detalhes em **[docs/CONTEXTS.md](../docs/CONTEXTS.md)**.
